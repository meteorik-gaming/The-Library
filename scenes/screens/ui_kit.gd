class_name UiKit
## Shared palette + small UI builder helpers for The Library's menu/screen system.

const BG := Color(0.09, 0.09, 0.11, 1.0)
const PANEL_BG := Color(0.14, 0.14, 0.17, 1.0)
const ACCENT := Color("#7fd6ff")
const TEXT := Color("#e6e6e6")
const LOCKED := Color("#555555")


static func label(text: String, size: int, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func body_text(text: String, size := 16, color: Color = TEXT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func button(text: String, size := 18) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 0)
	b.add_theme_font_size_override("font_size", size)
	return b


static func spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = h
	return c


static func tab_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(140, 40)
	b.add_theme_font_size_override("font_size", 18)
	b.focus_mode = Control.FOCUS_NONE
	return b


## Wires a subtle hover-in feedback (scale + glow) onto `control`, growing it
## by `growth` (relative to its own current scale, never an absolute
## Vector2.ONE -- see the NPC squash-tween in grid_actor.gd for why) and
## fading its modulate up, reverting both on hover-out.
##
## The in-flight Tween is stashed on `control` itself via set_meta/get_meta
## rather than a variable captured by the two mouse_entered/mouse_exited
## lambdas below: GDScript lambdas snapshot captured locals by value at
## creation time, so two separately-created lambdas would each get their own
## frozen copy and couldn't see/kill each other's tween. Node metadata is
## shared external state both callbacks read and write, so the usual
## "always kill the in-flight tween before starting a new one" rule holds.
static func add_hover_scale(control: Control, growth := 0.025, duration := 0.15) -> void:
	control.pivot_offset = control.size / 2.0
	var rest_scale := control.scale

	control.mouse_entered.connect(func() -> void:
		var t: Tween = control.get_meta("hover_tween") if control.has_meta("hover_tween") else null
		if t:
			t.kill()
		t = control.create_tween()
		t.set_parallel(true)
		t.tween_property(control, "scale", rest_scale * (1.0 + growth), duration)
		t.tween_property(control, "modulate", Color(1.15, 1.15, 1.15), duration)
		control.set_meta("hover_tween", t)
	)
	control.mouse_exited.connect(func() -> void:
		var t: Tween = control.get_meta("hover_tween") if control.has_meta("hover_tween") else null
		if t:
			t.kill()
		t = control.create_tween()
		t.set_parallel(true)
		t.tween_property(control, "scale", rest_scale, duration)
		t.tween_property(control, "modulate", Color.WHITE, duration)
		control.set_meta("hover_tween", t)
	)
