# BitKilnBaker

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Runs [BitKilnRecipe](BitKilnRecipe.md)s and writes their outputs.

## Description

[run()](#method-run) only computes, so it works anywhere, including in a running game (for example to recolor a sprite at runtime). [bake()](#method-bake) also saves files, which only makes sense in the editor or a `--headless` script.

## Methods

| Return | Signature |
|---|---|
| [BitKilnBaker.Result](BitKilnBaker.Result.md) | [bake](#method-bake)(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static |
| PackedInt32Array | [empty_frames](#method-empty_frames)(context: [BitKilnContext](BitKilnContext.md)) static |
| String | [fingerprint](#method-fingerprint)(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [load_image_file](#method-load_image_file)(path: String) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [load_source](#method-load_source)(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [load_texture_image](#method-load_texture_image)(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [palette_image](#method-palette_image)(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static |
| Array[[BitKilnContext](BitKilnContext.md)] | [run](#method-run)(recipe: [BitKilnRecipe](BitKilnRecipe.md), op_count: int = -1) static |

## Constants

- **IMAGE_EXTENSIONS** = `Array[String](["png", "webp", "jpg", "jpeg", "bmp", "tga", "svg"])`: Image files BitKiln reads directly.

## Method Descriptions

<a id="method-bake"></a>
### [BitKilnBaker.Result](BitKilnBaker.Result.md) bake(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static

Runs the recipe and saves its outputs.

---

<a id="method-empty_frames"></a>
### PackedInt32Array empty_frames(context: [BitKilnContext](BitKilnContext.md)) static

Indices (row by row) of `context`'s frames with no visible pixels.

---

<a id="method-fingerprint"></a>
### String fingerprint(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static

Changes whenever anything that affects the result changes: the source file, the ops (and their scripts), files they use, and the outputs.

---

<a id="method-load_image_file"></a>
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) load_image_file(path: String) static

The image file at `path` decoded as is, or `null` when it isn't a readable image file (exported games only have the imported versions).

---

<a id="method-load_source"></a>
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) load_source(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static

The recipe's source as an [Image](https://docs.godotengine.org/en/stable/classes/class_image.html): read from the file itself when it's an image file (exact pixels, whatever the import settings), from the texture otherwise.

---

<a id="method-load_texture_image"></a>
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) load_texture_image(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)) static

`texture`'s pixels, from its file when possible. Palettes and other textures ops use go through this too.

---

<a id="method-palette_image"></a>
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) palette_image(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static

Every distinct color of `buffer`, opaque, darkest first, as a one-row image.

---

<a id="method-run"></a>
### Array[[BitKilnContext](BitKilnContext.md)] run(recipe: [BitKilnRecipe](BitKilnRecipe.md), op_count: int = -1) static

Runs the recipe's first `op_count` ops (all of them when negative) and returns one context per variant, or nothing when the source can't be read. Without a source, the ops start from a blank canvas.
