@abstract
class_name PopupWindowModifier
extends Node

var window: PopupWindow
var global_position: Vector2 = Vector2.ZERO

@abstract func refresh() -> void

func _init() -> void:
	var position_parent: Node = get_parent()
	while not position_parent is Control:
		if not position_parent: return
		
		position_parent = position_parent.get_parent()
		
		if position_parent is Window:
			return
	
	
	if position_parent:
		global_position = position_parent.global_position
