@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_export_plugin(ExportICOSaver.new())


func _exit_tree() -> void:
	remove_export_plugin(ExportICOSaver.new())
