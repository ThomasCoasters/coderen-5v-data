@tool
class_name AttractionInfoWindow
extends PopupWindow

func _ready() -> void:
	if additional_values.has("Attraction"):
		window_name = additional_values["Attraction"].name + " - Info"
