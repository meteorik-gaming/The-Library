class_name ScreenBase
extends Control
## Shared chrome for overlay screens (Choose World Type, Options, a future
## pause menu, etc.): a dimmed backdrop behind a centered panel.
##
## Opened via `ScreenBase.open(instance)`: added to the tree root so it
## always renders on top and blocks input to whatever's behind. `close()`
## (or emitting `closed` yourself) frees it and lets the caller react.

signal closed

var body: VBoxContainer


static func open(screen: Control) -> Control:
	Engine.get_main_loop().root.add_child(screen)
	return screen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Builds a dimmed backdrop + a centered fixed-size panel with an optional
## title, and returns the body vbox so the caller can keep adding content.
func build_panel(panel_size: Vector2, title: String = "") -> VBoxContainer:
	var dim := ColorRect.new()
	dim.color = UiKit.BG
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -panel_size.x / 2.0
	panel.offset_top = -panel_size.y / 2.0
	panel.offset_right = panel_size.x / 2.0
	panel.offset_bottom = panel_size.y / 2.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.PANEL_BG
	sb.content_margin_left = 30.0
	sb.content_margin_right = 30.0
	sb.content_margin_top = 30.0
	sb.content_margin_bottom = 30.0
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	panel.add_child(body)

	if not title.is_empty():
		body.add_child(UiKit.label(title, 28, UiKit.ACCENT))

	return body


func add_back_button(action: Callable = Callable()) -> Button:
	var b := UiKit.button("Volver")
	b.pressed.connect(action if action.is_valid() else close)
	body.add_child(b)
	return b


func close() -> void:
	closed.emit()
	queue_free()
