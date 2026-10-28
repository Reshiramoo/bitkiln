@tool
class_name BitKilnFilter
extends RefCounted
## Soft image operations for ops like blur and glow: images as premultiplied float
## planes (red, green, blue, alpha), blurred frame by frame, then snapped back to a few
## alpha steps so the result still reads as pixel art.

enum Kernel {
	BOX, ## Every pixel within the radius counts the same.
	GAUSSIAN, ## Nearer pixels count more: the softest look.
}

## 4×4 ordered-dithering thresholds, row by row.
const _BAYER_4: Array[float] = [0.03125, 0.53125, 0.15625, 0.65625, 0.78125, 0.28125, 0.90625, 0.40625,
	0.21875, 0.71875, 0.09375, 0.59375, 0.96875, 0.46875, 0.84375, 0.34375]


## [param buffer] as four premultiplied planes [r, g, b, a], values 0–1.
static func to_planes(buffer: BitKilnBuffer) -> Array[PackedFloat32Array]:
	var n := buffer.pixels.size()
	var r := PackedFloat32Array()
	var g := PackedFloat32Array()
	var b := PackedFloat32Array()
	var a := PackedFloat32Array()
	r.resize(n)
	g.resize(n)
	b.resize(n)
	a.resize(n)
	var p := buffer.pixels
	for i in n:
		var c := p[i]
		if c == 0:
			continue
		var alpha := ((c >> 24) & 0xFF) / 255.0
		r[i] = (c & 0xFF) / 255.0 * alpha
		g[i] = ((c >> 8) & 0xFF) / 255.0 * alpha
		b[i] = ((c >> 16) & 0xFF) / 255.0 * alpha
		a[i] = alpha
	return [r, g, b, a]


## Premultiplied planes back to pixels.
static func from_planes(planes: Array[PackedFloat32Array], w: int, h: int) -> BitKilnBuffer:
	var buffer := BitKilnBuffer.create(w, h)
	var p := buffer.pixels
	var r := planes[0]
	var g := planes[1]
	var b := planes[2]
	var a := planes[3]
	for i in w * h:
		var alpha := a[i]
		if alpha <= 0.0:
			continue
		p[i] = BitKilnBuffer.pack(roundi(r[i] / alpha * 255.0), roundi(g[i] / alpha * 255.0),
			roundi(b[i] / alpha * 255.0), roundi(minf(alpha, 1.0) * 255.0))
	buffer.pixels = p
	return buffer


## Weights for offsets -radius..radius, summing to 1.
static func kernel(kind: Kernel, radius: int) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	weights.resize(radius * 2 + 1)
	var sigma := maxf(radius / 2.0, 0.5)
	var total := 0.0
	for i in weights.size():
		var d := float(i - radius)
		weights[i] = 1.0 if kind == Kernel.BOX else exp(-d * d / (2.0 * sigma * sigma))
		total += weights[i]
	for i in weights.size():
		weights[i] /= total
	return weights


## Every plane blurred with [param weights] across, then down, each frame of
## [param frame] size on its own (outside the frame counts as transparent).
static func blur(planes: Array[PackedFloat32Array], w: int, h: int, frame: Vector2i,
		weights: PackedFloat32Array) -> Array[PackedFloat32Array]:
	var result: Array[PackedFloat32Array] = []
	for plane in planes:
		result.append(_pass(_pass(plane, w, h, frame, weights, true), w, h, frame, weights, false))
	return result


## Every plane smeared along [param direction] over [param length] pixels, trailing
## behind it (motion blur), each frame on its own.
static func smear(planes: Array[PackedFloat32Array], w: int, h: int, frame: Vector2i, direction: Vector2,
		length: int) -> Array[PackedFloat32Array]:
	var step := direction.normalized()
	var offsets: Array[Vector2i] = []
	for k in length + 1:
		offsets.append(Vector2i((-step * k).round()))
	var result: Array[PackedFloat32Array] = []
	var weight := 1.0 / offsets.size()
	for plane in planes:
		var out := PackedFloat32Array()
		out.resize(w * h)
		for y in h:
			var fy0 := (y / frame.y) * frame.y
			for x in w:
				var fx0 := (x / frame.x) * frame.x
				var sum := 0.0
				for o in offsets:
					var sx := x + o.x
					var sy := y + o.y
					if sx >= fx0 and sy >= fy0 and sx < fx0 + frame.x and sy < fy0 + frame.y:
						sum += plane[sy * w + sx]
				out[y * w + x] = sum * weight
		result.append(out)
	return result


## [param alpha] (0–1) snapped to one of [param steps] levels; with [param dither], pixels
## between two levels pick one by an ordered pattern instead of always rounding.
## [param steps] 0 keeps it as is.
static func step_alpha(alpha: float, steps: int, dither: bool, x: int, y: int) -> float:
	if steps <= 0:
		return alpha
	var scaled := clampf(alpha, 0.0, 1.0) * steps
	var threshold := _BAYER_4[(y % 4) * 4 + x % 4] if dither else 0.5
	return clampf(floorf(scaled + threshold), 0.0, steps) / steps


## Changes every pixel's alpha with [method step_alpha], keeping the color.
static func step_planes(planes: Array[PackedFloat32Array], w: int, h: int, steps: int, dither: bool) -> void:
	if steps <= 0:
		return
	var r := planes[0]
	var g := planes[1]
	var b := planes[2]
	var a := planes[3]
	for y in h:
		for x in w:
			var i := y * w + x
			var before := a[i]
			if before <= 0.0:
				continue
			var after := step_alpha(before, steps, dither, x, y)
			var k := after / before
			r[i] *= k
			g[i] *= k
			b[i] *= k
			a[i] = after
	planes.assign([r, g, b, a])


## For every pixel: the distance to the nearest pixel where [param sources] is 1 (0 on a
## source; [code]INF[/code]-like when its frame has none), and that source's index. Two-pass
## chamfer transform with 1 / √2 steps, each frame of [param frame] size on its own.
static func nearest_sources(sources: PackedByteArray, w: int, h: int, frame: Vector2i) -> Array:
	const DIAGONAL := 1.41421356
	var far := float(w + h) * 2.0
	var d := PackedFloat32Array()
	d.resize(w * h)
	var nearest := PackedInt32Array()
	nearest.resize(w * h)
	for i in w * h:
		d[i] = 0.0 if sources[i] else far
		nearest[i] = i if sources[i] else -1
	var forward: Array[Vector3i] = [Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(-1, -1, 1), Vector3i(1, -1, 1)]
	var backward: Array[Vector3i] = [Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(1, 1, 1), Vector3i(-1, 1, 1)]
	for pass_index in 2:
		var offsets := forward if pass_index == 0 else backward
		var ys := range(h) if pass_index == 0 else range(h - 1, -1, -1)
		var xs := range(w) if pass_index == 0 else range(w - 1, -1, -1)
		for y: int in ys:
			var fy0 := (y / frame.y) * frame.y
			for x: int in xs:
				var i := y * w + x
				if d[i] == 0.0:
					continue
				var fx0 := (x / frame.x) * frame.x
				for o in offsets:
					var nx := x + o.x
					var ny := y + o.y
					if nx < fx0 or ny < fy0 or nx >= fx0 + frame.x or ny >= fy0 + frame.y:
						continue
					var n := ny * w + nx
					var candidate := d[n] + (DIAGONAL if o.z == 1 else 1.0)
					if candidate < d[i]:
						d[i] = candidate
						nearest[i] = nearest[n]
	return [d, nearest]


static func _pass(plane: PackedFloat32Array, w: int, h: int, frame: Vector2i, weights: PackedFloat32Array,
		horizontal: bool) -> PackedFloat32Array:
	var radius := (weights.size() - 1) / 2
	var out := PackedFloat32Array()
	out.resize(w * h)
	for y in h:
		var fy0 := (y / frame.y) * frame.y
		for x in w:
			var fx0 := (x / frame.x) * frame.x
			var sum := 0.0
			for k in range(-radius, radius + 1):
				if horizontal:
					var sx := x + k
					if sx >= fx0 and sx < fx0 + frame.x:
						sum += plane[y * w + sx] * weights[k + radius]
				else:
					var sy := y + k
					if sy >= fy0 and sy < fy0 + frame.y:
						sum += plane[sy * w + x] * weights[k + radius]
			out[y * w + x] = sum
	return out

