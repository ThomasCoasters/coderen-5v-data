class_name BadApplePlayer
extends Node


const BADAPPLE: VideoStream = preload("uid://cqcqyeic10216")

var time_per_frame: float = 0.5
var video_player: VideoStreamPlayer

var video_timer: Timer

var desktop_icon_colored: Dictionary[Vector2i, bool]
var generated_desktop_icons: Array[String]
var max_desktop_icons: Vector2i

func _init(p_time_per_frame: float = 1.3) -> void:
	time_per_frame = p_time_per_frame


func _ready() -> void:
	video_player = VideoStreamPlayer.new()
	video_player.hide()
	video_player.stream = BADAPPLE
	add_child(video_player)
	video_player.finished.connect(_remove_all_icons)
	
	video_timer = Timer.new()
	video_timer.wait_time = time_per_frame
	video_timer.timeout.connect(display_current_frame)
	add_child(video_timer)
	
	await setup_desktop_icons()
	
	video_timer.start()
	video_player.play()
	


func setup_desktop_icons() -> void:
	var to_be_created_icons: Array[GeneratedDesktopIconSettings]
	max_desktop_icons = Vector2i.ZERO
	
	while max_desktop_icons.x < 5 or max_desktop_icons.x > 200 or max_desktop_icons.y < 5 or max_desktop_icons.y > 200:
		await get_tree().create_timer(0.5).timeout
		max_desktop_icons = DesktopIconCalculator.GetMaxDesktopIcons(DisplayServer.screen_get_size())
		print(max_desktop_icons)
	
	for y: int in max_desktop_icons.y:
		for x: int in max_desktop_icons.x:
			var position: Vector2i = Vector2i(x, y)
			desktop_icon_colored[position] = false
			
			to_be_created_icons.append(_get_desktop_icon_settings(position, false))
	
	to_be_created_icons.sort_custom(
		func(icon_a: GeneratedDesktopIconSettings, icon_b: GeneratedDesktopIconSettings):
			var pos_a_array: Array = JSON.parse_string(icon_a.name)
			var pos_b_array: Array = JSON.parse_string(icon_b.name)
			var pos_a: Vector2i = Vector2i(pos_a_array[0], pos_a_array[1])
			var pos_b: Vector2i = Vector2i(pos_b_array[0], pos_b_array[1])
			
			# if row above
			if pos_a.y < pos_b.y:
				return true
			
			# if row below
			if pos_a.y > pos_b.y:
				return false
			# if same row to the left
			if pos_a.x < pos_b.x:
				return true
			
			# if same row, to the right
			return false
	)
	
	await _create_icons(to_be_created_icons)
	await get_tree().create_timer(5).timeout


func display_current_frame() -> void:
	video_timer.start()
	
	var texture: Texture2D = video_player.get_video_texture()
	if not texture: return
	
	var frame: Image = texture.get_image()
	if frame.is_empty(): return
	
	var frame_size: Vector2i = frame.get_size()
	
	var icon_width: float = float(frame_size.x) / float(max_desktop_icons.x)
	var icon_height: float = float(frame_size.y) / float(max_desktop_icons.y)
	
	var to_be_updated_icons: Array[GeneratedDesktopIconSettings]
	
	for y: int in max_desktop_icons.y:
		for x: int in max_desktop_icons.x:
			var position: Vector2i = Vector2i(x, y)
			
			# Define the rectangular region for this specific desktop icon
			var region_rect := Rect2i(
				int(x * icon_width),
				int(y * icon_height),
				int(icon_width),
				int(icon_height)
			)
			
			region_rect = region_rect.intersection(Rect2i(Vector2i.ZERO, frame_size))
			if region_rect.has_area() == false:
				continue
				
			# Crop the frame to the icon's sub-region
			var sub_image: Image = frame.get_region(region_rect)
			
			# Calculate the average color of this sub-region
			var avg_color: Color = _calculate_average_color(sub_image)
			
			var is_colored: bool = avg_color.get_luminance() > 0.5
			
			if is_colored == desktop_icon_colored[position]: continue
			desktop_icon_colored[position] = is_colored
			to_be_updated_icons.append(_get_desktop_icon_settings(position, is_colored))
	
	if not to_be_updated_icons.is_empty():
		await _create_icons(to_be_updated_icons, true)
		var updated_names: Array[String] = []
		for icon_settings in to_be_updated_icons:
			updated_names.append(icon_settings.name)

		DesktopIconSpawner.RefreshMultipleIcons(updated_names)


func _calculate_average_color(img: Image) -> Color:
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
		
	var total_r: float = 0.0
	var total_g: float = 0.0
	var total_b: float = 0.0
	var pixel_count: int = 0
	
	var width: int = img.get_width()
	var height: int = img.get_height()
	var step: int = max(1, int(min(width, height) / 8))
	
	for y: int in range(0, height, step):
		for x: int in range(0, width, step):
			var c: Color = img.get_pixel(x, y)
			total_r += c.r
			total_g += c.g
			total_b += c.b
			pixel_count += 1
			
	if pixel_count == 0:
		return Color.BLACK
		
	return Color(total_r / pixel_count, total_g / pixel_count, total_b / pixel_count)


func _get_desktop_icon_settings(position: Vector2i, is_colored: bool = false) -> GeneratedDesktopIconSettings:
	var icon_name: String = JSON.stringify([position.x, position.y])
	
	var desktop_icon: GeneratedDesktopIconSettings = GeneratedDesktopIconSettings.new()
	
	desktop_icon.name = icon_name
	desktop_icon.headless = true
	desktop_icon.visual_icon_path = "res://desktop_icons/visuals/bad_apple/frame_00111.ico" if is_colored else "res://desktop_icons/visuals/bad_apple/frame_00000.ico"
	var window_settings: GeneratedWindowSettings = GeneratedWindowSettings.new()
	window_settings.aditional_values = {
		"BadApple": true,
		"Start": true,
		"AnimatedBadAppleIcon": true
	}
	window_settings.window_scene = preload("res://main/main.tscn")
	
	desktop_icon.window_settings = window_settings
	
	return desktop_icon


func _create_icons(to_be_created_icons: Array[GeneratedDesktopIconSettings], multithreaded: bool = false) -> void:
	var icons: Dictionary[GeneratedDesktopIconSettings, String] = {}
	
	for desktop_icon: GeneratedDesktopIconSettings in to_be_created_icons:
		if not generated_desktop_icons.has(name):
			generated_desktop_icons.append(desktop_icon.name)
		
		# get the cmdline arguments
		var desktop_icon_args: String = (
			desktop_icon.get_base_cmdline_args() +
			" ++" +
			desktop_icon.get_user_cmdline_args()
		)
		
		desktop_icon.visual_icon_path = Main._convert_icon_path(desktop_icon.visual_icon_path)
		
		icons[desktop_icon] = desktop_icon_args
	
	# spawn the desktop icons
	var icon_spawner: DesktopIconSpawner = DesktopIconSpawner.new()
	if multithreaded: icon_spawner.CreateMultipleIconsParallel(icons)
	else: icon_spawner.CreateMultipleIcons(icons)
	
	await icon_spawner.MultipleIconsCreationFinished


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		await _remove_all_icons()

func _remove_all_icons() -> void:
	video_timer.stop()
	DesktopIconSpawner.DeleteMultipleIcons(PackedStringArray(generated_desktop_icons))
	await get_tree().create_timer(5).timeout
	DesktopIconSpawner.DeleteMultipleIcons(PackedStringArray(generated_desktop_icons))
	queue_free()
