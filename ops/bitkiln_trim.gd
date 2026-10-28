@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnTrim
extends BitKilnOp
## Cuts away empty space around the sprite. On a sheet, every frame is trimmed by the
## same amount (to the smallest box that fits all of them), so frames stay aligned.

## Empty space to keep around the content.
@export_range(0, 64, 1, "or_greater", "suffix:px") var margin := 0
## Pixels with less alpha than this count as empty.
@export_range(0.0, 1.0, 0.01) var alpha_threshold := 0.01


func _apply(context: BitKilnContext) -> void:
	var size := context.frame_size
	var threshold := maxi(1, roundi(alpha_threshold * 255.0))
	var p := context.color.pixels
	var w := context.width
	var lo := size
	var hi := Vector2i(-1, -1)
	for y in context.height:
		var row := y * w
		var local_y := y % size.y
		for x in w:
			if (p[row + x] >> 24) & 0xFF >= threshold:
				var local_x := x % size.x
				lo = Vector2i(mini(lo.x, local_x), mini(lo.y, local_y))
				hi = Vector2i(maxi(hi.x, local_x), maxi(hi.y, local_y))
	if hi.x < 0:
		context.warn("Trim: the image is empty.")
		return
	var bounds := Rect2i(lo, hi - lo + Vector2i.ONE).grow(margin)
	context.remap_frames(bounds.size, -bounds.position)
