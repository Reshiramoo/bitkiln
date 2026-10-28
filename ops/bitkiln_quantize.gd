@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnQuantize
extends BitKilnOp
## Snaps every color to the nearest color of a palette, optionally with ordered
## (Bayer) dithering. Good for cleaning up art that was painted or scaled with soft
## brushes, and for keeping effects like glows inside your game's palette.

enum Dither {
	NONE, ## Each pixel takes its nearest palette color.
	BAYER_2, ## 2×2 pattern: coarse checkerboard.
	BAYER_4, ## 4×4 pattern.
	BAYER_8, ## 8×8 pattern: the finest gradients.
}

## Every distinct color in this image is a palette color (any size; a Lospec palette
## imported by BitKiln works). Transparent pixels are ignored.
@export var palette: Texture2D
## Ordered dithering pattern, for gradients that would otherwise band.
@export var dither := Dither.NONE
## How far dithering may push a color before snapping it.
@export_range(0.0, 1.0, 0.01) var dither_strength := 0.5
## Make every pixel fully opaque or fully transparent, as most pixel art is.
@export var hard_alpha := true
## With [member hard_alpha]: pixels with at least this alpha become opaque.
@export_range(0.01, 1.0, 0.01) var alpha_threshold := 0.5


func _apply(context: BitKilnContext) -> void:
	var colors := BitKilnPalette.load_colors(palette)
	if colors.is_empty():
		context.warn("Quantize: no palette colors.")
		return
	# Compare opaque colors: alpha is handled separately.
	for i in colors.size():
		colors[i] = BitKilnBuffer.with_alpha(colors[i], 255)
	var matrix := bayer_matrix(1 << dither) if dither != Dither.NONE else PackedFloat32Array()
	var n := 1 << dither
	var spread := dither_strength * 64.0
	var threshold := roundi(alpha_threshold * 255.0)
	var buffer := context.color
	var p := buffer.pixels
	var w := buffer.width
	var cache := {}
	for y in buffer.height:
		for x in w:
			var i := y * w + x
			var c := p[i]
			if c == 0:
				continue
			var a := (c >> 24) & 0xFF
			if hard_alpha:
				if a < threshold:
					p[i] = 0
					continue
				a = 255
			var shift := 0
			var key := c
			if n > 1:
				var t := matrix[(y % n) * n + x % n]
				shift = roundi((t - 0.5) * spread)
				key = c * 256 + (y % n) * n + x % n
			if not cache.has(key):
				var shifted := BitKilnBuffer.pack((c & 0xFF) + shift, ((c >> 8) & 0xFF) + shift,
					((c >> 16) & 0xFF) + shift, 255)
				cache[key] = colors[BitKilnPalette.nearest(shifted, colors)]
			p[i] = BitKilnBuffer.with_alpha(cache[key], a)
	buffer.pixels = p


## Thresholds 0–1 of an [param n]×[param n] Bayer matrix (n a power of two), row by row.
static func bayer_matrix(n: int) -> PackedFloat32Array:
	var m := PackedInt32Array([0])
	var size := 1
	while size < n:
		var next := PackedInt32Array()
		next.resize(size * size * 4)
		for y in size:
			for x in size:
				var v := m[y * size + x] * 4
				next[y * size * 2 + x] = v
				next[y * size * 2 + x + size] = v + 2
				next[(y + size) * size * 2 + x] = v + 3
				next[(y + size) * size * 2 + x + size] = v + 1
		m = next
		size *= 2
	var result := PackedFloat32Array()
	result.resize(m.size())
	for i in m.size():
		result[i] = (m[i] + 0.5) / float(m.size())
	return result
