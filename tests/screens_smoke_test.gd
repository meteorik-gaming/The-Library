extends Node
## Builds every top-level screen and confirms none of them error on build,
## taking a screenshot of each for a quick visual check.
##   <godot> res://tests/screens_smoke_test.tscn        (windowed; renders)


func _ready() -> void:
	await _screenshot("LaunchScreen", "res://scenes/launch_screen/launch_screen.tscn", "user://launch_screen.png")
	await _screenshot("MainMenu", "res://scenes/main_menu/main_menu.tscn", "user://main_menu.png")
	await _screenshot("ChooseWorldTypeScreen", "res://scenes/screens/choose_world_type_screen.tscn", "user://choose_world_type_screen.png")
	await _screenshot("OptionsScreen", "res://scenes/screens/options_screen.tscn", "user://options_screen.png")

	print("\nOK")
	get_tree().quit()


func _screenshot(label: String, scene_path: String, out_path: String) -> void:
	var node: Control = load(scene_path).instantiate()
	add_child(node)
	await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout

	get_viewport().get_texture().get_image().save_png(out_path)
	print("PASS  built + screenshotted %s -> %s" % [label, ProjectSettings.globalize_path(out_path)])

	node.queue_free()
	await get_tree().process_frame
