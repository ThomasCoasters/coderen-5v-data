class_name Attack
extends Control


var action_manager: BossActionManager


signal finished

func finish() -> void:
	finished.emit()
	queue_free()
