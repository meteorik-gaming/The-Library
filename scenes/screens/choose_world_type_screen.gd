class_name ChooseWorldTypeScreen
extends ScreenBase
## Lets the player pick which placeholder world to test Jugar with.
## Isometric stays locked until that system is ported over from another
## project; Top-Down opens a bare, textureless movement sandbox.

signal world_chosen(scene_path: String)

const TOPDOWN_WORLD_SCENE := "res://scenes/worlds/topdown_world/topdown_world.tscn"
const ISOMETRIC_WORLD_SCENE := "res://scenes/worlds/isometric_world/isometric_world.tscn"


func _ready() -> void:
	super._ready()
	build_panel(Vector2(760, 420), "ELEGIR TIPO DE MUNDO")

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(row)

	row.add_child(_card("Top-Down", "Cuadrado sin texturas, movimiento libre con flechas.", TOPDOWN_WORLD_SCENE, false))
	row.add_child(_card("Isométrico", "Mismo cuarto 10x10, con tiles placeholder isométricos.", ISOMETRIC_WORLD_SCENE, false))

	add_back_button()


func _card(title: String, description: String, scene_path: String, locked: bool) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 240)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.BG
	sb.content_margin_left = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top = 16.0
	sb.content_margin_bottom = 16.0
	panel.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	v.add_child(UiKit.label(title, 20, UiKit.LOCKED if locked else UiKit.ACCENT))
	v.add_child(UiKit.spacer(4))
	v.add_child(UiKit.body_text(description, 14))
	v.add_child(UiKit.spacer(8))

	var btn := UiKit.button("Próximamente" if locked else "Elegir")
	btn.disabled = locked
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not locked:
		btn.pressed.connect(_choose.bind(scene_path))
	v.add_child(btn)

	return panel


func _choose(scene_path: String) -> void:
	world_chosen.emit(scene_path)
	close()
