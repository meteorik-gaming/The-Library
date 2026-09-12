class_name Player
extends CharacterBody2D
## Shared movement controller for The Library's placeholder worlds — free
## continuous movement with corner assist, facing/animating via CharacterSprite
## based on whichever movement key currently "wins" (see DirectionalFacing).

const SPEED := 220.0
const CORNER_ASSIST_MAX := 3.0
const CORNER_ASSIST_STEP := 1.0

@onready var sprite: CharacterSprite = $Sprite

var _facing := DirectionalFacing.new()


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	_apply_corner_assist(input_dir)
	move_and_slide()

	_facing.update()
	var direction := _facing.current_direction()
	if direction != "":
		sprite.play_moving(direction)
	else:
		sprite.play_idle()


## If the input direction is blocked but a small perpendicular nudge would
## clear it, shift the player there first. Softens tight corridor turns so
## they don't require pixel-precise alignment against the corner.
func _apply_corner_assist(input_dir: Vector2) -> void:
	if input_dir == Vector2.ZERO:
		return

	var motion := input_dir * SPEED * get_physics_process_delta_time()
	if not test_move(global_transform, motion):
		return

	var perpendicular := Vector2(-input_dir.y, input_dir.x).normalized()
	var offset := CORNER_ASSIST_STEP
	while offset <= CORNER_ASSIST_MAX:
		for dir_sign: float in [1.0, -1.0]:
			var nudge: Vector2 = perpendicular * offset * dir_sign
			var nudged_transform := global_transform.translated(nudge)
			if not test_move(nudged_transform, motion):
				global_position += nudge
				return
		offset += CORNER_ASSIST_STEP
