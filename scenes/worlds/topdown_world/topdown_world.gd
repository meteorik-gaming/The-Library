extends Node2D
## Bare textureless top-down sandbox — a 10x10 walled room, chosen from
## ChooseWorldTypeScreen, for prototyping mechanics before any art exists.
## See scenes/worlds/isometric_world/ for the isometric equivalent.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const CELL_SIZE := 64.0
const ROOM_CELLS := 10
const ROOM_SIZE := CELL_SIZE * ROOM_CELLS
const CAMERA_MARGIN := 200.0

## Grid deltas ARE screen directions here (no projection to untangle, unlike
## isometric_world.gd's _classify_axes()).
const GRID_DIR_TO_FACING := {
	Vector2i(0, -1): "north",
	Vector2i(0, 1): "south",
	Vector2i(-1, 0): "west",
	Vector2i(1, 0): "east",
}

@onready var camera: Camera2D = $Player/Camera2D
@onready var npc: NPC = $NPC


func _ready() -> void:
	camera.limit_left = -CAMERA_MARGIN
	camera.limit_top = -CAMERA_MARGIN
	camera.limit_right = ROOM_SIZE + CAMERA_MARGIN
	camera.limit_bottom = ROOM_SIZE + CAMERA_MARGIN

	npc.configure_at_cells(_cell_to_world, Vector2i(3, 3), Vector2i(6, 3), _build_nav_grid(), GRID_DIR_TO_FACING)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE


## A shared AStarGrid2D for every NPC in this room to pathfind on — real
## pathfinding (not just "step toward the target"), so it already handles
## obstacles if/when this room grows any.
func _build_nav_grid() -> AStarGrid2D:
	var nav_grid := AStarGrid2D.new()
	nav_grid.region = Rect2i(0, 0, ROOM_CELLS, ROOM_CELLS)
	nav_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	nav_grid.update()
	return nav_grid


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
