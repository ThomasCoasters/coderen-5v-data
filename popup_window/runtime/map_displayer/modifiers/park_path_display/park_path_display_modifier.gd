class_name ParkPathDisplayModifier
extends PopupWindowModifier


const INVIS_THEME = preload("uid://drannfj12iked")
const CLICK_MARKER = preload("uid://capvxrjlsqcad")

const NORMAL_PATH_COLOR: Color = Color(0.718, 0.959, 0.853, 0.91)
const FASTEST_PATH_COLOR: Color = Color(0.216, 0.376, 1.0, 1.0)
const COMBINE_TOLERANCE: float = 5.0

const WALK_SPEED_M_PER_S: float = 1.3
const STEP_METERS: float = 0.71


var path_holder: Node

var a_star: AStar2D = AStar2D.new()
var last_point: Vector2 = Vector2.INF
var fastest_path_line: Line2D
var click_markers: Array[ClickMarker]

var queued_for_remove: bool = false


func _input(event: InputEvent) -> void:
	if queued_for_remove: return
	if event is InputEventMouseButton:
		if not event.button_index == MOUSE_BUTTON_RIGHT:
			return
		if not event.pressed:
			return
		if HoverCheck.is_interactable_hovered(get_viewport()):
			return
		
		_calculate_path()


func refresh() -> void:
	if queued_for_remove: return
	for child in get_children():
		child.queue_free()
	
	var current_park: ParkID = window.current_park
	
	while window.current_park.path_data.is_empty():
		if not current_park == window.current_park: return
		await get_tree().process_frame
	
	_draw_park_paths(window.park_map_displayer.current_tile_settings)


func remove() -> void:
	if queued_for_remove: return
	queued_for_remove = true
	
	if fastest_path_line:
		var path_remove_tween: Tween = create_tween()
		path_remove_tween.set_trans(Tween.TRANS_LINEAR)
		
		for point: int in fastest_path_line.gradient.get_point_count():
			path_remove_tween.tween_method(
				func(value):
					fastest_path_line.gradient.set_color(point, value),
				FASTEST_PATH_COLOR,
				Color(FASTEST_PATH_COLOR, 0.0),
				0.5
			)
		
		await path_remove_tween.finished
		fastest_path_line.queue_free()
	
	for click_marker: ClickMarker in click_markers:
		if click_marker: await click_marker.queue_delete()
	
	for path: Node in path_holder.get_children():
		await get_tree().process_frame
		if path is Line2D:
			var normal_path_remove_tween: Tween = create_tween()
			normal_path_remove_tween.finished.connect(path.queue_free)
			for point: int in path.gradient.get_point_count():
				normal_path_remove_tween.tween_method(
					func(value):
						path.gradient.set_color(point, value),
					NORMAL_PATH_COLOR,
					Color(NORMAL_PATH_COLOR, 0.0),
					1.0
				)
		else:
			path.queue_free()
			continue
	
	while get_child_count() > 0:
		if path_holder.get_child_count() == 0: path_holder.queue_free()
		await get_tree().process_frame
	
	queue_free()


func _draw_park_paths(tile_settings: ParkMapDisplayer.TileSettings) -> void:
	if not window.current_park:
		window.main.create_error_popup("Could not find the current park, try resetting the park paths. If the issue persists, try resetting the program.")
		return
		
	var paths_data = window.current_park.path_data
	if paths_data.is_empty():
		window.main.create_error_popup("Could not find path data for the current park, some parks have this issue. If this issue persists through every park, try resetting the program.")
		return
	
	path_holder = Node.new()
	add_child(path_holder)
	
	a_star.clear()
	
	var current_id: int = 0
	var position_to_id: Dictionary[Vector2, int] = {}

	for way in paths_data:
		if queued_for_remove: return
		
		var line_2d = Line2D.new()
		line_2d.width = 3.0
		line_2d.default_color = NORMAL_PATH_COLOR
		line_2d.antialiased = true
		
		var last_point_id: int = -1
		
		for point in way:
			var pos = ParkMapDisplayer._lon_lat_to_pixel(
				point[1],
				point[0],
				tile_settings,
				window.park_map_displayer.padded_pixels_northwest,
				window.park_map_displayer.current_image_scale
			) + global_position
			
			if not (pos.x > 0 and pos.x < window.size.x and pos.y > 0 and pos.y < window.size.y):
				continue
				
			line_2d.add_point(pos)
			
			var matched_id: int = -1
			var snapped_pos: Vector2 = (pos / COMBINE_TOLERANCE).floor() * COMBINE_TOLERANCE
			
			if position_to_id.has(snapped_pos):
				matched_id = position_to_id[snapped_pos]
			else:
				for existing_pos in position_to_id:
					if existing_pos.distance_to(pos) <= COMBINE_TOLERANCE:
						matched_id = position_to_id[existing_pos]
						break
			
			var current_point_id: int
			if matched_id != -1:
				current_point_id = matched_id
			else:
				current_point_id = current_id
				a_star.add_point(current_point_id, pos)
				position_to_id[snapped_pos] = current_point_id
				current_id += 1
			
			if not last_point_id == -1 and not last_point_id == current_point_id:
				if not a_star.are_points_connected(last_point_id, current_point_id):
					a_star.connect_points(last_point_id, current_point_id)
			
			last_point_id = current_point_id
		
		path_holder.add_child(line_2d)
		
		var visible_gradient: Gradient = Gradient.new()
		for point: int in visible_gradient.get_point_count():
			visible_gradient.set_color(point, Color(NORMAL_PATH_COLOR, 0.0))
		
		line_2d.gradient = visible_gradient
		
		var path_tween: Tween = create_tween()
		for point: int in visible_gradient.get_point_count():
			path_tween.tween_method(
				func(value):
					visible_gradient.set_color(point, value),
				Color(NORMAL_PATH_COLOR, 0.0),
				NORMAL_PATH_COLOR,
				1.0
			)
		
		if path_holder.get_child_count() % 4: await get_tree().process_frame


func _calculate_path() -> void:
	if fastest_path_line:
		var old_line: Line2D = fastest_path_line
		
		var path_remove_tween: Tween = create_tween()
		path_remove_tween.set_trans(Tween.TRANS_LINEAR)
		path_remove_tween.finished.connect(
			old_line.queue_free
		)
		
		for point: int in fastest_path_line.gradient.get_point_count():
			path_remove_tween.tween_method(
				func(value):
					fastest_path_line.gradient.set_color(point, value),
				FASTEST_PATH_COLOR,
				Color(FASTEST_PATH_COLOR, 0.0),
				0.5
			)
	
	
	if last_point == Vector2.INF:
		last_point = DisplayServer.mouse_get_position() - window.position
		
		for click_marker: ClickMarker in click_markers:
			if click_marker: click_marker.queue_delete()
		click_markers.clear()
		
		var first_click_marker = CLICK_MARKER.instantiate()
		click_markers.append(first_click_marker)
		first_click_marker.position = a_star.get_closest_position_in_segment(
			last_point
		) - Vector2(
			first_click_marker.size.x / 2,
			first_click_marker.size.y
		)
		add_child(first_click_marker)
		return
	
	var new_point: Vector2 = DisplayServer.mouse_get_position() - window.position
	
	var click_marker = CLICK_MARKER.instantiate()
	click_markers.append(click_marker)
	click_marker.position = a_star.get_closest_position_in_segment(
		new_point
	) - Vector2(
		click_marker.size.x / 2,
		click_marker.size.y
	)
	add_child(click_marker)
	
	
	var path: PackedVector2Array = a_star.get_point_path(
		a_star.get_closest_point(last_point),
		a_star.get_closest_point(new_point)
	)
	if path.is_empty():
		window.main.create_error_popup("Could not calculate fastest path between points.")
	path.insert(0, a_star.get_closest_position_in_segment(last_point))
	path.append(a_star.get_closest_position_in_segment(new_point))
	_create_data_window(path)
	
	fastest_path_line = Line2D.new()
	fastest_path_line.joint_mode = Line2D.LINE_JOINT_ROUND
	fastest_path_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	fastest_path_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	fastest_path_line.width = 5.0
	fastest_path_line.antialiased = true
	
	var visible_gradient: Gradient = Gradient.new()
	for point: int in visible_gradient.get_point_count():
		visible_gradient.set_color(point, Color(FASTEST_PATH_COLOR, 0.0))
	
	fastest_path_line.gradient = visible_gradient
	
	
	for point in path:
		fastest_path_line.add_point(point)
	
	add_child(fastest_path_line)
	
	last_point = Vector2.INF
	
	
	var path_tween: Tween = create_tween()
	path_tween.set_trans(Tween.TRANS_LINEAR)
	for point: int in visible_gradient.get_point_count():
		path_tween.tween_method(
			func(value):
				visible_gradient.set_color(point, value),
			Color(FASTEST_PATH_COLOR, 0.0),
			FASTEST_PATH_COLOR,
			0.5
		)



func _create_data_window(path: PackedVector2Array) -> void:
	var distance: float = calculate_distance(path)
	distance = snappedf(distance, 0.1)
	var distance_data: DistanceData = DistanceData.new()
	distance_data.distance = distance
	
	var walk_time: TimeData = seconds_to_time(meters_to_seconds(distance))
	var step_count: int = meters_to_steps(distance)
	
	
	var window_settings: GeneratedWindowSettings = GeneratedWindowSettings.new()
	
	window_settings.window_scene = preload("uid://fequey4u5qqw")
	window_settings.ignore_cap = true
	window_settings.aditional_values["distance_data"] = distance_data
	window_settings.aditional_values["steps"] = step_count
	window_settings.aditional_values["time"] = walk_time
	@warning_ignore("integer_division")
	window_settings.aditional_values["position"] = path[path.size() / 2] + Vector2(window.position)
	
	DesktopIconOutput.output_by_window_settings(window_settings)
	


func calculate_distance(path: PackedVector2Array) -> float:
	var total_distance: float = 0.0
	var last_pos: Vector2 = Vector2.INF
	
	for path_pos: Vector2 in path:
		if not last_pos == Vector2.INF:
			total_distance += ParkMapDisplayer.pixel_meter_distance(
				last_pos,
				path_pos,
				window.park_map_displayer.current_tile_settings,
				window.park_map_displayer.padded_pixels_northwest,
				window.park_map_displayer.current_image_scale
			)
		
		last_pos = path_pos
	
	return total_distance


func meters_to_seconds(meters: float) -> int:
	return roundi(meters * WALK_SPEED_M_PER_S)

func meters_to_steps(meters: float) -> int:
	return roundi(meters / STEP_METERS)

func seconds_to_time(seconds: float) -> TimeData:
	var minutes: int = floori(seconds/60)
	var hours: int = floori(float(minutes)/60)
	seconds -= minutes * 60
	minutes -= hours * 60
	
	var time_data: TimeData = TimeData.new()
	time_data.seconds = seconds
	time_data.minutes = minutes
	time_data.hours = hours
	
	return time_data
