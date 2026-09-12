class_name NPC
extends IsoGridActor
## Generic placeholder NPC that walks back and forth between two anchor
## points on the isometric grid. No schedule/time-of-day routing yet — see
## the AnchorA/AnchorB children for the two spots it patrols between.

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


## Called by the world after instancing, mirroring Player's setup() but
## deriving the start/anchor cells from the AnchorA/AnchorB marker positions
## (drag those two nodes in the editor to set the patrol span).
func configure(layer: TileMapLayer, walkable_check: Callable) -> void:
	var cell_a := layer.local_to_map(layer.to_local(anchor_a.global_position))
	var cell_b := layer.local_to_map(layer.to_local(anchor_b.global_position))
	configure_at_cells(layer, cell_a, cell_b, walkable_check)


## Alternative to configure() for callers that already know the exact grid
## cells to patrol between (e.g. a room script placing an NPC by coordinate
## rather than by hand-positioned markers).
func configure_at_cells(layer: TileMapLayer, cell_a: Vector2i, cell_b: Vector2i, walkable_check: Callable) -> void:
	_cell_a = cell_a
	_cell_b = cell_b
	setup(layer, cell_a, walkable_check)


func _ready() -> void:
	proximity_area.body_entered.connect(_on_proximity_entered)


func _physics_process(_delta: float) -> void:
	if floor_layer == null or is_moving() or _waiting:
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
