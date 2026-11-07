class_name DistanceData
extends RefCounted


var distance: float


func _to_string() -> String:
	if distance > 1000:
		return "%s km" %snappedf(distance/1000, 0.01)
	else:
		return "%s m" %snappedf(distance, 0.01)
