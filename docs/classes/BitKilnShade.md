# BitKilnShade

**Inherits:** [BitKilnOp](BitKilnOp.md)

Shades flat colors the way pixel artists do: a few lighter bands on the side facing the light and darker ones away from it, with hues shifting warm in the light and cool in the shadow ("hue shifting") instead of only getting lighter or darker.

## Description

The shape comes from the normal layer of a [BitKilnNormalMap](BitKilnNormalMap.md) before this op (whose snapping also decides how the bands fall), or from a smooth rounded one made just for shading. Shade before outlining, or the outline gets shaded too. A rim light can add a thin edge of light on the side opposite the light.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [alpha_threshold](#property-alpha_threshold) | `0.5` |
| float | [base_band](#property-base_band) | `0.35` |
| float | [hue_shift](#property-hue_shift) | `10.0` |
| Vector3 | [light_direction](#property-light_direction) | `Vector3(-1, -1, 1)` |
| int | [light_steps](#property-light_steps) | `1` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [palette](#property-palette) |  |
| Color | [rim_color](#property-rim_color) | `Color(1, 1, 1, 0)` |
| Vector2 | [rim_direction](#property-rim_direction) | `Vector2(1, 1)` |
| float | [saturation_shift](#property-saturation_shift) | `0.05` |
| int | [shadow_steps](#property-shadow_steps) | `2` |
| float | [value_step](#property-value_step) | `0.12` |

## Property Descriptions

<a id="property-alpha_threshold"></a>
### float alpha_threshold = `0.5`

Pixels with at least this alpha count as part of the sprite.

---

<a id="property-base_band"></a>
### float base_band = `0.35`

How much of the surface keeps its own color, between the lit and shadow bands (0–1).

---

<a id="property-hue_shift"></a>
### float hue_shift = `10.0`

Hue change per band, in degrees: toward yellow in the light, toward blue in the shadow.

---

<a id="property-light_direction"></a>
### Vector3 light_direction = `Vector3(-1, -1, 1)`

Where the light comes from, as (x right, y down, z toward the viewer): (-1, -1, 1) is from the top left, in front.

---

<a id="property-light_steps"></a>
### int light_steps = `1`

Lighter bands on the lit side.

---

<a id="property-palette"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) palette

When set, every shade snaps to the nearest color of this palette, so shading stays inside your game's colors.

---

<a id="property-rim_color"></a>
### Color rim_color = `Color(1, 1, 1, 0)`

Color of the rim light; alpha 0 turns it off.

---

<a id="property-rim_direction"></a>
### Vector2 rim_direction = `Vector2(1, 1)`

Which edges get the rim, as (x right, y down): (1, 0) is the right side. Usually opposite the light.

---

<a id="property-saturation_shift"></a>
### float saturation_shift = `0.05`

Saturation change per band: lights get less saturated, shadows more.

---

<a id="property-shadow_steps"></a>
### int shadow_steps = `2`

Darker bands on the shadow side.

---

<a id="property-value_step"></a>
### float value_step = `0.12`

Brightness change per band (0–1).
