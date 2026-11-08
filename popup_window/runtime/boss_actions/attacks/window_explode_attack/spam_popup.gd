extends Control


signal close_requested


@onready var error_text_label: RichTextLabel = %ErrorTextLabel
@onready var ok_button: Button = %OKButton
@onready var content_margin_container: MarginContainer = %ContentMarginContainer


var error_text: String
var bbcode_enabled: bool


func _ready() -> void:
	while not error_text_label:
		await get_tree().process_frame
	
	error_text_label.bbcode_enabled = bbcode_enabled
	error_text_label.text = error_text
	
	ok_button.pressed.connect(close_requested.emit)
	
	content_margin_container.resized.connect(func(): size = content_margin_container.size)
	await get_tree().process_frame
	
	size = content_margin_container.size
