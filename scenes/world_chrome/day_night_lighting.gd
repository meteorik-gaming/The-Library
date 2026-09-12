extends CanvasModulate
## Ambient day/night light for a room. Samples a colour gradient by the time
## of day (GameClock) and pushes it to this CanvasModulate every frame, so
## the change is one continuous fade with no stepping. Also:
##  - eases the edge vignette with the ambient brightness, and
##  - fades any PointLight2D glows down during the day so they don't stack
##    on top of an already-bright ambient and blow the scene out.
##
## The look lives in a plain resource (day_night_gradient.tres, wired to
## this node in world_chrome.tscn) — open it and drag the colour stops
## around, or assign your own Gradient. Gradient offset 0..1 maps to
## 00:00..24:00 — so 0.29 is ~7am, 0.5 is noon, 0.875 is 9pm.

@export var ambient_gradient: Gradient

## Vignette max darkening at the gradient's brightest point vs its darkest.
@export_range(0.0, 1.0) var day_vignette := 0.12
@export_range(0.0, 1.0) var night_vignette := 0.58

## Ambient-colour luminance treated as full night / full day for the vignette
## and light-fade ramps (tune if the gradient gets recoloured a lot).
@export var night_luminance := 0.12
@export var day_luminance := 0.90

## PointLight2D energy multiplier at full day (1.0 = unchanged, 0.0 = fully
## off at midday). At night the lights are always at full energy.
@export_range(0.0, 1.0) var day_light_scale := 0.1

@onready var _vignette: CanvasItem = get_node_or_null("../Atmosphere/Vignette")

## [{ "light": PointLight2D, "base": float }] — every PointLight2D in the
## room, with its authored energy captured so the day fade is always
## relative to that.
var _lights: Array[Dictionary] = []


func _ready() -> void:
	if ambient_gradient == null:
		ambient_gradient = _fallback_gradient()
	_collect_lights()
	GameClock.hour_changed.connect(_apply)
	_apply(GameClock.get_clock_hour())


func _collect_lights() -> void:
	var root := get_tree().current_scene
	if root == null:
		return
	for node in root.find_children("*", "PointLight2D", true, false):
		_lights.append({"light": node, "base": node.energy})


func _apply(hour: float) -> void:
	var c := ambient_gradient.sample(fposmod(hour, 24.0) / 24.0)
	color = c

	var brightness := clampf(
		remap(c.get_luminance(), night_luminance, day_luminance, 0.0, 1.0), 0.0, 1.0)

	if _vignette and _vignette.material is ShaderMaterial:
		var mat: ShaderMaterial = _vignette.material
		mat.set_shader_parameter("max_darkness", lerpf(night_vignette, day_vignette, brightness))

	var light_mult := lerpf(1.0, day_light_scale, brightness)
	for entry in _lights:
		var light: PointLight2D = entry["light"]
		if is_instance_valid(light):
			light.energy = entry["base"] * light_mult


## Used only if no Gradient resource is assigned in the scene.
func _fallback_gradient() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.2, 0.29, 0.34, 0.74, 0.8, 0.88, 0.95, 1.0])
	g.colors = PackedColorArray([
		Color(0.20, 0.22, 0.38), Color(0.21, 0.23, 0.39), Color(0.55, 0.45, 0.52),
		Color(0.95, 0.93, 0.96), Color(0.97, 0.95, 0.94), Color(0.86, 0.68, 0.55),
		Color(0.42, 0.36, 0.50), Color(0.24, 0.25, 0.42), Color(0.20, 0.22, 0.38),
	])
	return g
