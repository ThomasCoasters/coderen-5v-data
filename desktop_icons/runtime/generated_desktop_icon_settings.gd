class_name GeneratedDesktopIconSettings
extends Resource
## Resource containing data for how a desktop icon should be generated.

## The name the desktop icon will have.
@export var name: String = "PLACEHOLDER"

## The script that runs when opening the desktop icon.
@export var opening_script: Script = preload("uid://dryu213407es1")
var opening_script_path: String:
	get():
		return opening_script.resource_path
@export var visual_icon_path: String = "":
	get():
		print(visual_icon_path)
		return ProjectSettings.globalize_path(visual_icon_path)

## if (when the desktop icon is opened) there should NOT be a opening visual.
@export var headless: bool = true

## Aditional normal godot cmdline args that are not available to be set using parameters. [br]
## Make sure to start every argument with a space. [br]
## To add non-godot recognized arguments, see: [member aditional_user_cmdline_args].
@export var aditional_base_cmdline_args: String
## Aditional user cmdline arguments needed to be added. [br]
## Make sure to start every argument with a space. [br]
## To add godot recognized arguments, see: [member aditional_base_cmdline_args].
@export var aditional_user_cmdline_args: String
## Optional: Settings that determine the window that spawns when the icon is opened.
@export var window_settings: GeneratedWindowSettings


## Gets normal godot recognized cmdline arguments for the desktop icon this should spawn. [br]
## For user made cmdline args, see: [method get_user_cmdline_args].
func get_base_cmdline_args() -> String:
	# get a refrence to all the base cmdline arguments
	var cmdline_args: String = ""
	
	# get the script arg based on the opening_script_path variable
	cmdline_args += ' --script %s' %opening_script_path
	if headless:
		cmdline_args += ' --headless'
	
	# add all other non-variable based args
	cmdline_args += aditional_base_cmdline_args
	
	# return the base cmdline arguments for this desktop icon
	return cmdline_args


## Gets cmdline arguments that are made by the user and not godot recognized.
## Does not automatically add the prepending [code]"++"[/code]. [br]
## For godot recognized cmdline args, see: [method get_user_cmdline_args].
func get_user_cmdline_args() -> String:
	# get a refrence to all the user cmdline arguments
	var cmdline_args: String = ""
	
	# if there are window settings given, add it's cmdline arguments to these user cmdline arguments
	if window_settings and window_settings.window_scene:
		cmdline_args += window_settings.property_values_to_cmdline_args()
	
	# add all the custom non-variable based cmdline arguments 
	cmdline_args += aditional_user_cmdline_args
	
	# return the user cmdline arguments
	return cmdline_args
