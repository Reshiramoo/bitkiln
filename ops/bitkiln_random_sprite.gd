@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnRandomSprite
extends BitKilnOp
## Generates a different random, mirrored sprite in every frame: creatures, ships or
## items, in the tradition of seeded pixel-sprite generators. Each sprite is a random
## half, mirrored, cleaned up into one piece, shaded from top to bottom, outlined, and
## (for creatures) given eyes. Use a recipe without a source and a big frame grid (8×8 =
## 64 sprites), then keep the ones you like, or bake a fresh set per game for
## procedural enemies and loot.

enum Kind {
	CREATURE, ## Round bodies with limbs, and eyes.
	SHIP, ## Pointed at the top, wide wings and engines at the bottom.
	ITEM, ## Compact, round-ish shapes: gems, potions, trinkets.
}
enum Mirror {
	HORIZONTAL, ## Left and right halves mirror each other.
	VERTICAL, ## Top and bottom halves mirror each other.
	BOTH, ## All four quarters mirror each other.
}

## What kind of sprites to make.
@export var kind := Kind.CREATURE
## Which halves mirror each other.
@export var mirror := Mirror.HORIZONTAL
## Frame number n uses seed + n, so the same seed always makes the same set.
@export var seed := 1
## How much of the shape is filled (0–1).
@export_range(0.1, 0.9, 0.01) var density := 0.5
## Colors to pick from, two or three per sprite (any palette texture). Empty = a random
## hue per sprite, shaded in its own ramp.
@export var palette: Texture2D
## Outline color; alpha 0 = no outline.
@export var outline := Color(0.08, 0.07, 0.12, 1.0)
## Blank pixels kept around the sprite inside each frame (room for the outline).
@export_range(0, 8, 1, "suffix:px") var margin := 1


func _apply(context: BitKilnContext) -> void:
	var size := context.frame_size
	var colors := BitKilnPalette.load_colors(palette) if palette != null else PackedInt32Array()
	var total := context.frames.x * context.frames.y
	for index in total:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(seed + index * 7919)
		var mask := _shape(size, rng)
		var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
		_paint(context.color, origin, size, mask, rng, colors)


## A sprite mask (1 = body) for a frame of [param size].
func _shape(size: Vector2i, rng: RandomNumberGenerator) -> PackedByteArray:
	var w := size.x
	var h := size.y
	var inner := size - Vector2i(margin, margin) * 2 - Vector2i(2, 2) # room for the outline
	var mask := PackedByteArray()
	mask.resize(w * h)
	if inner.x < 2 or inner.y < 2:
		return mask
	var half := Vector2i(ceili(inner.x / 2.0) if mirror != Mirror.VERTICAL else inner.x,
		ceili(inner.y / 2.0) if mirror != Mirror.HORIZONTAL else inner.y)
	var origin := Vector2i(margin + 1, margin + 1)
	for y in half.y:
		for x in half.x:
			# Position in the whole sprite, 0–1, for the density map.
			var u := (x + 0.5) / inner.x
			var v := (y + 0.5) / inner.y
			if rng.randf() >= _density(u, v):
				continue
			for p: Vector2i in _mirrored(Vector2i(x, y), inner):
				mask[(origin.y + p.y) * w + origin.x + p.x] = 1
	_keep_largest(mask, w, h)
	return mask


## How likely a pixel at (u, v) of the sprite (0–1 each) is filled.
func _density(u: float, v: float) -> float:
	var cx := absf(u - 0.5) * 2.0 # 0 at the middle column, 1 at the sides
	var cy := absf(v - 0.5) * 2.0
	var d := 0.0
	match kind:
		Kind.CREATURE:
			d = 1.0 - (cx * cx + cy * cy) * 0.8
			if v > 0.75:
				d = 0.55 if cx > 0.3 else 0.15 # legs, a gap between them
		Kind.SHIP:
			d = clampf(v * 1.3 - cx * (1.2 - v * 0.6), 0.0, 1.0)
			if v > 0.85 and cx < 0.5:
				d = 0.8 # engines
		Kind.ITEM:
			d = 1.0 - pow(cx * cx + cy * cy, 0.75) * 1.1
	return clampf(d * (density / 0.5), 0.0, 0.97)


func _mirrored(p: Vector2i, inner: Vector2i) -> Array[Vector2i]:
	var points: Array[Vector2i] = [p]
	var mx := Vector2i(inner.x - 1 - p.x, p.y)
	var my := Vector2i(p.x, inner.y - 1 - p.y)
	match mirror:
		Mirror.HORIZONTAL:
			points.append(mx)
		Mirror.VERTICAL:
			points.append(my)
		Mirror.BOTH:
			points.append_array([mx, my, Vector2i(inner.x - 1 - p.x, inner.y - 1 - p.y)])
	return points


## Clears everything but the largest group of touching (4-connected) pixels.
static func _keep_largest(mask: PackedByteArray, w: int, h: int) -> void:
	var labels := PackedInt32Array()
	labels.resize(w * h)
	var best_label := 0
	var best_size := 0
	var label := 0
	for start in w * h:
		if not mask[start] or labels[start] != 0:
			continue
		label += 1
		var count := 0
		var stack := PackedInt32Array([start])
		labels[start] = label
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			count += 1
			var x := i % w
			for n: int in [i - 1 if x > 0 else -1, i + 1 if x < w - 1 else -1, i - w, i + w]:
				if n >= 0 and n < w * h and mask[n] and labels[n] == 0:
					labels[n] = label
					stack.append(n)
		if count > best_size:
			best_size = count
			best_label = label
	for i in w * h:
		if labels[i] != best_label:
			mask[i] = 0


func _paint(buffer: BitKilnBuffer, origin: Vector2i, size: Vector2i, mask: PackedByteArray,
		rng: RandomNumberGenerator, colors: PackedInt32Array) -> void:
	var w := size.x
	var h := size.y
	# Body colors: light, base, dark.
	var ramp: Array[int] = []
	if colors.size() >= 2:
		# A base color and its brighter and darker neighbours in the palette.
		var sorted: Array = Array(colors)
		sorted.sort_custom(func(a: int, b: int) -> bool: return _luma(a) < _luma(b))
		var k := rng.randi_range(1, sorted.size() - 2) if sorted.size() >= 3 else 1
		ramp = [sorted[mini(k + 1, sorted.size() - 1)], sorted[k], sorted[k - 1]]
	else:
		var base := Color.from_hsv(rng.randf(), rng.randf_range(0.45, 0.8), rng.randf_range(0.55, 0.85))
		ramp = [
			BitKilnBuffer.from_color(Color.from_hsv(fposmod(base.h - 0.04, 1.0), base.s * 0.8, minf(base.v + 0.2, 1.0))),
			BitKilnBuffer.from_color(base),
			BitKilnBuffer.from_color(Color.from_hsv(fposmod(base.h + 0.06, 1.0), minf(base.s * 1.15, 1.0), base.v * 0.6)),
		]
	var top := h
	var bottom := 0
	for y in h:
		for x in w:
			if mask[y * w + x]:
				top = mini(top, y)
				bottom = maxi(bottom, y)
	var p := buffer.pixels
	for y in h:
		var row := (origin.y + y) * buffer.width + origin.x
		for x in w:
			var i := y * w + x
			if mask[i]:
				var t := float(y - top) / maxf(bottom - top, 1)
				# Lighter at the top, darker at the bottom and along the lower edge.
				var c := ramp[0] if t < 0.3 else (ramp[1] if t < 0.75 else ramp[2])
				if y + 1 < h and not mask[i + w]:
					c = ramp[2]
				p[row + x] = c
			elif outline.a > 0.0 and _touches(mask, x, y, w, h):
				p[row + x] = BitKilnBuffer.from_color(outline)
	if kind == Kind.CREATURE:
		_add_eyes(p, buffer.width, origin, mask, w, h, top, bottom)
	buffer.pixels = p


## Two eyes in the upper third, mirrored, where the body is solid around them.
func _add_eyes(p: PackedInt32Array, stride: int, origin: Vector2i, mask: PackedByteArray, w: int, h: int,
		top: int, bottom: int) -> void:
	var eye_y := top + maxi(1, (bottom - top) / 3)
	for dx in range(1, w / 2):
		var left := w / 2 - dx - (0 if w % 2 == 1 else 1)
		var right := w - 1 - left
		if left < 1 or right >= w - 1 or left == right:
			continue
		var ok := true
		for x: int in [left, right]:
			for o: Vector2i in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx := x + o.x
				var ny := eye_y + o.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h or not mask[ny * w + nx]:
					ok = false
		if ok:
			var eye := BitKilnBuffer.from_color(outline if outline.a > 0.0 else Color.BLACK)
			p[(origin.y + eye_y) * stride + origin.x + left] = eye
			p[(origin.y + eye_y) * stride + origin.x + right] = eye
			return


static func _touches(mask: PackedByteArray, x: int, y: int, w: int, h: int) -> bool:
	for o: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx := x + o.x
		var ny := y + o.y
		if nx >= 0 and ny >= 0 and nx < w and ny < h and mask[ny * w + nx]:
			return true
	return false


static func _luma(c: int) -> int:
	return (c & 0xFF) * 299 + ((c >> 8) & 0xFF) * 587 + ((c >> 16) & 0xFF) * 114
