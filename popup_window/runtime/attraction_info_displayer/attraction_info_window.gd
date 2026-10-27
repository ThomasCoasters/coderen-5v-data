@tool
class_name AttractionInfoWindow
extends PopupWindow

@onready var current_queue_time_label: Label = %CurrentQueueTimeLabel

func _ready() -> void:
	if additional_values.has("Attraction"):
		window_name = additional_values["Attraction"].name + " - Info"
