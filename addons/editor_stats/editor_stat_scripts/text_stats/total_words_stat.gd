@tool
class_name TotalWordsStat
extends EditorStat


func get_stat_value() -> int:
	# get an refrence for the amount of words in the scripts, array to keep it shared
	var words_count: Array[int] = [0]
	
	# create a RegEx to split all words in the codes
	var regex: RegEx = RegEx.new()
	regex.compile("\\S+")
	
	
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
			
			# get an refrence to the script's text
			var text: String = ""
			
			# if the file is an script or shader, set the text to the code
			if file is Script:
				text = file.source_code
			elif file is Shader:
				text = file.code
			
			# if there was an text, add the amount of words to the word count
			if not text.is_empty():
				words_count[0] += regex.search_all(text).size()
	)
	
	
	# return the amount of words
	return words_count[0]
