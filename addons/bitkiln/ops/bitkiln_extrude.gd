@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnExtrude
extends BitKilnOp
## Grows every frame by [member amount] pixels on each side, filled with copies of its
## edge pixels. For tiles and atlas frames: when the GPU samples slightly past a frame's
## edge (filtering, camera zoom, subpixel positions), it finds the same colors instead of
## a gap or the neighbouring frame. Set the TileSet's separation and margins to match.

## Pixels added on each side.
@export_range(1, 16, 1, "or_greater", "suffix:px") var amount := 1


func _apply(context: BitKilnContext) -> void:
	var size := context.frame_size
	var out_size := size + Vector2i(amount, amount) * 2
	for layer_name: StringName in context.layers:
		var src: BitKilnBuffer = context.layers[layer_name]
		var dst := BitKilnBuffer.create(out_size.x * context.frames.x, out_size.y * context.frames.y)
		var sp := src.pixels
		var dp := dst.pixels
		for fy in context.frames.y:
			for fx in context.frames.x:
				for y in out_size.y:
					var sy := fy * size.y + clampi(y - amount, 0, size.y - 1)
					for x in out_size.x:
						var sx := fx * size.x + clampi(x - amount, 0, size.x - 1)
						dp[(fy * out_size.y + y) * dst.width + fx * out_size.x + x] = sp[sy * src.width + sx]
		dst.pixels = dp
		context.layers[layer_name] = dst
	context.source_offset += Vector2(amount, amount)
