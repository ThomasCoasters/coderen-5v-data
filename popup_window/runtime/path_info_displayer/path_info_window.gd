@tool
extends PopupWindow


const STEP_DATA: StepData = preload("uid://dvv24v74w2ig5")
const TWEEN_TIME: float = 1

const MAP_WINDOW: String = "res://popup_window/runtime/map_displayer/map_window.tscn"


@onready var background: NinePatchRect = %Background
@onready var bottom_arrow_texture: TextureRect = %BottomArrowTexture
@onready var content_container: VBoxContainer = %ContentContainer
@onready var walk_time_label: Label = %WalkTimeLabel
@onready var walk_distance_label: Label = %WalkDistanceLabel
@onready var steps_label: Label = %StepsLabel
@onready var closest_date_label: Label = %ClosestDateLabel
@onready var date_steps_label: Label = %DateStepsLabel
@onready var days_walk_label: Label = %DaysWalkLabel


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	
	custom_border.hide()
	background.size.y -= custom_border.size.y
	background.position = Vector2.ZERO
	dragged.connect(_turn_into_normal_window, CONNECT_ONE_SHOT)
	if main.open_windows.has(MAP_WINDOW):
		main.open_windows[MAP_WINDOW].dragged.connect(_turn_into_normal_window, CONNECT_ONE_SHOT)
		main.open_windows[MAP_WINDOW].focus_entered.connect(_turn_into_normal_window, CONNECT_ONE_SHOT)
	
	if additional_values.has("position"):
		position = additional_values["position"]
	@warning_ignore("integer_division")
	position -= Vector2i(
		size.x / 2,
		size.y
	)
	
	if additional_values.has("distance_data"):
		walk_distance_label.text = str(additional_values["distance_data"])
	if additional_values.has("time"):
		walk_time_label.text = str(additional_values["time"])
	
	if additional_values.has("steps"):
		var steps: int = int(additional_values["steps"])
		steps_label.text = str(steps)
		
		var date: String = STEP_DATA.get_closest_date(steps)
		closest_date_label.text = STEP_DATA.readable_date(date)
		date_steps_label.text = str(STEP_DATA.steps_by_date.get(date, "NO DATE FOUND"))
		
		print(steps)
		print(STEP_DATA.avrage_step_count)
		print(steps / STEP_DATA.avrage_step_count)
		print(snappedf(steps / STEP_DATA.avrage_step_count, 0.01))
		days_walk_label.text = str(snappedf(steps / STEP_DATA.avrage_step_count, 0.01))


func _turn_into_normal_window() -> void:
	if custom_border.visible:
		return
	
	custom_border.modulate = Color.TRANSPARENT
	custom_border.show()
	content_container.offset_transform_position.y = -custom_border.size.y
	
	var tween: Tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_parallel()
	
	tween.tween_property(custom_border, "modulate", Color.WHITE, TWEEN_TIME)
	tween.tween_property(bottom_arrow_texture, "position", bottom_arrow_texture.position + Vector2(0, 23), TWEEN_TIME)
	tween.tween_property(bottom_arrow_texture, "modulate", Color.TRANSPARENT, TWEEN_TIME)
	tween.tween_property(background, "position", Vector2.ZERO, TWEEN_TIME)
	tween.tween_property(background, "size:y", size.y, TWEEN_TIME)
	tween.tween_property(content_container, "offset_transform_position:y", 0, TWEEN_TIME)
	
	await tween.finished
	
	bottom_arrow_texture.hide()
