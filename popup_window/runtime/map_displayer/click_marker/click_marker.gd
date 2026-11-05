class_name ClickMarker
extends AttractionMarker

@export var tween_duration: float = 1.5
@export var position_increase: float = 10
@export var scale_increase: Vector2 = Vector2(1.3, 1.3)

func _ready() -> void:
	await super()
	
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_loops()
	
	tween.tween_property(
		self,
		"offset_transform_position:y",
		-position_increase,
		tween_duration/2
	).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(
		self,
		"offset_transform_scale",
		scale_increase,
		tween_duration/2
	).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(
		self,
		"offset_transform_position:y",
		0,
		tween_duration/2
	).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(
		self,
		"offset_transform_scale",
		Vector2.ONE,
		tween_duration/2
	).set_ease(Tween.EASE_IN)
