@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnGlow
extends BitKilnOp
## A halo around the sprite, or around just its bright pixels (eyes, gems, flames, magic).
## The glow fades out over [member radius] pixels in a few crisp rings of decreasing
## opacity (optionally dithered), the way pixel artists draw halos, instead of a smooth
## blur. Put a [BitKilnPad] before it so the halo has room inside the frame.

enum Source {
	SILHOUETTE, ## The whole sprite glows.
	BRIGHT, ## Only pixels at least [member brightness_threshold] bright glow.
}
enum Blend {
	BEHIND, ## The glow sits behind the sprite, like a halo.
	ADD, ## The glow also lightens the sprite itself, like light spilling over it.
}

@export var source := Source.SILHOUETTE
## For Bright: how bright (0–1) a pixel must be to glow.
@export_range(0.0, 1.0, 0.01) var brightness_threshold := 0.8
## Glow color; its alpha scales the glow's opacity. With [member use_sprite_colors], it
## tints the glowing pixels' own colors instead.
@export var color := Color(1.0, 0.85, 0.4, 1.0)
## Each glowing pixel glows in its own color (multiplied by [member color]).
@export var use_sprite_colors := false
## How far the glow reaches, in pixels.
@export_range(1, 32, 1, "or_greater", "suffix:px") var radius := 3
## Opacity next to the glowing pixels; it fades to nothing at [member radius]. Above 1
## makes the inner rings solid.
@export_range(0.0, 4.0, 0.05, "or_greater") var intensity := 1.0
## How the opacity fades from the glowing pixels (0) to [member radius] (1). Empty = linear.
@export var falloff: Curve
## Opacity levels the glow snaps to; 0 keeps it smooth.
@export_range(0, 8, 1) var rings := 3
## Pick between two rings with an ordered (Bayer) pattern instead of rounding.
@export var dither := false
@export var blend := Blend.BEHIND


func _apply(context: BitKilnContext) -> void:
	var w := context.width
	var h := context.height
	var sp := context.color.pixels
	var glowing := PackedByteArray()
	glowing.resize(w * h)
	var any := false
	for i in sp.size():
		var c := sp[i]
		if (c >> 24) & 0xFF < 128:
			continue
		if source == Source.BRIGHT:
			var luma := ((c & 0xFF) * 0.299 + ((c >> 8) & 0xFF) * 0.587 + ((c >> 16) & 0xFF) * 0.114) / 255.0
			if luma < brightness_threshold:
				continue
		glowing[i] = 1
		any = true
	if not any:
		return
	var found := BitKilnFilter.nearest_sources(glowing, w, h, context.frame_size)
	var distances: PackedFloat32Array = found[0]
	var nearest: PackedInt32Array = found[1]
	var tint := BitKilnBuffer.from_color(color)
	var limit := radius + 0.25
	var rp := sp.duplicate()
	for y in h:
		for x in w:
			var i := y * w + x
			var d := distances[i]
			if d == 0.0 or d > limit:
				continue
			var t := clampf((d - 1.0) / radius, 0.0, 1.0)
			var fade := falloff.sample_baked(t) if falloff != null else 1.0 - t
			var alpha := BitKilnFilter.step_alpha(clampf(fade * intensity * color.a, 0.0, 1.0), rings, dither, x, y)
			if alpha <= 0.0:
				continue
			var g := tint
			if use_sprite_colors:
				var s := sp[nearest[i]]
				g = BitKilnBuffer.pack((s & 0xFF) * (tint & 0xFF) / 255, ((s >> 8) & 0xFF) * ((tint >> 8) & 0xFF) / 255,
					((s >> 16) & 0xFF) * ((tint >> 16) & 0xFF) / 255, 255)
			var c := sp[i]
			if blend == Blend.ADD and c != 0:
				rp[i] = BitKilnBuffer.pack((c & 0xFF) + roundi((g & 0xFF) * alpha),
					((c >> 8) & 0xFF) + roundi(((g >> 8) & 0xFF) * alpha),
					((c >> 16) & 0xFF) + roundi(((g >> 16) & 0xFF) * alpha), (c >> 24) & 0xFF)
			else:
				rp[i] = BitKilnBuffer.blend(c, BitKilnBuffer.with_alpha(g, roundi(alpha * 255.0)))
	context.color.pixels = rp
