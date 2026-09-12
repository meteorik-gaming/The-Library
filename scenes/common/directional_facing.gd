class_name DirectionalFacing
extends RefCounted
## Picks which of move_up/move_down/move_left/move_right is "most
## intentional" right now, for a free-roam mover to decide what to face/
## animate when multiple movement keys are held at once: the one with the
## greatest input strength (matters for analog input), tied broken by
## whichever has been held the longest continuously — i.e. whichever of the
## currently-held keys was pressed first. Grid-stepped actors (NPCs) don't
## need this: their facing is just whatever direction they're stepping in.

const ACTIONS: Array[String] = ["move_up", "move_down", "move_left", "move_right"]

## action name -> semantic direction, shared by every world: W/A/S/D always
## mean north/west/south/east regardless of whether that reads as screen
## up/left/down/right (top-down) or a screen diagonal (isometric).
const ACTION_TO_DIRECTION := {
	"move_up": "north",
	"move_down": "south",
	"move_left": "west",
	"move_right": "east",
}

var _held_order: Array[String] = []


## Call once per physics frame before current_direction().
func update() -> void:
	for action: String in ACTIONS:
		var held := Input.is_action_pressed(action)
		var tracked: bool = action in _held_order
		if held and not tracked:
			_held_order.append(action)
		elif not held and tracked:
			_held_order.erase(action)


## "north"/"south"/"east"/"west" for whichever action currently wins, or ""
## if nothing is held.
func current_direction() -> String:
	var best := ""
	var best_strength := 0.0
	for action in _held_order:
		var strength := Input.get_action_strength(action)
		if strength > best_strength + 0.001:
			best_strength = strength
			best = action
	return ACTION_TO_DIRECTION.get(best, "")
