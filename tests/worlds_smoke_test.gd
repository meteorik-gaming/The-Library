extends Node
## Builds every placeholder world and confirms none of them error on build,
## taking a screenshot of each for a quick visual check.
##   <godot> res://tests/worlds_smoke_test.tscn        (windowed; renders)


func _ready() -> void:
	await _screenshot("TopdownWorld", "res://scenes/worlds/topdown_world/topdown_world.tscn", "user://topdown_world.png")
	await _screenshot("IsometricWorld", "res://scenes/worlds/isometric_world/isometric_world.tscn", "user://isometric_world.png")
	await _check_topdown_movement()
	await _check_topdown_npc()
	await _check_iso_movement()
	await _check_world_chrome_toggles()

	print("\nOK")
	get_tree().quit()


## Confirms the Q (devtools grid overlay) and E (keybinds panel) toggles
## from world_chrome actually flip their target's visibility, not just that
## the scene builds.
func _check_world_chrome_toggles() -> void:
	var world: Node = load("res://scenes/worlds/topdown_world/topdown_world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame

	var devtools_overlay: Node2D = world.get_node("WorldChrome/DevToolsOverlay")
	var keybinds_ui: CanvasLayer = world.get_node("WorldChrome/KeybindsUI")

	print("%s  DevToolsOverlay starts hidden" % ("PASS" if not devtools_overlay.visible else "FAIL"))
	print("%s  KeybindsUI starts hidden" % ("PASS" if not keybinds_ui.visible else "FAIL"))

	_fire_action("toggle_devtools")
	await get_tree().process_frame
	print("%s  Q toggles DevToolsOverlay on (DevTools.enabled=%s, visible=%s)" % [
		"PASS" if DevTools.enabled and devtools_overlay.visible else "FAIL", DevTools.enabled, devtools_overlay.visible
	])

	_fire_action("toggle_stats")
	await get_tree().process_frame
	print("%s  E toggles KeybindsUI on (visible=%s)" % [
		"PASS" if keybinds_ui.visible else "FAIL", keybinds_ui.visible
	])

	world.queue_free()
	await get_tree().process_frame


## Presses move_right for 3s (far more than needed to cross the room) and
## confirms the player both actually moved AND got stopped by the wall
## instead of sliding through it.
func _check_topdown_movement() -> void:
	var world: Node = load("res://scenes/worlds/topdown_world/topdown_world.tscn").instantiate()
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
	print("%s  TopdownWorld moved %.1fpx pressing move_right (start x=%.1f, end x=%.1f)" % [
		"PASS" if moved else "FAIL", traveled, start.x, player.global_position.x
	])
	print("%s  TopdownWorld was stopped by the wall instead of sliding through" % [
		"PASS" if stopped_by_wall else "FAIL"
	])

	world.queue_free()
	await get_tree().process_frame


## TopdownWorld's NPC now patrols on the same square grid as everything
## else there (added alongside the isometric one, per Alan's request).
func _check_topdown_npc() -> void:
	var world: Node = load("res://scenes/worlds/topdown_world/topdown_world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame

	var npc: NPC = world.get_node("NPC")
	var start: Vector2 = npc.global_position
	for i in 60:
		await get_tree().physics_frame

	var moved := npc.global_position.distance_to(start) > 1.0
	print("%s  TopdownWorld NPC patrolled on its own (moved %.1fpx with no input)" % [
		"PASS" if moved else "FAIL", npc.global_position.distance_to(start)
	])

	world.queue_free()
	await get_tree().process_frame


## Isometric movement is free/continuous now (not grid-stepped) — WASD is
## just projected onto the diamond's screen-diagonal axes. Checks: (a)
## holding move_up alone goes screen top-left (north), (b) holding move_up +
## move_right together blends into a 3rd direction (still summed vectors,
## not locked to one of the 4 axes) — both x and y move less far than either
## solo axis would, since the two partially cancel — and (c) the NPC (which
## IS still grid-stepped) patrols on its own.
func _check_iso_movement() -> void:
	var world: Node = load("res://scenes/worlds/isometric_world/isometric_world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame

	var player: IsoPlayerMover = world.get_node("Player")
	var npc: NPC = world.get_node("NPC")
	var solo_start: Vector2 = player.global_position
	var npc_start: Vector2 = npc.global_position

	Input.action_press("move_up")
	for i in 30:
		await get_tree().physics_frame
	Input.action_release("move_up")
	await get_tree().physics_frame

	var solo_diff := player.global_position - solo_start
	var went_top_left := solo_diff.x < -1.0 and solo_diff.y < -1.0
	print("%s  IsometricWorld move_up alone went screen top-left (dx=%.1f, dy=%.1f)" % [
		"PASS" if went_top_left else "FAIL", solo_diff.x, solo_diff.y
	])

	var blend_start: Vector2 = player.global_position
	Input.action_press("move_up")
	Input.action_press("move_right")
	for i in 30:
		await get_tree().physics_frame
	Input.action_release("move_up")
	Input.action_release("move_right")
	await get_tree().physics_frame

	var blend_diff := player.global_position - blend_start
	var is_blended := blend_diff.length() > 1.0 and not blend_diff.normalized().is_equal_approx(solo_diff.normalized())
	print("%s  IsometricWorld move_up+move_right blends into a 3rd direction (dx=%.1f, dy=%.1f)" % [
		"PASS" if is_blended else "FAIL", blend_diff.x, blend_diff.y
	])

	var npc_moved := npc.global_position.distance_to(npc_start) > 1.0
	print("%s  IsometricWorld NPC patrolled on its own (moved %.1fpx with no input)" % [
		"PASS" if npc_moved else "FAIL", npc.global_position.distance_to(npc_start)
	])

	world.queue_free()
	await get_tree().process_frame


## Input.action_press() only sets the polling state Input.is_action_pressed()
## reads — it does NOT dispatch an event through _unhandled_input(), so it's
## useless for testing action-toggle code like DevTools/Keybinds. This does
## a real press+release event round-trip through the input pipeline instead.
func _fire_action(action: StringName) -> void:
	var press := InputEventAction.new()
	press.action = action
	press.pressed = true
	Input.parse_input_event(press)

	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _screenshot(label: String, scene_path: String, out_path: String) -> void:
	var node: Node = load(scene_path).instantiate()
	add_child(node)
	await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout

	get_viewport().get_texture().get_image().save_png(out_path)
	print("PASS  built + screenshotted %s -> %s" % [label, ProjectSettings.globalize_path(out_path)])

	node.queue_free()
	await get_tree().process_frame
