class_name NPC
extends GridActor
## Generic placeholder NPC that walks back and forth between two anchor
## points on a grid, pathfinding around obstacles with Godot's built-in
## AStarGrid2D (works in both the isometric and top-down rooms — see
## configure_at_cells()). Grid-only movement, always — unlike the player,
## NPCs never free-roam/vector-sum. No schedule/time-of-day routing yet,
## just the two fixed anchors. AnchorA/AnchorB are repositioned to match at
## configure time, purely so they're accurate if you inspect the scene.

@export var pause_seconds := 1.2

@onready var anchor_a: Marker2D = $AnchorA
@onready var anchor_b: Marker2D = $AnchorB
@onready var proximity_area: Area2D = $ProximityArea
@onready var sprite: CharacterSprite = $Sprite

var _nav_grid: AStarGrid2D
var _grid_dir_to_facing: Dictionary
var _cell_a: Vector2i
var _cell_b: Vector2i
var _path: Array[Vector2i] = []
var _target_is_b := true
var _waiting := false
var _react_tween: Tween


## Called by the world after instancing with the two grid cells to patrol
## between, the same cell_to_world the room uses for its own actors
## (TileMapLayer.map_to_local for isometric, cell * CELL_SIZE for
## top-down — see GridActor), a shared AStarGrid2D already configured with
## the room's bounds/solid cells for pathfinding, and a Vector2i grid delta
## -> "north"/"south"/"east"/"west" map (raw grid deltas mean different
## screen directions in each room — see isometric_world.gd) so the sprite
## faces the right way while stepping.
func configure_at_cells(cell_to_world_fn: Callable, cell_a: Vector2i, cell_b: Vector2i, nav_grid: AStarGrid2D, grid_dir_to_facing: Dictionary) -> void:
	_nav_grid = nav_grid
	_grid_dir_to_facing = grid_dir_to_facing
	_cell_a = cell_a
	_cell_b = cell_b
	var pos_a: Vector2 = cell_to_world_fn.call(cell_a)
	var pos_b: Vector2 = cell_to_world_fn.call(cell_b)
	anchor_a.position = Vector2.ZERO
	anchor_b.position = pos_b - pos_a
	setup(cell_a, cell_to_world_fn, func(c): return not nav_grid.is_point_solid(c))


func _ready() -> void:
	proximity_area.body_entered.connect(_on_proximity_entered)


func _physics_process(_delta: float) -> void:
	if _nav_grid == null or is_moving() or _waiting:
		return

	var target_cell := _cell_b if _target_is_b else _cell_a
	if grid_cell == target_cell:
		_waiting = true
		_path.clear()
		sprite.play_idle()
		get_tree().create_timer(pause_seconds).timeout.connect(_on_pause_finished, CONNECT_ONE_SHOT)
		return

	if _path.is_empty():
		_path = _nav_grid.get_id_path(grid_cell, target_cell)
		if not _path.is_empty():
			_path.pop_front()  # first point is grid_cell itself

	if _path.is_empty():
		return  # no path to the target right now (e.g. boxed in)

	var step := _path[0] - grid_cell
	try_step(step)
	if not is_moving():
		return  # try_step declined (shouldn't happen if the path is valid, but stay safe)
	_path.pop_front()
	sprite.play_moving(_grid_dir_to_facing.get(step, "south"))


func _on_pause_finished() -> void:
	_target_is_b = not _target_is_b
	_waiting = false


func _on_proximity_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _react_tween:
		_react_tween.kill()
	# Squash relative to CharacterSprite's own display scale, not a bare
	# 1.0 -- otherwise this settles back to 1x and undoes DISPLAY_SCALE.
	var rest_scale := Vector2.ONE * CharacterSprite.DISPLAY_SCALE
	_react_tween = create_tween()
	_react_tween.tween_property(sprite, "scale", rest_scale * Vector2(1.15, 0.9), 0.12)
	_react_tween.tween_property(sprite, "scale", rest_scale, 0.18)
