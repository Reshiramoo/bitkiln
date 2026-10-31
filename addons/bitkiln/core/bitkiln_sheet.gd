@tool
class_name BitKilnSheet
extends RefCounted
## Helpers for sprite sheets.


## A likely frame grid (columns, rows) for [param image]: the most frames such that no
## sprite (a group of touching pixels) is cut by a frame edge and every frame fits the
## largest sprite. Images with nothing to go on give (1, 1).
static func guess_frames(image: Image) -> Vector2i:
	if image == null or image.is_empty():
		return Vector2i.ONE
	var buffer := BitKilnBuffer.from_image(image)
	var islands := island_bounds(buffer)
	if islands.is_empty():
		return Vector2i.ONE
	return Vector2i(_guess_axis(buffer.width, islands, true), _guess_axis(buffer.height, islands, false))


## Bounding boxes of every group of touching (8-connected) non-transparent pixels.
static func island_bounds(buffer: BitKilnBuffer) -> Array[Rect2i]:
	var w := buffer.width
	var h := buffer.height
	var p := buffer.pixels
	var seen := PackedByteArray()
	seen.resize(w * h)
	var result: Array[Rect2i] = []
	var stack := PackedInt32Array()
	for start in w * h:
		if p[start] == 0 or seen[start]:
			continue
		var lo := Vector2i(start % w, start / w)
		var hi := lo
		seen[start] = 1
		stack.append(start)
		while not stack.is_empty():
			var i := stack[stack.size() - 1]
			stack.resize(stack.size() - 1)
			var x := i % w
			var y := i / w
			lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
			hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var n := ny * w + nx
					if p[n] != 0 and not seen[n]:
						seen[n] = 1
						stack.append(n)
		result.append(Rect2i(lo, hi - lo + Vector2i.ONE))
	return result


## Most cells along one axis whose edges cut no island and fit the widest one.
static func _guess_axis(length: int, islands: Array[Rect2i], horizontal: bool) -> int:
	var widest := 0
	for island in islands:
		widest = maxi(widest, island.size.x if horizontal else island.size.y)
	for count in range(length, 1, -1):
		if length % count != 0:
			continue
		var cell := length / count
		if cell < widest:
			continue
		var fits := true
		for island in islands:
			var start := island.position.x if horizontal else island.position.y
			var end := start + (island.size.x if horizontal else island.size.y) - 1
			if start / cell != end / cell:
				fits = false
				break
		if fits:
			return count
	return 1
