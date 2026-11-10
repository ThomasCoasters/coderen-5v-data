@abstract
class_name FireballSpawnerBase
extends Control


const FIREBALL = preload("uid://bev6rgakhrgkj")


@export var projectile_count: int = 0
@export var cooldown: float = 1


func _ready() -> void:
	await get_window().ready
	spawn()


func spawn() -> void:
	start_cooldown()


func start_cooldown() -> void:
	get_tree().create_timer(cooldown).timeout.connect(spawn, ConnectFlags.CONNECT_ONE_SHOT)
