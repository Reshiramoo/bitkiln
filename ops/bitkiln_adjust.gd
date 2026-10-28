@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnAdjust
extends BitKilnOp
## Shifts hue, saturation, brightness and contrast, and can tint toward a color. Every
## pixel of one color changes the same way, so the result has as many colors as the
## source. Combine with a mask to recolor one part.

## Rotates every hue, in degrees.
@export_range(-180.0, 180.0, 0.5, "suffix:°") var hue := 0.0
## -1 = grey, 0 = unchanged, 1 = twice as saturated.
@export_range(-1.0, 1.0, 0.01) var saturation := 0.0
## Added to brightness: -1 = black, 1 = white.
@export_range(-1.0, 1.0, 0.01) var value := 0.0
## -1 = flat grey, 0 = unchanged, 1 = twice the contrast (around mid grey).
@export_range(-1.0, 1.0, 0.01) var contrast := 0.0
## Mixed into every color by its alpha: white with alpha 0 changes nothing.
@export var tint := Color(1.0, 1.0, 1.0, 0.0)


func _apply(context: BitKilnContext) -> void:
	var p := context.color.pixels
	var cache := {}
	for i in p.size():
		var c := p[i]
		if c == 0:
			continue
		if not cache.has(c):
			cache[c] = adjust(c)
		p[i] = cache[c]
	context.color.pixels = p


## [param c] with this op's changes.
func adjust(c: int) -> int:
	var color := BitKilnBuffer.to_color(c)
	if contrast != 0.0:
		var k := 1.0 + contrast
		color.r = clampf((color.r - 0.5) * k + 0.5, 0.0, 1.0)
		color.g = clampf((color.g - 0.5) * k + 0.5, 0.0, 1.0)
		color.b = clampf((color.b - 0.5) * k + 0.5, 0.0, 1.0)
	if hue != 0.0 or saturation != 0.0 or value != 0.0:
		color = Color.from_hsv(wrapf(color.h + hue / 360.0, 0.0, 1.0), clampf(color.s * (1.0 + saturation), 0.0, 1.0),
			clampf(color.v + value, 0.0, 1.0), color.a)
	if tint.a > 0.0:
		var a := color.a
		color = color.lerp(tint, tint.a)
		color.a = a
	return BitKilnBuffer.from_color(color)
