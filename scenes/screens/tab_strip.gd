class_name TabStrip
extends HBoxContainer
## Generic top tab strip: exclusive-select buttons built from a list of
## (id, label) pairs. Emits tab_selected(id) when the active tab changes.
##
## Named TabStrip, not TabBar, to avoid colliding with Godot's own built-in
## TabBar control -- a typed `@onready var x: TabBar` would silently resolve
## to the ENGINE class instead of this one, since global class_names and
## built-in class names share one namespace, and fail its type check at
## runtime with a confusing "Trying to assign value of type 'HBoxContainer'
## to a variable of type 'TabBar'" (the real error says the assigned value's
## *base engine type*, not "not a TabStrip", which is what made this easy to
## misdiagnose the first time).
##
## Only owns the strip itself -- swapping which tab's content is visible is
## the caller's job, same separation as ScreenBase (chrome) vs. each screen
## (content), so this is reusable by any future tabbed screen, not just the
## pause/inventory menu.

signal tab_selected(id: StringName)

var _buttons := {}  # StringName -> Button
var _active: StringName = &""


## `tabs`: Array of [id: StringName, label: String].
func setup(tabs: Array) -> void:
	for tab in tabs:
		var id: StringName = tab[0]
		var b := UiKit.tab_button(tab[1])
		b.pressed.connect(_on_pressed.bind(id))
		add_child(b)
		_buttons[id] = b
	if not tabs.is_empty():
		select(tabs[0][0])


func select(id: StringName) -> void:
	if id == _active:
		return
	_active = id
	for tab_id in _buttons:
		_buttons[tab_id].button_pressed = (tab_id == id)
	tab_selected.emit(id)


func _on_pressed(id: StringName) -> void:
	select(id)
