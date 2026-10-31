@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnReduce
extends BitKilnOp
## Reduces the image to at most [member colors] colors, picking them from the image
## itself (median cut, weighted by how many pixels use each color). Good for cleaning up
## painted or scaled art into a pixel-art palette; add a Palette output to save the
## colors it picked.

## Most colors to keep, across all frames.
@export_range(2, 256, 1) var colors := 16
## Make every pixel fully opaque or fully transparent.
@export var hard_alpha := true
## With [member hard_alpha]: pixels with at least this alpha become opaque.
@export_range(0.01, 1.0, 0.01) var alpha_threshold := 0.5


func _apply(context: BitKilnContext) -> void:
	var p := context.color.pixels
	var threshold := roundi(alpha_threshold * 255.0)
	var counts := {}
	for i in p.size():
		var c := p[i]
		if c == 0:
			continue
		if hard_alpha:
			if (c >> 24) & 0xFF < threshold:
				p[i] = 0
				continue
			c = BitKilnBuffer.with_alpha(c, 255)
			p[i] = c
		var opaque := BitKilnBuffer.with_alpha(c, 255)
		counts[opaque] = counts.get(opaque, 0) + 1
	if counts.size() > colors:
		var palette := median_cut(counts, colors)
		var cache := {}
		for i in p.size():
			var c := p[i]
			if c == 0:
				continue
			if not cache.has(c):
				var nearest := palette[BitKilnPalette.nearest(BitKilnBuffer.with_alpha(c, 255), palette)]
				cache[c] = BitKilnBuffer.with_alpha(nearest, (c >> 24) & 0xFF)
			p[i] = cache[c]
	context.color.pixels = p


## Up to [param count] colors that represent [param counts] (opaque color -> pixel count).
static func median_cut(counts: Dictionary, count: int) -> PackedInt32Array:
	var boxes: Array[Array] = [counts.keys()]
	while boxes.size() < count:
		# Split the box whose widest channel spans the most.
		var best := -1
		var best_range := 0
		var best_channel := 0
		for b in boxes.size():
			if boxes[b].size() < 2:
				continue
			for channel in 3:
				var lo := 255
				var hi := 0
				for c: int in boxes[b]:
					var v := (c >> (channel * 8)) & 0xFF
					lo = mini(lo, v)
					hi = maxi(hi, v)
				if hi - lo > best_range:
					best_range = hi - lo
					best = b
					best_channel = channel
		if best < 0:
			break
		var box: Array = boxes[best]
		var shift := best_channel * 8
		box.sort_custom(func(a: int, b: int) -> bool: return (a >> shift) & 0xFF < (b >> shift) & 0xFF)
		# Weighted median: half the pixels on each side.
		var total := 0
		for c: int in box:
			total += counts[c]
		var running := 0
		var split := 1
		for k in box.size() - 1:
			running += counts[box[k]]
			split = k + 1
			if running * 2 >= total:
				break
		boxes[best] = box.slice(0, split)
		boxes.append(box.slice(split))
	var palette := PackedInt32Array()
	for box in boxes:
		var r := 0
		var g := 0
		var b := 0
		var n := 0
		for c: int in box:
			var k: int = counts[c]
			r += (c & 0xFF) * k
			g += ((c >> 8) & 0xFF) * k
			b += ((c >> 16) & 0xFF) * k
			n += k
		palette.append(BitKilnBuffer.pack(roundi(float(r) / n), roundi(float(g) / n), roundi(float(b) / n), 255))
	return palette
