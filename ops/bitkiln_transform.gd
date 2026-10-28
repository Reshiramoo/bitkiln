@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnTransform
extends BitKilnOp
## Flips and turns every frame by quarter turns, without changing any pixel. Normal maps
## turn with the colors, so lighting stays right. Quarter turns of non-square frames swap
## the frame's width and height.

enum Turn {
	NONE, ## No turn.
	CLOCKWISE, ## A quarter turn clockwise.
	HALF, ## Half a turn.
	COUNTERCLOCKWISE, ## A quarter turn counterclockwise.
}

## Mirror left to right (before turning).
@export var flip_h := false
## Mirror top to bottom (before turning).
@export var flip_v := false
@export var turn := Turn.NONE


func _apply(context: BitKilnContext) -> void:
	if not flip_h and not flip_v and turn == Turn.NONE:
		return
	var size := context.frame_size
	var out_size := Vector2i(size.y, size.x) if turn == Turn.CLOCKWISE or turn == Turn.COUNTERCLOCKWISE else size
	for layer_name: StringName in context.layers:
		var src: BitKilnBuffer = context.layers[layer_name]
		var dst := BitKilnBuffer.create(out_size.x * context.frames.x, out_size.y * context.frames.y)
		var sp := src.pixels
		var dp := dst.pixels
		var is_normal := layer_name == BitKilnContext.NORMAL
		for fy in context.frames.y:
			for fx in context.frames.x:
				for y in out_size.y:
					for x in out_size.x:
						var s := source_of(Vector2i(x, y), size)
						var c := sp[(fy * size.y + s.y) * src.width + fx * size.x + s.x]
						if is_normal and c != 0:
							c = turn_normal(c)
						dp[(fy * out_size.y + y) * dst.width + fx * out_size.x + x] = c
		dst.pixels = dp
		context.layers[layer_name] = dst
	context.reset_source_mapping()


## The pixel of a [param size] frame that lands at [param dest] after the flips and turn.
func source_of(dest: Vector2i, size: Vector2i) -> Vector2i:
	var s := dest
	match turn:
		Turn.CLOCKWISE:
			s = Vector2i(dest.y, size.y - 1 - dest.x)
		Turn.HALF:
			s = Vector2i(size.x - 1 - dest.x, size.y - 1 - dest.y)
		Turn.COUNTERCLOCKWISE:
			s = Vector2i(size.x - 1 - dest.y, dest.x)
	if flip_h:
		s.x = size.x - 1 - s.x
	if flip_v:
		s.y = size.y - 1 - s.y
	return s


## A normal map pixel flipped and turned the same way as the image.
func turn_normal(c: int) -> int:
	var x := (c & 0xFF) - 128
	var y := ((c >> 8) & 0xFF) - 128 # up is positive
	if flip_h:
		x = -x
	if flip_v:
		y = -y
	for i in int(turn):
		var t := x
		x = y
		y = -t
	return BitKilnBuffer.pack(x + 128, y + 128, (c >> 16) & 0xFF, (c >> 24) & 0xFF)
