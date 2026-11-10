class_name FireballCircleSpawner
extends FireballSpawnerBase


@export var angle_bonus_per_projectile: float = 4



func spawn() -> void:
	for i: int in range(projectile_count):
		var angle: float = (360.0 / projectile_count) * i
		angle += rotation
		
		var projectile: Fireball = FIREBALL.instantiate()
		projectile.global_position = global_position
		projectile.rotation_degrees = angle
		
		get_window().add_child(projectile)
	
	
	rotation += angle_bonus_per_projectile
	
	super()
