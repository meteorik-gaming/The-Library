class_name CharacterSprite
extends AnimatedSprite2D
## Directional character sprite driven by the Template-<AnimationType>-Sheet.png
## naming convention — see assets/characters/CHARACTER_SPRITES.md for the
## full spec. Slices whichever sheets exist for `identifier` into per-row
## looping animations at _ready(), and exposes play_moving()/play_idle() so
## a mover script only needs to know a semantic direction name
## ("north"/"south"/"east"/"west"), not which row/flip that maps to for the
## current world type.

const FRAME_SIZE := 32
const DISPLAY_SCALE := 2.0
const ANIMATION_TYPES := ["Attack", "Idle", "Interact", "Jump", "Rotate", "Run", "Walk"]
const ROW_NAMES := ["front", "diagonal_front", "side", "diagonal_back", "back"]
const SHEET_PATH_FORMAT := "res://assets/characters/%s-%s-Sheet.png"

## direction -> {row, flip}. Rows per CHARACTER_SPRITES.md: 0 front,
## 1 diagonal_front, 2 side, 3 diagonal_back, 4 back.
const TOPDOWN_ROW_MAP := {
	"south": {"row": 0, "flip": false},
	"east": {"row": 2, "flip": false},
	"west": {"row": 2, "flip": true},
	"north": {"row": 4, "flip": false},
}
const ISO_ROW_MAP := {
	"south": {"row": 1, "flip": false},
	"west": {"row": 1, "flip": true},
	"east": {"row": 3, "flip": false},
	"north": {"row": 3, "flip": true},
}

@export var identifier := "Template"
@export var is_isometric := false
@export var tint := Color.WHITE

var _row_map: Dictionary
var _current_direction := "south"


func _ready() -> void:
	_row_map = ISO_ROW_MAP if is_isometric else TOPDOWN_ROW_MAP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2(DISPLAY_SCALE, DISPLAY_SCALE)
	modulate = tint
	sprite_frames = _build_sprite_frames()
	play_idle()


func play_moving(direction: String) -> void:
	play_animation("Walk", direction)


## direction defaults to whatever we were last facing, so stopping doesn't
## reset the character to face south.
func play_idle(direction: String = "") -> void:
	play_animation("Idle", direction if direction != "" else _current_direction)


## Public entry point for any AnimationType — Attack/Interact/Jump/Run/etc,
## not just the Idle/Walk states play_idle()/play_moving() cover. `Rotate`
## has no directions; pass any direction string for it, it's ignored.
func play_animation(animation_type: String, direction: String) -> void:
	_play(direction, animation_type)


## Whichever direction was last actually faced (walking or otherwise) — for
## callers (e.g. Attack/Interact input) that want "face whatever way the
## character is currently facing" without tracking it themselves.
func get_current_direction() -> String:
	return _current_direction


## Seconds for one playthrough of `animation_type` facing `direction`, from
## its frame count / playback speed -- every CharacterSprite animation loops
## (see CHARACTER_SPRITES.md), so this is how a caller times a one-shot
## action (Attack/Interact) instead of it looping forever. Returns 0.0 if
## that sheet/direction combo doesn't exist.
func get_animation_duration(animation_type: String, direction: String) -> float:
	if sprite_frames == null:
		return 0.0

	var anim_name: String
	if animation_type == "Rotate":
		anim_name = "Rotate"
	elif _row_map.has(direction):
		anim_name = "%s_%s" % [animation_type, ROW_NAMES[_row_map[direction]["row"]]]
	else:
		return 0.0

	if not sprite_frames.has_animation(anim_name):
		return 0.0
	var speed := sprite_frames.get_animation_speed(anim_name)
	if speed <= 0.0:
		return 0.0
	return sprite_frames.get_frame_count(anim_name) / speed


func _play(direction: String, animation_type: String) -> void:
	if sprite_frames == null:
		return

	# No directional rows for Rotate -- one flat frame strip, ignore direction.
	if animation_type == "Rotate":
		if sprite_frames.has_animation("Rotate") and (animation != "Rotate" or not is_playing()):
			play("Rotate")
		return

	if not _row_map.has(direction):
		return
	_current_direction = direction

	var row_info: Dictionary = _row_map[direction]
	flip_h = row_info["flip"]

	var anim_name := "%s_%s" % [animation_type, ROW_NAMES[row_info["row"]]]
	if not sprite_frames.has_animation(anim_name):
		return
	if animation != anim_name or not is_playing():
		play(anim_name)


func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")

	for animation_type in ANIMATION_TYPES:
		var path := SHEET_PATH_FORMAT % [identifier, animation_type]
		if not ResourceLoader.exists(path):
			continue
		var texture: Texture2D = load(path)
		var cols := int(texture.get_width() / FRAME_SIZE)
		var rows := int(texture.get_height() / FRAME_SIZE)

		if animation_type == "Rotate":
			# No directional rows -- a flat frame strip for character-select
			# / inventory previews, not tied to any movement key.
			_add_row_animation(frames, "Rotate", texture, 0, cols)
			continue

		for row in mini(rows, ROW_NAMES.size()):
			var anim_name := "%s_%s" % [animation_type, ROW_NAMES[row]]
			_add_row_animation(frames, anim_name, texture, row, cols)

	return frames


func _add_row_animation(frames: SpriteFrames, anim_name: String, texture: Texture2D, row: int, cols: int) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, 8.0)
	for col in cols:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(col * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
		frames.add_frame(anim_name, atlas)
