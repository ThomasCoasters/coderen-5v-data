@tool
class_name ParkPathRefresher
extends EditorScript


func _run() -> void:
	_scan_directory("res://API/theme_parks/resources/")


func _scan_directory(path: String) -> void:
	# open the directory
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	
	#  make the directory be loopable
	directory.list_dir_begin()
	
	var park: ParkID = null
	var path_json_value: Array = []
	
	while true:
		# get the next file path in the directory
		var file_path: String = directory.get_next()
		if file_path == "":
			break
		
		# if the file starts with . ignore it
		if file_path.begins_with("."):
			continue
		
		# get the full path to the file
		var full_path: String = path.path_join(file_path)
		
		# checks if the gotten directory was another directory
		if directory.current_is_dir():
			# scan that directory
			_scan_directory(full_path)
		
		# if the file is not a directory, but is an resource file
		elif file_path.ends_with(".res"):
			# load the resource
			var resource: Resource = load(full_path)
			
			# check if the resource is valid
			if resource is ParkID:
				park = resource
		
		elif file_path.ends_with(".json"):
			var json_value: Variant = JSON.parse_string(FileAccess.open(full_path, FileAccess.READ).get_as_text())
			if json_value is Array:
				path_json_value = json_value
	
	park.path_data = path_json_value
	
	# stop the loopable directory
	directory.list_dir_end()
