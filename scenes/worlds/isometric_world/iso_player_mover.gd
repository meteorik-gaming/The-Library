class_name IsoPlayerMover
extends IsoGridActor
## WASD/arrow-driven grid stepping for the isometric room. The four grid
## axes get assigned to keys by their SCREEN direction, not their raw
## grid delta, so movement feels like N/S/E/W on the diamond instead of
## along the (visually diagonal) raw grid axes:
##   W = north = screen top-left      S = south = screen bottom-right
##   A = west  = screen bottom-left   D = east  = screen top-right
## The isometric_world script computes these from the actual TileSet
## projection (see isometric_world.gd) and hands them in via set_axes(),
## rather than this script guessing Godot's tile_layout sign convention.

var _axes: Dictionary = {}


func set_axes(axes: Dictionary) -> void:
	_axes = axes


func _physics_process(_delta: float) -> void:
	if is_moving() or _axes.is_empty():
		return

	if Input.is_action_pressed("move_up"):
		try_step(_axes["north"])
	elif Input.is_action_pressed("move_down"):
		try_step(_axes["south"])
	elif Input.is_action_pressed("move_left"):
		try_step(_axes["west"])
	elif Input.is_action_pressed("move_right"):
		try_step(_axes["east"])
