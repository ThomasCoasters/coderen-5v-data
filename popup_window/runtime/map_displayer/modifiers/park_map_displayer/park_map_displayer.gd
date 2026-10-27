@icon("uid://wtmvjebpaw26")
class_name ParkMapDisplayer
extends TextureRect
## A [TextureRect] displaying a given [ParkID]'s sattelite image.

signal image_refresh_requested(_park: ParkID)

signal image_requests_finished
signal http_requester_freed

## The size each tile is in pixels.
const TILE_SIZE: int = 256
## The maximum amount of tiles that can be used per axis to display the map of the park.
const MAX_TARGET_TILES: int = 20

const MAX_CONCURRENT_HTTP_REQUESTS: int = 4

@export_range(0, 200, 1, "or_greater") var padding_pixels: int = 50
@export var max_screen_scale_size: Vector2 = Vector2(0.85, 0.85)
var max_size: Vector2 = Vector2i(1920, 1080)

@export_category("Backup Values")
@export var backup_grid_size: Vector2i = Vector2i(4, 4)
@export_range(1, 20) var backup_zoom: int = 16

## The combined end image gotten from stitching multiple images together
var stitched_image: Image = Image.new()

var current_tile_settings: TileSettings



var http_requests_left: int = 0:
	set(value):
		http_requests_left = value
		
		if http_requests_left == 0:
			image_requests_finished.emit()

var free_http_requesters: Array[HTTPRequest]


var padded_pixels_northwest: Vector2
var padded_pixels_southeast: Vector2

var current_image_scale: float

func _enter_tree() -> void:
	max_size = Vector2i(Vector2(DisplayServer.screen_get_size()) * max_screen_scale_size)
	print(max_size)


## Refreshes the image to display the sattelite of the current [param park].
func refresh_image(park: ParkID) -> void:
	if not is_inside_tree():
		return
	
	image_refresh_requested.emit(park)
	
	current_tile_settings = TileSettings.new()
	
	current_tile_settings.zoom = backup_zoom
	current_tile_settings.grid = backup_grid_size
	
	# go through every attraction to check
	# if it's longitutional or lateral values are the min or max
	for attraction: AttractionID in park.attractions:
		if current_tile_settings.cords_unidentified():
			current_tile_settings.min_lon = attraction.longitude
			current_tile_settings.max_lon = attraction.longitude
			current_tile_settings.min_lat = attraction.latitude
			current_tile_settings.max_lat = attraction.latitude
			
			continue
		
		if not attraction.longitude == 0.0:
			current_tile_settings.min_lon = min(current_tile_settings.min_lon, attraction.longitude)
			current_tile_settings.max_lon = max(current_tile_settings.max_lon, attraction.longitude)
		
		if not attraction.latitude == 0.0:
			current_tile_settings.min_lat = min(current_tile_settings.min_lat, attraction.latitude)
			current_tile_settings.max_lat = max(current_tile_settings.max_lat, attraction.latitude)
	
	
	
	
	if current_tile_settings.cords_unidentified():
		var error_popup: AcceptDialog = AcceptDialog.new()
		error_popup.title = "Error! Sorry :("
		error_popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
		error_popup.dialog_text = "Due to an error in the data this program uses, the map display for %s has no attractions, and thus will be displaying a rough area. The attraction marker modifier will also be useless." %park.name
		error_popup.ok_button_text = "I understand."
		error_popup.dialog_autowrap = true
		error_popup.visible = true
		error_popup.size = Vector2i(400, 200)
		add_child(error_popup)
		
		var park_tile: Vector2i = _lon_lat_to_tile(
			park.longitude,
			park.latitude,
			current_tile_settings.zoom
		)
		
		# get the starting and ending tiles
		current_tile_settings.start_tile_x = park_tile.x - floor(float(current_tile_settings.grid.x) / 2)
		current_tile_settings.end_tile_x = park_tile.x + ceil(float(current_tile_settings.grid.x) / 2)
		current_tile_settings.start_tile_y = park_tile.y - floor(float(current_tile_settings.grid.y) / 2)
		current_tile_settings.end_tile_y = park_tile.y + ceil(float(current_tile_settings.grid.y) / 2)
		
		padded_pixels_northwest = Vector2(
			current_tile_settings.start_tile_x * TILE_SIZE,
			current_tile_settings.start_tile_y * TILE_SIZE
		)
		padded_pixels_southeast = Vector2(
			(current_tile_settings.end_tile_x + 1) * TILE_SIZE,
			(current_tile_settings.end_tile_y + 1) * TILE_SIZE
		)
	
	else:
		current_tile_settings.grid = _calculate_tiles()
	
	# create the stitched image
	stitched_image = Image.create_empty(current_tile_settings.grid.x * TILE_SIZE, current_tile_settings.grid.y * TILE_SIZE, false, Image.FORMAT_RGBA8)
	
	# actually start creating the image
	_start_tile_grid_queue()


func _start_tile_grid_queue() -> void:
	free_http_requesters.clear()
	for child in get_children():
		if child is HTTPRequest:
			child.queue_free()
	
	http_requests_left = 0
	
	for i: int in range(MAX_CONCURRENT_HTTP_REQUESTS):
		var http_request: HTTPRequest = HTTPRequest.new()
		http_request.use_threads = true
		
		http_request.request_completed.connect(
			_on_request_completed.bind(
				http_request
			)
		)
		
		add_child.call_deferred(http_request)
		
		await http_request.tree_entered
		
		free_http_requesters.append(http_request)
	
	for tile_x in range(current_tile_settings.start_tile_x, current_tile_settings.end_tile_x + 1):
		for tile_y in range(current_tile_settings.start_tile_y, current_tile_settings.end_tile_y + 1):
			var destination_x: int = (tile_x - current_tile_settings.start_tile_x) * TILE_SIZE
			var destination_y: int = (tile_y - current_tile_settings.start_tile_y) * TILE_SIZE
			var destination: Vector2i = Vector2i(destination_x, destination_y)
			
			while free_http_requesters.is_empty():
				await http_requester_freed
			
			var http_request: HTTPRequest = free_http_requesters.pop_front()
			
			http_request.set_meta("current_destination_pos", destination)
			
			var url = "https://mt1.google.com/vt/lyrs=s&x=%d&y=%d&z=%d" %[tile_x, tile_y, current_tile_settings.zoom]
			
			http_requests_left += 1
			http_request.request(url)
	
	
	if not http_requests_left <= 0:
		await image_requests_finished
	
	
	var crop_origin = padded_pixels_northwest - Vector2(current_tile_settings.start_tile_x * TILE_SIZE, current_tile_settings.start_tile_y * TILE_SIZE)
	var crop_size = padded_pixels_southeast - padded_pixels_northwest
	var crop_rect = Rect2i(int(crop_origin.x), int(crop_origin.y), int(crop_size.x), int(crop_size.y))
	
	crop_rect = crop_rect.intersection(Rect2i(0, 0, stitched_image.get_width(), stitched_image.get_height()))
	if crop_rect.has_area():
		stitched_image = stitched_image.get_region(crop_rect)
	
	var image_size: Vector2i = stitched_image.get_size()
	if image_size.x > max_size.x or image_size.y > max_size.y:
		current_image_scale = min(max_size.x / image_size.x, max_size.y / image_size.y)
		image_size = image_size * current_image_scale
	else:
		current_image_scale = 1.0
	
	stitched_image.resize(image_size.x, image_size.y)
	var image_texture: ImageTexture = ImageTexture.create_from_image(stitched_image)
	
	
	texture = image_texture
	
	size = image_size
	print("new size: ", size)


func _on_request_completed(
	_result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	requestee: HTTPRequest
) -> void:
	
	
	var current_destination_pos: Vector2i = requestee.get_meta("current_destination_pos")
	
	free_http_requesters.append(requestee)
	
	if not free_http_requesters.is_empty():
		http_requester_freed.emit()
	
	if not response_code == 200:
		printerr("Could not load a jpeg from the body that was returned. Creating empty space")
		
		stitched_image.blit_rect(
			Image.create_empty(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8),
			Rect2i(0, 0, TILE_SIZE, TILE_SIZE),
			current_destination_pos
		)
		http_requests_left -= 1
		return
	
	var tile_image: Image = Image.new()
	
	tile_image.load_jpg_from_buffer(body)
	
	tile_image.convert(Image.FORMAT_RGBA8)
	
	if tile_image.get_width() != TILE_SIZE:
		tile_image.resize(TILE_SIZE, TILE_SIZE)
	
	stitched_image.blit_rect(tile_image, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), current_destination_pos)
	
	http_requests_left -= 1



static func _lon_lat_to_tile(lon: float, lat: float, zoom_value: int) -> Vector2i:
	var lat_rad = deg_to_rad(clamp(lat, -85.051129, 85.051129))
	var n = pow(2.0, zoom_value)
	var x = int(floor((lon + 180.0) / 360.0 * n))
	var y = int(floor((1.0 - log(tan(lat_rad) + 1.0 / cos(lat_rad)) / PI) / 2.0 * n))
	return Vector2i(x, y)

static func _get_mercator_y(lat: float) -> float:
	var clamped_lat = clamp(lat, -85.051129, 85.051129)
	var lat_rad = deg_to_rad(clamped_lat)
	return (1.0 - log(tan(lat_rad) + 1.0 / cos(lat_rad)) / PI) / 2.0


static func _lon_lat_to_world_pixel(lon: float, lat: float, zoom_value: int) -> Vector2:
	var n = pow(2.0, zoom_value)
	var world_pixel_x = (lon + 180.0) / 360.0 * n * TILE_SIZE
	var world_pixel_y = _get_mercator_y(lat) * n * TILE_SIZE
	return Vector2(world_pixel_x, world_pixel_y)

static func _lon_lat_to_pixel(
	lon: float,
	lat: float,
	tile_settings: TileSettings,
	padded_px_nw: Vector2,
	image_scale: float
) -> Vector2:
	var world_pixel = _lon_lat_to_world_pixel(lon, lat, tile_settings.zoom)
	return Vector2(
		world_pixel.x - padded_px_nw.x,
		world_pixel.y - padded_px_nw.y
	) * image_scale

func _calculate_tiles() -> Vector2i:
	var delta_lon = max(current_tile_settings.max_lon - current_tile_settings.min_lon, 0.0001)
	
	var y_min: float = _get_mercator_y(current_tile_settings.min_lat)
	var y_max: float = _get_mercator_y(current_tile_settings.max_lat)
	var delta_y: float = max(abs(y_max - y_min), 0.0001)
	
	var lon_zoom: float = log(MAX_TARGET_TILES / (delta_lon / 360.0)) / log(2.0)
	var lat_zoom: float = log(MAX_TARGET_TILES / delta_y) / log(2.0)
	
	current_tile_settings.zoom = int(clamp(floor(min(lon_zoom, lat_zoom)), 0, 20))
	
	var p_nw = _lon_lat_to_world_pixel(current_tile_settings.min_lon, current_tile_settings.max_lat, current_tile_settings.zoom)
	var p_se = _lon_lat_to_world_pixel(current_tile_settings.max_lon, current_tile_settings.min_lat, current_tile_settings.zoom)
	
	padded_pixels_northwest = p_nw - Vector2(padding_pixels, padding_pixels)
	padded_pixels_southeast = p_se + Vector2(padding_pixels, padding_pixels)
	
	current_tile_settings.start_tile_x = int(floor(padded_pixels_northwest.x / TILE_SIZE))
	current_tile_settings.start_tile_y = int(floor(padded_pixels_northwest.y / TILE_SIZE))
	current_tile_settings.end_tile_x = int(floor(padded_pixels_southeast.x / TILE_SIZE))
	current_tile_settings.end_tile_y = int(floor(padded_pixels_southeast.y / TILE_SIZE))
	
	var grid_width = (current_tile_settings.end_tile_x - current_tile_settings.start_tile_x) + 1
	var grid_height = (current_tile_settings.end_tile_y - current_tile_settings.start_tile_y) + 1
	
	print("width: ", grid_width, ", height: ", grid_height)
	
	return Vector2i(grid_width, grid_height)


class TileSettings extends RefCounted:
	var min_lon: float = INF
	var max_lon: float = -INF
	var min_lat: float = INF
	var max_lat: float = -INF
	
	var start_tile_x: int = 0
	var end_tile_x: int = 0
	var start_tile_y: int = 0
	var end_tile_y: int = 0
	
	var zoom: int
	
	var grid: Vector2i
	
	
	func cords_unidentified() -> bool:
		return(
			min_lon == INF and min_lat == INF and max_lon == -INF and max_lat == -INF
		) or ( 
			min_lon == 0.0 and min_lat == 0.0 and max_lon == 0.0 and max_lat == 0.0
		)
