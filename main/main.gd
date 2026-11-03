class_name Main
extends Node
## The main node controlling everything


## The desktop icons that should be generated when starting the programm.
@export var initial_desktop_icons: Array[GeneratedDesktopIconSettings]
@export var initial_park_desktop_icons: Array[GeneratedDesktopIconSettings]
var park_icons_generated: bool = false
## The window scene that starts when starting the game.
@export var initial_window_scene: PackedScene
@export var initial_no_park_window_scene: PackedScene

## All the desktop icons that were generated through the runtime of the programm.
var generated_desktop_icons: Array[GeneratedDesktopIconSettings]

var open_windows: Dictionary[String, PopupWindow]

var current_park: ParkID

func _enter_tree():
	# make the window invis from the boot screen
	
	# Wait a frame to be rendered before restoring the window properties.
	# Otherwise, properties will be restored too early and the window border
	# will show up around a transparent window.
	await get_tree().process_frame
	
	# make the programm unquittable in normal manners
	get_tree().auto_accept_quit = false
	
	# get the main window
	var main_window = get_tree().root
	
	# make the main window "invisible"
	main_window.transparent = false
	main_window.borderless = false
	main_window.size = Vector2i(1, 1)
	main_window.position = Vector2i(-1000, -1000)
	main_window.exclude_from_capture = true
	
	# make this not display in the taskbar
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(DesktopIconConfig.OUTPUT_DIRECTORY):
		DirAccess.make_dir_absolute(DesktopIconConfig.OUTPUT_DIRECTORY)
	
	# if icons should be created, generate the icons
	if not initial_desktop_icons.is_empty():
		_create_desktop_icons(initial_desktop_icons)
	
	
	if load_current_park():
		if not initial_park_desktop_icons.is_empty():
			park_icons_generated = true
			_create_desktop_icons(initial_park_desktop_icons)
		
		# spawn a new window
		spawn_window()
	
	else:
		if initial_no_park_window_scene:
			spawn_window(initial_no_park_window_scene.instantiate())
		elif initial_window_scene:
			spawn_window(initial_window_scene.instantiate())



func _process(_delta: float) -> void:
	# check if there is something changed with the desktop icon output file
	# and add what should be added for that output file
	_check_desktop_icon_output()


## Creates the desktop icons provided by [param icons_to_create].
func _create_desktop_icons(icons_to_create: Array[GeneratedDesktopIconSettings]) -> void:
	# add all the, to be created, icons to the generated icons variable
	generated_desktop_icons.append_array(icons_to_create)
	
	# get a refrence to all the icons that should get created
	var icons: Dictionary[GeneratedDesktopIconSettings, String] = {}
	
	# go through every setting and add it to the to be created icons
	for desktop_icon: GeneratedDesktopIconSettings in icons_to_create:
		# get the cmdline arguments
		var desktop_icon_args: String = (
			desktop_icon.get_base_cmdline_args() +
			" ++" +
			desktop_icon.get_user_cmdline_args()
		)
		
		# add the resource as the key and the cmdline arguments as the value
		icons[desktop_icon] = desktop_icon_args
	
	# spawn the desktop icons
	var icon_spawner: DesktopIconSpawner = DesktopIconSpawner.new()
	icon_spawner.CreateMultipleIconsParallel(icons)


## Deletes the desktop icons provided by [param icons_to_delete].
func _delete_desktop_icons(icons_to_delete: Array[GeneratedDesktopIconSettings]) -> void:
	for desktop_icon: GeneratedDesktopIconSettings in icons_to_delete:
		DesktopIconSpawner.DeleteDesktopIcon(desktop_icon.name)

## Checks if there is a [GeneratedWindowSettings] resource
## inside the [const DesktopIconConfig.OUTPUT_DIRECTORY].
## If there is, spawns the window provided and clears the directory again
func _check_desktop_icon_output() -> void:
	# get all the output files
	var output_files: PackedStringArray = DesktopIconOutput.get_output_files()
	# if there are none, do nothing
	if output_files.is_empty():
		return
	
	# go through every output file and spawn the window scene assosiated to it
	for file_path: String in output_files:
		# load the resource
		var output_settings: GeneratedWindowSettings = load(file_path) as GeneratedWindowSettings
		if not output_settings: continue
		
		if output_settings.aditional_values.has("exit_program"):
			DesktopIconOutput.remove_output_files()
			
			for generated_desktop_icon in generated_desktop_icons:
				DesktopIconSpawner.DeleteDesktopIcon(generated_desktop_icon.name)
			
			get_tree().quit()
		
		# check if it exists and has a window scene provided
		if output_settings.window_scene:
			# instantiate the window scene
			var window_scene: PopupWindow =\
			output_settings.window_scene.instantiate() as PopupWindow
			
			# do nothing if the window scene does not exist
			if not window_scene:
				continue
			
			window_scene.additional_values = output_settings.aditional_values
			
			if not output_settings.is_modifier:
				spawn_window(window_scene, output_settings.ignore_cap, output_settings.toggle)
				continue
			
			var modifier_node: PopupWindowModifier
			if output_settings.modifier_scene:
				modifier_node = output_settings.modifier_scene.instantiate() as PopupWindowModifier
			elif output_settings.modifier_script:
				modifier_node = output_settings.modifier_script.new()
			
			add_window_modifier(
				modifier_node,
				output_settings.window_scene,
				output_settings.should_open_window,
				output_settings.toggle
			)
	
	
	DesktopIconOutput.remove_output_files()


## Spawns the given [param window] on the OS.
func spawn_window(window: PopupWindow = null, ignore_cap: bool = false, toggle_open: bool = false) -> void:
	# if there was no window given, use the backup window
	if not window:
		if not initial_window_scene: return
		
		window = initial_window_scene.instantiate()
	
	if not ignore_cap and open_windows.has(window.scene_file_path):
		if toggle_open:
			open_windows[window.scene_file_path].close_requested.emit()
		
		window.queue_free()
		return
	
	open_windows[window.scene_file_path] = window
	
	# set the refrence to the main node of the window to this (the main node)
	window.main = self
	window.current_park = current_park
	
	# add the window as a child
	add_child(window)
	
	# when a window needs to be closed, decrease window count and delete it
	window.close_requested.connect(
		func():
			open_windows.erase(window.scene_file_path)
			_delete_desktop_icons(window.initial_desktop_icons)
			window.queue_free()
	)
	
	if window.initial_desktop_icons: _create_desktop_icons(window.initial_desktop_icons)


## Adds the given [param popup_window_modifier] to the given [param window].
## Does not add it if the given [param window] is not currently open,
## and [param open_if_not_active] is [code]false[/code],
## If [param open_if_not_active] is [code]true[/code] instead, it opens the window and then adds it. 
func add_window_modifier(
	popup_window_modifier: PopupWindowModifier,
	window: PackedScene,
	open_if_not_active: bool = false,
	toggle: bool = false
) -> void:
	var window_node: PopupWindow
	if not open_windows.has(window.resource_path):
		if not open_if_not_active:
			popup_window_modifier.queue_free()
			return
		
		window_node = window.instantiate()
		spawn_window(window_node)
	
	if not window_node:
		window_node = open_windows[window.resource_path]
	
	window_node.add_modifier(popup_window_modifier, toggle)


func change_park(new_park: ParkID) -> void:
	if new_park:
		if not initial_park_desktop_icons.is_empty() and not park_icons_generated:
			park_icons_generated = true
			_create_desktop_icons(initial_park_desktop_icons)
	else:
		if not initial_park_desktop_icons.is_empty():
			park_icons_generated = false
			_delete_desktop_icons(initial_park_desktop_icons)
	
	
	
	current_park = new_park
	save_current_park()
	
	for window: PopupWindow in open_windows.values():
		window.current_park = new_park
		window._park_changed(new_park)


func save_current_park() -> void:
	var save_file = FileAccess.open("user://current_park.save", FileAccess.WRITE)
	var park_path: String = current_park.resource_path
	
	var json_string: String = JSON.stringify(park_path)
	
	save_file.store_line(json_string)

func load_current_park() -> ParkID:
	if not FileAccess.file_exists("user://current_park.save"):
		return null
	
	var saved_park = FileAccess.open("user://current_park.save", FileAccess.READ)
	saved_park = saved_park.get_as_text()
	current_park = load(JSON.parse_string(saved_park))
	
	return current_park
