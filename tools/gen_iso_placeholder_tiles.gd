@tool
extends EditorScript

## One-shot placeholder art generator. Run from the editor
## (File > Run, with this script open) to (re)write:
##   assets/tiles/iso/iso_floor.png  — 64x32 diamond floor tile
##   assets/tiles/iso/iso_wall.png   — 64x80 iso cube (32px top + 48px body)
##
## Flat-colour stand-ins so the isometric room is buildable now. Replace with
## real pixel art later.

const TILE_W := 64
const TILE_H := 32
const WALL_EXTRUDE := 48

const FLOOR_FILL := Color("46506b")
const FLOOR_EDGE := Color("2e3547")
const WALL_TOP := Color("6a5a8a")
const WALL_LEFT := Color("4a3f66")
const WALL_RIGHT := Color("38304d")

const OUT_DIR := "res://assets/tiles/iso/"


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	_save(_make_floor(), OUT_DIR + "iso_floor.png")
	_save(_make_wall(), OUT_DIR + "iso_wall.png")
	print("gen_iso_placeholder_tiles: wrote iso_floor.png + iso_wall.png to ", OUT_DIR)
	var fs := EditorInterface.get_resource_filesystem()
	if fs:
		fs.scan()


## Diamond metric: 0 at centre, 1 on the edge.
static func _diamond(x: float, y: float) -> float:
	return absf(x - TILE_W * 0.5) / (TILE_W * 0.5) + absf(y - TILE_H * 0.5) / (TILE_H * 0.5)


func _make_floor() -> Image:
	var img := Image.create(TILE_W, TILE_H, false, Image.FORMAT_RGBA8)
	for y in TILE_H:
		for x in TILE_W:
			var d := _diamond(x + 0.5, y + 0.5)
			if d <= 1.0:
				img.set_pixel(x, y, FLOOR_EDGE if d > 0.86 else FLOOR_FILL)
	return img


func _make_wall() -> Image:
	var h := TILE_H + WALL_EXTRUDE
	var img := Image.create(TILE_W, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in TILE_W:
			var px := x + 0.5
			var py := y + 0.5
			# Top face: the diamond in the top TILE_H band.
			if py <= TILE_H and _diamond(px, py) <= 1.0:
				img.set_pixel(x, y, WALL_TOP)
				continue
			# Left face: below the diamond's lower-left edge (y = 16 + x*0.5).
			if px <= TILE_W * 0.5:
				var edge_l := TILE_H * 0.5 + px * 0.5
				if py >= edge_l and py <= edge_l + WALL_EXTRUDE:
					img.set_pixel(x, y, WALL_LEFT)
			# Right face: below the lower-right edge (y = 32 - (x-32)*0.5).
			else:
				var edge_r := TILE_H - (px - TILE_W * 0.5) * 0.5
				if py >= edge_r and py <= edge_r + WALL_EXTRUDE:
					img.set_pixel(x, y, WALL_RIGHT)
	return img


func _save(img: Image, path: String) -> void:
	var err := img.save_png(path)
	if err != OK:
		push_error("gen_iso_placeholder_tiles: could not write %s (err %d)" % [path, err])
