extends Node

## Shared spreadsheet-style grid reference system (column letters, row
## numbers) — lets gameplay/devtools code refer to world positions the same
## way you'd eyeball them on the devtools grid overlay (e.g. "K24"), instead
## of raw pixels. Column A / row 1 is treated as the origin cell.

const TILE_SIZE := 64.0
const COL_OFFSET := 0  # engine cell x -> 1-based spreadsheet column index
const ROW_OFFSET := 0  # engine cell y -> spreadsheet row number


func cell_to_label(cx: int, cy: int) -> String:
	return _column_letters(cx + COL_OFFSET) + str(cy + ROW_OFFSET)


## Parses a ref like "K24" or "AB30" into engine cell coordinates.
func ref_to_cell(ref: String) -> Vector2i:
	var col_str := ""
	var row_str := ""
	for c in ref:
		if c.is_valid_int():
			row_str += c
		else:
			col_str += c

	var col_num := 0
	for c in col_str.to_upper():
		col_num = col_num * 26 + (c.unicode_at(0) - 64)

	return Vector2i(col_num - COL_OFFSET, row_str.to_int() - ROW_OFFSET)


func ref_to_world(ref: String) -> Vector2:
	return Vector2(ref_to_cell(ref)) * TILE_SIZE


## World-space rect spanning both named cells (order doesn't matter).
func rect_from_refs(from_ref: String, to_ref: String) -> Rect2:
	var a := ref_to_cell(from_ref)
	var b := ref_to_cell(to_ref)
	var min_cell := Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var max_cell := Vector2i(maxi(a.x, b.x), maxi(a.y, b.y))
	var top_left := Vector2(min_cell) * TILE_SIZE
	var bottom_right := Vector2(max_cell + Vector2i.ONE) * TILE_SIZE
	return Rect2(top_left, bottom_right - top_left)


## Excel-style bijective base-26 column naming (1 -> "A", 26 -> "Z", 27 -> "AA"...).
func _column_letters(n: int) -> String:
	var s := ""
	while n > 0:
		var rem := (n - 1) % 26
		s = char(65 + rem) + s
		n = (n - 1) / 26
	return s
