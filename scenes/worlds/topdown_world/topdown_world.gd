extends Node2D
## Bare textureless top-down sandbox — a 10x10 walled room, chosen from
## ChooseWorldTypeScreen, for prototyping mechanics before any art exists.
## See scenes/worlds/isometric_world/ for the isometric equivalent.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const CELL_SIZE := 64.0
const ROOM_CELLS := 10
const ROOM_SIZE := CELL_SIZE * ROOM_CELLS
const CAMERA_MARGIN := 200.0

@onready var camera: Camera2D = $Player/Camera2D
@onready var npc: NPC = $NPC


func _ready() -> void:
	camera.limit_left = -CAMERA_MARGIN
	camera.limit_top = -CAMERA_MARGIN
	camera.limit_right = ROOM_SIZE + CAMERA_MARGIN
	camera.limit_bottom = ROOM_SIZE + CAMERA_MARGIN

	npc.configure_at_cells(_cell_to_world, Vector2i(3, 3), Vector2i(6, 3), _is_walkable)


func _cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE


func _is_walkable(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < ROOM_CELLS and cell.y >= 0 and cell.y < ROOM_CELLS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
