# BitKilnPalette

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Reads palettes from textures: a row of colors per palette, as in Pocket's palette swap images and Lospec palettes imported by BitKiln (`.hex`, `.gpl`).

## Methods

| Return | Signature |
|---|---|
| float | [distance](#method-distance)(a: int, b: int) static |
| PackedInt32Array | [load_colors](#method-load_colors)(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html), row: int = -1) static |
| int | [nearest](#method-nearest)(c: int, palette: PackedInt32Array) static |
| int | [row_count](#method-row_count)(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)) static |

## Method Descriptions

<a id="method-distance"></a>
### float distance(a: int, b: int) static

Squared distance between two colors, weighted for how the eye sees them ("redmean"); alpha counts fully.

---

<a id="method-load_colors"></a>
### PackedInt32Array load_colors(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html), row: int = -1) static

The colors in row `row` of `texture`, left to right, transparent pixels skipped. With `row` negative: every distinct color, row by row.

---

<a id="method-nearest"></a>
### int nearest(c: int, palette: PackedInt32Array) static

The index of the color in `palette` closest to `c`.

---

<a id="method-row_count"></a>
### int row_count(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)) static

Rows in `texture`'s image.
