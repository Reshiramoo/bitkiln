# BitKilnGlow

**Inherits:** [BitKilnOp](BitKilnOp.md)

A halo around the sprite, or around just its bright pixels (eyes, gems, flames, magic). The glow fades out over [radius](#property-radius) pixels in a few crisp rings of decreasing opacity (optionally dithered), the way pixel artists draw halos, instead of a smooth blur. Put a [BitKilnPad](BitKilnPad.md) before it so the halo has room inside the frame.

## Properties

| Type | Name | Default |
|---|---|---|
| [Blend](#enum-blend) | [blend](#property-blend) | `BEHIND` |
| float | [brightness_threshold](#property-brightness_threshold) | `0.8` |
| Color | [color](#property-color) | `Color(1, 0.85, 0.4, 1)` |
| bool | [dither](#property-dither) | `false` |
| [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) | [falloff](#property-falloff) |  |
| float | [intensity](#property-intensity) | `1.0` |
| int | [radius](#property-radius) | `3` |
| int | [rings](#property-rings) | `3` |
| [Source](#enum-source) | [source](#property-source) | `SILHOUETTE` |
| bool | [use_sprite_colors](#property-use_sprite_colors) | `false` |

## Enumerations

<a id="enum-source"></a>
### enum Source

- **SILHOUETTE** = `0`: The whole sprite glows.
- **BRIGHT** = `1`: Only pixels at least [brightness_threshold](#property-brightness_threshold) bright glow.

<a id="enum-blend"></a>
### enum Blend

- **BEHIND** = `0`: The glow sits behind the sprite, like a halo.
- **ADD** = `1`: The glow also lightens the sprite itself, like light spilling over it.

## Property Descriptions

<a id="property-blend"></a>
### [Blend](#enum-blend) blend = `BEHIND`

Whether the glow stays behind the sprite or also lightens it.

---

<a id="property-brightness_threshold"></a>
### float brightness_threshold = `0.8`

For Bright: how bright (0–1) a pixel must be to glow.

---

<a id="property-color"></a>
### Color color = `Color(1, 0.85, 0.4, 1)`

Glow color; its alpha scales the glow's opacity. With [use_sprite_colors](#property-use_sprite_colors), it tints the glowing pixels' own colors instead.

---

<a id="property-dither"></a>
### bool dither = `false`

Pick between two rings with an ordered (Bayer) pattern instead of rounding.

---

<a id="property-falloff"></a>
### [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) falloff

How the opacity fades from the glowing pixels (0) to [radius](#property-radius) (1). Empty = linear.

---

<a id="property-intensity"></a>
### float intensity = `1.0`

Opacity next to the glowing pixels; it fades to nothing at [radius](#property-radius). Above 1 makes the inner rings solid.

---

<a id="property-radius"></a>
### int radius = `3`

How far the glow reaches, in pixels.

---

<a id="property-rings"></a>
### int rings = `3`

Opacity levels the glow snaps to; 0 keeps it smooth.

---

<a id="property-source"></a>
### [Source](#enum-source) source = `SILHOUETTE`

What glows: the whole sprite or its bright pixels.

---

<a id="property-use_sprite_colors"></a>
### bool use_sprite_colors = `false`

Each glowing pixel glows in its own color (multiplied by [color](#property-color)).
