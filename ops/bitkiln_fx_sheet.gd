@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnFxSheet
extends BitKilnOp
## Draws an animated effect across the frames: sparkles, impact bursts, smoke puffs,
## slashes, pulsing orbs and shockwave rings. Use it on a recipe without a source, with
## [member BitKilnRecipe.frames] set to the number of frames (6×1, 8×1…), and play the
## result with a Sprite Frames output, a [code]PocketSpriteVfx[/code] or an AnimatedSprite2D.
##
## Each pixel gets a "heat" from 0 (the hot, bright core) to 1 (the cool, fading edge),
## colored by [member colors] in [member color_steps] hard steps, so the sheet stays in a
## small palette.

enum Effect {
	SPARKLE, ## Four-pointed twinkles that pop in and out at random spots; loops.
	IMPACT, ## A flash, then spikes bursting outward.
	SMOKE, ## Puffs drifting toward [member direction], growing and fading.
	SLASH, ## A crescent swipe that sweeps around and thins out.
	ORB, ## A pulsing ball of light with a halo; loops.
	RING, ## A shockwave ring expanding and thinning.
}

## Which effect to draw.
@export var effect := Effect.IMPACT
## From the hot core (left) to the fading edge (right). Its alpha is kept, so a gradient
## ending transparent fades out. With Constant interpolation and points at 0, 1/n, 2/n…
## ([member color_steps] = n), every band is exactly one of its colors. Empty = white,
## yellow, orange, red.
@export var colors: Gradient
## Heat levels, each a hard band of color; 0 = smooth.
@export_range(0, 16, 1) var color_steps := 4
## How big the effect gets, relative to the frame (1 = touches the frame's edge).
@export_range(0.1, 1.0, 0.01) var scale := 0.9
## Sparkles, spikes or puffs.
@export_range(1, 32, 1) var count := 6
## Which way smoke drifts and slashes face, in degrees clockwise from right.
@export_range(-360.0, 360.0, 1.0, "suffix:°") var direction := -90.0
## Changes the random placement (sparkles, spikes, puffs).
@export var seed := 1
## How the effect advances over the frames (0 = first frame, 1 = last). Empty = evenly.
@export var timing: Curve
## Fading pixels pick their band with an ordered pattern, for softer fades.
@export var dither := false


func _apply(context: BitKilnContext) -> void:
	var size := context.frame_size
	var total := context.frames.x * context.frames.y
	var gradient := colors if colors != null else _default_colors()
	var heat := PackedFloat32Array()
	heat.resize(size.x * size.y)
	var p := context.color.pixels
	for index in total:
		# Looping effects stop one step short of the start, so the loop doesn't repeat a frame.
		var t := float(index) / (total if _loops() else total - 1) if total > 1 else 0.5
		if timing != null:
			t = clampf(timing.sample_baked(t), 0.0, 1.0)
		heat.fill(-1.0)
		_draw(heat, size, t)
		var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
		for y in size.y:
			var row := (origin.y + y) * context.width + origin.x
			for x in size.x:
				var h := heat[y * size.x + x]
				if h < 0.0:
					continue
				var c := BitKilnFilter.gradient_color(gradient, h, color_steps, dither, x, y)
				p[row + x] = BitKilnBuffer.blend(c, p[row + x])
	context.color.pixels = p


func _loops() -> bool:
	return effect == Effect.ORB or effect == Effect.SPARKLE


func _draw(heat: PackedFloat32Array, size: Vector2i, t: float) -> void:
	var center := Vector2(size) * 0.5
	var radius := minf(size.x, size.y) * 0.5 * scale
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	match effect:
		Effect.SPARKLE:
			for i in count:
				var at := center + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * (radius - 2.0)
				var phase := rng.randf()
				var life := fposmod(t - phase, 1.0)
				var arm := sin(life * PI) * radius * 0.45
				if arm < 0.5:
					continue
				_plot(heat, size, at, 0.0)
				for d: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
					for k in range(1, roundi(arm) + 1):
						_plot(heat, size, at + d * k, float(k) / (arm + 1.0))
				if arm > 2.5:
					for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
						_plot(heat, size, at + d, 0.6)
		Effect.IMPACT:
			if t < 0.3:
				var flash := radius * (0.35 + t)
				_disc(heat, size, center, flash, func(d: float) -> float: return d / flash * 0.5 + t)
			var angles := PackedFloat32Array()
			for i in count:
				angles.append(TAU * i / count + rng.randf_range(-0.25, 0.25) * TAU / count)
			var inner := radius * clampf(t * 1.2 - 0.2, 0.0, 1.0)
			var outer := radius * (0.4 + 0.6 * sqrt(t))
			for a in angles:
				var dir := Vector2.from_angle(a)
				var steps := ceili(outer)
				for k in steps:
					var r := lerpf(inner, outer, float(k) / maxf(steps - 1, 1))
					var width := (1.0 - float(k) / steps) * 1.2
					var at := center + dir * r
					_plot(heat, size, at, clampf(t * 0.7 + float(k) / steps * 0.3, 0.0, 1.0))
					if width > 0.6:
						_plot(heat, size, at + dir.orthogonal() * 0.8, clampf(t * 0.7 + 0.3, 0.0, 1.0))
		Effect.SMOKE:
			var drift := Vector2.from_angle(deg_to_rad(direction))
			for i in count:
				var start := Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)) * radius
				var speed := rng.randf_range(0.5, 1.0)
				var at := center + start + drift * radius * 0.7 * t * speed
				var r := radius * (0.2 + 0.25 * t) * rng.randf_range(0.7, 1.2) * (1.0 - smoothstep(0.75, 1.0, t) * 0.6)
				_disc(heat, size, at, r, func(d: float) -> float: return clampf(d / r * 0.5 + t * 0.6, 0.0, 1.0))
		Effect.SLASH:
			var facing := deg_to_rad(direction)
			var head := smoothstep(0.0, 0.6, t)
			var tail := smoothstep(0.35, 1.0, t)
			var sweep := PI * 1.2
			var thickness := radius * 0.35
			for y in size.y:
				for x in size.x:
					var v := Vector2(x + 0.5, y + 0.5) - center
					var along := fposmod(v.angle() - (facing - sweep * 0.5), TAU) / sweep # 0..1 across the swipe
					if along > 1.0 or along < tail or along > head:
						continue
					var span := maxf(head - tail, 0.001)
					var taper := clampf((along - tail) / span, 0.0, 1.0)
					var band := thickness * taper * (1.0 - t * 0.5)
					var dist := v.length()
					if dist <= radius and dist >= radius - band:
						heat[y * size.x + x] = clampf(1.0 - taper + (radius - dist) / maxf(band, 1.0) * 0.3, 0.0, 1.0)
		Effect.ORB:
			var pulse := 0.5 + 0.12 * sin(TAU * t)
			var core := radius * pulse
			var halo := radius * (pulse + 0.35)
			_disc(heat, size, center, halo, func(d: float) -> float:
				return clampf(d / core * 0.45, 0.0, 0.45) if d <= core else 0.55 + (d - core) / (halo - core) * 0.45)
		Effect.RING:
			var r := radius * (0.15 + 0.85 * t)
			var width := maxf(1.0, radius * 0.3 * (1.0 - t))
			for y in size.y:
				for x in size.x:
					var d := (Vector2(x + 0.5, y + 0.5) - center).length()
					if d <= r and d >= r - width:
						heat[y * size.x + x] = clampf(t * 0.7 + (r - d) / width * 0.3, 0.0, 1.0)


## Sets the heat at [param at] (keeping the hotter of the two).
static func _plot(heat: PackedFloat32Array, size: Vector2i, at: Vector2, value: float) -> void:
	var x := floori(at.x)
	var y := floori(at.y)
	if x < 0 or y < 0 or x >= size.x or y >= size.y:
		return
	var i := y * size.x + x
	if heat[i] < 0.0 or value < heat[i]:
		heat[i] = value


## A disc of [param radius]; [param heat_at] maps the distance from the center to a heat.
static func _disc(heat: PackedFloat32Array, size: Vector2i, center: Vector2, radius: float, heat_at: Callable) -> void:
	for y in range(maxi(0, floori(center.y - radius)), mini(size.y, ceili(center.y + radius))):
		for x in range(maxi(0, floori(center.x - radius)), mini(size.x, ceili(center.x + radius))):
			var d := (Vector2(x + 0.5, y + 0.5) - center).length()
			if d <= radius:
				var i := y * size.x + x
				var value: float = heat_at.call(d)
				if heat[i] < 0.0 or value < heat[i]:
					heat[i] = value


static func _default_colors() -> Gradient:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75])
	gradient.colors = PackedColorArray([Color8(255, 255, 240), Color8(255, 225, 110), Color8(250, 140, 50), Color8(190, 55, 40)])
	gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	return gradient
