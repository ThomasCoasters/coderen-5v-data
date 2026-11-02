@tool
class_name FolderCleaner
extends EditorScript

func _run() -> void:
	_scan_directory_editor_stats("res://")



func _scan_directory_editor_stats(path: String) -> void:
	# open the directory
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		print("null", path)
		return
	
	#  make the directory be loopable
	directory.list_dir_begin()
	
	while true:
		# get the next file path in the directory
		var file_path: String = directory.get_next()
		if file_path == "":
			break
		
		# get the full path to the file
		var full_path: String = path.path_join(file_path)
		
		# checks if the gotten directory was another directory
		if directory.current_is_dir():
			# scan that directory
			_scan_directory_editor_stats(full_path)
			
			
			if is_folder_empty(full_path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(full_path))
				print("Deleted folder at: ", full_path)
	
	# stop the loopable directory
	directory.list_dir_end()


func is_folder_empty(path: String) -> bool:
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name != "." and file_name != "..":
				dir.list_dir_end()
				return false
			file_name = dir.get_next()
			
		dir.list_dir_end()
		return true
		
	return true
