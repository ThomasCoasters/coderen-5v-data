@tool
class_name CommentToCodeRatioStat
extends EditorStat

func get_stat_value() -> String:
	# refrences for the amount of comment, code and empty lines
	var comment_lines: Array[int] = [0]
	var code_lines: Array[int] = [0]
	var empty_lines: Array[int] = [0]
	
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
			
			# go through every line of the file, until the end has been reached
			while not file.eof_reached():
				# get the current line
				var line: String = file.get_line().strip_edges()
				
				# if the line is empty (only tabs or spaces), add 1 to empty lines
				if line.is_empty():
					empty_lines[0] += 1
				
				# if the line starts with an comment marker, add 1 to the comment lines
				elif line.begins_with("#") or line.begins_with("//") or line.begins_with("/*"):
					comment_lines[0] += 1
				
				# if there was no comment marker, add 1 to the code lines
				else:
					code_lines[0] += 1
	)
	
	# if there were no code lines, return "0%", to make sure /0 never happens
	if code_lines[0] == 0:
		return "0%"
	
	# get the comment to code ratio
	var ratio: float = (
		float(comment_lines[0]) / float(code_lines[0] + comment_lines[0])
	) * 100.0
	
	# return a nicer formatted way to display this
	return "%.1f%% (%d comments / %d code) \n\n%s empty lines" %[
		ratio, comment_lines[0], code_lines[0], empty_lines[0]
	]
