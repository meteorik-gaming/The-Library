extends Node2D
## Isometric equivalent of scenes/worlds/topdown_world/ — same 10x10 walled
## room spec, built on an isometric TileSet (64x32 diamond tiles) instead of
## flat rectangles. Movement here is grid-stepped (see IsoGridActor) instead
## of free-roam, with WASD assigned to screen directions rather than raw grid
## axes — see iso_player_mover.gd for the mapping.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const ROOM_CELLS := 10
const FLOOR_SOURCE_ID := 0
const WALL_SOURCE_ID := 1
const CAMERA_MARGIN := 200.0

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var player: IsoPlayerMover = $Player
@onready var npc: NPC = $NPC
@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	_build_room()

	var axes := _compute_screen_axes()
	var start_cell := Vector2i(ROOM_CELLS / 2, ROOM_CELLS / 2)
	player.setup(floor_layer, start_cell, _is_walkable)
	player.set_axes(axes)
	npc.configure_at_cells(floor_layer, Vector2i(3, 3), Vector2i(6, 3), _is_walkable)

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


func _is_walkable(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < ROOM_CELLS and cell.y >= 0 and cell.y < ROOM_CELLS


## Figures out, from the TileSet's actual isometric projection, which raw
## grid delta (+X/-X/+Y/-Y) lands in each screen quadrant — rather than
## assuming Godot's tile_layout sign convention. North/south/east/west are
## named by where they land on screen: north = top-left, south =
## bottom-right, west = bottom-left, east = top-right (per the diamond
## room's diagonal axes).
func _compute_screen_axes() -> Dictionary:
	var origin: Vector2 = floor_layer.map_to_local(Vector2i.ZERO)
	var candidates := {
		Vector2i(1, 0): floor_layer.map_to_local(Vector2i(1, 0)) - origin,
		Vector2i(-1, 0): floor_layer.map_to_local(Vector2i(-1, 0)) - origin,
		Vector2i(0, 1): floor_layer.map_to_local(Vector2i(0, 1)) - origin,
		Vector2i(0, -1): floor_layer.map_to_local(Vector2i(0, -1)) - origin,
	}

	var axes := {}
	for cell_delta: Vector2i in candidates:
		var screen_delta: Vector2 = candidates[cell_delta]
		if screen_delta.x < 0 and screen_delta.y < 0:
			axes["north"] = cell_delta
		elif screen_delta.x > 0 and screen_delta.y > 0:
			axes["south"] = cell_delta
		elif screen_delta.x < 0 and screen_delta.y > 0:
			axes["west"] = cell_delta
		elif screen_delta.x > 0 and screen_delta.y < 0:
			axes["east"] = cell_delta
	return axes


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
