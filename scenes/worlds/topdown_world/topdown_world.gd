extends Node2D
## Bare textureless top-down sandbox — a 10x10 walled room, chosen from
## ChooseWorldTypeScreen, for prototyping mechanics before any art exists.
## See scenes/worlds/isometric_world/ for the isometric equivalent.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const ROOM_SIZE := 640.0
const CAMERA_MARGIN := 200.0

@onready var camera: Camera2D = $Player/Camera2D


func _ready() -> void:
	camera.limit_left = -CAMERA_MARGIN
	camera.limit_top = -CAMERA_MARGIN
	camera.limit_right = ROOM_SIZE + CAMERA_MARGIN
	camera.limit_bottom = ROOM_SIZE + CAMERA_MARGIN


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
