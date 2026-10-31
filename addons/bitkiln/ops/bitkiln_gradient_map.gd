@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnGradientMap
extends BitKilnOp
## Recolors by brightness: dark pixels take the gradient's left colors, bright ones its
## right colors. Turns greyscale art into any color scheme, or remaps a sprite onto a
## ramp. With a Constant gradient (or [member steps]), only the gradient's colors appear.

## Colors from darkest (offset 0) to brightest (offset 1). Set its interpolation to
## Constant for hard bands of exactly its colors.
@export var gradient: Gradient
## Brightness levels to snap to before looking up the gradient; 0 = smooth.
@export_range(0, 32, 1) var steps := 0
## Stretch the brightness range of the image to the whole gradient, so its darkest pixel
## gets the first color and its brightest the last.
@export var normalize := true


func _apply(context: BitKilnContext) -> void:
	if gradient == null:
		context.warn("Gradient Map: no gradient.")
		return
	var p := context.color.pixels
	var lo := 1.0
	var hi := 0.0
	if normalize:
		for c in p:
			if c != 0:
				var l := luminance(c)
				lo = minf(lo, l)
				hi = maxf(hi, l)
	var cache := {}
	for i in p.size():
		var c := p[i]
		if c == 0:
			continue
		if not cache.has(c):
			var l := luminance(c)
			if normalize:
				l = (l - lo) / (hi - lo) if hi > lo else 0.5
			if steps > 0:
				l = (floorf(l * steps * 0.9999) + 0.5) / steps
			var mapped := gradient.sample(l)
			mapped.a = ((c >> 24) & 0xFF) / 255.0
			cache[c] = BitKilnBuffer.from_color(mapped)
		p[i] = cache[c]
	context.color.pixels = p


## Perceived brightness of [param c], 0–1.
static func luminance(c: int) -> float:
	return ((c & 0xFF) * 0.299 + ((c >> 8) & 0xFF) * 0.587 + ((c >> 16) & 0xFF) * 0.114) / 255.0
