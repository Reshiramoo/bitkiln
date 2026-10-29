# BitKilnRecipe

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

How to turn source images into baked files: a stack of [BitKilnOp](BitKilnOp.md)s and the [BitKilnOutput](BitKilnOutput.md)s to write.

## Description

Every source goes through the same ops and gets its own files, so one recipe can serve a whole set of sprites. Sources are never changed. In the editor, a recipe bakes again by itself when a source changes (see [auto_bake](#property-auto_bake)), so you can keep editing the original art. Without sources, ops start from a blank canvas: generators like [BitKilnShape](BitKilnShape.md) draw on it. Baked files are plain PNGs: exported games don't need BitKiln.

## Properties

| Type | Name | Default |
|---|---|---|
| bool | [auto_bake](#property-auto_bake) | `true` |
| bool | [auto_frames](#property-auto_frames) | `false` |
| Vector2i | [canvas_size](#property-canvas_size) | `Vector2i(16, 16)` |
| Vector2i | [frames](#property-frames) | `Vector2i(1, 1)` |
| Array[[BitKilnOp](BitKilnOp.md)] | [ops](#property-ops) | `[]` |
| Array[[BitKilnOutput](BitKilnOutput.md)] | [outputs](#property-outputs) | `[...]` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [source](#property-source) |  |
| Array[[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)] | [sources](#property-sources) | `[]` |

## Methods

| Return | Signature |
|---|---|
| [BitKilnBaker.Result](BitKilnBaker.Result.md) | [bake](#method-bake)() |
| String | [get_naming_path](#method-get_naming_path)(index: int = 0) |
| int | [get_run_count](#method-get_run_count)() |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [get_source](#method-get_source)(index: int = 0) |
| Array[[BitKilnContext](BitKilnContext.md)] | [run](#method-run)(op_count: int = -1, source_index: int = 0, skip: Array[[BitKilnOp](BitKilnOp.md)] = []) |

## Property Descriptions

<a id="property-auto_bake"></a>
### bool auto_bake = `true`

Bake again whenever a source image (or a palette or texture an op uses) is reimported.

---

<a id="property-auto_frames"></a>
### bool auto_frames = `false`

Guess each source's frame grid instead of using [frames](#property-frames) for all of them, for sources with different layouts.

---

<a id="property-canvas_size"></a>
### Vector2i canvas_size = `Vector2i(16, 16)`

Without sources: the size of one blank frame, in pixels.

---

<a id="property-frames"></a>
### Vector2i frames = `Vector2i(1, 1)`

Columns and rows of frames, for sprite sheets. Ops treat each frame as its own image.

---

<a id="property-ops"></a>
### Array[[BitKilnOp](BitKilnOp.md)] ops = `[]`

Applied in order, top to bottom.

---

<a id="property-outputs"></a>
### Array[[BitKilnOutput](BitKilnOutput.md)] outputs = `[...]`

Files to write when baked, for every source.

---

<a id="property-source"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) source

The first source. Setting it puts it first in [sources](#property-sources). Recipes saved before [sources](#property-sources) existed load into it this way.

---

<a id="property-sources"></a>
### Array[[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)] sources = `[]`

The images to start from, each baked with the same ops into its own files. Their files are read directly, so import settings (compression, mipmaps) don't affect the pixels. Leave it empty to start from a blank canvas of [canvas_size](#property-canvas_size), for generator ops like [BitKilnShape](BitKilnShape.md) to draw on.

## Method Descriptions

<a id="method-bake"></a>
### [BitKilnBaker.Result](BitKilnBaker.Result.md) bake()

Runs the ops on every source and writes the outputs; see [BitKilnBaker.bake()](BitKilnBaker.md#method-bake).

---

<a id="method-get_naming_path"></a>
### String get_naming_path(index: int = 0)

The path outputs of run `index` are named after: its source image's, or without sources the recipe's own, minus a "_kiln" suffix (`res://fx/spark_kiln.tres` names files "spark").

---

<a id="method-get_run_count"></a>
### int get_run_count()

How many times the ops run per bake: once per source, or once for a blank canvas.

---

<a id="method-get_source"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) get_source(index: int = 0)

Source number `index`, skipping empty slots; `null` for a blank canvas.

---

<a id="method-run"></a>
### Array[[BitKilnContext](BitKilnContext.md)] run(op_count: int = -1, source_index: int = 0, skip: Array[[BitKilnOp](BitKilnOp.md)] = [])

Runs the ops on source `source_index` and returns one context per variant; see [BitKilnBaker.run()](BitKilnBaker.md#method-run).
