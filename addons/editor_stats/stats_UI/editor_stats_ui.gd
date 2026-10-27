@tool
class_name EditorStatsUI
extends Control
## The [Control] that contains all visuals for the editor stats [EditorDock].


## The [EditorStat]'s that already exist.
var editor_stats: Array[EditorStat] = []

## The location of all the [EditorStat]'s (can contain aditional folders).
const EDITOR_STAT_LOCATION: String = "res://addons/editor_stats/editor_stat_resources/"

## The container holding all stats.
@onready var editor_stat_container: VBoxContainer = %EditorStatContainer
## The button used to refresh the stats.
@onready var refresh_editor_stat_button: Button = %RefreshEditorStatButton


func refresh() -> void:
	# set the text on the refresh button to show when it last updated
	refresh_editor_stat_button.text =\
	"Refresh (Last updated: %s)" %[Time.get_time_string_from_system()]
	
	# remove every old editor stat text
	for child in editor_stat_container.get_children():
		child.queue_free()
	
	# get the new editor stats
	editor_stats = _load_editor_stats(EDITOR_STAT_LOCATION)
	
	# sort the editor stats by their stat type
	editor_stats.sort_custom(
		func(stat_a: EditorStat, stat_b: EditorStat) -> bool:
			return stat_a.stat_type < stat_b.stat_type
	)
	
	# refrence for the stat of the current 
	var current_stat: EditorStat.StatType = EditorStat.StatType.NULL
	
	# go through every editor stat
	for editor_stat: EditorStat in editor_stats:
		# if this stat is the start of an new type, display a label for that
		if editor_stat.stat_type != current_stat:
			# get the name of the ENUM value
			var stat_name: String =\
			EditorStat.StatType.keys()[editor_stat.stat_type] as String
			# set the name to pascal case instead of SCREAMING_SNAKE_CASE
			stat_name = stat_name.to_pascal_case()
			# add the suffix
			stat_name += " stats"
			
			# create a label to display the stat type
			var type_label: Label = Label.new()
			type_label.text = stat_name
			type_label.add_theme_font_size_override("font_size", 25)
			
			# add the label to the editor stat container
			editor_stat_container.add_child(type_label)
			
			# set the current stat
			current_stat = editor_stat.stat_type
		
		
		
		# create a label and set it's text
		var stat_label: RichTextLabel = RichTextLabel.new()
		stat_label.set_text(
			"[b][i]" + editor_stat.stat_name + "[/i][/b] " + str(editor_stat.get_stat_value())
		)
		
		# set settings on the rich text label
		stat_label.set_fit_content(true)
		stat_label.set_autowrap_mode(TextServer.AUTOWRAP_WORD_SMART)
		stat_label.bbcode_enabled = true
		
		# add the label to the editor stat container
		editor_stat_container.add_child(stat_label)


## loads all the [EditorStat]'s
func _load_editor_stats(path: String) -> Array[EditorStat]:
	var result: Array[EditorStat] = []
	_scan_directory_editor_stats(path, result)
	return result


## scans the directory for [EditorStat]'s
func _scan_directory_editor_stats(path: String, result: Array[EditorStat]) -> void:
	# open the directory
	var directory: DirAccess = DirAccess.open(path)
	if directory == null:
		return
	
	#  make the directory be loopable
	directory.list_dir_begin()
	
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
			# scan that directory
			_scan_directory_editor_stats(full_path, result)
		
		# if the file is not a directory, but is an resource file
		elif file_path.ends_with(".tres"):
			# load the resource
			var resource: Resource = load(full_path)
			
			# check if the resource is valid
			if resource is EditorStat:
				# add it to the results
				result.append(resource)
	
	# stop the loopable directory
	directory.list_dir_end()


func _on_refresh_editor_stat_button_pressed() -> void:
	refresh()
