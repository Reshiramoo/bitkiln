@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnOutline
extends BitKilnOp
## An outline around the sprite, or along the inside of its edge, in whole pixels.
## Shapes match the pixel-perfect outline of Pocket's [code]sprite_fx[/code] shader.
##
## Selective coloring ("sel-out") colors each outline pixel with a darker version of the
## sprite color next to it instead of one flat color, a common pixel-art technique that
## keeps outlines from looking heavy. Put a [BitKilnPad] before an outer outline when the
## sprite touches its frame's edge.

enum Mode {
	OUTER, ## Around the sprite, on empty pixels.
	INNER, ## On the sprite's own edge pixels.
}
enum Shape {
	ROUND, ## Pixels within [member width] (plus a quarter), like a circle.
	SQUARE, ## Includes diagonals: a 1 px square outline fills corners.
	DIAMOND, ## No diagonals at 1 px, the classic pixel-art outline.
}
enum Coloring {
	SOLID, ## Every outline pixel is [member color].
	SELECTIVE, ## Each outline pixel is the nearest sprite color, darkened by [member darken].
}

@export var mode := Mode.OUTER
@export_range(1, 8, 1, "suffix:px") var width := 1
@export var shape := Shape.ROUND
@export var coloring := Coloring.SOLID
@export var color := Color.BLACK
## For selective coloring: 0 = the sprite's own color, 1 = black.
@export_range(0.0, 1.0, 0.01) var darken := 0.5
## Pixels with at least this alpha count as part of the sprite.
@export_range(0.01, 1.0, 0.01) var alpha_threshold := 0.5


func _apply(context: BitKilnContext) -> void:
	var src := context.color
	var dst := src.copy()
	var sp := src.pixels
	var dp := dst.pixels
	var w := src.width
	var size := context.frame_size
	var threshold := roundi(alpha_threshold * 255.0)
	var offsets := shape_offsets(width, shape)
	var solid_color := BitKilnBuffer.from_color(color)
	var keep := 1.0 - darken
	for y in src.height:
		var fy0 := (y / size.y) * size.y
		for x in w:
			var fx0 := (x / size.x) * size.x
			var i := y * w + x
			var solid := (sp[i] >> 24) & 0xFF >= threshold
			if solid == (mode == Mode.OUTER):
				continue
			var found := -1 # index of the neighbour that makes this an outline pixel
			for o: Vector2i in offsets:
				var nx := x + o.x
				var ny := y + o.y
				var inside := nx >= fx0 and ny >= fy0 and nx < fx0 + size.x and ny < fy0 + size.y
				if mode == Mode.OUTER:
					if inside and (sp[ny * w + nx] >> 24) & 0xFF >= threshold:
						found = ny * w + nx
						break
				elif not inside or (sp[ny * w + nx] >> 24) & 0xFF < threshold:
					found = i
					break
			if found < 0:
				continue
			if coloring == Coloring.SOLID:
				dp[i] = BitKilnBuffer.blend(solid_color, sp[i]) if mode == Mode.INNER else solid_color
			else:
				var c := sp[found]
				dp[i] = BitKilnBuffer.pack(roundi((c & 0xFF) * keep), roundi(((c >> 8) & 0xFF) * keep),
					roundi(((c >> 16) & 0xFF) * keep), 255)
	dst.pixels = dp
	context.color = dst


## The offsets within [param radius] for a shape, nearest first.
static func shape_offsets(radius: int, outline_shape: Shape) -> Array[Vector2i]:
	var limit := float(radius) + (0.25 if outline_shape == Shape.ROUND else 0.0)
	var offsets: Array[Vector2i] = []
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if (x != 0 or y != 0) and _shape_distance(Vector2i(x, y), outline_shape) <= limit:
				offsets.append(Vector2i(x, y))
	offsets.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.length_squared() < b.length_squared())
	return offsets


static func _shape_distance(offset: Vector2i, outline_shape: Shape) -> float:
	match outline_shape:
		Shape.SQUARE:
			return maxi(absi(offset.x), absi(offset.y))
		Shape.DIAMOND:
			return absi(offset.x) + absi(offset.y)
	return Vector2(offset).length()
