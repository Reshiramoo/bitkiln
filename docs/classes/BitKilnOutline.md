# BitKilnOutline

**Inherits:** [BitKilnOp](BitKilnOp.md)

An outline around the sprite, or along the inside of its edge, in whole pixels. Shapes match the pixel-perfect outline of Pocket's `sprite_fx` shader.

## Description

Selective coloring ("sel-out") colors each outline pixel with a darker version of the sprite color next to it instead of one flat color, a common pixel-art technique that keeps outlines from looking heavy. Put a [BitKilnPad](BitKilnPad.md) before an outer outline when the sprite touches its frame's edge.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [alpha_threshold](#property-alpha_threshold) | `0.5` |
| Color | [color](#property-color) | `Color(0, 0, 0, 1)` |
| [Coloring](#enum-coloring) | [coloring](#property-coloring) | `SOLID` |
| float | [darken](#property-darken) | `0.5` |
| [Mode](#enum-mode) | [mode](#property-mode) | `OUTER` |
| [Shape](#enum-shape) | [shape](#property-shape) | `ROUND` |
| int | [width](#property-width) | `1` |

## Methods

| Return | Signature |
|---|---|
| Array[Vector2i] | [shape_offsets](#method-shape_offsets)(radius: int, outline_shape: [Shape](#enum-shape)) static |

## Enumerations

<a id="enum-mode"></a>
### enum Mode

- **OUTER** = `0`: Around the sprite, on empty pixels.
- **INNER** = `1`: On the sprite's own edge pixels.

<a id="enum-shape"></a>
### enum Shape

- **ROUND** = `0`: Pixels within [width](#property-width) (plus a quarter), like a circle.
- **SQUARE** = `1`: Includes diagonals: a 1 px square outline fills corners.
- **DIAMOND** = `2`: No diagonals at 1 px, the classic pixel-art outline.

<a id="enum-coloring"></a>
### enum Coloring

- **SOLID** = `0`: Every outline pixel is [color](#property-color).
- **SELECTIVE** = `1`: Each outline pixel is the nearest sprite color, darkened by [darken](#property-darken).

## Property Descriptions

<a id="property-alpha_threshold"></a>
### float alpha_threshold = `0.5`

Pixels with at least this alpha count as part of the sprite.

---

<a id="property-color"></a>
### Color color = `Color(0, 0, 0, 1)`

For solid coloring. With alpha below 1, an inner outline blends over the sprite.

---

<a id="property-coloring"></a>
### [Coloring](#enum-coloring) coloring = `SOLID`

One color, or darker versions of the sprite's own colors.

---

<a id="property-darken"></a>
### float darken = `0.5`

For selective coloring: 0 = the sprite's own color, 1 = black.

---

<a id="property-mode"></a>
### [Mode](#enum-mode) mode = `OUTER`

Around the sprite or on its edge.

---

<a id="property-shape"></a>
### [Shape](#enum-shape) shape = `ROUND`

Which neighbours count at each distance; decides whether corners fill.

---

<a id="property-width"></a>
### int width = `1`

Thickness in pixels.

## Method Descriptions

<a id="method-shape_offsets"></a>
### Array[Vector2i] shape_offsets(radius: int, outline_shape: [Shape](#enum-shape)) static

The offsets within `radius` for a shape, nearest first.
