@tool
class_name AppleWindow
extends Control


@onready var custom_window_border: CustomWindowBorder = %CustomWindowBorder


func set_icon(icon: Texture2D) -> void:
	custom_window_border.window_icon = icon


func set_rect(rect: Rect2i, offset: Vector2, rect_scale: float) -> void:
	size = rect.size * rect_scale
	position = offset + rect.position * rect_scale
