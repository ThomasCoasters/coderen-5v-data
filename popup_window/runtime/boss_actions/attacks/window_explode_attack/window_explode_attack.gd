extends Attack


const SPAM_POPUP = preload("uid://dvgabvyrehuvc")


@export var outline_color: Color = Color(0.317, 0.021, 0.029, 1.0)
@export var inner_color: Color = Color(0.9, 0.156, 0.172, 1.0)
@export var wait_time: float = 2.5

@export var min_popup_windows: int = 60
@export var max_popup_windows: int = 100

@export var popup_texts: Array[String] = ["Hello World"]

var outline_progress: float = 0.0
var line_gradient: Gradient

var _popups: Array[Control]

func _ready() -> void:
	for i in range(randi_range(min_popup_windows, max_popup_windows)):
		var spam_popup: Control = SPAM_POPUP.instantiate()
		spam_popup.error_text = popup_texts.pick_random()
		spam_popup.position = Vector2i(
			randi_range(int(position.x), int(size.x)),
			randi_range(int(position.y), int(size.y))
		)
		spam_popup.close_requested.connect(spam_popup.queue_free)
		add_child(spam_popup, false, Node.INTERNAL_MODE_BACK)
		_popups.append(spam_popup)
		
	
	line_gradient = Gradient.new()
	for point: int in line_gradient.get_point_count():
		line_gradient.set_color(point, Color(outline_color, 0.0))


func _process(delta: float) -> void:
	outline_progress += delta
	if outline_progress >= wait_time:
		finish()
	
	
	if outline_progress < wait_time/2:
		line_gradient.set_color(0, Color(
			outline_color,
			outline_progress / ((wait_time/2)) * outline_color.a
		))
	else:
		line_gradient.set_color(1, Color(
			outline_color,
			(outline_progress - ((wait_time/2))) / ((wait_time/2)) * outline_color.a
		))
	
	for child: Node in get_children():
		child.free()
	
	var open_windows: Dictionary[String, Rect2i] = WindowWindowsUtil.GetOpenWindowPositions()
	
	for open_window: String in open_windows:
		if not open_window.containsn(get_window().title): _add_marker(open_windows[open_window])
	
	for popup: Control in _popups:
		_add_marker(Rect2(
			popup.position,
			popup.size
		))


func _add_marker(rect: Rect2) -> void:
	var window_marker: Line2D = Line2D.new()
	window_marker.points = PackedVector2Array([
		rect.position + Vector2(13, 6),
		Vector2(
			rect.position.x + 13,
			rect.position.y + rect.size.y - 13
		),
		rect.position + rect.size - Vector2(13, 13),
		Vector2(
			rect.position.x + rect.size.x - 13,
			rect.position.y + 6
		)
	])
	
	window_marker.joint_mode = Line2D.LINE_JOINT_ROUND
	window_marker.closed = true
	window_marker.gradient = line_gradient
	
	var color_rect: ColorRect = ColorRect.new()
	color_rect.position = rect.position + Vector2(13, 6)
	color_rect.size = rect.size - Vector2(13, 6) - Vector2(13, 13)
	color_rect.color = Color(
		inner_color,
		outline_progress / wait_time * inner_color.a
	)
	
	add_child(color_rect)
	add_child(window_marker)

func finish() -> void:
	for popup: Control in _popups:
		popup.close_requested.emit()
	super()
