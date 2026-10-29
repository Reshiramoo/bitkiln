# BitKilnBaker

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Runs [BitKilnRecipe](BitKilnRecipe.md)s and writes their outputs.

## Description

[run()](#method-run) only computes, so it works anywhere, including in a running game (for example to recolor a sprite at runtime). [bake()](#method-bake) also saves files, which only makes sense in the editor or a `--headless` script.

## Methods

| Return | Signature |
|---|---|
| [BitKilnBaker.Result](BitKilnBaker.Result.md) | [bake](#method-bake)(recipe: [BitKilnRecipe](BitKilnRecipe.md), before_save: Callable = Callable()) static |
| String | [edit_signature](#method-edit_signature)(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static |
| PackedInt32Array | [empty_frames](#method-empty_frames)(context: [BitKilnContext](BitKilnContext.md)) static |
| String | [fingerprint](#method-fingerprint)(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [load_image_file](#method-load_image_file)(path: String) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [load_source](#method-load_source)(recipe: [BitKilnRecipe](BitKilnRecipe.md), index: int = 0) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [load_texture_image](#method-load_texture_image)(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)) static |
| Array[Dictionary] | [output_groups](#method-output_groups)(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static |
| [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) | [palette_image](#method-palette_image)(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static |
| PackedStringArray | [planned_files](#method-planned_files)(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static |
| Array[[BitKilnContext](BitKilnContext.md)] | [run](#method-run)(recipe: [BitKilnRecipe](BitKilnRecipe.md), op_count: int = -1, source_index: int = 0, skip: Array[[BitKilnOp](BitKilnOp.md)] = []) static |

## Constants

- **IMAGE_EXTENSIONS** = `Array[String](["png", "webp", "jpg", "jpeg", "bmp", "tga", "svg"])`: Image files BitKiln reads directly.

## Method Descriptions

<a id="method-bake"></a>
### [BitKilnBaker.Result](BitKilnBaker.Result.md) bake(recipe: [BitKilnRecipe](BitKilnRecipe.md), before_save: Callable = Callable()) static

Runs the recipe on every source and saves the outputs. Outputs that leave out ops ([BitKilnOutput.skip_ops](BitKilnOutput.md#property-skip_ops)) get their own run; outputs with the same ops share one. `before_save` is called as `(path, index)` before each file is saved, `index` being its place in `Result.files`; the editor uses it to move a file whose path changed, so references to it keep working.

---

<a id="method-edit_signature"></a>
### String edit_signature(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static

Like [fingerprint()](#method-fingerprint), but cheap enough to check many times a second: files count by their modification time instead of their contents. Changes whenever the recipe is edited.

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
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) load_source(recipe: [BitKilnRecipe](BitKilnRecipe.md), index: int = 0) static

Source number `index` of `recipe` as an [Image](https://docs.godotengine.org/en/stable/classes/class_image.html): read from the file itself when it's an image file (exact pixels, whatever the import settings), from the texture otherwise. `null` without that source.

---

<a id="method-load_texture_image"></a>
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) load_texture_image(texture: [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)) static

`texture`'s pixels, from its file when possible. Palettes and other textures ops use go through this too.

---

<a id="method-output_groups"></a>
### Array[Dictionary] output_groups(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static

The recipe's outputs grouped by the ops they leave out: `{"skip": Array[BitKilnOp](BitKilnOp.md), "outputs": Array[BitKilnOutput](BitKilnOutput.md)}` each.

---

<a id="method-palette_image"></a>
### [Image](https://docs.godotengine.org/en/stable/classes/class_image.html) palette_image(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static

Every distinct color of `buffer`, opaque, darkest first, as a one-row image.

---

<a id="method-planned_files"></a>
### PackedStringArray planned_files(recipe: [BitKilnRecipe](BitKilnRecipe.md)) static

Every file `recipe` writes with its current sources, ops and outputs, in the order [bake()](#method-bake) writes them. Runs the ops, since variants decide the files.

---

<a id="method-run"></a>
### Array[[BitKilnContext](BitKilnContext.md)] run(recipe: [BitKilnRecipe](BitKilnRecipe.md), op_count: int = -1, source_index: int = 0, skip: Array[[BitKilnOp](BitKilnOp.md)] = []) static

Runs the recipe's first `op_count` ops (all of them when negative), leaving out the ones in `skip`, on source number `source_index`, and returns one context per variant, or nothing when the source can't be read. Without sources, the ops start from a blank canvas.
