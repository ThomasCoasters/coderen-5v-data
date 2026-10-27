@tool
class_name PropertyListRefresher
extends EditorScript
## A [EditorScript] that refreshes the currently edited object's property list.


func _run() -> void:
	# get the godot editor's inspector and refresh the currently edited object's property list
	var editor_inspector: EditorInspector = EditorInterface.get_inspector()
	editor_inspector.get_edited_object().notify_property_list_changed()
