class_name AttractionMarkerDisplayModifier
extends PopupWindowModifier

const ATTRACTION_MARKER = preload("uid://bhnnv4bd5btjb")

func get_generated_window_settings(attraction: AttractionID) -> GeneratedWindowSettings:
	var window_settings: GeneratedWindowSettings = GeneratedWindowSettings.new()
	
	window_settings.window_scene = preload("uid://ctepg2rx4pfat")
	window_settings.ignore_cap = true
	window_settings.aditional_values["Attraction"] = attraction
	
	
	return window_settings

func refresh() -> void:
	for child in get_children():
		child.queue_free()
	_draw_attraction_markers(window.park_map_displayer.current_tile_settings)


func _draw_attraction_markers(tile_settings: ParkMapDisplayer.TileSettings) -> void:
	for attraction: AttractionID in window.current_park.attractions:
		var pos = ParkMapDisplayer._lon_lat_to_pixel(
			attraction.longitude,
			attraction.latitude,
			tile_settings,
			window.park_map_displayer.padded_pixels_northwest,
			window.park_map_displayer.current_image_scale
		) + global_position
		
		var attraction_marker: Button = ATTRACTION_MARKER.instantiate()
		attraction_marker.position = pos + attraction_marker.position
		attraction_marker.tooltip_text = attraction.name
		attraction_marker.z_index += 1
		
		attraction_marker.pressed.connect(DesktopIconOutput.output_by_window_settings.bind(get_generated_window_settings(attraction)))
		add_child(attraction_marker)
