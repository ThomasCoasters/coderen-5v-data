@abstract
@tool
class_name EditorStat
extends Resource
## The base [Resource] that can get an value for a specific editor stat,
## and display it in the editor stats dock.
## [br]
## To make a new stat, create a new script and extend this class,
## and change the [method get_stat_value] function.

## All the possible type of stats this could be.
enum StatType{
	NULL,
	CODE,
	FILE,
	TEXT
}

## The name this stat has inside the editor stats dock.
@export var stat_name: String = ""

## The [StatType] this [EditorStat] is.
@export var stat_type: StatType

## Returns the value that this stat has.
@abstract func get_stat_value() -> Variant
