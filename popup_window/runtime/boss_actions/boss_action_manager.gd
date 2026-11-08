@tool
class_name BossActionManager
extends PopupWindow


@onready var transparent_window_component: TransparentWindowComponent = $TransparentWindowComponent

@export var attacks: Array[PackedScene]

func _ready() -> void:
	if Engine.is_editor_hint(): return
	
	visible = false
	visible = true
	
	transparent_window_component.InitializeForWindow(self)
	
	_resize_to_all_monitors()
	
	start_random_attack()


func start_random_attack() -> void:
	_spawn_attack(attacks.pick_random())


func _resize_to_all_monitors() -> void:
	var monitor_count: int = DisplayServer.get_screen_count()
	
	var screen_rect: Rect2 = Rect2(
		INF,
		INF,
		-INF,
		-INF
	)
	
	for monitor: int in monitor_count:
		var monitor_rect: Rect2 = Rect2(
			DisplayServer.screen_get_position(monitor),
			DisplayServer.screen_get_size(monitor)
		)
		
		print(monitor_rect.position)
		print(screen_rect.position.min(monitor_rect.position))
		
		screen_rect.position = screen_rect.position.min(monitor_rect.position)
		screen_rect.size = screen_rect.size.max(monitor_rect.position + monitor_rect.size)
	
	
	position = Vector2i(screen_rect.position)
	size = Vector2i(screen_rect.size)


func _spawn_attack(attack: PackedScene) -> void:
	var loaded_attack: Attack = attack.instantiate()
	
	loaded_attack.action_manager = self
	
	loaded_attack.finished.connect(_attack_finished)
	
	add_child(loaded_attack)


func _attack_finished() -> void:
	#start_random_attack()
	pass
