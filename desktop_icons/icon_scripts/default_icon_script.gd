extends SceneTree

func _init() -> void:
	# get the custom cmdline arguments
	var user_cmdline_args: PackedStringArray = OS.get_cmdline_user_args()
	
	# output a desktop icon from the cmdline arguments
	DesktopIconOutput.output_by_custom_cmdline_args(user_cmdline_args)
	
	# stop this session
	quit()
