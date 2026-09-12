class_name OptionsScreen
extends ScreenBase
## Basic audio/video options. Applies immediately for the running session —
## no persistence to disk yet, that's a separate step once it's worth it.

const MASTER_BUS := "Master"


func _ready() -> void:
	super._ready()
	build_panel(Vector2(480, 320), "OPCIONES")

	body.add_child(UiKit.label("Volumen", 16))
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = _get_master_linear()
	volume_slider.value_changed.connect(_on_volume_changed)
	body.add_child(volume_slider)

	body.add_child(UiKit.spacer(8))

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Pantalla completa"
	fullscreen_toggle.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	body.add_child(fullscreen_toggle)

	body.add_child(UiKit.spacer(8))
	add_back_button()


func _get_master_linear() -> float:
	var idx := AudioServer.get_bus_index(MASTER_BUS)
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func _on_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index(MASTER_BUS)
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))


func _on_fullscreen_toggled(enabled: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)
