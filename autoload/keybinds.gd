extends Node

## Central rebind system for the Keybinds panel. Bindings are tracked as
## (action, kind) pairs, kind being "key" or "mouse" — an action can have an
## independently rebindable key AND click.
##
## Rebinding applies live to InputMap immediately (so you can test it right
## away) but is NOT written to disk until save() runs. reset_to_defaults()
## reverts to the bindings project.godot shipped with and persists that too.

signal rebound(action: StringName, kind: String)
signal saved
signal reset_done

const SAVE_PATH := "user://keybinds.cfg"

## Each entry: [action, kind].
const REBINDABLE_BINDINGS: Array = [
	[&"move_left", "key"],
	[&"move_right", "key"],
	[&"move_up", "key"],
	[&"move_down", "key"],
	[&"toggle_stats", "key"],
	[&"toggle_devtools", "key"],
	[&"dialogic_default_action", "key"],
]

var _capturing_action: StringName = &""
var _capturing_kind := ""
var _default_events := {}  # action -> Array[InputEvent], snapshot before any load/rebind


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for binding in REBINDABLE_BINDINGS:
		var action: StringName = binding[0]
		if not _default_events.has(action):
			_default_events[action] = InputMap.action_get_events(action).duplicate()
	_load()


func _unhandled_input(event: InputEvent) -> void:
	if _capturing_action == &"":
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			cancel_capture()
		else:
			_apply_rebind(_capturing_action, _capturing_kind, event)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		_apply_rebind(_capturing_action, _capturing_kind, event)
		get_viewport().set_input_as_handled()


## Called by the Keybinds UI: the next key press or mouse click gets bound.
func begin_capture(action: StringName, kind: String) -> void:
	if _capturing_action != &"" and (_capturing_action != action or _capturing_kind != kind):
		cancel_capture()
	_capturing_action = action
	_capturing_kind = kind


func cancel_capture() -> void:
	var action := _capturing_action
	var kind := _capturing_kind
	_capturing_action = &""
	_capturing_kind = ""
	if action != &"":
		rebound.emit(action, kind)


func is_capturing() -> bool:
	return _capturing_action != &""


## Human-readable label for the current "key" or "mouse" binding of `action`.
func get_binding_label(action: StringName, kind: String) -> String:
	var code := get_binding_code(action, kind)
	if code < 0:
		return "?"
	return _code_label(kind, code)


## Raw keycode (kind "key") or button_index (kind "mouse") currently bound, or -1.
func get_binding_code(action: StringName, kind: String) -> int:
	for e in InputMap.action_get_events(action):
		if kind == "key" and e is InputEventKey:
			return e.physical_keycode if e.physical_keycode != 0 else e.keycode
		elif kind == "mouse" and e is InputEventMouseButton:
			return e.button_index
	return -1


func _code_label(kind: String, code: int) -> String:
	if kind == "key":
		return OS.get_keycode_string(code)
	return _mouse_button_label(code)


func _mouse_button_label(button_index: int) -> String:
	match button_index:
		MOUSE_BUTTON_LEFT:
			return "Mouse Left"
		MOUSE_BUTTON_RIGHT:
			return "Mouse Right"
		MOUSE_BUTTON_MIDDLE:
			return "Mouse Middle"
		_:
			return "Mouse %d" % button_index


func _apply_rebind(action: StringName, kind: String, event: InputEvent) -> void:
	_capturing_action = &""
	_capturing_kind = ""

	var new_event: InputEvent
	if event is InputEventKey:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = event.physical_keycode
		new_event = key_event
	else:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = event.button_index
		new_event = mouse_event

	_replace_events(action, kind, new_event)
	rebound.emit(action, kind)


func _replace_events(action: StringName, kind: String, new_event: InputEvent) -> void:
	var kept: Array[InputEvent] = []
	for e in InputMap.action_get_events(action):
		if kind == "key" and e is InputEventKey:
			continue
		if kind == "mouse" and e is InputEventMouseButton:
			continue
		kept.append(e)
	InputMap.action_erase_events(action)
	for e in kept:
		InputMap.action_add_event(action, e)
	if new_event:
		InputMap.action_add_event(action, new_event)


func _binding_key(action: StringName, kind: String) -> String:
	return "%s:%s" % [action, kind]


## Writes the current (live) bindings to disk.
func save() -> void:
	var cfg := ConfigFile.new()
	for binding in REBINDABLE_BINDINGS:
		var action: StringName = binding[0]
		var kind: String = binding[1]
		var code := get_binding_code(action, kind)
		if code >= 0:
			cfg.set_value("keybinds", _binding_key(action, kind), code)
	cfg.save(SAVE_PATH)
	saved.emit()


## Reverts every rebindable binding to what project.godot shipped with, and
## persists that (clears any saved overrides on disk).
func reset_to_defaults() -> void:
	for binding in REBINDABLE_BINDINGS:
		var action: StringName = binding[0]
		if _default_events.has(action):
			InputMap.action_erase_events(action)
			for e in _default_events[action]:
				InputMap.action_add_event(action, e)

	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	for binding in REBINDABLE_BINDINGS:
		rebound.emit(binding[0], binding[1])
	reset_done.emit()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return

	for binding in REBINDABLE_BINDINGS:
		var action: StringName = binding[0]
		var kind: String = binding[1]
		var section_key := _binding_key(action, kind)
		if not cfg.has_section_key("keybinds", section_key):
			continue
		var code: int = cfg.get_value("keybinds", section_key, -1)
		if code < 0:
			continue

		var new_event: InputEvent
		if kind == "key":
			var key_event := InputEventKey.new()
			key_event.physical_keycode = code
			new_event = key_event
		else:
			var mouse_event := InputEventMouseButton.new()
			mouse_event.button_index = code
			new_event = mouse_event

		_replace_events(action, kind, new_event)
