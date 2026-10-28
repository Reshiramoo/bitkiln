@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnRepack
extends BitKilnOp
## Rearranges frames into a new grid, or picks some of them: a 4×4 sheet into a 16-frame
## strip, a strip into rows of 8, or frames 5–8 of a sheet as their own animation. Frames
## are read and written row by row; leftover cells stay empty.

## Frames per row in the new grid; 0 = all in one row.
@export_range(0, 256, 1) var columns := 0
## The first frame to keep (counted row by row from 0).
@export_range(0, 1024, 1) var first := 0
## How many frames to keep from [member first]; 0 = all the rest.
@export_range(0, 1024, 1) var count := 0
## Leave out frames with no visible pixels.
@export var skip_empty := false


func _apply(context: BitKilnContext) -> void:
	var size := context.frame_size
	var total := context.frames.x * context.frames.y
	var picked := PackedInt32Array()
	var last := total if count <= 0 else mini(first + count, total)
	for index in range(first, last):
		if skip_empty and _is_empty(context, index):
			continue
		picked.append(index)
	if picked.is_empty():
		context.warn("Repack: no frames picked.")
		return
	var cols := picked.size() if columns <= 0 else mini(columns, picked.size())
	var grid := Vector2i(cols, ceili(float(picked.size()) / cols))
	for layer_name: StringName in context.layers:
		var src: BitKilnBuffer = context.layers[layer_name]
		var dst := BitKilnBuffer.create(size.x * grid.x, size.y * grid.y)
		var sp := src.pixels
		var dp := dst.pixels
		for k in picked.size():
			var from := Vector2i(picked[k] % context.frames.x, picked[k] / context.frames.x) * size
			var to := Vector2i(k % grid.x, k / grid.x) * size
			for y in size.y:
				var src_row := (from.y + y) * src.width + from.x
				var dst_row := (to.y + y) * dst.width + to.x
				for x in size.x:
					dp[dst_row + x] = sp[src_row + x]
		dst.pixels = dp
		context.layers[layer_name] = dst
	context.frames = grid


static func _is_empty(context: BitKilnContext, index: int) -> bool:
	var size := context.frame_size
	var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
	var p := context.color.pixels
	for y in size.y:
		var row := (origin.y + y) * context.width + origin.x
		for x in size.x:
			if p[row + x] != 0:
				return false
	return true
