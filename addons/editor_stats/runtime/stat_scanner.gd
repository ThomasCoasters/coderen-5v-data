class_name StatScanner
extends RefCounted

## Recursively scans a given directory and calls [param callback] on every file.
## Callback signature: func(full_path: String, is_dir: bool) -> void
static func scan_dir(path: String, callback: Callable) -> void:
	# open the directory
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	
	# make the directory be loopable
	dir.list_dir_begin()
	
	while true:
		# get the next file path in the directory
		var item: String = dir.get_next()
		if item == "":
			break
		
		# if the file starts with . ignore it
		if item.begins_with("."):
			continue
		
		# get the full path to the file
		var full_path: String = path.path_join(item)
		# check if the item is an directory (folder)
		var is_dir: bool = dir.current_is_dir()
		
		# call the given callback with the path to the item, and if the item is an dir (folder).
		callback.call(full_path, is_dir)
		
		# if the item is an directory (folder), recurcively scan that
		if is_dir:
			scan_dir(full_path, callback)
	
	# stop the loopable directory
	dir.list_dir_end()
