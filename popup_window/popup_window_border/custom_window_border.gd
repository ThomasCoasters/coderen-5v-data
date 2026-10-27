class_name CustomWindowBorder
extends PanelContainer
## A custom border for a [PopupWindow].

## Emitted when the window should be closed.
signal close_requested

signal modifier_close_requested

## The icon that [member window_texture_node] should use if none is given in [param window_icon].
const DEFAULT_ICON: CompressedTexture2D = preload("uid://cyggl6sx2s1d5")
## The name of the window displayed in [member window_name]
## if none is given in [member window_name].
const DEFAULT_NAME: String = "App Window"

## The button that checks if the window should get dragged.
@onready var drag_detection_button: Button = %DragDetectionButton
## The node that displays the texture of the window set in [param window_icon].
@onready var window_texture_node: TextureRect = %WindowTexture
## The node that displays the name of the window set in [member window_name].
@onready var window_name_node: Label = %WindowName
## The button that closes the window, emitting [signal close_requested].
@onready var close_button_node: Button = %CloseButton
@onready var modifier_close_button: Button = %ModifierCloseButton

## If [code]true[/code] this window is draggable by clicking anywhere,
## else is only draggable by clicking on the [member drag_detection_button].
@export var global_dragging: bool = false
## The icon that should be displayed in the [param window_texture_node].
@export var window_icon: CompressedTexture2D = DEFAULT_ICON:
	set(value):
		# set the value of this variable 
		window_icon = value
		
		# if the node displaying this value does not exist, wait until this node is ready
		if not window_texture_node:
			await ready
		
		# set the actual displayed value
		window_texture_node.texture = window_icon
## The name that should be displayed in the [param window_name_node].
@export var window_name: String = DEFAULT_NAME:
	set(value):
		# set the value of this variable 
		window_name = value
		
		# if the node displaying this value does not exist, wait until this node is ready
		if not window_name_node:
			await ready
		
		# set the actual displayed value
		window_name_node.text = window_name

## The [PopupWindow] that has this border as it's custom border
var parent_window: PopupWindow
## If the user is currently dragging (moving) the window.
var is_dragging: bool = false
## The offset at which the dragging (moving) started at.
var drag_offset: Vector2i = Vector2i.ZERO


func _ready() -> void:
	# make the close button actually call the close requested signal
	close_button_node.pressed.connect(close_requested.emit)
	
	# add the drag starting and ending depending on if the drag detection button is pressed
	drag_detection_button.button_down.connect(_on_drag_started)
	drag_detection_button.button_up.connect(_on_drag_ended)
	
	modifier_close_button.pressed.connect(modifier_close_requested.emit)
	modifier_close_button.hide()


func _process(_delta: float) -> void:
	# if this window does not use global dragging, do nothing
	if not global_dragging:
		return
	
	# get the current (local) position of the mouse
	var mouse_pos = get_viewport().get_mouse_position()
	# get the area this viewport uses
	var viewport_rect = Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	# if the mouse is not in the viewport's area, do nothing
	if not viewport_rect.has_point(mouse_pos):
		return
	
	# get what is currently being hovered. if it can consume inputs, do nothing.
	if HoverCheck.is_interactable_hovered(get_viewport()):
		return
	
	# set the cursor to be the drag visual
	DisplayServer.cursor_set_shape(DisplayServer.CURSOR_DRAG)


func _input(event: InputEvent) -> void:
	# if this window does not use global dragging, do nothing
	if not global_dragging:
		return
	
	# check if the event that has happened is something to do with mouse buttons
	if event is InputEventMouseButton:
		# if a mouse button was pressed
		if event.pressed:
			# get what is currently being hovered. if it can consume inputs, do nothing.
			if HoverCheck.is_interactable_hovered(get_viewport()):
				return
			
			# enter the dragging state
			_on_drag_started()
		
		# if the mouse button was released, exit the dragging state
		else:
			_on_drag_ended()


## Gets the current position the user has dragged the window to.
func get_current_drag_position() -> Vector2i:
	return DisplayServer.mouse_get_position() - Vector2i(drag_offset)


## Called when the [member drag_detection_button] is pressed,
## and thus the user wants to start dragging. [br]
## For ending the dragging, see: [method _on_drag_ended].
func _on_drag_started() -> void:
	# set the current dragging state to be true
	is_dragging = true
	# set the drag offset depending on the current mouse position and the window's position
	drag_offset = DisplayServer.mouse_get_position() - parent_window.position


## Called when the [member drag_detection_button] is released,
## and thus the user wants to stop dragging. [br]
## For starting the dragging, see: [method _on_drag_started].
func _on_drag_ended() -> void:
	# set the current dragging state to false
	is_dragging = false
