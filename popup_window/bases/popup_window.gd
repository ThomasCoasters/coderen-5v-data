@tool
class_name PopupWindow
extends Window


signal dragged


var main: Main

@export_storage var setup_done: bool = false
@export var window_name: String:
	set(value):
		window_name = value
		title = value
		
		if custom_border:
			custom_border.set(&"window_name", value)

@export var initial_desktop_icons: Array[GeneratedDesktopIconSettings]

@export_group("Modifiers")
@export var modifier_parent_node: CanvasItem
var modifiers: Dictionary[PopupWindowModifier, String]
var additional_values: Dictionary[String, Variant]

@export_group("Custom Border")
const CUSTOM_BORDER_PROPERTIES: Array[String] = [
	"border_parent_override",
	"border_index_override",
	"border_scene",
	"border_global_dragging"
]

@export var has_custom_border: bool = true:
	set(value):
		has_custom_border = value
		notify_property_list_changed()
		_setup_custom_border()
@export var border_parent_override: Node:
	set(value):
		border_parent_override = value
		_setup_custom_border()
@export var border_index_override: int = -1:
	set(value):
		border_index_override = value
		_setup_custom_border()
@export var border_scene: PackedScene = preload("uid://t8260cy2xvyw"):
	set(value):
		border_scene = value
		_setup_custom_border()

@export_storage var border_properties: Dictionary[StringName, Variant] = {}


var custom_border: CustomWindowBorder
var current_park: ParkID


func _enter_tree() -> void:
	if not setup_done and Engine.is_editor_hint():
		_setup_intial_values()
		setup_done = true
	
	borderless = false
	borderless = true
	_setup_custom_border()


func _validate_property(property: Dictionary) -> void:
	if property.name in CUSTOM_BORDER_PROPERTIES and not has_custom_border:
		property.usage |= PROPERTY_USAGE_READ_ONLY

func _get_property_list() -> Array[Dictionary]:
	if not Engine.is_editor_hint():
		return []
	
	var properties: Array[Dictionary] = []
	
	if border_scene and has_custom_border:
		var instantiated_border: CustomWindowBorder =\
		border_scene.instantiate() as CustomWindowBorder
		
		if instantiated_border:
			var border_script: Script = instantiated_border.get_script()
			if border_script:
				var _border_properties: Array[Dictionary] = border_script.get_script_property_list()
				for property: Dictionary[StringName, Variant] in _border_properties:
					if (property.usage & PROPERTY_USAGE_STORAGE) and (property.usage & PROPERTY_USAGE_EDITOR):
						properties.append(property)
						if not border_properties.has(property.name):
							border_properties[property.name] = border_script.get_property_default_value(property.name)
				
				instantiated_border.free()
		
		for border_property_name in border_properties:
			var used_property: bool = false
			
			for property in properties:
				if border_property_name == property.name:
					used_property = true
					break
			
			if not used_property:
				border_properties.erase(border_property_name)
	
	
	
	return properties


func _get(property: StringName) -> Variant:
	if border_properties.has(property):
		return border_properties[property] 
	
	return null

func _set(property: StringName, value: Variant) -> bool:
	if border_properties.has(property):
		border_properties[property] = value
		
		if border_properties.has(property):
			custom_border.set(property, value)
		return true
	
	return false

func _property_can_revert(property: StringName) -> bool:
	if border_properties.has(property):
		return true
	return false

func _property_get_revert(property: StringName) -> Variant:
	var instantiated_border: CustomWindowBorder =\
	border_scene.instantiate() as CustomWindowBorder
	if not instantiated_border:
		return null
	
	var border_script: Script = instantiated_border.get_script()
	if not border_script:
		return null
	
	return border_script.get_property_default_value(property)

func _input(event: InputEvent) -> void:
	_handle_window_dragging(event)


func add_modifier(modifier: PopupWindowModifier, toggle: bool = false) -> void:
	var existing_modifier: PopupWindowModifier = null
	for mod in modifiers.keys():
		var modifier_script: Script = modifier.get_script()
		print(modifier_script)
		if modifiers[mod] == modifier_script.resource_path:
			existing_modifier = mod
			break
	
	if existing_modifier:
		if toggle:
			modifiers.erase(existing_modifier)
			existing_modifier.remove()
			
			modifier.queue_free()
			
			if modifiers.is_empty() and custom_border:
				custom_border.modifier_close_button.hide()
		else:
			modifier.queue_free()
		return
	
	custom_border.modifier_close_button.show()
	
	var modifier_parent: Node = modifier_parent_node as Node if modifier_parent_node else self
	
	modifier.window = self
	
	modifiers[modifier] = modifier.get_script().resource_path
	modifier_parent.add_child(modifier)
	
	modifier.refresh()


func refresh_modifiers() -> void:
	for modifier: PopupWindowModifier in modifiers:
		modifier.refresh()

func _setup_intial_values() -> void:
	initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	
	unresizable = true
	transparent = true
	
	minimize_disabled = true
	maximize_disabled = true
	
	transparent_bg = true


func _setup_custom_border() -> void:
	if custom_border:
		custom_border.queue_free()
	
	if not has_custom_border:
		return
	
	custom_border = border_scene.instantiate() as CustomWindowBorder
	assert(
		custom_border,
		"Assigned a wrong scene for a window's border in the constant named 'custom_border'."
	)
	
	var border_parent: Node = border_parent_override
	
	if not border_parent:
		border_parent = self
	
	for border_property in custom_border.get_property_list():
		if border_properties.has(border_property.name):
			custom_border.set(border_property.name, get(border_property.name))
	
	border_parent.add_child(custom_border)
	border_parent.move_child(custom_border, border_index_override)
	if not Engine.is_editor_hint():
		custom_border.parent_window = self
	
	if not Engine.is_editor_hint():
		custom_border.close_requested.connect(close_requested.emit)
		custom_border.modifier_close_requested.connect(_modifier_close_requested)

func _handle_window_dragging(event: InputEvent) -> void:
	if not custom_border:
		return
	
	if event is InputEventMouseMotion:
		if custom_border.is_dragging:
			var new_pos: Vector2i = custom_border.get_current_drag_position()
			if not position == new_pos:
				dragged.emit()
				position = new_pos


func _modifier_close_requested() -> void:
	var last_modifier: PopupWindowModifier = modifiers.keys().pop_back()
	last_modifier.remove()
	modifiers.erase(last_modifier)
	
	if modifiers.is_empty():
		custom_border.modifier_close_button.hide()


func _on_window_button_pressed() -> void:
	main.spawn_window()


func _park_changed(_new_park: ParkID) -> void:
	pass
