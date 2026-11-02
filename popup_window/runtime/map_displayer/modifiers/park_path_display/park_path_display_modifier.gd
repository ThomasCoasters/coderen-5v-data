class_name ParkPathDisplayModifier
extends PopupWindowModifier

func refresh() -> void:
	for child in get_children():
		child.queue_free()
	_draw_park_paths(window.park_map_displayer.current_tile_settings)


func _draw_park_paths(tile_settings: ParkMapDisplayer.TileSettings) -> void:
	if not window.current_park:
		return
		
	var paths_data = window.current_park.path_data
	if paths_data.is_empty():
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
	
	print("completed")
