@tool
class_name ParkDB
extends Resource
## A database full of every [ParkID] that the program has.


## All theme parks based on their location gotten from
## [member ParkID.continent] and [member ParkID.zone].
## [br][br]
## Written as: [codeblock]
##{
##	"continent": 
##	{
##		"zone":
##		{
##			"name": RESOURCE,
##			..
##		},
##		..
##	},
##	..
##}
##[/codeblock]
@export var parks_by_location: Dictionary[String, Dictionary]

@export_tool_button("A") var a: Callable = _a

func _a() -> void:
	DisplayServer.clipboard_set(JSON.stringify(parks_by_location))
