@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnShade
extends BitKilnOp
## Shades flat colors the way pixel artists do: a few lighter bands on the side facing the
## light and darker ones away from it, with hues shifting warm in the light and cool in
## the shadow ("hue shifting") instead of only getting lighter or darker.
##
## The shape comes from the normal layer of a [BitKilnNormalMap] before this op (whose
## snapping also decides how the bands fall), or from a smooth rounded one made just for
## shading. Shade before outlining, or the outline gets shaded too. A rim light can add a
## thin edge of light on the side opposite the light.

## Where the light comes from, as (x right, y down, z toward the viewer): (-1, -1, 1) is
## from the top left, in front.
@export var light_direction := Vector3(-1.0, -1.0, 1.0)
## Lighter bands on the lit side.
@export_range(0, 6, 1) var light_steps := 1
## Darker bands on the shadow side.
@export_range(0, 6, 1) var shadow_steps := 2
## How much of the surface keeps its own color, between the lit and shadow bands (0–1).
@export_range(0.0, 0.95, 0.01) var base_band := 0.35
## Brightness change per band (0–1).
@export_range(0.0, 0.5, 0.01) var value_step := 0.12
## Hue change per band, in degrees: toward yellow in the light, toward blue in the shadow.
@export_range(0.0, 60.0, 0.5, "suffix:°") var hue_shift := 10.0
## Saturation change per band: lights get less saturated, shadows more.
@export_range(0.0, 0.5, 0.01) var saturation_shift := 0.05
## When set, every shade snaps to the nearest color of this palette, so shading stays
## inside your game's colors.
@export var palette: Texture2D

@export_group("Rim Light")
## Color of the rim light; alpha 0 turns it off.
@export var rim_color := Color(1.0, 1.0, 1.0, 0.0)
## Which edges get the rim, as (x right, y down): (1, 0) is the right side. Usually
## opposite the light.
@export var rim_direction := Vector2(1.0, 1.0)
@export_group("")

## Pixels with at least this alpha count as part of the sprite.
@export_range(0.01, 1.0, 0.01) var alpha_threshold := 0.5


func _apply(context: BitKilnContext) -> void:
	var normal := context.get_layer(BitKilnContext.NORMAL)
	if normal == null:
		normal = _smooth_normals(context)
	var w := context.width
	var h := context.height
	var size := context.frame_size
	var threshold := roundi(alpha_threshold * 255.0)
	# Normals are stored green-up; the light is given y-down.
	var light := Vector3(light_direction.x, -light_direction.y, light_direction.z).normalized()
	var flat := light.z # how lit a surface facing the viewer is
	var colors := BitKilnPalette.load_colors(palette) if palette != null else PackedInt32Array()
	var rim := BitKilnBuffer.from_color(rim_color)
	var rim_dir := Vector2(rim_direction.x, -rim_direction.y).normalized()
	var cp := context.color.pixels
	var np := normal.pixels
	# How much more (or less) lit than a surface facing the viewer each pixel is.
	var amounts := PackedFloat32Array()
	amounts.resize(w * h)
	var brightest := 0.0
	var darkest := 0.0
	for i in w * h:
		if (cp[i] >> 24) & 0xFF < threshold:
			continue
		var nc := np[i]
		var n := Vector3(0.0, 0.0, 1.0) if nc == 0 else \
			Vector3((nc & 0xFF) / 127.5 - 1.0, ((nc >> 8) & 0xFF) / 127.5 - 1.0, ((nc >> 16) & 0xFF) / 127.5 - 1.0).normalized()
		amounts[i] = n.dot(light) - flat
		brightest = maxf(brightest, amounts[i])
		darkest = minf(darkest, amounts[i])
	# Bands spread over the light the sprite actually gets, so every step shows.
	var out := cp.duplicate()
	var cache := {}
	for y in h:
		var fy0 := (y / size.y) * size.y
		for x in w:
			var i := y * w + x
			var c := cp[i]
			if (c >> 24) & 0xFF < threshold:
				continue
			var lit := amounts[i]
			var amount := lit / brightest if lit > 0.0 else (lit / -darkest if lit < 0.0 else 0.0)
			var band := 0
			var strength := absf(amount)
			if strength > base_band:
				var steps := light_steps if amount > 0.0 else shadow_steps
				var k := clampi(ceili((strength - base_band) / (1.0 - base_band) * steps), 0, steps)
				band = k if amount > 0.0 else -k
			var key := c * 16 + band + 8
			if not cache.has(key):
				cache[key] = _shade(c, band, colors)
			var shaded: int = cache[key]
			if rim_color.a > 0.0 and _on_edge(cp, x, y, w, size, fy0, threshold):
				var nc := np[i]
				var facing := Vector2((nc & 0xFF) / 127.5 - 1.0, ((nc >> 8) & 0xFF) / 127.5 - 1.0)
				if nc != 0 and facing.length() > 0.1 and facing.normalized().dot(rim_dir) > 0.5:
					shaded = BitKilnBuffer.blend(rim, shaded)
			out[i] = shaded
	context.color.pixels = out


## [param c] shaded [param band] steps lighter (positive) or darker (negative).
func _shade(c: int, band: int, colors: PackedInt32Array) -> int:
	if band == 0 and colors.is_empty():
		return c
	var color := BitKilnBuffer.to_color(c)
	var k := absf(band)
	var hue := color.h
	var target := 60.0 / 360.0 if band > 0 else 240.0 / 360.0
	var diff := wrapf(target - hue, -0.5, 0.5)
	hue = wrapf(hue + signf(diff) * minf(absf(diff), hue_shift / 360.0 * k), 0.0, 1.0)
	var saturation := clampf(color.s + (saturation_shift * k if band < 0 else -saturation_shift * k), 0.0, 1.0)
	var value := clampf(color.v + value_step * band, 0.0, 1.0)
	if color.s < 0.01:
		hue = color.h # greys have no hue to shift
		saturation = color.s
	var shaded := BitKilnBuffer.from_color(Color.from_hsv(hue, saturation, value, color.a))
	if not colors.is_empty():
		var nearest := colors[BitKilnPalette.nearest(BitKilnBuffer.with_alpha(shaded, 255), colors)]
		shaded = BitKilnBuffer.with_alpha(nearest, (c >> 24) & 0xFF)
	return shaded


func _smooth_normals(context: BitKilnContext) -> BitKilnBuffer:
	var maker := BitKilnNormalMap.new()
	maker.snap_directions = 0
	maker.detail_depth = 0.0
	maker.bevel_radius = maxi(2, mini(context.frame_size.x, context.frame_size.y) / 4)
	var temp := BitKilnContext.new()
	temp.color = context.color
	temp.frames = context.frames
	maker._apply(temp)
	return temp.get_layer(BitKilnContext.NORMAL)


static func _on_edge(cp: PackedInt32Array, x: int, y: int, w: int, size: Vector2i, fy0: int, threshold: int) -> bool:
	var fx0 := (x / size.x) * size.x
	for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + o.x
		var ny := y + o.y
		if nx < fx0 or ny < fy0 or nx >= fx0 + size.x or ny >= fy0 + size.y:
			return true
		if (cp[ny * w + nx] >> 24) & 0xFF < threshold:
			return true
	return false
