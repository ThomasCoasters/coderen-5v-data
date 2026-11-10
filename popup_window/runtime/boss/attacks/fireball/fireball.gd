class_name Fireball
extends Control


@export var speed: float = 10
@onready var texture: Sprite2D = $Texture

func _ready() -> void:
	texture.rotation = -rotation

func _process(delta: float) -> void:
	position += get_transform().x * speed * delta


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
