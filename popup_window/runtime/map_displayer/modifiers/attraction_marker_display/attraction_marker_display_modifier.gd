class_name AttractionMarkerDisplayModifier
extends PopupWindowModifier


const ATTRACTION_MARKER = preload("uid://bhnnv4bd5btjb")


var marker_wait_time: float = 0.05
var wait_time_randomness: float = 1

var queued_for_remove: bool = false


func get_generated_window_settings(attraction: AttractionID) -> GeneratedWindowSettings:
	var window_settings: GeneratedWindowSettings = GeneratedWindowSettings.new()
	
	window_settings.window_scene = preload("uid://ctepg2rx4pfat")
	window_settings.ignore_cap = true
	window_settings.aditional_values["Attraction"] = attraction
	
	
	return window_settings

func refresh() -> void:
	if queued_for_remove: return
	for child in get_children():
		child.queue_free()
	_draw_attraction_markers(window.park_map_displayer.current_tile_settings)


func remove() -> void:
	if queued_for_remove: return
	queued_for_remove = true
	
	for child in get_children():
		if child is AttractionMarker:
			child.queue_delete()
		else:
			child.queue_free()
		await get_tree().create_timer(
			marker_wait_time + marker_wait_time * (wait_time_randomness * ((randf() * 2) -1))
		).timeout
	
	while get_child_count() > 0:
		await get_tree().process_frame
	
	queue_free()


func _draw_attraction_markers(tile_settings: ParkMapDisplayer.TileSettings) -> void:
	var attraction_marker_by_location: Dictionary[Vector2, AttractionMarker]
	
	for attraction: AttractionID in window.current_park.attractions:
		var pos = ParkMapDisplayer._lon_lat_to_pixel(
			attraction.longitude,
			attraction.latitude,
			tile_settings,
			window.park_map_displayer.padded_pixels_northwest,
			window.park_map_displayer.current_image_scale
		) + global_position
		
		var attraction_marker: AttractionMarker = ATTRACTION_MARKER.instantiate()
		attraction_marker.position = pos + attraction_marker.position
		attraction_marker.tooltip_text = attraction.name
		attraction_marker.z_index += 1
		
		attraction_marker.pressed.connect(DesktopIconOutput.output_by_window_settings.bind(get_generated_window_settings(attraction)))
		
		attraction_marker_by_location[Vector2(attraction.longitude, attraction.latitude)] = attraction_marker
	
	var attraction_positions: Array[Vector2] = attraction_marker_by_location.keys()
	attraction_positions.sort_custom(
		func(pos_a: Vector2, pos_b: Vector2):
			if pos_a.y > pos_b.y: return true
			return false
	)
	
	for attraction_position: Vector2 in attraction_positions:
		if queued_for_remove: return
		add_child(attraction_marker_by_location[attraction_position])
		await get_tree().create_timer(
			marker_wait_time + marker_wait_time * (wait_time_randomness * ((randf() * 2) -1))
		).timeout
