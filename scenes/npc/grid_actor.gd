class_name GridActor
extends CharacterBody2D
## Base for anything that steps cell-by-cell on a grid — used by NPCs in
## both the isometric room (diamond grid, positions from a TileMapLayer) and
## the top-down room (plain square grid, positions from cell * CELL_SIZE).
## Movement is one full cell at a time, tweened smoothly between cells.
## `cell_to_world` is a Callable(Vector2i) -> Vector2 so this doesn't need
## to know which kind of room it's in.

const STEP_DURATION := 0.16

var grid_cell: Vector2i
var cell_to_world: Callable
var is_walkable: Callable = func(_cell: Vector2i) -> bool: return true

var _moving := false
var _tween: Tween


## Called once by the world after instancing, before any movement happens.
func setup(start_cell: Vector2i, cell_to_world_fn: Callable, walkable_check: Callable) -> void:
	cell_to_world = cell_to_world_fn
	grid_cell = start_cell
	is_walkable = walkable_check
	global_position = cell_to_world.call(grid_cell)


func is_moving() -> bool:
	return _moving


## Steps exactly one cell in `direction` (a grid-space delta, e.g. Vector2i(1,0)).
## No-ops if already mid-step or the target cell isn't walkable.
func try_step(direction: Vector2i) -> void:
	if _moving or direction == Vector2i.ZERO:
		return

	var target_cell := grid_cell + direction
	if not is_walkable.call(target_cell):
		return

	_moving = true
	grid_cell = target_cell
	var target_pos: Vector2 = cell_to_world.call(target_cell)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", target_pos, STEP_DURATION)
	_tween.finished.connect(_on_step_finished, CONNECT_ONE_SHOT)


func _on_step_finished() -> void:
	_moving = false
