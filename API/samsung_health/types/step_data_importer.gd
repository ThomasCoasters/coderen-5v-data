@tool
class_name StepDataImporter
extends EditorScript


const DATA_FILE_PATH: String = "res://API/samsung_health/data/Activity Day Summary.txt"
const SAVE_FILE_PATH: String = "res://API/samsung_health/data/"


func _run() -> void:
	var data_file = FileAccess.open(DATA_FILE_PATH, FileAccess.READ)
	if data_file == null:
		printerr("Failed to data data file: ", DATA_FILE_PATH)
	
	var step_data: StepData = StepData.new()
	
	while not data_file.eof_reached():
		var row: PackedStringArray = data_file.get_csv_line()
		
		if row.size() < 10:
			continue
		
		var date: String = row[0]
		date = date.split(" ")[0]
		var json_string: String = row[9]
		
		var total_steps: int = 0
		
		var json = JSON.new()
		json.parse(json_string)
		
		var data = json.get_data()
		if data is Dictionary and data.has("mUnitDataList"):
			for unit in data["mUnitDataList"]:
				total_steps += int(unit.get("walkStep", 0)) + int(unit.get("runStep", 0))
		
		step_data.steps_by_date[date] = total_steps
		if total_steps > step_data.highest_step_count:
			step_data.highest_step_count = total_steps
	
	ResourceSaver.save(step_data, SAVE_FILE_PATH.path_join("step_data.res"))
	
	data_file.close()
