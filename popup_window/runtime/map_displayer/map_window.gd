@tool
class_name MapPopupWindow
extends PopupWindow
## A [PopupWindow] designed to be the window that holds a [ParkMapDisplayer].

## The [ParkMapDisplayer] that displays the park map.
@onready var park_map_displayer: ParkMapDisplayer = %ParkMapDisplayer
@onready var content_margin_container: MarginContainer = %ContentMarginContainer

func _ready() -> void:
	park_map_displayer.main = main
	
	# connect signals from the park map displayer
	park_map_displayer.resized.connect(_refresh_park_map_size)
	park_map_displayer.image_refresh_requested.connect(_refresh_started)
	
	# refresh the image the park map displayer is currently displaying
	park_map_displayer.refresh_image(current_park)


## Called when the [member park_map_displayer]
## emits [signal ParkMapDisplayer.image_refresh_requested].
func _refresh_started(park: ParkID) -> void:
	hide()
	
	# set the name of the window
	window_name = park.name + " - Park Map"


## Called when the park map's size changed, also changing the size of the window to match.
func _refresh_park_map_size() -> void:
	show()
	refresh_modifiers()
	
	# get the new size of the window, by getting the park map's size and the custom border's size
	var new_size: Vector2i = Vector2i(park_map_displayer.size)
	new_size.y += int(custom_border.size.y)
	new_size += Vector2i(
		content_margin_container.get_theme_constant("margin_left") + content_margin_container.get_theme_constant("margin_right"),
		content_margin_container.get_theme_constant("margin_bottom") + content_margin_container.get_theme_constant("margin_top"),
	)
	
	# set the size of the window and the content scale size
	size = new_size
	content_scale_size = new_size


func _park_changed(new_park: ParkID) -> void:
	park_map_displayer.refresh_image(new_park)
