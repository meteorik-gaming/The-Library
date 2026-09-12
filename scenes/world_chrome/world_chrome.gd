extends Node2D
## Bundles the dev/atmosphere systems any room can just instance: day/night
## ambient lighting + vignette, the Q devtools grid overlay, an always-on
## clock readout (with devtools-only time controls), and an E-toggled
## keybinds panel.

@onready var keybinds_ui: CanvasLayer = $KeybindsUI


func _ready() -> void:
	keybinds_ui.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_stats"):
		keybinds_ui.visible = not keybinds_ui.visible
