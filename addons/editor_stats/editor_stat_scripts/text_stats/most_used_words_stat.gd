@tool
class_name MostUsedWordsStat
extends EditorStat

## The amount of top used words to display.
@export var slice_count: int = 3

## The starting point of the words to display.
@export var slice_starting_point: int = 0

func get_stat_value() -> String:
	# get an refrence for the amount of words in the scripts, array to keep it shared
	var used_word_counts: Dictionary[String, int] = {}
	
	# create a RegEx to split all words in the codes
	var regex: RegEx = RegEx.new()
	regex.compile("\\w+")
	
	
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
			
			# if there was an text
			if not text.is_empty():
				# make the text lowercase
				text = text.to_lower()
				
				# add the amount of words to the word count
				for match_obj: RegExMatch in regex.search_all(text):
					var word: String = match_obj.get_string()
					used_word_counts[word] = used_word_counts.get(word, 0) + 1
	)
	
	# if there were no used words, return an empty string
	if used_word_counts.is_empty():
		return ""
	
	
	# Convert the dictionary to the exact same thing, just now as an Array instead of dictionary
	var word_pairs: Array[Array] = []
	for word: String in used_word_counts:
		word_pairs.append([word, used_word_counts[word]])
	
	
	# sort the words depending on how many times they appear in the code
	word_pairs.sort_custom(func(a: Array, b: Array) -> bool:
		return a[1] > b[1]
	)
	
	
	# get the top amount of used words
	var end_point: int = slice_starting_point + slice_count
	var top_pairs: Array = word_pairs.slice(slice_starting_point, end_point)
	
	# get an refrence to the used words formatted in 'word(used_count)'
	var formatted_entries: Array[String] = []
	
	# go through every pair of word and number used, and format it
	for pair: Array in top_pairs:
		formatted_entries.append("%s(%d)" % [pair[0], pair[1]])
	
	# return the formatted enties seperated
	return ", ".join(formatted_entries)
