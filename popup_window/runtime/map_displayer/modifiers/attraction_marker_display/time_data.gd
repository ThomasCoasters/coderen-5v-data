class_name TimeData
extends RefCounted


var seconds: float = 0.0
var minutes: int = 0
var hours: int = 0


func _to_string() -> String:
	var string: String = ""
	if not hours == 0:
		string += "%s hours" %hours
	if not minutes == 0:
		if not string.is_empty(): string += ", "
		string += "%s minutes" %minutes
	if not seconds == 0:
		if not string.is_empty(): string += ", "
		string += "%s seconds" %roundi(seconds)
	
	if string.is_empty():
		string += "No Time, Instant"
	
	return string
