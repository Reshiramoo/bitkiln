@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnAnimate
extends BitKilnOp
## Turns a still sprite into an animation: hit flashes, squash and stretch, hops, shakes,
## wobbles, spins, waves, fades, dissolves and afterimages, from a stack of
## [BitKilnMotion] effects. Each frame of the source becomes a row of
## [member frame_count] frames (so a sheet of poses gets an animation per pose).
##
## It stays pixel art: movement snaps to whole pixels, rotation and skewing use RotSprite
## (no new colors, clean lines), and fades and dissolves remove whole pixels instead of
## making them half transparent. Effects apply in order, so a squash then a spin squashes
## first. Frames grow by [member margin] on every side to give the motion room.

enum Layout {
	ROWS, ## Each source frame gets its own row of frames.
	STRIP, ## All frames in one row, source frame after source frame.
}

## Frames in the animation.
@export_range(2, 64, 1, "or_greater") var frame_count := 8
## What happens over the animation, applied in order.
@export var effects: Array[BitKilnMotion] = []
## Transparent pixels added on every side of each frame, so the sprite can move and grow.
@export_range(0, 64, 1, "or_greater", "suffix:px") var margin := 4
## The last frame leads back into the first (time stops one frame short of the end).
## Off: the last frame is the end of the animation, for one-shots like a death dissolve.
@export var loop := true
@export var layout := Layout.ROWS
## Fades, blinks and afterimages remove whole pixels in an ordered pattern instead of
## making them half transparent.
@export var dither_fades := true


func _apply(context: BitKilnContext) -> void:
	var source_size := context.frame_size
	var in_count := context.frames.x * context.frames.y
	var out_size := source_size + Vector2i(margin, margin) * 2
	var grid := Vector2i(frame_count, in_count) if layout == Layout.ROWS else Vector2i(frame_count * in_count, 1)
	var color_out := BitKilnBuffer.create(out_size.x * grid.x, out_size.y * grid.y)
	var normal_in := context.get_layer(BitKilnContext.NORMAL)
	var normal_out := BitKilnBuffer.create(color_out.width, color_out.height) if normal_in != null else null
	for f in in_count:
		var sprite := _extract(context.color, context, f)
		var normals := _extract(normal_in, context, f) if normal_in != null else null
		var bounds := _content_bounds(sprite)
		var big: BitKilnBuffer = null # the sprite at 8×, made once if a frame needs it
		for i in frame_count:
			var t := float(i) / frame_count if loop else float(i) / maxi(frame_count - 1, 1)
			var index := f * frame_count + i
			var cell := Vector2i(index % grid.x, index / grid.x) * out_size
			# Afterimages first, behind the sprite.
			for motion in effects:
				if motion == null or not motion.enabled or motion.effect != BitKilnMotion.Effect.AFTERIMAGE:
					continue
				var u := motion.local_time(t)
				if u < 0.0:
					continue
				for g in range(motion.ghosts, 0, -1):
					var tg := t - float(g * motion.ghost_spacing) / frame_count
					if loop:
						tg = fposmod(tg, 1.0)
					elif tg < 0.0:
						continue
					var state := _state(tg, bounds)
					if state.needs_big and big == null:
						big = _scale8(sprite)
					var ghost := _render(sprite, big, null, state, source_size, out_size, null)
					var opacity := clampf(motion.amount * motion.envelope(u) * (1.0 - float(g - 1) / motion.ghosts), 0.0, 1.0)
					_composite(color_out, cell, ghost, opacity, motion.color)
			var current := _state(t, bounds)
			if current.needs_big and big == null:
				big = _scale8(sprite)
			var normal_frame := BitKilnBuffer.create(out_size.x, out_size.y) if normals != null else null
			var frame := _render(sprite, big, normals, current, source_size, out_size, normal_frame)
			_composite(color_out, cell, frame, 1.0, Color(0, 0, 0, 0))
			if normal_frame != null:
				_blit(normal_out, cell, normal_frame)
	context.layers.clear()
	context.layers[BitKilnContext.COLOR] = color_out
	if normal_out != null:
		context.layers[BitKilnContext.NORMAL] = normal_out
	context.frames = grid
	context.reset_source_mapping()


## Where the sprite is and how it looks at animation time [param t].
func _state(t: float, bounds: Rect2) -> Dictionary:
	var transform := Transform2D.IDENTITY
	var offset := Vector2.ZERO
	var waves: Array[Array] = [] # [amplitude, cycles, phase, vertical]
	var state := {
		"flash": 0.0, "flash_color": Color.WHITE, "tints": [], "alpha": 1.0, "visible": true,
		"dissolve": 0.0, "dissolve_color": Color.WHITE, "dissolve_seed": 0,
	}
	for motion in effects:
		if motion == null or not motion.enabled or motion.effect == BitKilnMotion.Effect.AFTERIMAGE:
			continue
		var u := motion.local_time(t)
		if u < 0.0:
			continue
		var env := motion.envelope(u)
		var pivot := bounds.position + bounds.size * motion.pivot
		var swing := sin(TAU * motion.cycles * u)
		match motion.effect:
			BitKilnMotion.Effect.SQUASH:
				var s := motion.amount * env * swing
				transform = _about(transform, pivot, Transform2D(0.0, Vector2(1.0 + s, 1.0 - s), 0.0, Vector2.ZERO))
			BitKilnMotion.Effect.JUMP:
				offset.y -= motion.amount * env * absf(sin(PI * motion.cycles * u))
			BitKilnMotion.Effect.SHAKE:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash([motion.seed, roundi(t * 10000.0)])
				offset += Vector2(rng.randf_range(-1.0, 1.0) * motion.direction.x,
					rng.randf_range(-1.0, 1.0) * motion.direction.y) * motion.amount * env
			BitKilnMotion.Effect.WOBBLE:
				var angle := deg_to_rad(motion.amount * env * swing)
				transform = _about(transform, pivot, Transform2D(angle, Vector2.ZERO))
			BitKilnMotion.Effect.SKEW:
				var k := motion.amount * env * swing
				transform = _about(transform, pivot, Transform2D(Vector2(1.0, 0.0), Vector2(-k, 1.0), Vector2.ZERO))
			BitKilnMotion.Effect.SPIN:
				transform = _about(transform, pivot, Transform2D(TAU * motion.amount * env, Vector2.ZERO))
			BitKilnMotion.Effect.WAVE:
				waves.append([motion.amount * env, motion.cycles, u, absf(motion.direction.y) > absf(motion.direction.x)])
			BitKilnMotion.Effect.MOVE:
				offset += motion.direction * motion.amount * env
			BitKilnMotion.Effect.SCALE:
				var s := maxf(1.0 + motion.amount * env, 0.01)
				transform = _about(transform, pivot, Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO))
			BitKilnMotion.Effect.FLASH:
				var flash := clampf(motion.amount * env, 0.0, 1.0)
				if flash > state.flash:
					state.flash = flash
					state.flash_color = motion.color
			BitKilnMotion.Effect.TINT:
				(state.tints as Array).append([motion.color, clampf(motion.amount * env, 0.0, 1.0)])
			BitKilnMotion.Effect.FADE:
				state.alpha *= 1.0 - clampf(motion.amount * env, 0.0, 1.0)
			BitKilnMotion.Effect.BLINK:
				if int(floor(u * motion.cycles * 2.0)) % 2 == 1:
					state.visible = false
			BitKilnMotion.Effect.DISSOLVE:
				var amount := clampf(motion.amount * env, 0.0, 1.0)
				if amount > state.dissolve:
					state.dissolve = amount
					state.dissolve_color = motion.color
					state.dissolve_seed = motion.seed
	# Whole-pixel movement, then into the frame's margin.
	transform = transform.translated(offset.round() + Vector2(margin, margin))
	state.transform = transform
	state.waves = waves
	state.needs_big = not (transform.x.is_equal_approx(Vector2(1, 0)) and transform.y.is_equal_approx(Vector2(0, 1)))
	return state


## [param transform], then [param local] around [param pivot].
static func _about(transform: Transform2D, pivot: Vector2, local: Transform2D) -> Transform2D:
	return Transform2D.IDENTITY.translated(pivot) * local * Transform2D.IDENTITY.translated(-pivot) * transform


## One frame of the sprite in [param state], [param out_size] big. With [param normals],
## writes the matching normal map into [param normal_frame].
func _render(sprite: BitKilnBuffer, big: BitKilnBuffer, normals: BitKilnBuffer, state: Dictionary, source_size: Vector2i,
		out_size: Vector2i, normal_frame: BitKilnBuffer) -> BitKilnBuffer:
	var out := BitKilnBuffer.create(out_size.x, out_size.y)
	if not state.visible:
		return out
	var inverse: Transform2D = (state.transform as Transform2D).affine_inverse()
	var use_big: bool = state.needs_big and big != null
	var sp := sprite.pixels
	var bp := big.pixels if use_big else PackedInt32Array()
	var op := out.pixels
	var np := normals.pixels if normals != null else PackedInt32Array()
	var nop := normal_frame.pixels if normal_frame != null else PackedInt32Array()
	var turn := (state.transform as Transform2D).get_rotation()
	var waves: Array[Array] = state.waves
	var flash: float = state.flash
	var flash_color: Color = state.flash_color
	var tints: Array = state.tints
	var alpha: float = state.alpha
	var dissolve: float = state.dissolve
	var dissolve_edge := BitKilnBuffer.from_color(state.dissolve_color)
	for y in out_size.y:
		for x in out_size.x:
			var d := Vector2(x + 0.5, y + 0.5)
			for wave in waves:
				if wave[3]:
					d.y -= roundf(wave[0] * sin(TAU * (wave[1] * (x + 0.5) / out_size.x + wave[2])))
				else:
					d.x -= roundf(wave[0] * sin(TAU * (wave[1] * (y + 0.5) / out_size.y + wave[2])))
			var s := inverse * d
			if s.x < 0.0 or s.y < 0.0 or s.x >= source_size.x or s.y >= source_size.y:
				continue
			var sx := int(s.x)
			var sy := int(s.y)
			var c := bp[int(s.y * 8.0) * big.width + int(s.x * 8.0)] if use_big else sp[sy * source_size.x + sx]
			if c == 0:
				continue
			if dissolve > 0.0:
				var noise := _noise(sx, sy, state.dissolve_seed)
				if noise < dissolve:
					continue
				if noise < dissolve + 0.08:
					c = BitKilnBuffer.with_alpha(dissolve_edge, (c >> 24) & 0xFF)
			if flash > 0.0 or not tints.is_empty():
				var color := BitKilnBuffer.to_color(c)
				for tint: Array in tints:
					var tint_color: Color = tint[0]
					color = Color(color.lerp(tint_color, tint[1]), color.a)
				if flash > 0.0:
					color = Color(color.lerp(flash_color, flash), color.a)
				c = BitKilnBuffer.from_color(color)
			if alpha < 1.0:
				if dither_fades:
					if alpha <= BitKilnFilter.BAYER_4[(y % 4) * 4 + x % 4]:
						continue
				else:
					c = BitKilnBuffer.with_alpha(c, roundi(((c >> 24) & 0xFF) * alpha))
			op[y * out_size.x + x] = c
			if normal_frame != null:
				nop[y * out_size.x + x] = _turn_normal(np[sy * source_size.x + sx], turn)
	out.pixels = op
	if normal_frame != null:
		normal_frame.pixels = nop
	return out


## Draws [param frame] over the cell at [param origin]: at [param opacity] (dithered when
## [member dither_fades]), recolored to [param tint] when its alpha is above 0.
func _composite(target: BitKilnBuffer, origin: Vector2i, frame: BitKilnBuffer, opacity: float, tint: Color) -> void:
	var tp := target.pixels
	var fp := frame.pixels
	var recolor := tint.a > 0.0
	var tint_pixel := BitKilnBuffer.from_color(tint)
	for y in frame.height:
		var row := (origin.y + y) * target.width + origin.x
		for x in frame.width:
			var c := fp[y * frame.width + x]
			if c == 0:
				continue
			if recolor:
				c = BitKilnBuffer.with_alpha(tint_pixel, (c >> 24) & 0xFF)
			if opacity < 1.0:
				if dither_fades:
					if opacity <= BitKilnFilter.BAYER_4[(y % 4) * 4 + x % 4]:
						continue
				else:
					c = BitKilnBuffer.with_alpha(c, roundi(((c >> 24) & 0xFF) * opacity))
			tp[row + x] = BitKilnBuffer.blend(c, tp[row + x])
	target.pixels = tp


static func _blit(target: BitKilnBuffer, origin: Vector2i, frame: BitKilnBuffer) -> void:
	var tp := target.pixels
	var fp := frame.pixels
	for y in frame.height:
		var row := (origin.y + y) * target.width + origin.x
		for x in frame.width:
			if fp[y * frame.width + x] != 0:
				tp[row + x] = fp[y * frame.width + x]
	target.pixels = tp


## Frame number [param index] of [param buffer] as a buffer of its own.
static func _extract(buffer: BitKilnBuffer, context: BitKilnContext, index: int) -> BitKilnBuffer:
	var size := context.frame_size
	var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
	var out := BitKilnBuffer.create(size.x, size.y)
	var bp := buffer.pixels
	var op := out.pixels
	for y in size.y:
		for x in size.x:
			op[y * size.x + x] = bp[(origin.y + y) * buffer.width + origin.x + x]
	out.pixels = op
	return out


## The box around the sprite's visible pixels (the whole frame when it's empty).
static func _content_bounds(sprite: BitKilnBuffer) -> Rect2:
	var lo := Vector2i(sprite.width, sprite.height)
	var hi := Vector2i(-1, -1)
	var p := sprite.pixels
	for y in sprite.height:
		for x in sprite.width:
			if p[y * sprite.width + x] != 0:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	if hi.x < 0:
		return Rect2(Vector2.ZERO, Vector2(sprite.width, sprite.height))
	return Rect2(Vector2(lo), Vector2(hi - lo + Vector2i.ONE))


static func _scale8(sprite: BitKilnBuffer) -> BitKilnBuffer:
	var size := Vector2i(sprite.width, sprite.height)
	var big := BitKilnScale.scale2x(sprite, size)
	big = BitKilnScale.scale2x(big, size * 2)
	return BitKilnScale.scale2x(big, size * 4)


## A stable pseudo-random value 0–1 for source pixel ([param x], [param y]).
static func _noise(x: int, y: int, seed: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663) ^ (seed * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h ^ (h >> 16)) & 0xFFFF) / 65536.0


## Names of the ready-made animations, for [method make_preset].
static func preset_names() -> PackedStringArray:
	return PackedStringArray(["Hit Flash", "Damage Blink", "Idle Bob", "Breathe", "Jump", "Collect", "Pulse",
		"Wobble", "Jelly", "Spin", "Shake", "Teleport", "Death Dissolve"])


## A ready-made animation: [code]{"frame_count": int, "loop": bool, "margin": int,
## "effects": Array[BitKilnMotion]}[/code].
static func make_preset(preset: String) -> Dictionary:
	var M := BitKilnMotion
	var effects: Array[BitKilnMotion] = []
	var count := 8
	var looping := true
	var room := 4
	var always := _curve([Vector2(0, 1), Vector2(1, 1)]) # loops shouldn't settle down
	match preset:
		"Hit Flash":
			count = 6
			looping = false
			var flash := M.create(M.Effect.FLASH, 1.0)
			flash.end = 0.34
			var shake := M.create(M.Effect.SHAKE, 2.0)
			shake.end = 0.6
			effects = [flash, shake]
		"Damage Blink":
			looping = false
			var blink := M.create(M.Effect.BLINK, 1.0)
			blink.cycles = 4.0
			var tint := M.create(M.Effect.TINT, 0.5)
			tint.color = Color(1.0, 0.25, 0.2)
			effects = [tint, blink]
		"Idle Bob":
			effects = [M.create(M.Effect.JUMP, 1.0)]
		"Breathe":
			var squash := M.create(M.Effect.SQUASH, 0.06)
			effects = [squash]
		"Jump":
			count = 10
			looping = false
			var crouch := M.create(M.Effect.SQUASH, 0.25)
			crouch.end = 0.2
			crouch.cycles = 0.5
			var hop := M.create(M.Effect.JUMP, 8.0)
			hop.start = 0.15
			hop.end = 0.85
			room = 10
			var land := M.create(M.Effect.SQUASH, 0.2)
			land.start = 0.8
			land.cycles = 0.5
			effects = [crouch, land, hop]
		"Collect":
			looping = false
			var grow := M.create(M.Effect.SCALE, 0.6)
			grow.pivot = Vector2(0.5, 0.5)
			var rise := M.create(M.Effect.MOVE, 6.0)
			rise.direction = Vector2(0.0, -1.0)
			var fade := M.create(M.Effect.FADE, 1.0)
			fade.start = 0.5
			effects = [grow, rise, fade]
			room = 9
		"Pulse":
			var pulse := M.create(M.Effect.SCALE, 0.2)
			pulse.pivot = Vector2(0.5, 0.5)
			pulse.curve = _curve([Vector2(0, 0), Vector2(0.5, 1), Vector2(1, 0)])
			effects = [pulse]
		"Wobble":
			var wobble := M.create(M.Effect.WOBBLE, 10.0)
			wobble.cycles = 2.0
			wobble.curve = always
			effects = [wobble]
		"Jelly":
			var skew := M.create(M.Effect.SKEW, 0.15)
			skew.cycles = 1.0
			skew.curve = always
			var squash := M.create(M.Effect.SQUASH, 0.08)
			squash.cycles = 2.0
			effects = [squash, skew]
		"Spin":
			var spin := M.create(M.Effect.SPIN, 1.0)
			spin.pivot = Vector2(0.5, 0.5)
			effects = [spin]
		"Shake":
			count = 6
			var shake := M.create(M.Effect.SHAKE, 1.0)
			shake.direction = Vector2(1.0, 1.0)
			shake.curve = always
			effects = [shake]
		"Teleport":
			looping = false
			var wave := M.create(M.Effect.WAVE, 2.0)
			wave.cycles = 2.0
			var fade := M.create(M.Effect.FADE, 1.0)
			fade.start = 0.3
			var tint := M.create(M.Effect.TINT, 0.6)
			tint.color = Color(0.5, 0.8, 1.0)
			effects = [tint, wave, fade]
		"Death Dissolve":
			count = 10
			looping = false
			var flash := M.create(M.Effect.FLASH, 1.0)
			flash.end = 0.1
			var dissolve := M.create(M.Effect.DISSOLVE, 1.0)
			dissolve.start = 0.1
			dissolve.color = Color(1.0, 0.6, 0.2)
			effects = [flash, dissolve]
	return {"frame_count": count, "loop": looping, "margin": room, "effects": effects}


static func _curve(points: Array[Vector2]) -> Curve:
	var curve := Curve.new()
	for point in points:
		curve.add_point(point)
	return curve


## A normal map pixel turned clockwise by [param angle] radians.
static func _turn_normal(c: int, angle: float) -> int:
	if c == 0 or is_zero_approx(angle):
		return c
	var x := (c & 0xFF) - 127.5
	var y := ((c >> 8) & 0xFF) - 127.5 # up is positive
	var cos_t := cos(angle)
	var sin_t := sin(angle)
	return BitKilnBuffer.pack(roundi(x * cos_t + y * sin_t + 127.5), roundi(-x * sin_t + y * cos_t + 127.5),
		(c >> 16) & 0xFF, (c >> 24) & 0xFF)
