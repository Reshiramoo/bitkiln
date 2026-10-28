@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnShape
extends BitKilnOp
## Draws a pixel-perfect shape on every frame (or one): ellipses and circles, rectangles,
## regular polygons, stars and lines, filled and/or outlined. On a recipe without a source
## it makes sprites from nothing; on a source it adds to the art. Several Shape ops build
## up icons, particles and UI pieces.
##
## Shapes are placed around the frame's center. [member grow], [member move] and
## [member spin] change the shape a little on each frame, for simple animations.

enum Kind {
	ELLIPSE, ## An ellipse filling [member size]; a circle when it's square.
	RECTANGLE, ## A rectangle of [member size].
	POLYGON, ## A regular polygon with [member sides] corners.
	STAR, ## A star with [member sides] tips.
	LINE, ## A line from [member offset] to [member line_end], [member line_width] thick.
}

## Which shape to draw.
@export var kind := Kind.ELLIPSE
## Width and height in pixels (for polygons and stars, of the circle around them).
@export var size := Vector2(12.0, 12.0)
## From the frame's center to the shape's center, in pixels (for lines, the start).
@export var offset := Vector2.ZERO
## Fill color; alpha 0 leaves the inside empty (for rings and outlines only).
@export var fill := Color(1.0, 1.0, 1.0, 1.0)
## Outline color, drawn along the inside of the shape's edge; alpha 0 = none.
@export var outline := Color(0.0, 0.0, 0.0, 0.0)
## Outline thickness, in pixels.
@export_range(1, 16, 1, "suffix:px") var outline_width := 1
## Corners of a polygon, or tips of a star.
@export_range(3, 32, 1) var sides := 5
## For stars: the inner corners' distance from the center, relative to the tips'.
@export_range(0.05, 1.0, 0.01) var star_inner := 0.5
## Clockwise turn, in degrees (polygons and stars).
@export_range(-360.0, 360.0, 0.5, "suffix:°") var rotation := 0.0
## For lines: the end, from the frame's center.
@export var line_end := Vector2(4.0, 4.0)
## For lines: thickness, in pixels.
@export_range(1, 16, 1, "suffix:px") var line_width := 1

@export_group("Animation")
## Draw on this frame only (counted row by row from 0); -1 = every frame.
@export_range(-1, 1024, 1) var frame := -1
## Added to [member size] on each frame after the first.
@export var grow := Vector2.ZERO
## Added to [member offset] (and [member line_end]) on each frame after the first.
@export var move := Vector2.ZERO
## Added to [member rotation] on each frame after the first, in degrees.
@export var spin := 0.0
@export_group("")


func _apply(context: BitKilnContext) -> void:
	var size_px := context.frame_size
	var total := context.frames.x * context.frames.y
	for index in total:
		if frame >= 0 and index != frame:
			continue
		var mask := shape_mask(size_px, index)
		var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size_px
		if fill.a > 0.0:
			BitKilnRaster.paint(context.color, origin, mask, size_px.x, size_px.y, BitKilnBuffer.from_color(fill))
		if outline.a > 0.0:
			var edge := BitKilnRaster.edge(mask, size_px.x, size_px.y, outline_width)
			BitKilnRaster.paint(context.color, origin, edge, size_px.x, size_px.y, BitKilnBuffer.from_color(outline))


## The shape on frame number [param index] of a [param frame_size] frame, as a mask.
func shape_mask(frame_size: Vector2i, index: int) -> PackedByteArray:
	var w := frame_size.x
	var h := frame_size.y
	var center := Vector2(frame_size) * 0.5 + offset + move * index
	var s := (size + grow * index).maxf(0.0)
	var turn := rotation + spin * index
	match kind:
		Kind.RECTANGLE:
			return BitKilnRaster.rectangle(w, h, Rect2(center - s * 0.5, s))
		Kind.POLYGON:
			return BitKilnRaster.polygon(w, h, BitKilnRaster.regular_polygon(center, s * 0.5, sides, turn))
		Kind.STAR:
			return BitKilnRaster.polygon(w, h, BitKilnRaster.star(center, s * 0.5, sides, star_inner, turn))
		Kind.LINE:
			var end := Vector2(frame_size) * 0.5 + line_end + move * index
			return BitKilnRaster.line(w, h, Vector2i(center.floor()), Vector2i(end.floor()), line_width)
	return BitKilnRaster.ellipse(w, h, Rect2(center - s * 0.5, s))
