# BitKilnRamp

**Inherits:** [BitKilnOp](BitKilnOp.md)

Draws color ramps for building palettes: from each base color, darker shades that shift toward blue and lighter ones that shift toward yellow, the way pixel artists build ramps by hand ("hue shifting"). One ramp per row, one pixel per color. Use it on a recipe without a source, with a Palette output to save the result, or as the base palette for [BitKilnShade](BitKilnShade.md), [BitKilnQuantize](BitKilnQuantize.md) and [BitKilnRandomSprite](BitKilnRandomSprite.md).

## Properties

| Type | Name | Default |
|---|---|---|
| PackedColorArray | [base_colors](#property-base_colors) | `PackedColorArray(...)` |
| int | [darker](#property-darker) | `2` |
| float | [hue_shift](#property-hue_shift) | `12.0` |
| int | [lighter](#property-lighter) | `2` |
| float | [saturation_shift](#property-saturation_shift) | `0.06` |
| float | [value_step](#property-value_step) | `0.13` |

## Methods

| Return | Signature |
|---|---|
| PackedColorArray | [make_ramp](#method-make_ramp)(base: Color) |
| Color | [shade](#method-shade)(base: Color, steps: int) |

## Property Descriptions

<a id="property-base_colors"></a>
### PackedColorArray base_colors = `PackedColorArray(...)`

One ramp per color, each on its own row.

---

<a id="property-darker"></a>
### int darker = `2`

Darker shades before each base color.

---

<a id="property-hue_shift"></a>
### float hue_shift = `12.0`

Hue change per shade, in degrees: toward blue going darker, toward yellow going lighter.

---

<a id="property-lighter"></a>
### int lighter = `2`

Lighter shades after each base color.

---

<a id="property-saturation_shift"></a>
### float saturation_shift = `0.06`

Saturation change per shade: darker shades get more saturated, lighter ones less.

---

<a id="property-value_step"></a>
### float value_step = `0.13`

Brightness change per shade (0–1).

## Method Descriptions

<a id="method-make_ramp"></a>
### PackedColorArray make_ramp(base: Color)

The ramp around `base`, darkest first.

---

<a id="method-shade"></a>
### Color shade(base: Color, steps: int)

`base` moved `steps` shades lighter (positive) or darker (negative).
