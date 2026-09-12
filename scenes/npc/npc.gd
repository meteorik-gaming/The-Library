class_name NPC
extends GridActor
## Generic placeholder NPC that walks back and forth between two anchor
## points on a grid (works in both the isometric and top-down rooms — see
## configure_at_cells()). No schedule/time-of-day routing yet, just the two
## fixed anchors. AnchorA/AnchorB are repositioned to match at configure
## time, purely so they're accurate if you inspect the scene.

@export var pause_seconds := 1.2

@onready var anchor_a: Marker2D = $AnchorA
@onready var anchor_b: Marker2D = $AnchorB
@onready var proximity_area: Area2D = $ProximityArea
@onready var sprite: Polygon2D = $Square

var _cell_a: Vector2i
var _cell_b: Vector2i
var _target_is_b := true
var _waiting := false
var _react_tween: Tween


## Called by the world after instancing with the two grid cells to patrol
## between, plus the same cell_to_world/walkable_check the room uses for
## its own actors (TileMapLayer.map_to_local for isometric, cell * CELL_SIZE
## for top-down — see GridActor).
func configure_at_cells(cell_to_world_fn: Callable, cell_a: Vector2i, cell_b: Vector2i, walkable_check: Callable) -> void:
	_cell_a = cell_a
	_cell_b = cell_b
	var pos_a: Vector2 = cell_to_world_fn.call(cell_a)
	var pos_b: Vector2 = cell_to_world_fn.call(cell_b)
	anchor_a.position = Vector2.ZERO
	anchor_b.position = pos_b - pos_a
	setup(cell_a, cell_to_world_fn, walkable_check)


func _ready() -> void:
	proximity_area.body_entered.connect(_on_proximity_entered)


func _physics_process(_delta: float) -> void:
	if not cell_to_world.is_valid() or is_moving() or _waiting:
		return

	var target_cell := _cell_b if _target_is_b else _cell_a
	if grid_cell == target_cell:
		_waiting = true
		get_tree().create_timer(pause_seconds).timeout.connect(_on_pause_finished, CONNECT_ONE_SHOT)
		return

	var diff := target_cell - grid_cell
	var step := Vector2i(signi(diff.x), 0) if diff.x != 0 else Vector2i(0, signi(diff.y))
	try_step(step)


func _on_pause_finished() -> void:
	_target_is_b = not _target_is_b
	_waiting = false


func _on_proximity_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if _react_tween:
		_react_tween.kill()
	_react_tween = create_tween()
	_react_tween.tween_property(sprite, "scale", Vector2(1.15, 0.9), 0.12)
	_react_tween.tween_property(sprite, "scale", Vector2.ONE, 0.18)
