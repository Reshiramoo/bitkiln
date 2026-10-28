# BitKilnQuantize

**Inherits:** [BitKilnOp](BitKilnOp.md)

Snaps every color to the nearest color of a palette, optionally with ordered (Bayer) dithering. Good for cleaning up art that was painted or scaled with soft brushes, and for keeping effects like glows inside your game's palette.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [alpha_threshold](#property-alpha_threshold) | `0.5` |
| [Dither](#enum-dither) | [dither](#property-dither) | `NONE` |
| float | [dither_strength](#property-dither_strength) | `0.5` |
| bool | [hard_alpha](#property-hard_alpha) | `true` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [palette](#property-palette) |  |

## Methods

| Return | Signature |
|---|---|
| PackedFloat32Array | [bayer_matrix](#method-bayer_matrix)(n: int) static |

## Enumerations

<a id="enum-dither"></a>
### enum Dither

- **NONE** = `0`: Each pixel takes its nearest palette color.
- **BAYER_2** = `1`: 2×2 pattern: coarse checkerboard.
- **BAYER_4** = `2`: 4×4 pattern.
- **BAYER_8** = `3`: 8×8 pattern: the finest gradients.

## Property Descriptions

<a id="property-alpha_threshold"></a>
### float alpha_threshold = `0.5`

With [hard_alpha](#property-hard_alpha): pixels with at least this alpha become opaque.

---

<a id="property-dither"></a>
### [Dither](#enum-dither) dither = `NONE`

Ordered dithering pattern, for gradients that would otherwise band.

---

<a id="property-dither_strength"></a>
### float dither_strength = `0.5`

How far dithering may push a color before snapping it.

---

<a id="property-hard_alpha"></a>
### bool hard_alpha = `true`

Make every pixel fully opaque or fully transparent, as most pixel art is.

---

<a id="property-palette"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) palette

Every distinct color in this image is a palette color (any size; a Lospec palette imported by BitKiln works). Transparent pixels are ignored.

## Method Descriptions

<a id="method-bayer_matrix"></a>
### PackedFloat32Array bayer_matrix(n: int) static

Thresholds 0–1 of an `n`×`n` Bayer matrix (n a power of two), row by row.
