# BitKilnRecipe

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

How to turn a source image into baked files: a stack of [BitKilnOp](BitKilnOp.md)s and the [BitKilnOutput](BitKilnOutput.md)s to write.

## Description

The source is never changed. In the editor, a recipe bakes again by itself when its source changes (see [auto_bake](#property-auto_bake)), so you can keep editing the original art. Baked files are plain PNGs: exported games don't need BitKiln.

## Properties

| Type | Name | Default |
|---|---|---|
| bool | [auto_bake](#property-auto_bake) | `true` |
| Vector2i | [frames](#property-frames) | `Vector2i(1, 1)` |
| Array[[BitKilnOp](BitKilnOp.md)] | [ops](#property-ops) | `[]` |
| Array[[BitKilnOutput](BitKilnOutput.md)] | [outputs](#property-outputs) | `[...]` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [source](#property-source) |  |

## Methods

| Return | Signature |
|---|---|
| [BitKilnBaker.Result](BitKilnBaker.Result.md) | [bake](#method-bake)() |
| Array[[BitKilnContext](BitKilnContext.md)] | [run](#method-run)(op_count: int = -1) |

## Property Descriptions

<a id="property-auto_bake"></a>
### bool auto_bake = `true`

Bake again whenever the source image (or a palette or texture an op uses) is reimported.

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

Files to write when baked.

---

<a id="property-source"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) source

The image to start from. Its file is read directly, so import settings (compression, mipmaps) don't affect the pixels.

## Method Descriptions

<a id="method-bake"></a>
### [BitKilnBaker.Result](BitKilnBaker.Result.md) bake()

Runs the ops and writes the outputs; see [BitKilnBaker.bake()](BitKilnBaker.md#method-bake).

---

<a id="method-run"></a>
### Array[[BitKilnContext](BitKilnContext.md)] run(op_count: int = -1)

Runs the ops and returns one context per variant; see [BitKilnBaker.run()](BitKilnBaker.md#method-run).
