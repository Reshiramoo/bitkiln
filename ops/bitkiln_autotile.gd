@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnAutotile
extends BitKilnOp
## Builds a full 47-tile "blob" tile set from five hand-drawn tiles, so a terrain (grass,
## water, walls) paints with every edge and corner right. Add a TileSet output to get a
## Godot TileSet with the terrain already set up for the TileMap terrain tools.
##
## The source is five tiles in a row (set [member BitKilnRecipe.frames] to 5×1), each
## drawn in one style all around:
## 1. [b]Island[/b]: a tile with nothing around it, outer corners on all four sides.
## 2. [b]Column[/b]: connected above and below, so its left and right edges show.
## 3. [b]Row[/b]: connected left and right, so its top and bottom edges show.
## 4. [b]Cross[/b]: connected on all four sides but not diagonally: inner corners.
## 5. [b]Fill[/b]: the middle of the terrain.
## Every output tile is put together from quarters of these, so tiles need an even size.

## Tiles per row in the output (47 tiles plus one empty cell).
@export_range(1, 48, 1) var columns := 8

## Neighbour bits: N, NE, E, SE, S, SW, W, NW.
const N := 1
const NE := 2
const E := 4
const SE := 8
const S := 16
const SW := 32
const W := 64
const NW := 128

enum Piece { ISLAND, COLUMN, ROW, CROSS, FILL }


func _apply(context: BitKilnContext) -> void:
	var size := context.frame_size
	if context.frames.x * context.frames.y < 5:
		context.warn("Autotile: the source needs five tiles (island, column, row, cross, fill); set Frames to 5×1.")
		return
	if size.x % 2 != 0 or size.y % 2 != 0:
		context.warn("Autotile: tiles need an even width and height, to be split into quarters.")
		return
	var masks := blob_masks()
	var rows := ceili(float(masks.size()) / columns)
	var half := size / 2
	for layer_name: StringName in context.layers:
		var src: BitKilnBuffer = context.layers[layer_name]
		var dst := BitKilnBuffer.create(size.x * columns, size.y * rows)
		var sp := src.pixels
		var dp := dst.pixels
		for k in masks.size():
			var cell := Vector2i(k % columns, k / columns) * size
			for quarter in 4:
				var piece := quarter_piece(masks[k], quarter)
				var piece_origin := Vector2i(piece % context.frames.x, piece / context.frames.x) * size
				var q := Vector2i(quarter % 2, quarter / 2) * half
				for y in half.y:
					var src_row := (piece_origin.y + q.y + y) * src.width + piece_origin.x + q.x
					var dst_row := (cell.y + q.y + y) * dst.width + cell.x + q.x
					for x in half.x:
						dp[dst_row + x] = sp[src_row + x]
		dst.pixels = dp
		context.layers[layer_name] = dst
	context.frames = Vector2i(columns, rows)
	var per_cell := PackedInt32Array()
	per_cell.resize(columns * rows)
	per_cell.fill(-1)
	for k in masks.size():
		per_cell[k] = masks[k]
	context.meta["autotile_masks"] = per_cell
	context.reset_source_mapping()


## The 47 neighbour combinations that look different: a corner only counts when both
## sides next to it are connected. Sorted, so the layout never changes.
static func blob_masks() -> PackedInt32Array:
	var seen := {}
	for m in 256:
		seen[normalize(m)] = true
	var result := PackedInt32Array(seen.keys())
	result.sort()
	return result


## [param mask] without corners whose two neighbouring sides aren't both connected.
static func normalize(mask: int) -> int:
	var m := mask
	if not (m & N and m & E):
		m &= ~NE
	if not (m & S and m & E):
		m &= ~SE
	if not (m & S and m & W):
		m &= ~SW
	if not (m & N and m & W):
		m &= ~NW
	return m


## Which template tile quarter number [param quarter] (0 top-left, 1 top-right,
## 2 bottom-left, 3 bottom-right) comes from, for a tile with neighbours [param mask].
static func quarter_piece(mask: int, quarter: int) -> Piece:
	var vertical := N if quarter < 2 else S
	var horizontal := W if quarter % 2 == 0 else E
	var diagonal: int = [NW, NE, SW, SE][quarter]
	var v := mask & vertical != 0
	var h := mask & horizontal != 0
	if not v and not h:
		return Piece.ISLAND
	if v and not h:
		return Piece.COLUMN
	if h and not v:
		return Piece.ROW
	return Piece.FILL if mask & diagonal else Piece.CROSS
