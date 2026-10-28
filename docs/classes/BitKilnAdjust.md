# BitKilnAdjust

**Inherits:** [BitKilnOp](BitKilnOp.md)

Shifts hue, saturation, brightness and contrast, and can tint toward a color. Every pixel of one color changes the same way, so the result has as many colors as the source. Combine with a mask to recolor one part.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [contrast](#property-contrast) | `0.0` |
| float | [hue](#property-hue) | `0.0` |
| float | [saturation](#property-saturation) | `0.0` |
| Color | [tint](#property-tint) | `Color(1, 1, 1, 0)` |
| float | [value](#property-value) | `0.0` |

## Methods

| Return | Signature |
|---|---|
| int | [adjust](#method-adjust)(c: int) |

## Property Descriptions

<a id="property-contrast"></a>
### float contrast = `0.0`

-1 = flat grey, 0 = unchanged, 1 = twice the contrast (around mid grey).

---

<a id="property-hue"></a>
### float hue = `0.0`

Rotates every hue, in degrees.

---

<a id="property-saturation"></a>
### float saturation = `0.0`

-1 = grey, 0 = unchanged, 1 = twice as saturated.

---

<a id="property-tint"></a>
### Color tint = `Color(1, 1, 1, 0)`

Mixed into every color by its alpha: white with alpha 0 changes nothing.

---

<a id="property-value"></a>
### float value = `0.0`

Added to brightness: -1 = black, 1 = white.

## Method Descriptions

<a id="method-adjust"></a>
### int adjust(c: int)

`c` with this op's changes.
