@tool
class_name ParkIDRefresher
extends EditorScript

const PARK_RESOURCE_PATH: String = "res://API/theme_parks/resources/"
var park_db = preload("uid://4mhtg5um74xo")

func _run() -> void:
	var _parks: Dictionary[String, Dictionary]
	_scan_directory_editor_stats(PARK_RESOURCE_PATH, _parks)
	
	
	var parks: Dictionary[String, Dictionary]
	for continent in _parks:
		parks[continent] = {}
		for zone in _parks[continent]:
			parks[continent][zone] = {}
			for park in _parks[continent][zone]:
				parks[continent][zone][park] = load(_parks[continent][zone][park])
	print(parks)
	
	park_db.parks_by_location = parks
	
	ResourceSaver.save(park_db)
	


## scans the directory for [EditorStat]'s
func _scan_directory_editor_stats(path: String, parks: Dictionary[String, Dictionary]) -> void:
	# open the directory
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	
	#  make the directory be loopable
	directory.list_dir_begin()
	
	var paths_json: String = ""
	var resource: ParkID = null
	
	while true:
		# get the next file path in the directory
		var file_path: String = directory.get_next()
		if file_path == "":
			break
		
		# if the file starts with . ignore it
		if file_path.begins_with("."):
			continue
		
		# get the full path to the file
		var full_path: String = path.path_join(file_path)
		
		# checks if the gotten directory was another directory
		if directory.current_is_dir():
			if file_path == "attractions": continue
			# scan that directory
			_scan_directory_editor_stats(full_path, parks)
		
		elif full_path.ends_with(".json"):
			paths_json = full_path
		
		elif full_path.ends_with(".res"):
			var park: ParkID = load(full_path) as ParkID
			if park:
				if not parks.has(park.continent): parks[park.continent] = {}
				if not parks[park.continent].has(park.zone): parks[park.continent][park.zone] = {}
				parks[park.continent][park.zone][park.name] = park.resource_path
				
				resource = park
	
	if resource and not paths_json.is_empty():
		print("set parks json for %s to %s" %[resource.name, paths_json])
		var file: FileAccess = FileAccess.open(paths_json, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json: JSON = JSON.new()
		var error: Error = json.parse(json_string)
		if error == OK:
			var data: Variant = json.get_data()
			if data is Array:
				resource.path_data = data
				DirAccess.remove_absolute(paths_json)
				ResourceSaver.save(resource)
	
	
	# stop the loopable directory
	directory.list_dir_end()
