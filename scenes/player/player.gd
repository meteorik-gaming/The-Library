class_name Player
extends CharacterBody2D
## Shared movement controller for The Library's placeholder worlds — free
## continuous movement with corner assist, facing/animating via CharacterSprite
## based on whichever movement key currently "wins" (see DirectionalFacing).
## Also plays Attack (left click) / Interact (right click) one-shot — see
## _play_action(). No cooldown/hit-detection/gating yet, just the frames
## wired up to input for a visual test; movement keeps working underneath.

const SPEED := 220.0
const CORNER_ASSIST_MAX := 3.0
const CORNER_ASSIST_STEP := 1.0

@onready var sprite: CharacterSprite = $Sprite

var _facing := DirectionalFacing.new()
var _action_end_msec := 0


func _physics_process(_delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * SPEED
	_apply_corner_assist(input_dir)
	move_and_slide()

	_facing.update()
	if Time.get_ticks_msec() < _action_end_msec:
		return  # let the Attack/Interact animation play out undisturbed

	var direction := _facing.current_direction()
	if direction != "":
		sprite.play_moving(direction)
	else:
		sprite.play_idle()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_play_action("Attack")
	elif event.is_action_pressed("interact"):
		_play_action("Interact")


## Plays a one-shot Attack/Interact facing whatever direction the sprite is
## currently facing, then lets normal movement-driven animation resume.
func _play_action(animation_type: String) -> void:
	var direction := sprite.get_current_direction()
	sprite.play_animation(animation_type, direction)
	var duration := sprite.get_animation_duration(animation_type, direction)
	_action_end_msec = Time.get_ticks_msec() + int(duration * 1000.0)


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
