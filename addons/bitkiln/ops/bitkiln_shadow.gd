@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnShadow
extends BitKilnOp
## A hard drop shadow: the sprite's silhouette, moved by [member offset], behind it.
## With [member length] above 1 it repeats along the offset into a long shadow.
## Put a [BitKilnPad] before it so the shadow has room inside the frame.

## Where the shadow falls, in pixels: (1, 1) is down and to the right.
@export var offset := Vector2i(1, 1)
## Shadow color; its alpha is the shadow's opacity.
@export var color := Color(0.0, 0.0, 0.0, 0.5)
## Steps of [member offset]: 1 = drop shadow, more = long shadow.
@export_range(1, 64, 1, "or_greater") var length := 1
## Pixels with at least this alpha cast a shadow.
@export_range(0.01, 1.0, 0.01) var alpha_threshold := 0.5


func _apply(context: BitKilnContext) -> void:
	if offset == Vector2i.ZERO:
		return
	var src := context.color
	var sp := src.pixels
	var dp := sp.duplicate()
	var w := src.width
	var size := context.frame_size
	var threshold := roundi(alpha_threshold * 255.0)
	var shadow := BitKilnBuffer.from_color(color)
	for y in src.height:
		var fy0 := (y / size.y) * size.y
		for x in w:
			if (sp[y * w + x] >> 24) & 0xFF < threshold:
				continue
			var fx0 := (x / size.x) * size.x
			for step in range(1, length + 1):
				var tx := x + offset.x * step
				var ty := y + offset.y * step
				if tx < fx0 or ty < fy0 or tx >= fx0 + size.x or ty >= fy0 + size.y:
					break
				var t := ty * w + tx
				if (sp[t] >> 24) & 0xFF < threshold:
					dp[t] = BitKilnBuffer.blend(sp[t], shadow)
	src.pixels = dp
