@abstract
class_name PopupWindowModifier
extends Node

var window: PopupWindow
var global_position: Vector2 = Vector2.ZERO

@abstract func refresh() -> void
@abstract func remove() -> void

func _ready() -> void:
	var position_parent: Node = get_parent()
	while not position_parent is Window and position_parent:
		var global_parent_pos: Vector2 = position_parent.get("position") as Vector2
		if global_parent_pos:
			global_position += global_parent_pos
		
		position_parent = position_parent.get_parent()
