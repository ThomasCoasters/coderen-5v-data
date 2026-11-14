class_name BadAppleWindowPlayer
extends BossActionManager


const APPLE_WINDOW = preload("uid://bcgwmxkx5r758")
const BADAPPLE: VideoStream = preload("uid://cqcqyeic10216")
const DISPLAY_SIZE: Vector2 = Vector2(1440, 1080)

@export var rect_data: BadAppleRectData

var windows: Array[AppleWindow]
var window_count: int = 50

var time_per_frame: float = 0.033
var current_frame: int = 0

var video_timer: Timer

var position_offset: Vector2 = Vector2.ZERO

var scale: float = 1.0
var offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	super()
	
	add_child(BadAppleInfo.get_audio())
	
	video_timer = Timer.new()
	video_timer.wait_time = time_per_frame
	video_timer.timeout.connect(display_current_frame)
	add_child(video_timer)
	
	for window: int in range(window_count):
		windows.append(APPLE_WINDOW.instantiate())
		add_child(windows[window])
	
	scale = min(size.x / DISPLAY_SIZE.x, size.y / DISPLAY_SIZE.y)
	offset = (Vector2(size) - scale * DISPLAY_SIZE) / 2
	
	
	video_timer.call_deferred("start")



func display_current_frame() -> void:
	if current_frame >= rect_data.rect_data.size():
		video_timer.stop()
		var desktop_icon_spawner: DesktopIconSpawner = DesktopIconSpawner.new()
		desktop_icon_spawner.SetUserIconHiddenState(false)
		await desktop_icon_spawner.DesktopIconHiddenStateChanged
		queue_free()
		return
	
	var rects: Array = rect_data.rect_data[current_frame]
	
	for i in range(rects.size()):
		windows[i].set_rect(rects[i], offset, scale)
		windows[i].show()
	for i in range(rects.size(), windows.size()):
		windows[i].hide()
	
	current_frame += 1
