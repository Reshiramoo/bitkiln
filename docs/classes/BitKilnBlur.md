# BitKilnBlur

**Inherits:** [BitKilnOp](BitKilnOp.md)

Blurs the image, frame by frame: soft shadows, smear frames for fast motion, hazy backgrounds. [alpha_steps](#property-alpha_steps) snaps the soft edges back to a few levels of transparency (optionally dithered), so the result still looks like pixel art; follow it with a [BitKilnQuantize](BitKilnQuantize.md) to bring the colors back into your palette too.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [alpha_steps](#property-alpha_steps) | `3` |
| Vector2 | [direction](#property-direction) | `Vector2(1, 0)` |
| bool | [dither](#property-dither) | `false` |
| [Kind](#enum-kind) | [kind](#property-kind) | `GAUSSIAN` |
| int | [radius](#property-radius) | `2` |

## Enumerations

<a id="enum-kind"></a>
### enum Kind

- **BOX** = `0`: Every pixel within [radius](#property-radius) counts the same.
- **GAUSSIAN** = `1`: Nearer pixels count more: the softest look.
- **MOTION** = `2`: Smeared behind [direction](#property-direction), as if moving fast.

## Property Descriptions

<a id="property-alpha_steps"></a>
### int alpha_steps = `3`

Levels of transparency the soft edges snap to; 0 keeps them smooth.

---

<a id="property-direction"></a>
### Vector2 direction = `Vector2(1, 0)`

For Motion: the direction of movement; the smear trails behind it.

---

<a id="property-dither"></a>
### bool dither = `false`

Pick between two levels with an ordered (Bayer) pattern instead of rounding.

---

<a id="property-kind"></a>
### [Kind](#enum-kind) kind = `GAUSSIAN`

How the blur spreads.

---

<a id="property-radius"></a>
### int radius = `2`

How far the blur reaches, in pixels (the length of the smear for Motion).
