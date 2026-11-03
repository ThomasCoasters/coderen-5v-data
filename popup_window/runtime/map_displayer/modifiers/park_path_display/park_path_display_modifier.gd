class_name ParkPathDisplayModifier
extends PopupWindowModifier

func refresh() -> void:
	for child in get_children():
		child.queue_free()
	var current_park: ParkID = window.current_park
	
	while window.current_park.path_data.is_empty():
		if not current_park == window.current_park: return
		await get_tree().process_frame
	
	_draw_park_paths(window.park_map_displayer.current_tile_settings)


func _draw_park_paths(tile_settings: ParkMapDisplayer.TileSettings) -> void:
	if not window.current_park:
		emit_error("Could not find the current park, try resetting the park paths. If the issue persists, try resetting the program.")
		return
		
	var paths_data = window.current_park.path_data
	if paths_data.is_empty():
		emit_error("Could not find path data for the current park, some parks have this issue. If this issue persists through every park, try resetting the program.")
		return
	
	
	for way in paths_data:
		var line_2d = Line2D.new()
		line_2d.width = 3.0
		line_2d.default_color = Color(0.9, 0.2, 0.2, 0.8) # Red lines for pedestrian paths
		line_2d.antialiased = true
		
		for point in way:
			var pos = ParkMapDisplayer._lon_lat_to_pixel(
				point[1],
				point[0],
				tile_settings,
				window.park_map_displayer.padded_pixels_northwest,
				window.park_map_displayer.current_image_scale
			)
			line_2d.add_point(pos)
			
		add_child(line_2d)


func emit_error(error_text: String) -> void:
	var error_popup: AcceptDialog = AcceptDialog.new()
	error_popup.title = "Error! Sorry :("
	error_popup.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
	error_popup.dialog_text = error_text
	error_popup.ok_button_text = "I understand."
	error_popup.dialog_autowrap = true
	error_popup.visible = true
	add_child(error_popup)
