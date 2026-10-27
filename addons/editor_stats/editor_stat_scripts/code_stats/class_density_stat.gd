@tool
class_name ClassDensityStat
extends EditorStat

func get_stat_value() -> String:
	# refrences to the total scripts and amount of "class_name"(s)
	var total_scripts: Array[int] = [0]
	var named_classes: Array[int] = [0]
	
	# scan the full directory
	StatScanner.scan_dir("res://", func(path: String, is_dir: bool) -> void:
		# do nothing with folders
		if is_dir:
			return
		
		# get the extension of the file
		var extension: String = path.get_extension()
		
		# if the extension is one of an script
		if extension in ["gd", "cs"]:
			# get the file
			var file: FileAccess = FileAccess.open(path, FileAccess.READ)
			if file == null:
				return
			
			# get the text from the file
			var text: String = file.get_as_text()
			# add 1 to the amount of scripts
			total_scripts[0] += 1
			
			# if the code has class_name or class in the text, add 1 to the named classes
			if "class_name " in text or "class " in text:
				named_classes[0] += 1
	)
	
	# prevent /0 if there were no scripts
	if total_scripts[0] == 0:
		return "0%"
	
	# get the percentage of class named scripts
	var percentage: float = (float(named_classes[0]) / float(total_scripts[0])) * 100.0
	# return a nicely formatted display
	return "%d/%d (%.1f%%)" % [named_classes[0], total_scripts[0], percentage]
