@abstract
class_name PopupWindowModifier
extends Control

var window: PopupWindow


@abstract func refresh() -> void

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
