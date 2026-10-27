@tool
class_name TotalFilesStat
extends EditorStat


func get_stat_value() -> int:
	# get a refrence for the amount of folders, array to keep it shared
	var file_count: Array[int] = [0]
	
	# scan the full directory
	StatScanner.scan_dir("res://", func(path: String, is_dir: bool) -> void:
		# if the file is not an folder, add 1 to the file_count
		if not is_dir:
			file_count[0] += 1
	)
	
	# return the amount of files
	return file_count[0]
