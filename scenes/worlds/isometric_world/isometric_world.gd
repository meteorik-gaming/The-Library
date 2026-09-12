extends Node2D
## Isometric equivalent of scenes/worlds/topdown_world/ — same 10x10 walled
## room spec, built on an isometric TileSet (64x32 diamond tiles) instead of
## flat rectangles. Same shared Player/back-to-menu behavior as the top-down
## room, just laid out on a tile grid.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const ROOM_CELLS := 10
const FLOOR_SOURCE_ID := 0
const WALL_SOURCE_ID := 1
const CAMERA_MARGIN := 200.0

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	_build_room()
	var center_cell := Vector2i(ROOM_CELLS / 2, ROOM_CELLS / 2)
	player.position = floor_layer.map_to_local(center_cell)
	_configure_camera()


## Fills a ROOM_CELLS x ROOM_CELLS floor and rings it with a one-cell-thick
## wall border — same shape as topdown_world's 4 walls, expressed as tiles.
func _build_room() -> void:
	for x in ROOM_CELLS:
		for y in ROOM_CELLS:
			floor_layer.set_cell(Vector2i(x, y), FLOOR_SOURCE_ID, Vector2i.ZERO)

	for x in range(-1, ROOM_CELLS + 1):
		wall_layer.set_cell(Vector2i(x, -1), WALL_SOURCE_ID, Vector2i.ZERO)
		wall_layer.set_cell(Vector2i(x, ROOM_CELLS), WALL_SOURCE_ID, Vector2i.ZERO)
	for y in range(-1, ROOM_CELLS + 1):
		wall_layer.set_cell(Vector2i(-1, y), WALL_SOURCE_ID, Vector2i.ZERO)
		wall_layer.set_cell(Vector2i(ROOM_CELLS, y), WALL_SOURCE_ID, Vector2i.ZERO)


## Isometric projection isn't axis-aligned, so bound the camera with the
## smallest rect containing all four corners of the wall ring instead of
## computing it from ROOM_CELLS directly.
func _configure_camera() -> void:
	var corners := [
		floor_layer.map_to_local(Vector2i(-1, -1)),
		floor_layer.map_to_local(Vector2i(ROOM_CELLS, -1)),
		floor_layer.map_to_local(Vector2i(-1, ROOM_CELLS)),
		floor_layer.map_to_local(Vector2i(ROOM_CELLS, ROOM_CELLS)),
	]
	var min_pos: Vector2 = corners[0]
	var max_pos: Vector2 = corners[0]
	for c: Vector2 in corners:
		min_pos = min_pos.min(c)
		max_pos = max_pos.max(c)

	camera.limit_left = min_pos.x - CAMERA_MARGIN
	camera.limit_top = min_pos.y - CAMERA_MARGIN
	camera.limit_right = max_pos.x + CAMERA_MARGIN
	camera.limit_bottom = max_pos.y + CAMERA_MARGIN


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
