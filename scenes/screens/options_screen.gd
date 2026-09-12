class_name OptionsScreen
extends ScreenBase
## Audio/video options. Reads/writes through the OptionsStore autoload,
## which applies changes live and persists them to user://options.cfg.

func _ready() -> void:
	super._ready()
	build_panel(Vector2(480, 320), "OPCIONES")
	build_controls(body)
	add_back_button()


## Builds just the volume/fullscreen controls, with no ScreenBase backdrop/
## panel chrome, so PauseMenu's Opciones tab can reuse them directly without
## instancing a whole OptionsScreen node.
static func build_controls(parent: Control) -> void:
	parent.add_child(UiKit.label("Volumen", 16))
	var volume_slider := HSlider.new()
	volume_slider.min_value = 0.0
	volume_slider.max_value = 1.0
	volume_slider.step = 0.01
	volume_slider.value = OptionsStore.master_volume
	volume_slider.value_changed.connect(OptionsStore.set_master_volume)
	parent.add_child(volume_slider)

	parent.add_child(UiKit.spacer(8))

	var fullscreen_toggle := CheckButton.new()
	fullscreen_toggle.text = "Pantalla completa"
	fullscreen_toggle.button_pressed = OptionsStore.fullscreen
	fullscreen_toggle.toggled.connect(OptionsStore.set_fullscreen)
	parent.add_child(fullscreen_toggle)
