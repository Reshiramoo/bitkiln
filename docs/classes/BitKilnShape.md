# BitKilnShape

**Inherits:** [BitKilnOp](BitKilnOp.md)

Draws a pixel-perfect shape on every frame (or one): ellipses and circles, rectangles, regular polygons, stars and lines, filled and/or outlined. On a recipe without a source it makes sprites from nothing; on a source it adds to the art. Several Shape ops build up icons, particles and UI pieces.

## Description

Shapes are placed around the frame's center. [grow](#property-grow), [move](#property-move) and [spin](#property-spin) change the shape a little on each frame, for simple animations.

## Properties

| Type | Name | Default |
|---|---|---|
| Color | [fill](#property-fill) | `Color(1, 1, 1, 1)` |
| int | [frame](#property-frame) | `-1` |
| Vector2 | [grow](#property-grow) | `Vector2(0, 0)` |
| [Kind](#enum-kind) | [kind](#property-kind) | `ELLIPSE` |
| Vector2 | [line_end](#property-line_end) | `Vector2(4, 4)` |
| int | [line_width](#property-line_width) | `1` |
| Vector2 | [move](#property-move) | `Vector2(0, 0)` |
| Vector2 | [offset](#property-offset) | `Vector2(0, 0)` |
| Color | [outline](#property-outline) | `Color(0, 0, 0, 0)` |
| int | [outline_width](#property-outline_width) | `1` |
| float | [rotation](#property-rotation) | `0.0` |
| int | [sides](#property-sides) | `5` |
| Vector2 | [size](#property-size) | `Vector2(12, 12)` |
| float | [spin](#property-spin) | `0.0` |
| float | [star_inner](#property-star_inner) | `0.5` |

## Methods

| Return | Signature |
|---|---|
| PackedByteArray | [shape_mask](#method-shape_mask)(frame_size: Vector2i, index: int) |

## Enumerations

<a id="enum-kind"></a>
### enum Kind

- **ELLIPSE** = `0`: An ellipse filling [size](#property-size); a circle when it's square.
- **RECTANGLE** = `1`: A rectangle of [size](#property-size).
- **POLYGON** = `2`: A regular polygon with [sides](#property-sides) corners.
- **STAR** = `3`: A star with [sides](#property-sides) tips.
- **LINE** = `4`: A line from [offset](#property-offset) to [line_end](#property-line_end), [line_width](#property-line_width) thick.

## Property Descriptions

<a id="property-fill"></a>
### Color fill = `Color(1, 1, 1, 1)`

Fill color; alpha 0 leaves the inside empty (for rings and outlines only).

---

<a id="property-frame"></a>
### int frame = `-1`

Draw on this frame only (counted row by row from 0); -1 = every frame.

---

<a id="property-grow"></a>
### Vector2 grow = `Vector2(0, 0)`

Added to [size](#property-size) on each frame after the first.

---

<a id="property-kind"></a>
### [Kind](#enum-kind) kind = `ELLIPSE`

Which shape to draw.

---

<a id="property-line_end"></a>
### Vector2 line_end = `Vector2(4, 4)`

For lines: the end, from the frame's center.

---

<a id="property-line_width"></a>
### int line_width = `1`

For lines: thickness, in pixels.

---

<a id="property-move"></a>
### Vector2 move = `Vector2(0, 0)`

Added to [offset](#property-offset) (and [line_end](#property-line_end)) on each frame after the first.

---

<a id="property-offset"></a>
### Vector2 offset = `Vector2(0, 0)`

From the frame's center to the shape's center, in pixels (for lines, the start).

---

<a id="property-outline"></a>
### Color outline = `Color(0, 0, 0, 0)`

Outline color, drawn along the inside of the shape's edge; alpha 0 = none.

---

<a id="property-outline_width"></a>
### int outline_width = `1`

Outline thickness, in pixels.

---

<a id="property-rotation"></a>
### float rotation = `0.0`

Clockwise turn, in degrees (polygons and stars).

---

<a id="property-sides"></a>
### int sides = `5`

Corners of a polygon, or tips of a star.

---

<a id="property-size"></a>
### Vector2 size = `Vector2(12, 12)`

Width and height in pixels (for polygons and stars, of the circle around them).

---

<a id="property-spin"></a>
### float spin = `0.0`

Added to [rotation](#property-rotation) on each frame after the first, in degrees.

---

<a id="property-star_inner"></a>
### float star_inner = `0.5`

For stars: the inner corners' distance from the center, relative to the tips'.

## Method Descriptions

<a id="method-shape_mask"></a>
### PackedByteArray shape_mask(frame_size: Vector2i, index: int)

The shape on frame number `index` of a `frame_size` frame, as a mask.
