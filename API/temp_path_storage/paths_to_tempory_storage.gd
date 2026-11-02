@tool
class_name PathsToTemporyStorage
extends EditorScript
const TEMP_STORAGE_DIR: String = "res://API/temp_path_storage/"


func _run() -> void:
	_scan_directory("res://API/theme_parks/resources/")


func _scan_directory(path: String) -> void:
	# open the directory
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	
	#  make the directory be loopable
	directory.list_dir_begin()
	
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
		
		
		elif file_path.ends_with(".json"):
			var folder_name: String = full_path.get_base_dir().replace("res://API/theme_parks/resources/", "")
			var location_path: String = TEMP_STORAGE_DIR.path_join(folder_name.path_join(file_path))
			
			var dir: DirAccess = DirAccess.open(TEMP_STORAGE_DIR)
			if dir and not dir.dir_exists(folder_name):
				dir.make_dir(folder_name)
			var json = FileAccess.open(full_path, FileAccess.READ)
			var json_content: Variant = JSON.parse_string(json.get_as_text())
			json.close()
			
			DirAccess.remove_absolute(full_path)
			
			var new_json: FileAccess = FileAccess.open(location_path, FileAccess.WRITE)
			new_json.store_var(json_content)
			new_json.close()
			print("saved: ", location_path)
			
	
	# stop the loopable directory
	directory.list_dir_end()
