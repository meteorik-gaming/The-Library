class_name PauseMenu
extends CanvasLayer
## Shared tabbed menu (Pausa/Inventario/Keybinds/Opciones), Minecraft-
## creative-menu/Stardew style: ESC opens it on the Pausa tab, E opens it on
## the Inventario tab, and every tab is then reachable from either entry
## point via TabStrip. Opening it is a REAL pause (get_tree().paused = true) —
## everything under WorldChrome with default process_mode freezes for free
## (GameClock included), since this node is the only thing here that needs
## PROCESS_MODE_ALWAYS to stay responsive.
##
## Lives resident inside world_chrome.tscn (toggled via `visible`) rather
## than being spawned/freed like ScreenBase screens, so KeybindsPanel's
## Keybinds-autoload signal connections and this node's own process mode
## don't need to be re-established on every open.

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const INVENTORY_SLOT_COUNT := 24
const INVENTORY_COLUMNS := 6
const PREVIEW_IDENTIFIER := "Template"
const PREVIEW_TINT := Color(0.498, 0.839, 1, 1)  # matches Player's tint

const TABS: Array = [
	[&"pausa", "Pausa"],
	[&"inventario", "Inventario"],
	[&"keybinds", "Keybinds"],
	[&"opciones", "Opciones"],
]

@onready var backdrop: ColorRect = $Backdrop
@onready var panel: PanelContainer = $Panel
@onready var tab_strip: TabStrip = $Panel/Body/TabStrip
@onready var pausa_tab: VBoxContainer = $Panel/Body/ContentArea/PausaTab
@onready var inventario_tab: Control = $Panel/Body/ContentArea/InventarioTab
@onready var keybinds_tab: Control = $Panel/Body/ContentArea/KeybindsPanel
@onready var opciones_tab: VBoxContainer = $Panel/Body/ContentArea/OpcionesTab

var _tabs_by_id: Dictionary
var _preview_sprite: CharacterSprite
var _preview_play_pause_button: Button
var _preview_playing := true
var _preview_direction := 1  # 1 forward, -1 backward


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_set_blocking_input(false)

	_tabs_by_id = {
		&"pausa": pausa_tab,
		&"inventario": inventario_tab,
		&"keybinds": keybinds_tab,
		&"opciones": opciones_tab,
	}

	tab_strip.setup(TABS)
	tab_strip.tab_selected.connect(_on_tab_selected)

	_build_pausa_tab()
	_build_inventario_tab()
	_build_opciones_tab()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle(&"pausa")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_stats"):
		_toggle(&"inventario")
		get_viewport().set_input_as_handled()


func open(default_tab: StringName) -> void:
	visible = true
	_set_blocking_input(true)
	get_tree().paused = true
	tab_strip.select(default_tab)


func close() -> void:
	visible = false
	_set_blocking_input(false)
	get_tree().paused = false


## CanvasLayer.visible hides this whole menu's RENDERING correctly, but
## Godot's mouse/GUI hit-testing does not consistently respect an ancestor
## CanvasLayer's visibility for its child Controls -- Backdrop/Panel stayed
## individually "visible" and kept swallowing every click in the game (via
## their own mouse_filter) even while the menu was invisible and closed.
## Toggling mouse_filter explicitly alongside `visible` is what actually
## stops/allows input, independent of the rendering visibility.
func _set_blocking_input(blocking: bool) -> void:
	var filter := Control.MOUSE_FILTER_STOP if blocking else Control.MOUSE_FILTER_IGNORE
	backdrop.mouse_filter = filter
	panel.mouse_filter = filter


func _toggle(default_tab: StringName) -> void:
	if visible:
		close()
	else:
		open(default_tab)


func _on_tab_selected(id: StringName) -> void:
	for tab_id in _tabs_by_id:
		_tabs_by_id[tab_id].visible = (tab_id == id)


func _build_pausa_tab() -> void:
	var resume := UiKit.button("Reanudar")
	resume.pressed.connect(close)
	pausa_tab.add_child(resume)

	var quit := UiKit.button("Salir al menú")
	quit.pressed.connect(func() -> void:
		get_tree().paused = false
		get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	)
	pausa_tab.add_child(quit)


## Placeholder-only for now: empty bordered slots, no Item resource/data
## model yet — see SYSTEMS.md's "Deliberately deferred" section once added.
## Right side is a character preview playing the Rotate sheet (see
## CHARACTER_SPRITES.md — Rotate exists exactly for this) with manual
## spin controls.
func _build_inventario_tab() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventario_tab.add_child(row)

	row.add_child(_build_slot_grid())
	_build_character_preview(row)


func _build_slot_grid() -> Control:
	var grid := GridContainer.new()
	grid.columns = INVENTORY_COLUMNS
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)

	for i in INVENTORY_SLOT_COUNT:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(64, 64)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UiKit.PANEL_BG
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = UiKit.LOCKED
		slot.add_theme_stylebox_override("panel", sb)
		grid.add_child(slot)

	return grid


## Frame (character preview) + ◀/⏯/▶ controls below it. Playing: ◀/▶ flip
## which way the Rotate loop spins. Paused: ◀/▶ instead step it one frame
## at a time, for manually posing it.
func _build_character_preview(parent: Control) -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	# Attach to the (already live) tree BEFORE building children -- a
	# CharacterSprite's _ready() (which builds sprite_frames and defaults to
	# Idle) only fires once its whole ancestor chain is actually inside the
	# SceneTree. Building it off-tree first and calling play_animation()
	# before that attach is a no-op (sprite_frames is still null), and
	# _ready()'s own play_idle() then wins once it finally does attach --
	# which is exactly why this used to silently show Idle instead of Rotate.
	parent.add_child(box)

	var frame := PanelContainer.new()
	frame.custom_minimum_size = Vector2(160, 160)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.PANEL_BG
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = UiKit.LOCKED
	frame.add_theme_stylebox_override("panel", sb)
	box.add_child(frame)

	_preview_sprite = CharacterSprite.new()
	_preview_sprite.identifier = PREVIEW_IDENTIFIER
	_preview_sprite.tint = PREVIEW_TINT
	frame.add_child(_preview_sprite)
	_preview_sprite.play_animation("Rotate", "")
	_apply_preview_speed()

	# CharacterSprite is a Node2D, not a Control -- PanelContainer only
	# auto-lays-out Control children, so center it manually against the
	# frame's actual runtime size instead (not a hardcoded guess).
	frame.resized.connect(func() -> void: _preview_sprite.position = frame.size / 2.0)
	_preview_sprite.position = frame.custom_minimum_size / 2.0

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)

	var left_button := _small_button("◀")
	left_button.pressed.connect(_on_preview_left)
	controls.add_child(left_button)

	_preview_play_pause_button = _small_button("")
	_preview_play_pause_button.pressed.connect(_on_preview_play_pause)
	controls.add_child(_preview_play_pause_button)
	_update_preview_play_pause_label()

	var right_button := _small_button("▶")
	right_button.pressed.connect(_on_preview_right)
	controls.add_child(right_button)

	box.add_child(controls)


func _small_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(44, 36)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _on_preview_left() -> void:
	if _preview_playing:
		_preview_direction = -1
		_apply_preview_speed()
	else:
		_step_preview_frame(-1)


func _on_preview_right() -> void:
	if _preview_playing:
		_preview_direction = 1
		_apply_preview_speed()
	else:
		_step_preview_frame(1)


func _on_preview_play_pause() -> void:
	_preview_playing = not _preview_playing
	_apply_preview_speed()
	_update_preview_play_pause_label()


func _apply_preview_speed() -> void:
	_preview_sprite.speed_scale = float(_preview_direction) if _preview_playing else 0.0


func _step_preview_frame(step: int) -> void:
	var frame_count := _preview_sprite.sprite_frames.get_frame_count("Rotate")
	if frame_count <= 0:
		return
	_preview_sprite.frame = wrapi(_preview_sprite.frame + step, 0, frame_count)


func _update_preview_play_pause_label() -> void:
	_preview_play_pause_button.text = "⏸" if _preview_playing else "⏵"


func _build_opciones_tab() -> void:
	OptionsScreen.build_controls(opciones_tab)
