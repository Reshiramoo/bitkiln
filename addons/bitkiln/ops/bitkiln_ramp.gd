@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnRamp
extends BitKilnOp
## Draws color ramps for building palettes: from each base color, darker shades that
## shift toward blue and lighter ones that shift toward yellow, the way pixel artists
## build ramps by hand ("hue shifting"). One ramp per row, one pixel per color. Use it on
## a recipe without a source, with a Palette output to save the result, or as the base
## palette for [BitKilnShade], [BitKilnQuantize] and [BitKilnRandomSprite].

## One ramp per color, each on its own row.
@export var base_colors := PackedColorArray([Color8(200, 60, 60), Color8(70, 140, 90), Color8(70, 100, 190)])
## Darker shades before each base color.
@export_range(0, 8, 1) var darker := 2
## Lighter shades after each base color.
@export_range(0, 8, 1) var lighter := 2
## Brightness change per shade (0–1).
@export_range(0.0, 0.5, 0.01) var value_step := 0.13
## Hue change per shade, in degrees: toward blue going darker, toward yellow going lighter.
@export_range(0.0, 60.0, 0.5, "suffix:°") var hue_shift := 12.0
## Saturation change per shade: darker shades get more saturated, lighter ones less.
@export_range(0.0, 0.5, 0.01) var saturation_shift := 0.06


func _apply(context: BitKilnContext) -> void:
	var length := darker + 1 + lighter
	if context.width < length or context.height < base_colors.size():
		context.warn("Ramp: the canvas needs at least %d×%d pixels for these ramps." % [length, base_colors.size()])
	var p := context.color.pixels
	for row in mini(base_colors.size(), context.height):
		var ramp := make_ramp(base_colors[row])
		for k in mini(ramp.size(), context.width):
			p[row * context.width + k] = BitKilnBuffer.from_color(ramp[k])
	context.color.pixels = p


## The ramp around [param base], darkest first.
func make_ramp(base: Color) -> PackedColorArray:
	var ramp := PackedColorArray()
	for k in range(-darker, lighter + 1):
		ramp.append(shade(base, k))
	return ramp


## [param base] moved [param steps] shades lighter (positive) or darker (negative).
func shade(base: Color, steps: int) -> Color:
	if steps == 0:
		return base
	var k := absf(steps)
	var target := 60.0 / 360.0 if steps > 0 else 240.0 / 360.0
	var diff := wrapf(target - base.h, -0.5, 0.5)
	var hue := wrapf(base.h + signf(diff) * minf(absf(diff), hue_shift / 360.0 * k), 0.0, 1.0)
	var saturation := clampf(base.s + (saturation_shift * k if steps < 0 else -saturation_shift * k), 0.0, 1.0)
	if base.s < 0.01:
		hue = base.h
		saturation = base.s
	return Color.from_hsv(hue, saturation, clampf(base.v + value_step * steps, 0.0, 1.0), base.a)
