# BitKilnOverlay

**Inherits:** [BitKilnOp](BitKilnOp.md)

Draws a texture on top of the image (or behind it): stickers and accessories, damage and dirt, patterns and cloth textures, light and shade drawn by hand, backgrounds.

## Description

The texture is placed in every frame at its own size (no blurry scaling), at [align](#property-align) plus [offset](#property-offset), tiled across the frame, or stretched to it pixel by pixel. A texture cut into [texture_frames](#property-texture_frames) puts its frames on the image's frames in turn, so an animated overlay follows an animated sheet. Blend modes other than Normal and Behind only change pixels the image already has, keeping its shape.

## Properties

| Type | Name | Default |
|---|---|---|
| Vector2 | [align](#property-align) | `Vector2(0.5, 0.5)` |
| [Blend](#enum-blend) | [blend](#property-blend) | `NORMAL` |
| bool | [clip_to_sprite](#property-clip_to_sprite) | `false` |
| bool | [dither](#property-dither) | `true` |
| int | [frame](#property-frame) | `-1` |
| [Layer](#enum-layer) | [layer](#property-layer) | `COLOR` |
| Vector2i | [offset](#property-offset) | `Vector2i(0, 0)` |
| float | [opacity](#property-opacity) | `1.0` |
| [Placement](#enum-placement) | [placement](#property-placement) | `PLACE` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [texture](#property-texture) |  |
| Vector2i | [texture_frames](#property-texture_frames) | `Vector2i(1, 1)` |

## Methods

| Return | Signature |
|---|---|
| int | [mix](#method-mix)(top: int, bottom: int, mode: [Blend](#enum-blend), clip: bool = false) static |

## Enumerations

<a id="enum-placement"></a>
### enum Placement

- **PLACE** = `0`: Once per frame, at [align](#property-align) and [offset](#property-offset).
- **TILE** = `1`: Repeated across the frame, starting at [offset](#property-offset).
- **STRETCH** = `2`: Scaled to the frame's size, nearest neighbour.

<a id="enum-blend"></a>
### enum Blend

- **NORMAL** = `0`: Covers the image.
- **BEHIND** = `1`: Goes behind the image: backgrounds, glows, platforms.
- **MULTIPLY** = `2`: Darkens the image's pixels: shading, dirt, patterns.
- **SCREEN** = `3`: Lightens the image's pixels.
- **OVERLAY** = `4`: Darkens the dark parts and lightens the light parts: texture and contrast.
- **ADD** = `5`: Adds light to the image's pixels.

<a id="enum-layer"></a>
### enum Layer

- **COLOR** = `0`: The colors.
- **NORMAL** = `1`: The normal map from a [BitKilnNormalMap](BitKilnNormalMap.md), for adding surface detail by hand.

## Property Descriptions

<a id="property-align"></a>
### Vector2 align = `Vector2(0.5, 0.5)`

Where the texture goes in the frame: (0, 0) top left, (0.5, 0.5) centered, (0.5, 1) bottom middle. The same point of the texture lands there.

---

<a id="property-blend"></a>
### [Blend](#enum-blend) blend = `NORMAL`

How the texture combines with the image.

---

<a id="property-clip_to_sprite"></a>
### bool clip_to_sprite = `false`

For Normal: only draw over the image's own pixels, keeping its shape (a clipping mask).

---

<a id="property-dither"></a>
### bool dither = `true`

Below full opacity, draw whole pixels in an ordered pattern instead of mixing colors, so no new colors appear.

---

<a id="property-frame"></a>
### int frame = `-1`

Draw on this frame only (counted row by row from 0); -1 = every frame.

---

<a id="property-layer"></a>
### [Layer](#enum-layer) layer = `COLOR`

Which layer to draw on.

---

<a id="property-offset"></a>
### Vector2i offset = `Vector2i(0, 0)`

Moves the texture, in pixels: (1, 0) is one pixel right.

---

<a id="property-opacity"></a>
### float opacity = `1.0`

How strongly the texture shows, 0–1.

---

<a id="property-placement"></a>
### [Placement](#enum-placement) placement = `PLACE`

How the texture is laid out in each frame.

---

<a id="property-texture"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) texture

The image to draw.

---

<a id="property-texture_frames"></a>
### Vector2i texture_frames = `Vector2i(1, 1)`

Columns and rows of [texture](#property-texture). Frame 1 of the image gets the texture's frame 1, frame 2 its frame 2, and so on, starting over when the texture has fewer frames.

## Method Descriptions

<a id="method-mix"></a>
### int mix(top: int, bottom: int, mode: [Blend](#enum-blend), clip: bool = false) static

`top` combined with `bottom` by `mode` (see [Blend](https://docs.godotengine.org/en/stable/classes/class_blend.html)(#enum-blend)). `clip` keeps Normal inside `bottom`'s pixels.
