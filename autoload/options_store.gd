extends Node

## Central store for persisted audio/video options (volume, fullscreen).
## Applies changes live to AudioServer/DisplayServer immediately, and
## persists them to disk on every change. Applies the saved (or default)
## settings once at boot in _ready(), so they take effect even if the
## Options screen is never opened this session.

signal saved

const SAVE_PATH := "user://options.cfg"
const SECTION := "options"
const MASTER_BUS := "Master"

const DEFAULT_VOLUME := 1.0
const DEFAULT_FULLSCREEN := false

var master_volume := DEFAULT_VOLUME
var fullscreen := DEFAULT_FULLSCREEN


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_apply()


func set_master_volume(value: float) -> void:
	master_volume = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(value))
	_save()


func set_fullscreen(enabled: bool) -> void:
	fullscreen = enabled
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	)
	_save()


func _apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER_BUS), linear_to_db(master_volume))
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.save(SAVE_PATH)
	saved.emit()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	master_volume = cfg.get_value(SECTION, "master_volume", DEFAULT_VOLUME)
	fullscreen = cfg.get_value(SECTION, "fullscreen", DEFAULT_FULLSCREEN)
