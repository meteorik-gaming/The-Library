extends Control
## Builds the rebind row list at runtime from Keybinds.REBINDABLE_BINDINGS —
## add a new rebindable (action, kind) pair there and it shows up here
## automatically. Buttons turn red when two bindings of the same kind share
## the same key/mouse button.

const BINDING_LABELS := {
	"move_left:key": "Move Left",
	"move_right:key": "Move Right",
	"move_up:key": "Move Up",
	"move_down:key": "Move Down",
	"toggle_stats:key": "Toggle This Panel",
	"toggle_devtools:key": "Devtools Overlay",
	"dialogic_default_action:key": "Advance Dialogue",
}

const CONFLICT_COLOR := Color(1, 0.35, 0.35)

@onready var rows_container: VBoxContainer = $ScrollContainer/Rows

var _buttons := {}
var _status_label: Label


func _ready() -> void:
	for binding in Keybinds.REBINDABLE_BINDINGS:
		_add_row(binding[0], binding[1])
	_add_footer()

	Keybinds.rebound.connect(_on_rebound)
	Keybinds.saved.connect(_on_saved)
	Keybinds.reset_done.connect(_on_reset_done)

	_refresh_conflicts()


func _add_row(action: StringName, kind: String) -> void:
	var key := "%s:%s" % [action, kind]

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = BINDING_LABELS.get(key, key)
	label.custom_minimum_size = Vector2(200, 0)
	row.add_child(label)

	var button := Button.new()
	button.text = Keybinds.get_binding_label(action, kind)
	button.custom_minimum_size = Vector2(90, 0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_rebind_pressed.bind(action, kind, button))
	row.add_child(button)

	rows_container.add_child(row)
	_buttons[key] = button


func _add_footer() -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	rows_container.add_child(spacer)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)

	var save_button := Button.new()
	save_button.text = "Save"
	save_button.focus_mode = Control.FOCUS_NONE
	save_button.pressed.connect(_on_save_pressed)
	footer.add_child(save_button)

	var reset_button := Button.new()
	reset_button.text = "Reset to Default"
	reset_button.focus_mode = Control.FOCUS_NONE
	reset_button.pressed.connect(_on_reset_pressed)
	footer.add_child(reset_button)

	rows_container.add_child(footer)

	_status_label = Label.new()
	_status_label.modulate = Color(0.7, 1, 0.7)
	rows_container.add_child(_status_label)


func _on_rebind_pressed(action: StringName, kind: String, button: Button) -> void:
	button.text = "..."
	Keybinds.begin_capture(action, kind)


func _on_rebound(action: StringName, kind: String) -> void:
	var key := "%s:%s" % [action, kind]
	if _buttons.has(key):
		_buttons[key].text = Keybinds.get_binding_label(action, kind)
	_status_label.text = ""
	_refresh_conflicts()


func _on_save_pressed() -> void:
	Keybinds.save()


func _on_saved() -> void:
	_status_label.text = "Saved."


func _on_reset_pressed() -> void:
	Keybinds.reset_to_defaults()


func _on_reset_done() -> void:
	_status_label.text = "Reset to defaults."


## Same key/mouse-button shared by more than one binding of the same kind
## gets flagged red on every button involved.
func _refresh_conflicts() -> void:
	var owners_by_kind := {"key": {}, "mouse": {}}

	for binding in Keybinds.REBINDABLE_BINDINGS:
		var action: StringName = binding[0]
		var kind: String = binding[1]
		var code := Keybinds.get_binding_code(action, kind)
		if code < 0:
			continue
		var owners: Dictionary = owners_by_kind[kind]
		if not owners.has(code):
			owners[code] = []
		owners[code].append("%s:%s" % [action, kind])

	var conflicted := {}
	for kind in owners_by_kind:
		for code in owners_by_kind[kind]:
			var keys: Array = owners_by_kind[kind][code]
			if keys.size() > 1:
				for k in keys:
					conflicted[k] = true

	for key in _buttons:
		var button: Button = _buttons[key]
		if conflicted.has(key):
			button.add_theme_color_override("font_color", CONFLICT_COLOR)
		else:
			button.remove_theme_color_override("font_color")
