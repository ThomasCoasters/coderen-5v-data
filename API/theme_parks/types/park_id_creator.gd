@tool
class_name ParkIDCreator
extends EditorScript
## Creates [ParkID] and [AttractionID] resources in the [member OUTPUT_FOLDER]
## for every park and attraction that the program can use.
## After that also updates a new [ParkDB] resource.


## Emitted when a part of the themepark requests are finished.
signal themepark_request_done(amount_left: int)


## The path to the folder the generated resources are saved in.
const OUTPUT_FOLDER: String = "res://API/theme_parks/resources/"
## The name of the file that will be generated for saving all the attractions per park in.
const ATTRACTION_FILE_NAME: String = "attractions"
## The URL that is the destinations request of the API
const DESTINATIONS_URL: String = "https://api.themeparks.wiki/v1/destinations"
## The URL that is the request to the API to get something from a given entity.
## NOTE: After calling this you still need to add the ID after it
const ENTITY_URL: String = "https://api.themeparks.wiki/v1/entity/"

## The [ParkDB] resource that will get automatically get generated and filled.
var park_db_resource: ParkDB
## The amount of themepark requests that are still ongoing.
var themepark_requests_left: int = 0:
	set(value):
		# if the new value is smaller than the old value, emit the signal that one is done.
		if value < themepark_requests_left: themepark_request_done.emit(value)
		
		# set the variable to the new value
		themepark_requests_left = value


func _run() -> void:
	# make sure this does not stop existing while waiting on a HTTP request to finish
	reference()
	
	# create a new parkDB resource
	park_db_resource = ParkDB.new()
	
	# create a HTTP request
	var http_request: HTTPRequest = HTTPRequest.new()
	http_request.use_threads = true
	# add the HTTP request to a scene tree to make in usable
	EditorInterface.get_edited_scene_root().add_child(http_request)
	
	# when the http request is finished, run the function that handles that part
	http_request.request_completed.connect(_destinations_http_request_completed.bind(http_request))
	
	# request all the destinations the API has
	http_request.request(DESTINATIONS_URL)


## Called when the HTTP request of getting all the destinations is completed.
func _destinations_http_request_completed(
	_result: int,
	_response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	requestee: HTTPRequest
) -> void:
	# delete the requestee, due to it being useless now
	requestee.queue_free()
	
	# get the data the request returned with
	var json: JSON = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response: Variant = json.data
	
	# go through every corperation that was returned in the response
	for corperation: Dictionary in response.destinations:
		# go through every themepark that is ran by the given corperation, creating it's ParkID
		for themepark: Dictionary in corperation.parks:
			# get the ID of the park
			var themepark_id = themepark.id
			
			# add a themepark to the requests that are still left to be processed
			themepark_requests_left += 1
			
			# create a HTTP request to get the data of this park
			var http_request: HTTPRequest = HTTPRequest.new()
			http_request.use_threads = true
			# add the HTTP request to a scene tree to make in usable
			EditorInterface.get_edited_scene_root().add_child(http_request)
			
			# call the completed function when the request is done
			http_request.request_completed.connect(
				_themepark_http_request_completed.bind(
					http_request
				)
			)
			
			# request all the data of this themepark
			http_request.request(ENTITY_URL + themepark_id)
	
	
	# keep waiting untill there are no themepark requests left
	while not themepark_requests_left <= 0:
		print("Themepark requests left: ", themepark_requests_left)
		await themepark_request_done
	
	
	# save the park DB resource that was generated
	ResourceSaver.save(park_db_resource, OUTPUT_FOLDER.path_join("park_db.res"))
	
	# let this code delete itself from memory when applicable
	unreference()


## Called when the HTTP request of getting all the data of a park is completed.
func _themepark_http_request_completed(
	_result: int,
	_response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	requestee: HTTPRequest
) -> void:
	# delete the requestee, due to it being useless now
	requestee.queue_free()
	
	# get the data the request returned with
	var json: JSON = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.data
	
	# create a new ParkID resource, as this will be the one that gets saved to the filesystem
	var park_id_resource: ParkID = ParkID.new()
	
	# get the name and ID of the park
	var park_name: String = response.name
	var park_id: String = response.id
	
	# get the position of the park, with backup values so nothing breaks
	var park_longitude: float =\
	response.location.longitude if response.location.longitude is float else 0
	var park_latitude: float =\
	response.location.latitude if response.location.latitude is float else 0
	
	# get the timezone of the park and split that to give the continent and zone it is located in
	var park_timezone: String = response.timezone
	var split_park_timezone:  PackedStringArray = park_timezone.split("/", true, 2)
	var park_continent: String = split_park_timezone[0]
	var park_zone: String = split_park_timezone[1]
	
	# set the just gotten values as values of the ParkID resource
	park_id_resource.id = park_id
	park_id_resource.name = park_name
	park_id_resource.longitude = park_longitude
	park_id_resource.latitude = park_latitude
	park_id_resource.timezone = park_timezone
	park_id_resource.continent = park_continent
	park_id_resource.zone = park_zone
	
	# get the path to where this should be saved
	var output_path: String = OUTPUT_FOLDER.path_join(park_name)
	
	# create a folder for this park
	var directory: DirAccess = DirAccess.open(OUTPUT_FOLDER)
	if directory and not directory.dir_exists(output_path):
		directory.make_dir(park_name)
	
	# create a HTTP request to get the attractions located in this park
	var http_request: HTTPRequest = HTTPRequest.new()
	http_request.use_threads = true
	# add the HTTP request to a scene tree to make in usable
	EditorInterface.get_edited_scene_root().add_child(http_request)
	
	# call the completed function when the request is done
	http_request.request_completed.connect(
		_rollercoasters_http_request_completed.bind(
			park_id_resource,
			output_path,
			http_request
		)
	)
	
	# request all the attractions this themepark has
	http_request.request(ENTITY_URL + park_id + "/children")


## Called when the HTTP request of getting all the attractions of a park is completed.
func _rollercoasters_http_request_completed(
	_result: int,
	_response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	park: ParkID,
	file_path: String,
	requestee: HTTPRequest
) -> void:
	# delete the requestee, due to it being useless now
	requestee.queue_free()
	
	# get the data the request returned with
	var json: JSON = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	
	# get the path to the output location
	var attraction_output_path: String = file_path.path_join(ATTRACTION_FILE_NAME)
	
	# create the folder where the attractions are outputted in
	var directory: DirAccess = DirAccess.open(file_path)
	if directory and not directory.dir_exists(attraction_output_path):
		directory.make_dir(ATTRACTION_FILE_NAME)
	
	# get a refrence for all the attractions that were generated in this code
	var generated_attraction_resources: Array[AttractionID]
	
	# go through all the children (attractions) the park this requested has
	for child_data: Dictionary in response.children:
		# if the child is not a attraction, go to the next
		if not child_data.entityType == "ATTRACTION":
			continue
		
		# create a AttractionID, as this will be the one that gets saved to the filesystem
		var attraction_id_resource: AttractionID = AttractionID.new()
		
		# get the name and ID of the park
		var attraction_name: String = child_data.name
		var attraction_id: String = child_data.id
		
		# get the position of the park, with backup values so nothing breaks
		var attraction_longitude: float =\
		child_data.location.longitude if child_data.location.longitude is float else 0
		var attraction_latitude: float =\
		child_data.location.latitude if child_data.location.latitude is float else 0
		
		# set the just gotten values as values of the AttractionID resource
		attraction_id_resource.id = attraction_id
		attraction_id_resource.name = attraction_name
		attraction_id_resource.longitude = attraction_longitude
		attraction_id_resource.latitude = attraction_latitude
		
		# add this resource to the collection of all generated AttractionID resources for this park
		generated_attraction_resources.append(attraction_id_resource)
	
	# set the attractions of the park to the generated attraction resources
	park.attractions = generated_attraction_resources
	# save the park in the filesystem
	ResourceSaver.save(park, file_path.path_join(clean_filename(park.name) + ".res"))
	
	# go through every attraction that was generated,
	# setting the parent park now so that it's attractions are visible, and after save the resource
	for attraction: AttractionID in generated_attraction_resources:
		attraction.parent_park = park
		ResourceSaver.save(
			attraction,
			attraction_output_path.path_join(clean_filename(attraction.name) + ".res")
		)
	
	# if the park DB does not have the zone or continent of this park, add it
	if not park_db_resource.parks_by_location.has(park.continent):
		park_db_resource.parks_by_location[park.continent] = {}
	if not park_db_resource.parks_by_location[park.continent].has(park.zone):
		park_db_resource.parks_by_location[park.continent][park.zone] = {}
	
	# add this park to the continent and zone it is in in the parkDB
	park_db_resource.parks_by_location[park.continent][park.zone].set(
		park.name,
		park
	)
	
	# reduce the themepark requests that are left
	themepark_requests_left -= 1


## Helper fuction to make sure illegal filenames are not generated
func clean_filename(input_name: String) -> String:
	# create a RegEx that deletes illegal icons
	var regex = RegEx.new()
	regex.compile(r'[\\\/:*?"<>|]')
	
	# get the clean name
	var clean_name = regex.sub(input_name, "", true)
	clean_name = clean_name.to_snake_case()
	
	# give a backup name if there was nothing left after the removal
	if clean_name.is_empty():
		clean_name = "unnamed_file"
	
	# return the clean name
	return clean_name
