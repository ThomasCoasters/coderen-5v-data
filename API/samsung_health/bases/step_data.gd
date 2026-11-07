@tool
class_name StepData
extends Resource

@export var steps_by_date: Dictionary[String, int]

@export var highest_step_count: int

@export var avrage_step_count: float

@export_tool_button("refresh avrage step count")
var refresh_avrage_step_count: Callable = _refresh_avrage_step_count
@export_tool_button("refresh highest step count")
var refresh_highest_step_count: Callable = _refresh_highest_step_count


func get_closest_date(wanted_step_count: int) -> String:
	var closest_date: String
	var closest_difference: float = INF
	
	for date: String in steps_by_date:
		var step_count: int = steps_by_date[date]
		var difference: int = abs(wanted_step_count - step_count)
		if difference < closest_difference:
			closest_date = date
			closest_difference = difference
	
	return closest_date


func readable_date(date: String) -> String:
	var split_date = date.split("-", true, 3)
	if not split_date.size() == 3:
		return ""
	var year: int = int(split_date[0])
	var month: int = int(split_date[1])
	var day: int = int(split_date[2])
	
	var month_str: String = ""
	
	match month:
		1:
			month_str = "JAN"
		2:
			month_str = "FEB"
		3:
			month_str = "MAR"
		4:
			month_str = "APR"
		5:
			month_str = "MAY"
		6:
			month_str = "JUN"
		7:
			month_str = "JUL"
		8:
			month_str = "AUG"
		9:
			month_str = "SEP"
		10:
			month_str = "OCT"
		11:
			month_str = "NOV"
		12:
			month_str = "DEC"
	
	var date_str = str(day, " ", month_str, " ", year)
	
	return date_str


func _refresh_avrage_step_count() -> void:
	var total_steps: int = 0
	for step_count: int in steps_by_date.values(): total_steps += step_count
	
	avrage_step_count = float(total_steps) / steps_by_date.values().size()
	ResourceSaver.save(self)

func _refresh_highest_step_count() -> void:
	for step_count: int in steps_by_date.values(): highest_step_count = step_count if step_count > highest_step_count else highest_step_count
	ResourceSaver.save(self)
