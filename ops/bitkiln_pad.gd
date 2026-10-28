@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnPad
extends BitKilnOp
## Adds transparent space around every frame, so outlines, shadows and glows that come
## after it have room and aren't cut off at the frame's edge.

## Pixels added on the left of every frame.
@export_range(0, 64, 1, "or_greater", "suffix:px") var left := 1
## Pixels added at the top of every frame.
@export_range(0, 64, 1, "or_greater", "suffix:px") var top := 1
## Pixels added on the right of every frame.
@export_range(0, 64, 1, "or_greater", "suffix:px") var right := 1
## Pixels added at the bottom of every frame.
@export_range(0, 64, 1, "or_greater", "suffix:px") var bottom := 1


func _apply(context: BitKilnContext) -> void:
	var size := context.frame_size + Vector2i(left + right, top + bottom)
	context.remap_frames(size, Vector2i(left, top))
