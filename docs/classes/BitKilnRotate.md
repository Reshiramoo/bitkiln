# BitKilnRotate

**Inherits:** [BitKilnOp](BitKilnOp.md)

Rotates every frame by any angle with RotSprite: the frame is scaled to 8× with Scale2x (three times), then sampled at the rotated positions. Lines stay clean and no new colors appear, unlike ordinary rotation, which smears or breaks pixel art.

## Description

With [directions](#property-directions), one sprite becomes a set facing every direction (8 for top-down characters, 16 for vehicles), either as variants (one file each) or as rows of one sheet.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [angle](#property-angle) | `45.0` |
| int | [directions](#property-directions) | `0` |
| bool | [expand](#property-expand) | `true` |
| [Layout](#enum-layout) | [layout](#property-layout) | `VARIANTS` |

## Methods

| Return | Signature |
|---|---|
| [BitKilnBuffer](BitKilnBuffer.md) | [scale8](#method-scale8)(color: [BitKilnBuffer](BitKilnBuffer.md), context: [BitKilnContext](BitKilnContext.md)) static |

## Enumerations

<a id="enum-layout"></a>
### enum Layout

- **VARIANTS** = `0`: Each direction is its own variant, baked to its own file.
- **ROWS** = `1`: Directions are stacked as rows of one sheet: the frames of direction 0, then direction 1, and so on.

## Property Descriptions

<a id="property-angle"></a>
### float angle = `45.0`

Clockwise, in degrees. With [directions](#property-directions), the first direction's angle.

---

<a id="property-directions"></a>
### int directions = `0`

How many directions to make, evenly around the circle starting at [angle](#property-angle): 8 = every 45°. 0 or 1 = just [angle](#property-angle).

---

<a id="property-expand"></a>
### bool expand = `true`

Grow frames to fit the rotated frame's corners (the same size for every angle, so frames stay aligned). Off: keep the size and cut off what falls outside.

---

<a id="property-layout"></a>
### [Layout](#enum-layout) layout = `VARIANTS`

With several directions: separate variants, or rows of one sheet.

## Method Descriptions

<a id="method-scale8"></a>
### [BitKilnBuffer](BitKilnBuffer.md) scale8(color: [BitKilnBuffer](BitKilnBuffer.md), context: [BitKilnContext](BitKilnContext.md)) static

The color layer at 8×, each frame scaled on its own with Scale2x three times.
