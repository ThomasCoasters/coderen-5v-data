class_name HoverCheck
extends RefCounted
## An utility class that checks stuff that have to do with hovering UI items.


## Returns [code]true[/code] if the given [param viewport]
## has an interactible [Control] that is currently being hovered.
static func is_interactable_hovered(viewport: Viewport) -> bool:
	# get the control node that is currently being hovered
	var hovered = viewport.gui_get_hovered_control()
	# if there is a control node that is being hovered and it is an interactible control node,
	# return true
	if hovered and (hovered is BaseButton or hovered is LineEdit or hovered is TextEdit):
		return true
	
	# if not, return false
	return false
