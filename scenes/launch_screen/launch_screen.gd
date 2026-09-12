extends Control

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const DISPLAY_DURATION := 2.5

var _transitioning := false


func _ready() -> void:
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	_go_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if _transitioning:
		return
	var is_key_press: bool = event is InputEventKey and event.pressed and not event.echo
	var is_click: bool = event is InputEventMouseButton and event.pressed
	if is_key_press or is_click:
		_go_to_main_menu()


func _go_to_main_menu() -> void:
	if _transitioning or not is_inside_tree():
		return
	_transitioning = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
