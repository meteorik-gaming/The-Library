extends Node

## Continuous real-time day clock, tracked in in-game hours. Pauses
## automatically whenever a Dialogic dialogue box is open. Each playable day
## runs 5:00 AM -> 1:00 AM (20 in-game hours), then jumps to 5:00 AM the
## next day.

signal day_started(day: int)
signal day_ended(day: int)
signal hour_changed(hour: float)
signal phase_changed(is_night: bool)
signal clock_paused
signal clock_resumed
signal speed_changed(multiplier: float)

const DAY_START_HOUR := 5.0
const DAY_END_HOUR := 1.0
const HOURS_PER_DAY := 24.0 - DAY_START_HOUR + DAY_END_HOUR

## Devtool speed cycle: 1x -> 2x -> 4x -> 0.5x -> back to 1x.
const BASE_SECONDS_PER_GAME_HOUR := 40.0
const SPEED_PRESETS := [1.0, 2.0, 4.0, 0.5]

@export var seconds_per_game_hour := 40.0
@export var night_start_hour := 21.0

var current_day := 1
var elapsed_hours_today := 0.0
var is_night := false
var is_paused := false
var speed_multiplier := 1.0


func _ready() -> void:
	Dialogic.timeline_started.connect(pause)
	Dialogic.timeline_ended.connect(resume)
	day_started.emit(current_day)


func _process(delta: float) -> void:
	if is_paused:
		return
	_advance_time(delta / seconds_per_game_hour)


## Devtool hook: jump the clock forward/back by an arbitrary number of hours,
## going through the same day/night bookkeeping as a normal tick.
func add_hours(delta_hours: float) -> void:
	_advance_time(delta_hours)


## Devtool hook: jump the day counter forward/back without touching the
## current hour. Clamped to 1 or above.
func add_days(delta_days: int) -> void:
	current_day = maxi(current_day + delta_days, 1)
	is_night = _is_night_at(get_clock_hour())
	day_started.emit(current_day)


## Devtool hook: cycle through SPEED_PRESETS.
func cycle_speed() -> void:
	var idx := SPEED_PRESETS.find(speed_multiplier)
	idx = (idx + 1) % SPEED_PRESETS.size()
	speed_multiplier = SPEED_PRESETS[idx]
	seconds_per_game_hour = BASE_SECONDS_PER_GAME_HOUR / speed_multiplier
	speed_changed.emit(speed_multiplier)


func _advance_time(delta_hours: float) -> void:
	elapsed_hours_today = maxf(0.0, elapsed_hours_today + delta_hours)
	hour_changed.emit(get_clock_hour())

	var should_be_night := _is_night_at(get_clock_hour())
	if should_be_night != is_night:
		is_night = should_be_night
		phase_changed.emit(is_night)

	if elapsed_hours_today >= HOURS_PER_DAY:
		_advance_day()


func pause() -> void:
	if is_paused:
		return
	is_paused = true
	clock_paused.emit()


func resume() -> void:
	if not is_paused:
		return
	is_paused = false
	clock_resumed.emit()


## Current time of day on a 24h clock face (e.g. 5.0 = 5:00 AM, 13.5 = 1:30 PM).
func get_clock_hour() -> float:
	return fmod(DAY_START_HOUR + elapsed_hours_today, 24.0)


func get_time_ratio() -> float:
	return clampf(elapsed_hours_today / HOURS_PER_DAY, 0.0, 1.0)


func _is_night_at(hour: float) -> bool:
	return hour >= night_start_hour or hour < DAY_START_HOUR


func _advance_day() -> void:
	day_ended.emit(current_day)
	current_day += 1
	elapsed_hours_today = 0.0
	is_night = false
	day_started.emit(current_day)
