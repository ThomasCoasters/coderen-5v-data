class_name DesktopIconConfig
extends RefCounted
## Base configurations for desktop icons.

## The folder the output is placed in.
const OUTPUT_DIRECTORY: String = "res://desktop_icons/output/"

## A getter function to the global path to the [const OUTPUT_DIRECTORY].
static func get_global_output_dir() -> String:
	return ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
