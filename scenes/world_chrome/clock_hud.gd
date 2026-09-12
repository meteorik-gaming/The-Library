extends CanvasLayer
## Always-visible day/time readout, top-left corner. The hour/day/speed
## controls only show up while devtools mode (Q) is on.

const WEEKDAYS: Array[String] = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

@onready var label: Label = $Panel/Label
@onready var hour_controls: HBoxContainer = $HourControls
@onready var hour_minus_button: Button = $HourControls/HourMinusButton
@onready var hour_plus_button: Button = $HourControls/HourPlusButton
@onready var day_controls: HBoxContainer = $DayControls
@onready var day_minus_button: Button = $DayControls/DayMinusButton
@onready var day_plus_button: Button = $DayControls/DayPlusButton
@onready var speed_button: Button = $SpeedButton

var _devtools_controls: Array


func _ready() -> void:
	GameClock.hour_changed.connect(_refresh)
	GameClock.day_started.connect(_refresh)
	_refresh()

	_devtools_controls = [hour_controls, day_controls, speed_button]
	for c in _devtools_controls:
		c.visible = DevTools.enabled
	DevTools.toggled.connect(_on_devtools_toggled)

	hour_minus_button.pressed.connect(func(): GameClock.add_hours(-1.0))
	hour_plus_button.pressed.connect(func(): GameClock.add_hours(1.0))
	day_minus_button.pressed.connect(func(): GameClock.add_days(-1))
	day_plus_button.pressed.connect(func(): GameClock.add_days(1))

	speed_button.pressed.connect(func(): GameClock.cycle_speed())
	GameClock.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(GameClock.speed_multiplier)


func _on_devtools_toggled(is_enabled: bool) -> void:
	for c in _devtools_controls:
		c.visible = is_enabled


func _refresh(_a = null) -> void:
	var hour := GameClock.get_clock_hour()
	var h := int(hour)
	var m := int(fmod(hour, 1.0) * 60.0)
	var weekday := WEEKDAYS[(GameClock.current_day - 1) % 7]
	label.text = "Day %d (%s)\n%02d:%02d %s" % [
		GameClock.current_day, weekday,
		h, m,
		"(night)" if GameClock.is_night else "(day)"
	]


func _on_speed_changed(multiplier: float) -> void:
	if multiplier == int(multiplier):
		speed_button.text = "%dx" % int(multiplier)
	else:
		speed_button.text = "%sx" % str(multiplier)
