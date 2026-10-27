@tool
class_name TotalLinesStat
extends EditorStat


func get_stat_value() -> int:
	# get an refrence for the amount of lines in the scripts, array to keep it shared
	var lines_count: Array[int] = [0]
	
	# scan the full directory
	StatScanner.scan_dir("res://", func(path: String, is_dir: bool) -> void:
		# if the file is an folder, do nothing
		if is_dir:
			return
		
		# get the extension of the file
		var extension: String = path.get_extension()
		
		# if the extension is one of an script (or shader)
		if extension in ["gd", "cs", "gdshader"]:
			# load the file at the given path
			var file: Resource = load(path)
			
			# if the file is an script or shader, add the amount of new lines to the lines count
			if file is Script:
				lines_count[0] += file.source_code.count("\n")
			elif file is Shader:
				lines_count[0] += file.code.count("\n")
	)
	
	
	# return the amount of lines
	return lines_count[0]
