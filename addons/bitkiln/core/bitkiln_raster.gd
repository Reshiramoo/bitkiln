@tool
class_name BitKilnRaster
extends RefCounted
## Pixel-perfect shapes for generator ops, as masks: one byte per pixel of a
## [code]w[/code]×[code]h[/code] area, 1 inside. A pixel is inside a shape when its center
## is, which gives the symmetric, hand-drawn-looking circles and polygons of pixel art.


## A filled ellipse inside [param rect] (pixel coordinates, fractional allowed).
static func ellipse(w: int, h: int, rect: Rect2) -> PackedByteArray:
	var mask := _empty(w, h)
	var center := rect.get_center()
	var radius := rect.size * 0.5
	if radius.x <= 0.0 or radius.y <= 0.0:
		return mask
	for y in range(maxi(0, floori(rect.position.y)), mini(h, ceili(rect.end.y))):
		var dy := (y + 0.5 - center.y) / radius.y
		for x in range(maxi(0, floori(rect.position.x)), mini(w, ceili(rect.end.x))):
			var dx := (x + 0.5 - center.x) / radius.x
			if dx * dx + dy * dy <= 1.0:
				mask[y * w + x] = 1
	return mask


## A filled rectangle.
static func rectangle(w: int, h: int, rect: Rect2) -> PackedByteArray:
	var mask := _empty(w, h)
	for y in range(maxi(0, roundi(rect.position.y)), mini(h, roundi(rect.end.y))):
		for x in range(maxi(0, roundi(rect.position.x)), mini(w, roundi(rect.end.x))):
			mask[y * w + x] = 1
	return mask


## A filled polygon (even-odd rule).
static func polygon(w: int, h: int, points: PackedVector2Array) -> PackedByteArray:
	var mask := _empty(w, h)
	if points.size() < 3:
		return mask
	var lo := points[0]
	var hi := points[0]
	for p in points:
		lo = lo.min(p)
		hi = hi.max(p)
	for y in range(maxi(0, floori(lo.y)), mini(h, ceili(hi.y) + 1)):
		var py := y + 0.5
		for x in range(maxi(0, floori(lo.x)), mini(w, ceili(hi.x) + 1)):
			var px := x + 0.5
			var inside := false
			var j := points.size() - 1
			for i in points.size():
				var a := points[i]
				var b := points[j]
				if (a.y > py) != (b.y > py) and px < (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x:
					inside = not inside
				j = i
			if inside:
				mask[y * w + x] = 1
	return mask


## Corners of a regular polygon around [param center] (first corner straight up, turned
## clockwise by [param degrees]).
static func regular_polygon(center: Vector2, radius: Vector2, sides: int, degrees := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var a := deg_to_rad(degrees) + TAU * i / sides - PI / 2.0
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	return points


## Points of a star: [param tips] outer points, inner corners at [param inner] of the radius.
static func star(center: Vector2, radius: Vector2, tips: int, inner: float, degrees := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in tips * 2:
		var a := deg_to_rad(degrees) + PI * i / tips - PI / 2.0
		points.append(center + Vector2(cos(a), sin(a)) * radius * (1.0 if i % 2 == 0 else inner))
	return points


## A line from [param from] to [param to] (Bresenham, pixel coordinates) drawn with a
## square brush [param width] pixels wide.
static func line(w: int, h: int, from: Vector2i, to: Vector2i, width := 1) -> PackedByteArray:
	var mask := _empty(w, h)
	var d := (to - from).abs()
	var step := Vector2i(1 if to.x > from.x else -1, 1 if to.y > from.y else -1)
	var error := d.x - d.y
	var p := from
	var lo := -(width - 1) / 2
	var hi := width / 2
	while true:
		for by in range(lo, hi + 1):
			for bx in range(lo, hi + 1):
				var x := p.x + bx
				var y := p.y + by
				if x >= 0 and y >= 0 and x < w and y < h:
					mask[y * w + x] = 1
		if p == to:
			break
		var e2 := error * 2
		if e2 > -d.y:
			error -= d.y
			p.x += step.x
		if e2 < d.x:
			error += d.x
			p.y += step.y
	return mask


## The pixels of [param mask] within [param width] pixels of its edge (4-neighbour steps):
## an inner outline.
static func edge(mask: PackedByteArray, w: int, h: int, width := 1) -> PackedByteArray:
	var result := _empty(w, h)
	var current := mask.duplicate()
	for step in width:
		var next := current.duplicate()
		for y in h:
			for x in w:
				var i := y * w + x
				if not current[i]:
					continue
				if x == 0 or y == 0 or x == w - 1 or y == h - 1 or not current[i - 1] or not current[i + 1] \
						or not current[i - w] or not current[i + w]:
					result[i] = 1
					next[i] = 0
		current = next
	return result


## Draws [param color] over [param buffer] where [param mask] (frame-sized) is set, in the
## frame whose top-left corner is [param origin].
static func paint(buffer: BitKilnBuffer, origin: Vector2i, mask: PackedByteArray, w: int, h: int, color: int) -> void:
	if (color >> 24) & 0xFF == 0:
		return
	var p := buffer.pixels
	for y in h:
		var row := (origin.y + y) * buffer.width + origin.x
		for x in w:
			if mask[y * w + x]:
				p[row + x] = BitKilnBuffer.blend(color, p[row + x])
	buffer.pixels = p


static func _empty(w: int, h: int) -> PackedByteArray:
	var mask := PackedByteArray()
	mask.resize(w * h)
	return mask
