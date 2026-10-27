@tool
class_name TotalFoldersStat
extends EditorStat


func get_stat_value() -> int:
	# get a refrence for the amount of folders, array to keep it shared
	var folder_count: Array[int] = [0]
	
	# scan the full directory
	StatScanner.scan_dir("res://", func(path: String, is_dir: bool) -> void:
		# if the file is an folder, add 1 to the folder_count
		if is_dir:
			folder_count[0] += 1
	)
	
	# return the amount of files
	return folder_count[0]
