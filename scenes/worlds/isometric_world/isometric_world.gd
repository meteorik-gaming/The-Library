extends Node2D
## Isometric equivalent of scenes/worlds/topdown_world/ — same 10x10 walled
## room spec, built on an isometric TileSet (64x32 diamond tiles) instead of
## flat rectangles. The player moves freely (continuous, vector-summed WASD)
## like in Top-Down, just projected onto the diamond's own screen-diagonal
## axes instead of straight up/down/left/right — see iso_player_mover.gd.
## The NPC still steps cell-by-cell (see scenes/npc/grid_actor.gd).

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

	var axes := _classify_axes()
	player.global_position = floor_layer.map_to_local(Vector2i(ROOM_CELLS / 2, ROOM_CELLS / 2))
	player.set_iso_axes(axes["north"]["screen_dir"], axes["east"]["screen_dir"])

	var grid_dir_to_facing := {}
	for direction in axes:
		grid_dir_to_facing[axes[direction]["grid_delta"]] = direction
	npc.configure_at_cells(floor_layer.map_to_local, Vector2i(3, 3), Vector2i(6, 3), _build_nav_grid(), grid_dir_to_facing)

	_configure_camera()


## A shared AStarGrid2D for every NPC in this room to pathfind on — real
## pathfinding (not just "step toward the target"), so it already handles
## obstacles if/when this room grows any.
func _build_nav_grid() -> AStarGrid2D:
	var nav_grid := AStarGrid2D.new()
	nav_grid.region = Rect2i(0, 0, ROOM_CELLS, ROOM_CELLS)
	nav_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav_grid.update()
	return nav_grid


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


## Figures out, from the TileSet's actual isometric projection, which
## SCREEN direction each raw grid delta (+X/-X/+Y/-Y) lands in — rather than
## assuming Godot's tile_layout sign convention. North/south/east/west are
## named by where they land on screen: north = top-left, south =
## bottom-right, west = bottom-left, east = top-right (the diamond room's
## diagonal axes). Returns direction -> {screen_dir: normalized Vector2 (for
## IsoPlayerMover's continuous movement), grid_delta: Vector2i (for NPC's
## grid-stepped facing)}.
func _classify_axes() -> Dictionary:
	var origin: Vector2 = floor_layer.map_to_local(Vector2i.ZERO)
	var candidates: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	var axes := {}
	for grid_delta in candidates:
		var screen_delta: Vector2 = floor_layer.map_to_local(grid_delta) - origin
		var direction := ""
		if screen_delta.x < 0 and screen_delta.y < 0:
			direction = "north"
		elif screen_delta.x > 0 and screen_delta.y > 0:
			direction = "south"
		elif screen_delta.x < 0 and screen_delta.y > 0:
			direction = "west"
		elif screen_delta.x > 0 and screen_delta.y < 0:
			direction = "east"
		if direction != "":
			axes[direction] = {"screen_dir": screen_delta.normalized(), "grid_delta": grid_delta}
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
