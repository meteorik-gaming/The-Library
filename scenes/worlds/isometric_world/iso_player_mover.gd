class_name IsoPlayerMover
extends CharacterBody2D
## Free continuous movement, same corner-assist idea as scenes/player/, but
## WASD is projected onto the isometric room's own screen-diagonal axes
## (north/east, handed in via set_iso_axes — see isometric_world.gd's
## _compute_screen_axes(), derived from the TileSet's actual projection)
## instead of straight screen up/down/left/right. Keys still just add as
## vectors — holding two together blends smoothly, same as normal 8-way
## movement, just rotated onto the diamond.
##   W = north (screen top-left)     S = south (screen bottom-right)
##   A = west  (screen bottom-left)  D = east  (screen top-right)

const SPEED := 220.0
const CORNER_ASSIST_MAX := 3.0
const CORNER_ASSIST_STEP := 1.0

@onready var sprite: CharacterSprite = $Sprite

var _north := Vector2.UP
var _east := Vector2.RIGHT
var _facing := DirectionalFacing.new()


func set_iso_axes(north: Vector2, east: Vector2) -> void:
	_north = north
	_east = east


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction := _east * input_dir.x - _north * input_dir.y
	velocity = direction * SPEED
	_apply_corner_assist(direction)
	move_and_slide()

	_facing.update()
	var facing_direction := _facing.current_direction()
	if facing_direction != "":
		sprite.play_moving(facing_direction)
	else:
		sprite.play_idle()


## Same idea as scenes/player/player.gd's corner assist, just working in the
## rotated iso direction space instead of raw screen axes.
func _apply_corner_assist(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	var motion := direction * SPEED * get_physics_process_delta_time()
	if not test_move(global_transform, motion):
		return

	var perpendicular := Vector2(-direction.y, direction.x).normalized()
	var offset := CORNER_ASSIST_STEP
	while offset <= CORNER_ASSIST_MAX:
		for dir_sign: float in [1.0, -1.0]:
			var nudge: Vector2 = perpendicular * offset * dir_sign
			var nudged_transform := global_transform.translated(nudge)
			if not test_move(nudged_transform, motion):
				global_position += nudge
				return
		offset += CORNER_ASSIST_STEP
