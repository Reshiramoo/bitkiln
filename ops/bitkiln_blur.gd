@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnBlur
extends BitKilnOp
## Blurs the image, frame by frame: soft shadows, smear frames for fast motion, hazy
## backgrounds. [member alpha_steps] snaps the soft edges back to a few levels of
## transparency (optionally dithered), so the result still looks like pixel art; follow
## it with a [BitKilnQuantize] to bring the colors back into your palette too.

enum Kind {
	BOX, ## Every pixel within [member radius] counts the same.
	GAUSSIAN, ## Nearer pixels count more: the softest look.
	MOTION, ## Smeared behind [member direction], as if moving fast.
}

## How the blur spreads.
@export var kind := Kind.GAUSSIAN
## How far the blur reaches, in pixels (the length of the smear for Motion).
@export_range(1, 32, 1, "or_greater", "suffix:px") var radius := 2
## For Motion: the direction of movement; the smear trails behind it.
@export var direction := Vector2(1.0, 0.0)
## Levels of transparency the soft edges snap to; 0 keeps them smooth.
@export_range(0, 16, 1) var alpha_steps := 3
## Pick between two levels with an ordered (Bayer) pattern instead of rounding.
@export var dither := false


func _apply(context: BitKilnContext) -> void:
	var w := context.width
	var h := context.height
	var planes := BitKilnFilter.to_planes(context.color)
	if kind == Kind.MOTION:
		if direction == Vector2.ZERO:
			return
		planes = BitKilnFilter.smear(planes, w, h, context.frame_size, direction, radius)
	else:
		var weights := BitKilnFilter.kernel(BitKilnFilter.Kernel.BOX if kind == Kind.BOX else BitKilnFilter.Kernel.GAUSSIAN,
			radius)
		planes = BitKilnFilter.blur(planes, w, h, context.frame_size, weights)
	BitKilnFilter.step_planes(planes, w, h, alpha_steps, dither)
	context.color = BitKilnFilter.from_planes(planes, w, h)
