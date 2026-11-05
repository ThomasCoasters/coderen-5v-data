@tool
class_name ExportICOSaver
extends EditorExportPlugin


var _export_path: String = ""

func _get_name() -> String:
	return "Export .ico files saver"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, flags: int) -> void:
	_export_path = path.get_base_dir()

func _export_file(path: String, type: String, features: PackedStringArray) -> void:
	if path.get_extension().to_lower() == "ico":
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		assert(
			file,
			"Could not read the .ico file at path: " + path
		)
		var file_content: PackedByteArray = file.get_buffer(file.get_length())
		file.close()
		
		var relative_path: String = path.replace("res://", "")
		var target_path: String = _export_path.path_join(relative_path)
		
		var target_folder: String = target_path.get_base_dir()
		var directory: DirAccess = DirAccess.open(target_folder)
		if not directory:
			DirAccess.make_dir_recursive_absolute(target_folder)
		
		var destination: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
		assert(
			destination,
			"Could not create file at '%s'" %target_path
		)
		
		destination.store_buffer(file_content)
		
		print("Exported '%s' successfully to '%s'" %[path.get_file(), target_path])
