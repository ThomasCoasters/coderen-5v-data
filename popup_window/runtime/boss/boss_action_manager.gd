@tool
class_name BossActionManager
extends PopupWindow


@onready var transparent_window_component: TransparentWindowComponent = $TransparentWindowComponent

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	visible = false
	visible = true
	
	transparent_window_component.InitializeForWindow(self)
	
	_resize_to_monitor()
	


func _resize_to_monitor() -> void:
	var monitor: int = DisplayServer.get_primary_screen()
	
	position = DisplayServer.screen_get_position(monitor)
	size = DisplayServer.screen_get_size(monitor)
