@tool
class_name LargestScriptStat
extends EditorStat

func get_stat_value() -> String:
	# refrence for the max amount of lines one script had, and it's name
	var max_lines: Array[int] = [0]
	var largest_script_name: Array[String] = [""]
	
	# scan the full directory
	StatScanner.scan_dir("res://", func(path: String, is_dir: bool) -> void:
		# do nothing with folders
		if is_dir:
			return
		
		# get the extension of the file
		var extension: String = path.get_extension()
		
		# if the extension is one of an script (or shader)
		if extension in ["gd", "cs", "gdshader"]:
			# load the file at the given path
			var file := FileAccess.open(path, FileAccess.READ)
			if file == null:
				return
			
			
			# get the text from the file
			var text: String = file.get_as_text()
			# get the amount of new line markings the script has + 1
			var line_count: int = text.count("\n") + 1
			
			# if the line count is higher than the highest
			if line_count > max_lines[0]:
				# set the new highest to this one
				max_lines[0] = line_count
				# also set the script name to the file of the path
				largest_script_name[0] = path.get_file()
	)
	# if there was no largest script, return null
	if largest_script_name[0].is_empty():
		return "None"
	
	# return a nicely formatted version of the values
	return "%s (%d lines)" % [largest_script_name[0], max_lines[0]]
