extends Node2D

## Q-toggled spreadsheet-style grid overlay (column letters, row numbers) for
## eyeballing world coordinates when placing things.
##
## Draws a fixed, generous world-space range once when toggled on rather than
## recomputing "what's visible" from the camera every frame -- that camera-
## tracking approach turned out to only ever reflect a ~zoom-1.0-sized patch
## regardless of actual zoom, leaving everything past it blank at any real
## zoom-out level. Since the range here is just plain world coordinates,
## normal camera rendering scales/positions it correctly no matter the zoom.

const GRID_HALF_WIDTH := 20
const GRID_HALF_HEIGHT := 15

@onready var _vignette: CanvasItem = get_node_or_null("../Atmosphere/Vignette")


func _ready() -> void:
	visible = false
	DevTools.toggled.connect(_on_devtools_toggled)


func _on_devtools_toggled(is_enabled: bool) -> void:
	visible = is_enabled
	# The night vignette darkens screen edges enough to hide the grid there
	# (worse the more zoomed out you are) -- devtools mode doesn't need it.
	if _vignette:
		_vignette.visible = not is_enabled
	if is_enabled:
		queue_redraw()


func _draw() -> void:
	var tile_size := GridRef.TILE_SIZE
	var font := ThemeDB.fallback_font
	var font_size := 10
	var line_color := Color(1, 1, 1, 0.15)
	var label_color := Color(1, 1, 0.4, 0.9)

	for cy in range(-GRID_HALF_HEIGHT, GRID_HALF_HEIGHT + 1):
		for cx in range(-GRID_HALF_WIDTH, GRID_HALF_WIDTH + 1):
			var cell_pos := Vector2(cx, cy) * tile_size
			draw_rect(Rect2(cell_pos, Vector2(tile_size, tile_size)), line_color, false, 1.0)
			var label := GridRef.cell_to_label(cx, cy)
			draw_string(font, cell_pos + Vector2(2, 12), label, HORIZONTAL_ALIGNMENT_LEFT, tile_size - 4, font_size, label_color)
