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
