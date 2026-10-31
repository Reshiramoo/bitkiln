@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnParticles
extends BitKilnOp
## Simulates particles and draws them across the frames, as pixel art: fire, smoke,
## sparks, explosions, magic, rain, snow.
##
## How many frames: set how long the effect lasts ([member duration]) and the speed it plays
## at ([member fps]), and [member frame_count] at Auto works out the count. Starting from
## one frame (a blank canvas, or a sprite the particles go over), the op makes that many
## frames in a row, so the result plays at real speed. After an op that already animated the
## image (a [BitKilnAnimate], say), it draws on that animation's frames at its speed instead.
## Over a source sheet that already has several frames, it draws on those, spreading
## [member duration] over them.
##
## The same settings always give the same sheet: every particle's randomness comes from
## [member seed] and its own number. With [member loop], emission repeats exactly every
## [member duration] and the simulation is warmed up first, so the last frame flows into
## the first. Particles snap to whole pixels, fade by dropping pixels in an ordered
## pattern, and can snap to a palette.

enum Emitter {
	POINT, ## From one point.
	CIRCLE, ## Anywhere inside a circle of [member emitter_size].x radius.
	RING, ## On the edge of a circle of [member emitter_size].x radius.
	RECTANGLE, ## Anywhere inside a rectangle of [member emitter_size].
	LINE, ## Along a horizontal line [member emitter_size].x long.
}
enum Shape {
	PIXEL, ## Single pixels (size is ignored).
	CIRCLE, ## Filled circles [member size_start]…[member size_end] wide.
	SQUARE, ## Filled squares.
	DIAMOND, ## Diamonds.
	STAR, ## Four-pointed sparkles.
	STREAK, ## Lines trailing behind the particle's movement, [member streak] seconds long.
	SPRITE, ## Frames of [member sprite], played over each particle's life.
}
enum Blend {
	NORMAL, ## Particles cover what's behind them.
	ADD, ## Particles lighten what's behind them, like light.
}

@export_group("Timing")
## Seconds the effect lasts. Hidden when [member frame_count] is set: the length is then
## the frame count at [member fps].
@export_range(0.05, 30.0, 0.05, "or_greater", "suffix:s") var duration := 1.0
## Frames per second the effect is made for. Sprite Frames and GIF outputs play at this
## speed unless they set their own, and so does the BitKiln dock's preview.
@export_range(1.0, 60.0, 0.5, "or_greater", "suffix:fps") var fps := 10.0
## Frames to make. 0 = Auto: [member duration] × [member fps]. Ignored over a sheet that
## already has several frames, or an animation made by an earlier op.
@export_range(0, 256, 1, "or_greater") var frame_count := 0:
	set(value):
		frame_count = maxi(value, 0)
		notify_property_list_changed()
## Seamless loop: emission repeats every [member duration] and the simulation is warmed up,
## so the last frame leads into the first. Off: the effect starts empty (bursts, one-shots).
@export var loop := true
## Simulation steps per frame; more is smoother for fast particles.
@export_range(1, 16, 1) var substeps := 4
## Changes every random choice.
@export var seed := 1

@export_group("Emission")
## Particles per second, emitted evenly.
@export_range(0.0, 500.0, 0.5, "or_greater") var rate := 20.0
## Extra particles all at once: x = when (0–1 of [member duration]), y = how many.
@export var bursts := PackedVector2Array()
## Where particles are born.
@export var emitter := Emitter.POINT
## Radius (circle, ring), width and height (rectangle) or length (line), in pixels.
@export var emitter_size := Vector2(4.0, 4.0)
## From the frame's center to the emitter, in pixels.
@export var emitter_offset := Vector2.ZERO

@export_group("Motion")
## Seconds each particle lives.
@export_range(0.05, 30.0, 0.05, "or_greater", "suffix:s") var lifetime := 1.0
## How much lifetimes vary, 0–1 (0.3 = up to 30% shorter).
@export_range(0.0, 1.0, 0.01) var lifetime_random := 0.3
## Direction particles start moving, in degrees clockwise from right (-90 = up).
@export_range(-360.0, 360.0, 1.0, "suffix:°") var direction := -90.0
## How far directions spread around [member direction], in degrees (360 = every way).
@export_range(0.0, 360.0, 1.0, "suffix:°") var spread := 40.0
## Starting speed, pixels per second: anywhere from x to y.
@export var speed := Vector2(8.0, 18.0)
## Constant acceleration, pixels per second²: (0, 60) falls, (0, -30) rises.
@export var gravity := Vector2.ZERO
## Slows particles down: 0 = none, 3 = strongly.
@export_range(0.0, 20.0, 0.1, "or_greater") var drag := 0.0
## Push away from (positive) or pull toward (negative) the emitter, pixels per second².
@export var radial_accel := 0.0
## Swirl around the emitter, pixels per second² (positive = clockwise).
@export var swirl := 0.0

@export_group("Look")
## How each particle is drawn.
@export var shape := Shape.CIRCLE
## Size at birth, in pixels.
@export_range(0.0, 32.0, 0.5, "or_greater", "suffix:px") var size_start := 3.0
## Size at death, in pixels.
@export_range(0.0, 32.0, 0.5, "or_greater", "suffix:px") var size_end := 1.0
## How size goes from start (0) to end (1) over each particle's life. Empty = evenly.
@export var size_curve: Curve
## How much sizes vary, 0–1.
@export_range(0.0, 1.0, 0.01) var size_random := 0.2
## Color over each particle's life, left (birth) to right (death); its alpha fades
## particles. Empty = white fading out.
@export var colors: Gradient
## Colors change in this many steps over a particle's life instead of blending smoothly,
## so the sheet keeps a small palette; 0 = smooth.
@export_range(0, 16, 1) var color_steps := 5
## For streaks: how far back the line reaches, in seconds of movement.
@export_range(0.0, 1.0, 0.005, "suffix:s") var streak := 0.05
## For the Sprite shape: a sheet of frames played over each particle's life.
@export var sprite: Texture2D
## For the Sprite shape: columns and rows of [member sprite].
@export var sprite_frames := Vector2i.ONE
## How particles combine with what's behind them.
@export var blend := Blend.NORMAL
## Fades drop pixels in an ordered pattern; off, they turn half transparent.
@export var dither_fades := true
## Snap every particle color to this palette.
@export var palette: Texture2D
@export_group("")


func _validate_property(property: Dictionary) -> void:
	if property.name == "duration" and frame_count > 0:
		property.usage = PROPERTY_USAGE_STORAGE


func get_fps() -> float:
	return fps


func playback_fps(earlier: float) -> float:
	return earlier if earlier > 0.0 else fps


## How many frames the op makes from a single frame: [member frame_count], or with Auto,
## [member duration] × [member fps].
func get_frame_count() -> int:
	return frame_count if frame_count > 0 else maxi(roundi(duration * fps), 1)


## Seconds the frames the op makes cover, playing at [member fps].
func get_duration() -> float:
	return get_frame_count() / fps


func _apply(context: BitKilnContext) -> void:
	var earlier := float(context.meta.get("fps", 0.0))
	var span := duration
	if context.frames == Vector2i.ONE:
		context.repeat_frame(get_frame_count())
		span = get_duration()
	var size := context.frame_size
	var total := context.frames.x * context.frames.y
	if earlier > 0.0 and total > 1:
		span = total / earlier # an earlier op's animation: keep to its speed
	context.meta["fps"] = playback_fps(earlier)
	var gradient := colors if colors != null else _default_colors()
	var colors_of_palette := BitKilnPalette.load_colors(palette) if palette != null else PackedInt32Array()
	var sprite_image := BitKilnBaker.load_texture_image(sprite) if shape == Shape.SPRITE and sprite != null else null
	var sprite_buffer := BitKilnBuffer.from_image(sprite_image) if sprite_image != null else null
	var center := Vector2(size) * 0.5 + emitter_offset
	var snapshots := simulate(total, 0, span)
	var p := context.color.pixels
	var mask_cache := {}
	var palette_cache := {}
	for index in total:
		var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
		for particle: Array in snapshots[index]:
			# [x, y, vx, vy, age, life, id]
			var age_ratio: float = particle[4] / particle[5]
			var color_time := age_ratio
			if color_steps > 0:
				color_time = (minf(floorf(age_ratio * color_steps), color_steps - 1) + 0.5) / color_steps
			var color := gradient.sample(color_time)
			if color.a <= 0.0:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash([seed, int(particle[6]), 7])
			var t := size_curve.sample_baked(age_ratio) if size_curve != null else age_ratio
			var particle_size := lerpf(size_start, size_end, t) * (1.0 - size_random * rng.randf())
			var at := center + Vector2(particle[0], particle[1])
			var pixels := _shape_pixels(at, Vector2(particle[2], particle[3]), particle_size, age_ratio, sprite_buffer, mask_cache)
			for entry: Array in pixels:
				var x: int = entry[0]
				var y: int = entry[1]
				if x < 0 or y < 0 or x >= size.x or y >= size.y:
					continue
				var c := color
				if entry.size() > 2:
					var sc: Color = entry[2] # a sprite's own pixel, tinted by the gradient
					c = Color(sc.r * color.r, sc.g * color.g, sc.b * color.b, sc.a * color.a)
				if c.a < 1.0:
					if dither_fades:
						if c.a <= BitKilnFilter.BAYER_4[(y % 4) * 4 + x % 4]:
							continue
						c.a = 1.0
					else:
						c.a = roundf(c.a * 4.0) / 4.0
						if c.a <= 0.0:
							continue
				var pixel := BitKilnBuffer.from_color(c)
				if not colors_of_palette.is_empty():
					var opaque := BitKilnBuffer.with_alpha(pixel, 255)
					if not palette_cache.has(opaque):
						palette_cache[opaque] = colors_of_palette[BitKilnPalette.nearest(opaque, colors_of_palette)]
					pixel = BitKilnBuffer.with_alpha(palette_cache[opaque], (pixel >> 24) & 0xFF)
				var i := (origin.y + y) * context.width + origin.x + x
				if blend == Blend.ADD and p[i] != 0:
					var under := p[i]
					var a := ((pixel >> 24) & 0xFF) / 255.0
					p[i] = BitKilnBuffer.pack((under & 0xFF) + roundi((pixel & 0xFF) * a),
						((under >> 8) & 0xFF) + roundi(((pixel >> 8) & 0xFF) * a),
						((under >> 16) & 0xFF) + roundi(((pixel >> 16) & 0xFF) * a), (under >> 24) & 0xFF)
				else:
					p[i] = BitKilnBuffer.blend(pixel, p[i])
	context.color.pixels = p


## The particles alive at each of [param count] frames:
## [code][x, y, vx, vy, age, life, id][/code] each, positions from the emitter's center.
## [param extra] more frames continue past the end (with [member loop], frame
## [param count] is the first one again). The frames cover [param span] seconds
## ([member duration] when negative).
func simulate(count: int, extra := 0, span := -1.0) -> Array[Array]:
	var length := span if span > 0.0 else duration
	var frame_dt := length / count
	var h := frame_dt / substeps
	var per_period := maxi(0, roundi(rate * length))
	var longest := lifetime
	# Spawn times (seconds) and particle numbers, for the whole simulated span.
	var start_time := 0.0
	if loop:
		start_time = -length * ceilf(longest / length)
	var spawns: Array[Vector2] = [] # (time, id)
	var period_start := floorf(start_time / length) * length
	var period := 0
	var end_time := length * (1.0 + float(extra) / count)
	while period_start + period * length < end_time:
		var base := period_start + period * length
		var id := 0
		for k in per_period:
			spawns.append(Vector2(base + (k + 0.5) / per_period * length, id))
			id += 1
		for burst in bursts:
			for k in int(burst.y):
				spawns.append(Vector2(base + clampf(burst.x, 0.0, 0.999) * length, id))
				id += 1
		period += 1
		if not loop:
			break
	spawns.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)

	var result: Array[Array] = []
	for i in count + extra:
		result.append([])
	var alive: Array[Array] = []
	var next_spawn := 0
	var t := start_time
	var steps := roundi((0.0 - start_time) / h) + (count + extra) * substeps
	for step in steps + 1:
		# Frames are captured at the start of their step, once the simulation reaches 0.
		var frame_step := step - roundi((0.0 - start_time) / h)
		if frame_step >= 0 and frame_step % substeps == 0 and frame_step / substeps < count + extra:
			var snapshot: Array = result[frame_step / substeps]
			for particle in alive:
				snapshot.append(particle.duplicate())
		if step == steps:
			break
		var survivors: Array[Array] = []
		for particle in alive:
			_integrate(particle, h)
			if particle[4] < particle[5]:
				survivors.append(particle)
		alive = survivors
		# Particles born during this step, already moved to its end.
		while next_spawn < spawns.size() and spawns[next_spawn].x < t + h:
			if spawns[next_spawn].x >= t - 0.000001:
				var born := _spawn(int(spawns[next_spawn].y), t + h - spawns[next_spawn].x)
				if born[4] < born[5]:
					alive.append(born)
			next_spawn += 1
		t += h
	return result


func _spawn(id: int, age: float) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, id])
	var at := Vector2.ZERO
	match emitter:
		Emitter.CIRCLE:
			at = Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * emitter_size.x
		Emitter.RING:
			at = Vector2.from_angle(rng.randf() * TAU) * emitter_size.x
		Emitter.RECTANGLE:
			at = Vector2(rng.randf_range(-0.5, 0.5) * emitter_size.x, rng.randf_range(-0.5, 0.5) * emitter_size.y)
		Emitter.LINE:
			at = Vector2(rng.randf_range(-0.5, 0.5) * emitter_size.x, 0.0)
	var angle := deg_to_rad(direction + rng.randf_range(-0.5, 0.5) * spread)
	var velocity := Vector2.from_angle(angle) * rng.randf_range(minf(speed.x, speed.y), maxf(speed.x, speed.y))
	var life := lifetime * (1.0 - lifetime_random * rng.randf())
	var particle := [at.x, at.y, velocity.x, velocity.y, 0.0, maxf(life, 0.01), float(id)]
	if age > 0.0:
		_integrate(particle, age)
	return particle


func _integrate(particle: Array, dt: float) -> void:
	var position := Vector2(particle[0], particle[1])
	var velocity := Vector2(particle[2], particle[3])
	var acceleration := gravity
	if (radial_accel != 0.0 or swirl != 0.0) and position.length_squared() > 0.0001:
		var out := position.normalized()
		acceleration += out * radial_accel + out.orthogonal() * -swirl
	velocity += acceleration * dt
	if drag > 0.0:
		velocity /= 1.0 + drag * dt
	position += velocity * dt
	particle[0] = position.x
	particle[1] = position.y
	particle[2] = velocity.x
	particle[3] = velocity.y
	particle[4] = particle[4] + dt


## The frame pixels one particle covers: [code][x, y][/code], or [code][x, y, Color][/code]
## for sprite pixels.
func _shape_pixels(at: Vector2, velocity: Vector2, particle_size: float, age_ratio: float, sprite_buffer: BitKilnBuffer,
		cache: Dictionary) -> Array:
	var cx := floori(at.x)
	var cy := floori(at.y)
	var pixels := []
	match shape:
		Shape.PIXEL:
			pixels.append([cx, cy])
		Shape.STREAK:
			var tail := at - velocity * streak
			var from := Vector2i(floori(tail.x), floori(tail.y))
			var d := Vector2i(cx, cy) - from
			var steps := maxi(absi(d.x), absi(d.y))
			for k in steps + 1:
				var q := Vector2(from) + Vector2(d) * (float(k) / maxi(steps, 1))
				pixels.append([roundi(q.x), roundi(q.y)])
		Shape.SPRITE:
			if sprite_buffer != null:
				var grid := sprite_frames.maxi(1)
				var fw := sprite_buffer.width / grid.x
				var fh := sprite_buffer.height / grid.y
				var count := grid.x * grid.y
				var frame := mini(int(age_ratio * count), count - 1)
				var ox := (frame % grid.x) * fw
				var oy := (frame / grid.x) * fh
				for y in fh:
					for x in fw:
						var c := sprite_buffer.pixels[(oy + y) * sprite_buffer.width + ox + x]
						if c != 0:
							pixels.append([cx - fw / 2 + x, cy - fh / 2 + y, BitKilnBuffer.to_color(c)])
		_:
			var s := maxi(1, roundi(particle_size))
			if particle_size < 0.5:
				return pixels
			var key := s * 16 + int(shape)
			if not cache.has(key):
				cache[key] = _mask_offsets(s)
			for offset: Vector2i in cache[key]:
				pixels.append([cx + offset.x, cy + offset.y])
	return pixels


## The pixels of the particle shape at size [param s], around (0, 0).
func _mask_offsets(s: int) -> Array[Vector2i]:
	var side := s + 2
	var mask: PackedByteArray
	var center := Vector2(side, side) * 0.5
	match shape:
		Shape.SQUARE:
			mask = BitKilnRaster.rectangle(side, side, Rect2(center - Vector2(s, s) * 0.5, Vector2(s, s)))
		Shape.DIAMOND:
			mask = BitKilnRaster.polygon(side, side, BitKilnRaster.regular_polygon(center, Vector2(s, s) * 0.5, 4))
		Shape.STAR:
			mask = BitKilnRaster.polygon(side, side, BitKilnRaster.star(center, Vector2(s, s) * 0.5 + Vector2(0.5, 0.5), 4, 0.3))
		_:
			mask = BitKilnRaster.ellipse(side, side, Rect2(center - Vector2(s, s) * 0.5, Vector2(s, s)))
	var offsets: Array[Vector2i] = []
	for y in side:
		for x in side:
			if mask[y * side + x]:
				offsets.append(Vector2i(x - side / 2, y - side / 2))
	if offsets.is_empty():
		offsets.append(Vector2i.ZERO)
	return offsets


## Names of the ready-made effects, for [method make_preset]. They're tuned for 32×32 frames.
static func preset_names() -> PackedStringArray:
	return PackedStringArray(["Fire", "Smoke", "Sparks", "Explosion", "Magic", "Dust", "Rain", "Snow", "Confetti", "Bubbles"])


## A ready-made effect, as property values to set on the op.
static func make_preset(preset: String) -> Dictionary:
	var base := {
		"duration": 1.0, "frame_count": 0, "loop": true, "rate": 20.0, "bursts": PackedVector2Array(), "emitter": Emitter.POINT,
		"emitter_size": Vector2(4, 4), "emitter_offset": Vector2.ZERO, "lifetime": 1.0, "lifetime_random": 0.3,
		"direction": -90.0, "spread": 40.0, "speed": Vector2(8, 18), "gravity": Vector2.ZERO, "drag": 0.0,
		"radial_accel": 0.0, "swirl": 0.0, "shape": Shape.CIRCLE, "size_start": 3.0, "size_end": 1.0, "size_curve": null,
		"size_random": 0.2, "colors": null, "color_steps": 5, "streak": 0.05, "blend": Blend.NORMAL, "dither_fades": true,
	}
	var values := {}
	match preset:
		"Fire":
			values = {"rate": 45.0, "emitter": Emitter.LINE, "emitter_size": Vector2(10, 0), "emitter_offset": Vector2(0, 10),
				"lifetime": 0.8, "lifetime_random": 0.4, "spread": 20.0, "speed": Vector2(10, 22), "gravity": Vector2(0, -18),
				"drag": 0.6, "size_start": 5.0, "size_end": 1.0,
				"colors": _gradient([Color8(255, 250, 220), Color8(255, 210, 90), Color8(245, 120, 40), Color8(170, 40, 30), Color8(90, 20, 20, 0)])}
		"Smoke":
			values = {"rate": 12.0, "emitter": Emitter.CIRCLE, "emitter_size": Vector2(3, 3), "emitter_offset": Vector2(0, 10),
				"lifetime": 1.6, "spread": 30.0, "speed": Vector2(6, 12), "drag": 0.3, "swirl": 4.0, "size_start": 3.0,
				"size_end": 8.0, "colors": _gradient([Color8(200, 200, 205, 230), Color8(140, 140, 150, 160), Color8(90, 90, 100, 0)])}
		"Sparks":
			values = {"rate": 30.0, "lifetime": 0.5, "spread": 120.0, "speed": Vector2(30, 60), "gravity": Vector2(0, 120),
				"shape": Shape.STREAK, "streak": 0.04, "blend": Blend.ADD, "emitter_offset": Vector2(0, 4),
				"colors": _gradient([Color8(255, 255, 230), Color8(255, 210, 80), Color8(240, 110, 30, 0)])}
		"Explosion":
			values = {"loop": false, "rate": 0.0, "bursts": PackedVector2Array([Vector2(0.0, 45)]), "emitter": Emitter.CIRCLE,
				"emitter_size": Vector2(2, 2), "lifetime": 0.8, "lifetime_random": 0.5, "spread": 360.0, "speed": Vector2(15, 45),
				"drag": 2.5, "size_start": 6.0, "size_end": 1.0,
				"colors": _gradient([Color8(255, 255, 240), Color8(255, 220, 100), Color8(245, 120, 40), Color8(130, 40, 30), Color8(60, 30, 30, 0)])}
		"Magic":
			values = {"rate": 24.0, "emitter": Emitter.RING, "emitter_size": Vector2(9, 9), "lifetime": 1.0, "spread": 360.0,
				"speed": Vector2(2, 6), "swirl": 60.0, "radial_accel": -12.0, "shape": Shape.STAR, "size_start": 4.0,
				"size_end": 1.0, "blend": Blend.ADD,
				"colors": _gradient([Color8(230, 255, 255), Color8(120, 220, 255), Color8(160, 90, 255), Color8(90, 40, 160, 0)])}
		"Dust":
			values = {"loop": false, "rate": 0.0, "bursts": PackedVector2Array([Vector2(0.0, 14)]), "emitter": Emitter.LINE,
				"emitter_size": Vector2(12, 0), "emitter_offset": Vector2(0, 12), "lifetime": 0.8, "spread": 150.0,
				"speed": Vector2(8, 20), "gravity": Vector2(0, 25), "drag": 1.5, "size_start": 4.0, "size_end": 1.0,
				"colors": _gradient([Color8(220, 200, 160, 230), Color8(170, 150, 120, 120), Color8(120, 100, 80, 0)])}
		"Rain":
			values = {"rate": 30.0, "emitter": Emitter.LINE, "emitter_size": Vector2(40, 0), "emitter_offset": Vector2(-4, -18),
				"lifetime": 0.45, "lifetime_random": 0.1, "direction": 100.0, "spread": 4.0, "speed": Vector2(90, 110),
				"shape": Shape.STREAK, "streak": 0.03, "colors": _gradient([Color8(170, 210, 255, 220), Color8(140, 180, 240, 200)])}
		"Snow":
			values = {"duration": 2.0, "rate": 8.0, "emitter": Emitter.LINE, "emitter_size": Vector2(36, 0),
				"emitter_offset": Vector2(0, -17), "lifetime": 3.0, "lifetime_random": 0.0, "direction": 90.0, "spread": 40.0,
				"speed": Vector2(8, 14), "size_start": 2.0, "size_end": 2.0, "size_random": 0.5,
				"colors": _gradient([Color8(255, 255, 255), Color8(230, 240, 255)])}
		"Confetti":
			values = {"loop": false, "rate": 0.0, "bursts": PackedVector2Array([Vector2(0.0, 30)]), "emitter_offset": Vector2(0, 10),
				"lifetime": 1.0, "lifetime_random": 0.6, "spread": 70.0, "speed": Vector2(35, 60), "gravity": Vector2(0, 70),
				"drag": 1.2, "shape": Shape.SQUARE, "size_start": 2.0, "size_end": 2.0, "size_random": 0.0,
				"colors": _gradient([Color8(255, 80, 90), Color8(255, 210, 60), Color8(80, 210, 120), Color8(80, 160, 255),
					Color8(220, 100, 255)], true)}
		"Bubbles":
			values = {"duration": 2.0, "rate": 5.0, "emitter": Emitter.LINE, "emitter_size": Vector2(18, 0),
				"emitter_offset": Vector2(0, 14), "lifetime": 2.0, "spread": 10.0, "speed": Vector2(8, 14), "swirl": 3.0,
				"shape": Shape.CIRCLE, "size_start": 2.0, "size_end": 4.0,
				"colors": _gradient([Color8(190, 230, 255, 200), Color8(150, 210, 255, 160), Color8(150, 210, 255, 0)])}
	base.merge(values, true)
	return base


static func _gradient(stops: Array[Color], constant := false) -> Gradient:
	var gradient := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors_list := PackedColorArray()
	for i in stops.size():
		offsets.append(float(i) / maxi(stops.size() - 1, 1) if not constant else float(i) / stops.size())
		colors_list.append(stops[i])
	gradient.offsets = offsets
	gradient.colors = colors_list
	if constant:
		gradient.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	return gradient


static func _default_colors() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.WHITE)
	gradient.set_color(1, Color(1, 1, 1, 0))
	return gradient
