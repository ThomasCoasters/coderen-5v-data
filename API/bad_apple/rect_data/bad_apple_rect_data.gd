@tool
class_name BadAppleRectData
extends Resource

# Array[Array[Array[int]]]
@export var rect_data: Array[Array]

@export_group("Editor Stuff")
@export var data_path: String
@export_tool_button("Set Rect Data")\
var get_rect_data_from_json: Callable = _get_rect_data_from_json


func _get_rect_data_from_json() -> void:
	var new_rect_data: Array[Array]
	
	var data_json: FileAccess = FileAccess.open(data_path, FileAccess.READ)
	var contents: Dictionary = JSON.parse_string(data_json.get_as_text())
	
	new_rect_data = []
	var current_frame: int = 0
	
	for frame: Dictionary in contents.frames:
		new_rect_data.append([])
		
		for rect in frame.r:
			var rect2: Rect2i = Rect2i(rect[0], rect[1], rect[2], rect[3])
			new_rect_data[current_frame].append(rect2)
		
		current_frame += 1
	
	rect_data = new_rect_data
	
	ResourceSaver.save(self)
