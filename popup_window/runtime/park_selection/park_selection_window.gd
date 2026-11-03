@tool
class_name ParkSelectionWindow
extends PopupWindow


const BASE_THEME = preload("uid://bndopykkard70")
const PARK_DB = preload("uid://4mhtg5um74xo")


@onready var grid_container: GridContainer = %GridContainer
@onready var search_line_edit: LineEdit = %SearchLineEdit
@onready var scroll_bar: ScrollContainer = %ScrollBar


var parks_by_continent: Dictionary[String, PackedStringArray]
var continent_panel_by_name: Dictionary[String, PanelContainer]
var park_button_by_name: Dictionary[String, Button]

func _ready() -> void:
	if Engine.is_editor_hint(): return
	search_line_edit.text_changed.connect(_search)
	
	_setup_park_selection_ui()
	
	scroll_bar.get_v_scroll_bar().mouse_default_cursor_shape = Control.CURSOR_VSIZE


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
		var spacer: Control = continent_container.add_spacer(true)
		spacer.custom_maximum_size.y = 5
		spacer.custom_minimum_size.y = 5
		
		var continent_label: Label = Label.new()
		continent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		continent_label.add_theme_font_size_override("font_size", 30)
		continent_label.text = continent
		continent_container.add_child(continent_label)
		
		
		continent_panel_by_name[continent] = continent_panel
		parks_by_continent[continent] = PackedStringArray()
		
		
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
				
				parks_by_continent[continent].append(park_name)
				park_button_by_name[park_name] = park_button



func _search(search_text: String) -> void:
	if search_text.is_empty():
		for park_button: Button in park_button_by_name.values():
			park_button.show()
		for continent_panel: PanelContainer in continent_panel_by_name.values():
			continent_panel.show()
		return
	
	for park_button: Button in park_button_by_name.values():
		park_button.hide()
	for continent_panel: PanelContainer in continent_panel_by_name.values():
		continent_panel.show()
	
	var fuzzy_search: FuzzySearch = FuzzySearch.new()
	fuzzy_search.use_exact_tokens = true
	
	for continent: String in parks_by_continent:
		if fuzzy_search.search(search_text, continent):
			for park_button: Button in park_button_by_name.values():
				park_button.show()
			continue
		
		
		var matched: bool = false
		
		for fuzzy_match: FuzzySearchMatch in\
		fuzzy_search.search_all(search_text, parks_by_continent[continent]):
			matched = true
			
			var park_name: String = parks_by_continent[continent][fuzzy_match.original_index]
			park_button_by_name[park_name].show()
		
		if not matched:
			continent_panel_by_name[continent].hide()
