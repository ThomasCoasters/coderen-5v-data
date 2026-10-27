@tool
class_name ParkSelectionWindow
extends PopupWindow


const BASE_THEME = preload("uid://dd3of3q6suro4")
const PARK_DB = preload("uid://4mhtg5um74xo")


@onready var grid_container: GridContainer = %GridContainer


func _ready() -> void:
	if Engine.is_editor_hint(): return
	_setup_park_selection_ui()


func _setup_park_selection_ui() -> void:
	var button_group: ButtonGroup = ButtonGroup.new()
	
	for continent: String in PARK_DB.parks_by_location:
		var continent_panel: PanelContainer = PanelContainer.new()
		continent_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		continent_panel.theme = BASE_THEME
		grid_container.add_child(continent_panel)
		
		var continent_margin: MarginContainer = MarginContainer.new()
		continent_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		continent_margin.theme = BASE_THEME
		continent_panel.add_child(continent_margin)
		
		var continent_container: VBoxContainer = VBoxContainer.new()
		continent_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		continent_margin.add_child(continent_container)
		
		var continent_label: Label = Label.new()
		continent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		continent_label.add_theme_font_size_override("font_size", 30)
		continent_label.text = continent
		continent_container.add_child(continent_label)
		
		for zone: String in PARK_DB.parks_by_location[continent]:
			for park_name: String in PARK_DB.parks_by_location[continent][zone]:
				var park: ParkID = PARK_DB.parks_by_location[continent][zone][park_name]
				
				var park_button: Button = Button.new()
				park_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				park_button.theme = BASE_THEME
				park_button.text = park_name
				park_button.toggle_mode = true
				park_button.theme = BASE_THEME
				
				park_button.button_group = button_group
				
				if park == current_park:
					park_button.press()
				
				park_button.toggled.connect(func(toggled_on: bool):
					if toggled_on:
						main.change_park(park)
				)
				
				continent_container.add_child(park_button)
	
	print("done")
