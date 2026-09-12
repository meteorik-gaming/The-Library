extends Control

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const DISPLAY_DURATION := 2.0


func _ready() -> void:
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	if is_inside_tree():
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
