class_name DesktopIconOutput
extends RefCounted
## An helper class that helps with desktop icons outputting.


## Gets all the current outputted files inside [const DesktopIconConfig.OUTPUT_DIRECTORY].
static func get_output_files() -> PackedStringArray:
	# get the location files were outputted to
	var files_dir: String = DesktopIconConfig.get_global_output_dir()
	var local_files_dir: String = DesktopIconConfig.OUTPUT_DIRECTORY
	
	# get all the current files and a refrence for outputted files
	var files: PackedStringArray = DirAccess.get_files_at(files_dir)
	var output_files: PackedStringArray = PackedStringArray()
	
	# go through every file in the outputted files,
	# if the file ends with .tres, add it to output files
	for file: String in files:
		if file.ends_with(".tres"):
			output_files.append(local_files_dir + file)
	
	# return the correct outputted files
	return output_files


## Removes all the outputted files inside [const DesktopIconConfig.OUTPUT_DIRECTORY].
static func remove_output_files() -> void:
	# get all the current outputted files
	var files_dir: String = DesktopIconConfig.get_global_output_dir()
	var files: PackedStringArray = DirAccess.get_files_at(files_dir)
	
	# go through every outputted file and delete it
	for file: String in files:
		var file_path: String = files_dir.path_join(file)
		DirAccess.remove_absolute(file_path)


## Outputs Desktop icons by using a [GeneratedWindowSettings] resource.
## To output using cmdline arguments, see: [method output_by_custom_cmdline_args].
static func output_by_window_settings(window_settings: GeneratedWindowSettings) -> void:
	# get the location the window settings should be outputted
	var output_dir: String = DesktopIconConfig.get_global_output_dir()
	
	# get a unique name for the outputted file by using time based numbers
	output_dir += str(Time.get_unix_time_from_system() + Time.get_ticks_usec()).replace(".", "") + ".tres"
	
	# save the window_settings resource at the output location
	ResourceSaver.save(window_settings, output_dir)


## Outputs Desktop Icons using user cmdline arguments. See: [method OS.get_cmdline_user_args].
## To output by a [GeneratedWindowSettings] resource, see: [method output_by_window_settings].
static func output_by_custom_cmdline_args(cmdline_args: PackedStringArray) -> void:
	# create a new window settings resource and set it's parameters from the cmdline aguments given
	var window_settings: GeneratedWindowSettings = GeneratedWindowSettings.new()
	window_settings.cmdline_args_to_property_values(cmdline_args)
	
	# use output_by_window_settings() to output that window settings resource
	output_by_window_settings(window_settings)
