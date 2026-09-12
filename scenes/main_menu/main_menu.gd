extends Control

const CHOOSE_WORLD_TYPE_SCENE := "res://scenes/screens/choose_world_type_screen.tscn"
const OPTIONS_SCENE := "res://scenes/screens/options_screen.tscn"

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var options_button: Button = $CenterContainer/VBoxContainer/OptionsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	for b in [play_button, options_button, quit_button]:
		UiKit.add_hover_scale(b)


func _on_play_pressed() -> void:
	var screen: ChooseWorldTypeScreen = ScreenBase.open(preload(CHOOSE_WORLD_TYPE_SCENE).instantiate())
	screen.world_chosen.connect(_on_world_chosen)


func _on_world_chosen(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _on_options_pressed() -> void:
	ScreenBase.open(preload(OPTIONS_SCENE).instantiate())


func _on_quit_pressed() -> void:
	get_tree().quit()
