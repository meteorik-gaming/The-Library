extends Node

## Global toggle for the Q devtool overlay (grid coordinates, NPC patrol
## routes, etc). Anything can react to `toggled` to show/hide its own debug
## visuals without needing to know about anything else that does the same.

signal toggled(is_enabled: bool)

var enabled := false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_devtools"):
		enabled = not enabled
		toggled.emit(enabled)
