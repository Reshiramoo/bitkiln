# BitKilnTransform

**Inherits:** [BitKilnOp](BitKilnOp.md)

Flips and turns every frame by quarter turns, without changing any pixel. Normal maps turn with the colors, so lighting stays right. Quarter turns of non-square frames swap the frame's width and height.

## Properties

| Type | Name | Default |
|---|---|---|
| bool | [flip_h](#property-flip_h) | `false` |
| bool | [flip_v](#property-flip_v) | `false` |
| [Turn](#enum-turn) | [turn](#property-turn) | `NONE` |

## Methods

| Return | Signature |
|---|---|
| Vector2i | [source_of](#method-source_of)(dest: Vector2i, size: Vector2i) |
| int | [turn_normal](#method-turn_normal)(c: int) |

## Enumerations

<a id="enum-turn"></a>
### enum Turn

- **NONE** = `0`: No turn.
- **CLOCKWISE** = `1`: A quarter turn clockwise.
- **HALF** = `2`: Half a turn.
- **COUNTERCLOCKWISE** = `3`: A quarter turn counterclockwise.

## Property Descriptions

<a id="property-flip_h"></a>
### bool flip_h = `false`

Mirror left to right (before turning).

---

<a id="property-flip_v"></a>
### bool flip_v = `false`

Mirror top to bottom (before turning).

---

<a id="property-turn"></a>
### [Turn](#enum-turn) turn = `NONE`

Quarter turns, after the flips.

## Method Descriptions

<a id="method-source_of"></a>
### Vector2i source_of(dest: Vector2i, size: Vector2i)

The pixel of a `size` frame that lands at `dest` after the flips and turn.

---

<a id="method-turn_normal"></a>
### int turn_normal(c: int)

A normal map pixel flipped and turned the same way as the image.
