# BitKilnBuffer

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

RGBA8 pixels stored as packed ints, for fast per-pixel work in GDScript.

## Description

A pixel is `r | g << 8 | b << 16 | a << 24` as a signed 32-bit int (the layout of [PackedByteArray.to_int32_array()](https://docs.godotengine.org/en/stable/classes/class_packedbytearray.html#class-packedbytearray-method-to-int32-array) on RGBA8 data). Fully transparent pixels are always `0`, whatever their color, so equal colors compare equal with `==`. Use [pack()](#method-pack) to make pixel values, never shifts by hand.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [height](#property-height) | `0` |
| PackedInt32Array | [pixels](#property-pixels) | `PackedInt32Array()` |
| int | [width](#property-width) | `0` |

## Methods

| Return | Signature |
|---|---|
| int | [alpha](#method-alpha)(c: int) static |
| int | [blend](#method-blend)(top: int, bottom: int) static |
| int | [blue](#method-blue)(c: int) static |
| [BitKilnBuffer](BitKilnBuffer.md) | [copy](#method-copy)() |
| [BitKilnBuffer](BitKilnBuffer.md) | [create](#method-create)(w: int, h: int) static |
| int | [from_color](#method-from_color)(color: Color) static |
| [BitKilnBuffer](BitKilnBuffer.md) | [from_image](#method-from_image)(image: [Image](https://docs.godotengine.org/en/stable/classes/class_image.html)) static |
| PackedInt32Array | [get_colors](#method-get_colors)() |
| int | [get_px](#method-get_px)(x: int, y: int) |
| int | [green](#method-green)(c: int) static |
| int | [pack](#method-pack)(r: int, g: int, b: int, a: int) static |
| int | [red](#method-red)(c: int) static |
| void | [set_px](#method-set_px)(x: int, y: int, value: int) |
| Color | [to_color](#method-to_color)(c: int) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [to_image](#method-to_image)() |
| [ImageTexture](https://docs.godotengine.org/en/stable/classes/class_imagetexture.html) | [to_texture](#method-to_texture)() |
| int | [with_alpha](#method-with_alpha)(c: int, a: int) static |

## Property Descriptions

<a id="property-height"></a>
### int height = `0`

Height in pixels.

---

<a id="property-pixels"></a>
### PackedInt32Array pixels = `PackedInt32Array()`

Row by row, `y * width + x`. Packed arrays are copied on write: to change many pixels, copy it to a local variable, change that, and assign it back.

---

<a id="property-width"></a>
### int width = `0`

Width in pixels.

## Method Descriptions

<a id="method-alpha"></a>
### int alpha(c: int) static

Alpha channel of `c`, 0–255.

---

<a id="method-blend"></a>
### int blend(top: int, bottom: int) static

`top` composited over `bottom` (straight alpha).

---

<a id="method-blue"></a>
### int blue(c: int) static

Blue channel of `c`, 0–255.

---

<a id="method-copy"></a>
### [BitKilnBuffer](BitKilnBuffer.md) copy()

An independent copy.

---

<a id="method-create"></a>
### [BitKilnBuffer](BitKilnBuffer.md) create(w: int, h: int) static

A transparent buffer of `w`×`h` pixels.

---

<a id="method-from_color"></a>
### int from_color(color: Color) static

A Color as a pixel value.

---

<a id="method-from_image"></a>
### [BitKilnBuffer](BitKilnBuffer.md) from_image(image: [Image](https://docs.godotengine.org/en/stable/classes/class_image.html)) static

A copy of `image` converted to RGBA8.

---

<a id="method-get_colors"></a>
### PackedInt32Array get_colors()

Every distinct color, transparent excluded, in order of first appearance.

---

<a id="method-get_px"></a>
### int get_px(x: int, y: int)

The pixel at (`x`, `y`), or `0` (transparent) outside the buffer.

---

<a id="method-green"></a>
### int green(c: int) static

Green channel of `c`, 0–255.

---

<a id="method-pack"></a>
### int pack(r: int, g: int, b: int, a: int) static

A pixel value from 0–255 channels. Alpha 0 gives `0`, whatever the color.

---

<a id="method-red"></a>
### int red(c: int) static

Red channel of `c`, 0–255.

---

<a id="method-set_px"></a>
### void set_px(x: int, y: int, value: int)

Sets the pixel at (`x`, `y`); does nothing outside the buffer.

---

<a id="method-to_color"></a>
### Color to_color(c: int) static

A pixel value as a Color.

---

<a id="method-to_image"></a>
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) to_image()

An RGBA8 [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) of the pixels.

---

<a id="method-to_texture"></a>
### [ImageTexture](https://docs.godotengine.org/en/stable/classes/class_imagetexture.html) to_texture()

An [ImageTexture](https://docs.godotengine.org/en/stable/classes/class_imagetexture.html) of the pixels.

---

<a id="method-with_alpha"></a>
### int with_alpha(c: int, a: int) static

The same color with alpha `a`.
