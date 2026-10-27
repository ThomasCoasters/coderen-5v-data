@tool
extends EditorPlugin

## The scene thats the dock's content
var dock_scene: Resource = preload(
	"res://addons/editor_stats/stats_UI/editor_stats_UI.tscn"
)
## The content inside the dock
var dock_content: EditorStatsUI

## The name the dock will have
const DOCK_NAME: String = "Editor Stats"

## refrence to the dock
var dock: EditorDock



func _enter_tree() -> void:
	# create the dock and add it
	_create_dock()
	
	# update the stats
	dock_content.refresh()



func _exit_tree() -> void:
	# remove the editor dock
	_remove_dock()





## Adds the dock to the editor
func _create_dock() -> void:
	# create a new editor dock
	dock = EditorDock.new()
	
	# set the docks size
	dock.size = Vector2(1780, 260)
	# set the name for the dock
	dock.name = DOCK_NAME
	# set the dock's position
	dock.default_slot = EditorDock.DOCK_SLOT_LEFT_BR
	# set the dock's content
	dock_content = dock_scene.instantiate()
	dock.add_child(dock_content)
	
	# add the dock
	add_dock(dock)


## Removes the dock and resets it
func _remove_dock() -> void:
	# remove the dock from the editor
	remove_dock(dock)
	
	# removes the dock from memory
	dock.queue_free()
	
	# reset the dock refrence
	dock = null
