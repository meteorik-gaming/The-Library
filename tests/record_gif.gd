extends Node
## Records a short animated GIF of any scene in motion — for bugs a static
## screenshot can't catch (the NPC-shrinks-while-patrolling bug that led to
## this tool is a perfect example: the very first frame looked correct).
## Needs ffmpeg on PATH; frames + the assembled GIF land in this project's
## user:// data dir (printed on completion).
##
##   <godot> res://tests/record_gif.tscn -- <scene_path> [seconds] [fps]
##   (windowed; renders)
##
## e.g. godot --path . res://tests/record_gif.tscn -- res://scenes/worlds/isometric_world/isometric_world.tscn 1.5 12

const DEFAULT_SECONDS := 1.5
const DEFAULT_FPS := 12.0
const FRAMES_DIR := "user://gif_frames"
const OUTPUT_PATH := "user://recording.gif"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("record_gif: pass a scene path after --, e.g. -- res://scenes/worlds/isometric_world/isometric_world.tscn [seconds] [fps]")
		get_tree().quit(1)
		return

	var scene_path: String = args[0]
	var seconds: float = float(args[1]) if args.size() > 1 else DEFAULT_SECONDS
	var fps: float = float(args[2]) if args.size() > 2 else DEFAULT_FPS

	var target: Node = load(scene_path).instantiate()
	add_child(target)
	await get_tree().process_frame

	_clear_frames_dir()
	var frame_count := int(seconds * fps)
	for i in frame_count:
		await get_tree().create_timer(1.0 / fps).timeout
		get_viewport().get_texture().get_image().save_png("%s/frame_%03d.png" % [FRAMES_DIR, i])
		print("captured frame %d/%d" % [i + 1, frame_count])

	_assemble_gif(fps)


func _clear_frames_dir() -> void:
	DirAccess.make_dir_recursive_absolute(FRAMES_DIR)
	var dir := DirAccess.open(FRAMES_DIR)
	if dir:
		for file_name in dir.get_files():
			dir.remove(file_name)


## Two-pass ffmpeg encode (palettegen + paletteuse) for a GIF that isn't
## muddy -- a naive single-pass GIF encode looks noticeably worse.
func _assemble_gif(fps: float) -> void:
	var frames_dir := ProjectSettings.globalize_path(FRAMES_DIR)
	var output := ProjectSettings.globalize_path(OUTPUT_PATH)
	var palette := frames_dir.path_join("palette.png")
	var input_pattern := frames_dir.path_join("frame_%03d.png")

	var gen_output := []
	var gen_code := OS.execute("ffmpeg", [
		"-y", "-framerate", str(fps), "-i", input_pattern,
		"-vf", "palettegen=stats_mode=diff", palette,
	], gen_output, true)

	var gif_output := []
	var gif_code := OS.execute("ffmpeg", [
		"-y", "-framerate", str(fps), "-i", input_pattern,
		"-i", palette,
		"-lavfi", "paletteuse=dither=bayer",
		output,
	], gif_output, true)

	if gen_code == 0 and gif_code == 0:
		print("\nsaved GIF: ", output)
	else:
		push_error("ffmpeg failed (palettegen exit=%d, paletteuse exit=%d) -- frames are still in %s" % [gen_code, gif_code, frames_dir])
		print("--- palettegen output ---\n", "\n".join(gen_output))
		print("--- paletteuse output ---\n", "\n".join(gif_output))

	get_tree().quit()
