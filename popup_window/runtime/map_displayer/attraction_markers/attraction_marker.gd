class_name AttractionMarker
extends Button

@export var popup_time: float = 0.6
@export_range(0,1,0.1) var popup_randomness: float = 0.4

func _ready() -> void:
	disabled = true
	
	popup_time = popup_time + popup_time * (popup_randomness * ((randf() * 2) -1))
	
	offset_transform_scale = Vector2.ZERO
	var initial_angle: float = randf_range(0, 360)
	initial_angle = initial_angle if initial_angle < 180 else initial_angle - 360
	
	offset_transform_rotation = deg_to_rad(initial_angle)
	
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BOUNCE)
	
	tween.tween_property(self, "offset_transform_scale", Vector2.ONE, popup_time * 1.2)
	tween.tween_property(self, "offset_transform_rotation", 0, popup_time / 1.2)
	
	await tween.finished
	
	disabled = false


func queue_delete() -> void:
	disabled = false
	
	popup_time = popup_time + popup_time * (popup_randomness * ((randf() * 2) -1))
	
	var final_angle: float = randf_range(0, 360)
	final_angle = final_angle if final_angle < 180 else final_angle - 360
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(self, "offset_transform_scale", Vector2.ZERO, popup_time * 1.2)
	tween.tween_property(self, "offset_transform_rotation", deg_to_rad(final_angle), popup_time / 1.2)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, popup_time)
	
	await tween.finished
	
	queue_free()
