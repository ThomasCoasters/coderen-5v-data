class_name RingPopupsAttack
extends Attack


@onready var fireball_circle_spawner: FireballCircleSpawner = %FireballCircleSpawner


@export var angle_bonus_per_projectile: float = 4
@export var projectile_count: int = 0
@export var cooldown: float = 1


func _ready() -> void:
	fireball_circle_spawner.angle_bonus_per_projectile = angle_bonus_per_projectile
	fireball_circle_spawner.projectile_count = projectile_count
	fireball_circle_spawner.cooldown = cooldown
