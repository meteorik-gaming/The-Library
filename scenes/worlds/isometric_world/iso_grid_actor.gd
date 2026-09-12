class_name IsoGridActor
extends CharacterBody2D
## Base for anything that steps cell-by-cell on an isometric TileMapLayer
## grid (the player mover and NPCs both extend this). Movement is one full
## cell at a time, tweened smoothly between cells rather than continuous
## free-roam — the isometric counterpart to the free CharacterBody2D
## movement used in scenes/player/.

const STEP_DURATION := 0.16

var floor_layer: TileMapLayer
var grid_cell: Vector2i
var is_walkable: Callable = func(_cell: Vector2i) -> bool: return true

var _moving := false
var _tween: Tween


## Called once by the world after instancing, before any movement happens.
func setup(layer: TileMapLayer, start_cell: Vector2i, walkable_check: Callable) -> void:
	floor_layer = layer
	grid_cell = start_cell
	is_walkable = walkable_check
	global_position = floor_layer.map_to_local(grid_cell)


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
	var target_pos: Vector2 = floor_layer.map_to_local(target_cell)

	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "global_position", target_pos, STEP_DURATION)
	_tween.finished.connect(_on_step_finished, CONNECT_ONE_SHOT)


func _on_step_finished() -> void:
	_moving = false
