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
	await _check_pause_freezes_world()
	await _check_attack_interact()

	print("\nOK")
	get_tree().quit()


## Confirms left/right click actually reach the player (not just that the
## input actions exist) -- regression check for a real bug where each
## world's Background/Void full-rect ColorRect defaulted to
## mouse_filter=STOP and silently swallowed every click in the game, even
## though nothing was ever visibly wrong (no error, no dialog -- clicks just
## did nothing). Both worlds have their own Void, so both are checked.
func _check_attack_interact() -> void:
	for world_data in [
		["TopdownWorld", "res://scenes/worlds/topdown_world/topdown_world.tscn"],
		["IsometricWorld", "res://scenes/worlds/isometric_world/isometric_world.tscn"],
	]:
		var label: String = world_data[0]
		var world: Node = load(world_data[1]).instantiate()
		add_child(world)
		await get_tree().process_frame

		var player: CharacterBody2D = world.get_node("Player")

		_fire_action("attack")
		await get_tree().process_frame
		var attacked: bool = player.sprite.animation.begins_with("Attack_")
		print("%s  %s: attack click reaches the player (animation=%s)" % [
			"PASS" if attacked else "FAIL", label, player.sprite.animation
		])

		_fire_action("interact")
		await get_tree().process_frame
		var interacted: bool = player.sprite.animation.begins_with("Interact_")
		print("%s  %s: interact click reaches the player (animation=%s)" % [
			"PASS" if interacted else "FAIL", label, player.sprite.animation
		])

		world.queue_free()
		await get_tree().process_frame


## Confirms the Q (devtools grid overlay) toggle still works, and that ESC/E
## open the shared PauseMenu on the expected tab (Pausa/Inventario) and
## close it again.
func _check_world_chrome_toggles() -> void:
	get_tree().paused = false  # safety net in case a prior check left this stuck

	var world: Node = load("res://scenes/worlds/topdown_world/topdown_world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame

	var devtools_overlay: Node2D = world.get_node("WorldChrome/DevToolsOverlay")
	var pause_menu: PauseMenu = world.get_node("WorldChrome/PauseMenu")

	print("%s  DevToolsOverlay starts hidden" % ("PASS" if not devtools_overlay.visible else "FAIL"))
	print("%s  PauseMenu starts hidden" % ("PASS" if not pause_menu.visible else "FAIL"))

	_fire_action("toggle_devtools")
	await get_tree().process_frame
	print("%s  Q toggles DevToolsOverlay on (DevTools.enabled=%s, visible=%s)" % [
		"PASS" if DevTools.enabled and devtools_overlay.visible else "FAIL", DevTools.enabled, devtools_overlay.visible
	])

	_fire_action("ui_cancel")
	await get_tree().process_frame
	print("%s  ESC opens PauseMenu on Pausa tab, paused (visible=%s, paused=%s, pausa_tab.visible=%s)" % [
		"PASS" if pause_menu.visible and get_tree().paused and pause_menu.pausa_tab.visible else "FAIL",
		pause_menu.visible, get_tree().paused, pause_menu.pausa_tab.visible
	])

	_fire_action("ui_cancel")
	await get_tree().process_frame
	print("%s  ESC closes PauseMenu again, unpaused (visible=%s, paused=%s)" % [
		"PASS" if not pause_menu.visible and not get_tree().paused else "FAIL", pause_menu.visible, get_tree().paused
	])

	_fire_action("toggle_stats")
	await get_tree().process_frame
	print("%s  E opens PauseMenu on Inventario tab, paused (visible=%s, paused=%s, inventario_tab.visible=%s)" % [
		"PASS" if pause_menu.visible and get_tree().paused and pause_menu.inventario_tab.visible else "FAIL",
		pause_menu.visible, get_tree().paused, pause_menu.inventario_tab.visible
	])

	_fire_action("toggle_stats")
	await get_tree().process_frame
	print("%s  E closes PauseMenu again, unpaused (visible=%s, paused=%s)" % [
		"PASS" if not pause_menu.visible and not get_tree().paused else "FAIL", pause_menu.visible, get_tree().paused
	])

	get_tree().paused = false
	world.queue_free()
	await get_tree().process_frame


## Confirms opening the PauseMenu is a REAL pause: NPC movement and
## GameClock's elapsed time both freeze while it's open, and resume once
## it's closed. Snapshots are taken a few frames AFTER opening (not at the
## instant ui_cancel fires) -- a step tween or GameClock tick that was
## already mid-flight the instant pause engages is expected to finish
## settling over a couple of frames; what actually matters is that nothing
## moves any further once things have settled into the paused state.
func _check_pause_freezes_world() -> void:
	get_tree().paused = false  # safety net in case a prior check left this stuck

	var world: Node = load("res://scenes/worlds/topdown_world/topdown_world.tscn").instantiate()
	add_child(world)
	await get_tree().process_frame

	var npc: NPC = world.get_node("NPC")

	_fire_action("ui_cancel")  # open, paused = true
	await get_tree().process_frame
	for i in 5:
		await get_tree().physics_frame

	var npc_settled: Vector2 = npc.global_position
	var hours_settled: float = GameClock.elapsed_hours_today

	for i in 30:
		await get_tree().physics_frame

	var npc_frozen := npc.global_position.distance_to(npc_settled) < 0.01
	var clock_frozen := is_equal_approx(GameClock.elapsed_hours_today, hours_settled)
	print("%s  Pausing freezes NPC movement (moved %.4fpx after settling paused)" % [
		"PASS" if npc_frozen else "FAIL", npc.global_position.distance_to(npc_settled)
	])
	print("%s  Pausing freezes GameClock (elapsed_hours_today stayed %.4f)" % [
		"PASS" if clock_frozen else "FAIL", GameClock.elapsed_hours_today
	])

	_fire_action("ui_cancel")  # close, paused = false
	await get_tree().process_frame

	for i in 10:
		await get_tree().physics_frame

	var clock_resumed := GameClock.elapsed_hours_today > hours_settled
	print("%s  Closing resumes GameClock (elapsed_hours_today now %.4f)" % [
		"PASS" if clock_resumed else "FAIL", GameClock.elapsed_hours_today
	])

	get_tree().paused = false
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
