extends Node
## Builds every placeholder world and confirms none of them error on build,
## taking a screenshot of each for a quick visual check.
##   <godot> res://tests/worlds_smoke_test.tscn        (windowed; renders)


func _ready() -> void:
	await _screenshot("TopdownWorld", "res://scenes/worlds/topdown_world/topdown_world.tscn", "user://topdown_world.png")
	await _screenshot("IsometricWorld", "res://scenes/worlds/isometric_world/isometric_world.tscn", "user://isometric_world.png")
	await _check_movement("TopdownWorld", "res://scenes/worlds/topdown_world/topdown_world.tscn")
	await _check_movement("IsometricWorld", "res://scenes/worlds/isometric_world/isometric_world.tscn")

	print("\nOK")
	get_tree().quit()


## Presses move_right for 3s (far more than needed to cross the room) and
## confirms the player both actually moved AND got stopped by the wall
## instead of sliding through it.
func _check_movement(label: String, scene_path: String) -> void:
	var world: Node = load(scene_path).instantiate()
	add_child(world)
	await get_tree().process_frame

	var player: Player = world.get_node("Player")
	var start: Vector2 = player.global_position

	Input.action_press("move_right")
	for i in 180:
		await get_tree().physics_frame
	Input.action_release("move_right")

	var traveled := player.global_position.x - start.x
	var moved := traveled > 10.0
	var stopped_by_wall := traveled < 400.0
	print("%s  %s moved %.1fpx pressing move_right (start x=%.1f, end x=%.1f)" % [
		"PASS" if moved else "FAIL", label, traveled, start.x, player.global_position.x
	])
	print("%s  %s was stopped by the wall instead of sliding through" % [
		"PASS" if stopped_by_wall else "FAIL", label
	])

	world.queue_free()
	await get_tree().process_frame


func _screenshot(label: String, scene_path: String, out_path: String) -> void:
	var node: Node = load(scene_path).instantiate()
	add_child(node)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	get_viewport().get_texture().get_image().save_png(out_path)
	print("PASS  built + screenshotted %s -> %s" % [label, ProjectSettings.globalize_path(out_path)])

	node.queue_free()
	await get_tree().process_frame
