# BitKilnContext

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

What a [BitKilnRecipe](BitKilnRecipe.md)'s ops work on: the image layers of one variant, and the frame grid they're cut into.

## Description

Every layer has the same size. [frames](#property-frames) splits them into equal cells; ops treat cell edges like image edges, so outlines, shadows and normals never reach into the neighbouring frame. Ops that change the size (padding, trimming, scaling) change every layer at once through [remap_frames()](#method-remap_frames) or [scale_nearest()](#method-scale_nearest).

## Properties

| Type | Name | Default |
|---|---|---|
| [BitKilnBuffer](BitKilnBuffer.md) | [color](#property-color) |  |
| Vector2i | [frame_size](#property-frame_size) |  |
| Vector2i | [frames](#property-frames) | `Vector2i(1, 1)` |
| int | [height](#property-height) |  |
| Dictionary | [layers](#property-layers) | `{}` |
| Dictionary | [meta](#property-meta) | `{}` |
| Vector2i | [source_frame_size](#property-source_frame_size) | `Vector2i(1, 1)` |
| Vector2 | [source_offset](#property-source_offset) | `Vector2(0, 0)` |
| String | [source_path](#property-source_path) | `""` |
| Vector2 | [source_scale](#property-source_scale) | `Vector2(1, 1)` |
| String | [variant](#property-variant) | `""` |
| PackedStringArray | [warnings](#property-warnings) | `[]` |
| int | [width](#property-width) |  |

## Methods

| Return | Signature |
|---|---|
| [BitKilnContext](BitKilnContext.md) | [copy](#method-copy)() |
| [BitKilnContext](BitKilnContext.md) | [create](#method-create)(image: [Image](https://docs.godotengine.org/en/stable/classes/class_image.html), frame_grid: Vector2i = Vector2i(1, 1)) static |
| [BitKilnBuffer](BitKilnBuffer.md) | [get_layer](#method-get_layer)(layer_name: StringName) |
| bool | [has_layer](#method-has_layer)(layer_name: StringName) |
| void | [remap_frames](#method-remap_frames)(new_frame_size: Vector2i, offset: Vector2i) |
| void | [reset_source_mapping](#method-reset_source_mapping)() |
| [BitKilnBuffer](BitKilnBuffer.md) | [scale_buffer](#method-scale_buffer)(src: [BitKilnBuffer](BitKilnBuffer.md), factor: int) static |
| void | [scale_nearest](#method-scale_nearest)(factor: int) |
| Vector2i | [to_source](#method-to_source)(local: Vector2i) |
| void | [warn](#method-warn)(message: String) |

## Constants

- **COLOR** = `&"color"`: Name of the color layer.
- **NORMAL** = `&"normal"`: Name of the normal map layer.

## Property Descriptions

<a id="property-color"></a>
### [BitKilnBuffer](BitKilnBuffer.md) color

The color layer.

---

<a id="property-frame_size"></a>
### Vector2i frame_size

Size of one frame in pixels.

---

<a id="property-frames"></a>
### Vector2i frames = `Vector2i(1, 1)`

Columns and rows of frames.

---

<a id="property-height"></a>
### int height

Height of every layer, in pixels.

---

<a id="property-layers"></a>
### Dictionary layers = `{}`

Layer name -> [BitKilnBuffer](BitKilnBuffer.md). `color` always exists; `normal` once a [BitKilnNormalMap](BitKilnNormalMap.md) has run.

---

<a id="property-meta"></a>
### Dictionary meta = `{}`

Extra data ops pass to outputs, e.g. `"autotile_masks"` from [BitKilnAutotile](BitKilnAutotile.md) for TileSet outputs. Copied with the context.

---

<a id="property-source_frame_size"></a>
### Vector2i source_frame_size = `Vector2i(1, 1)`

Size of one frame of the source image, before any op.

---

<a id="property-source_offset"></a>
### Vector2 source_offset = `Vector2(0, 0)`

Where the source frame's top-left corner is in the current frame, in current pixels. Padding and trimming move it; with [source_scale](#property-source_scale), it maps current pixels back to the source (see [to_source()](#method-to_source)), which is how masks follow the art.

---

<a id="property-source_path"></a>
### String source_path = `""`

The recipe's source image path, for messages.

---

<a id="property-source_scale"></a>
### Vector2 source_scale = `Vector2(1, 1)`

Current pixels per source pixel. Scaling multiplies it.

---

<a id="property-variant"></a>
### String variant = `""`

The variant's name, e.g. a palette's file name; empty for the main one.

---

<a id="property-warnings"></a>
### PackedStringArray warnings = `[]`

Messages collected while baking, shown in the BitKiln dock.

---

<a id="property-width"></a>
### int width

Width of every layer, in pixels.

## Method Descriptions

<a id="method-copy"></a>
### [BitKilnContext](BitKilnContext.md) copy()

A deep copy, for ops that split one context into variants.

---

<a id="method-create"></a>
### [BitKilnContext](BitKilnContext.md) create(image: [Image](https://docs.godotengine.org/en/stable/classes/class_image.html), frame_grid: Vector2i = Vector2i(1, 1)) static

A context holding `image` as its color layer, cut into `frame_grid`.

---

<a id="method-get_layer"></a>
### [BitKilnBuffer](BitKilnBuffer.md) get_layer(layer_name: StringName)

The layer called `layer_name`, or `null`.

---

<a id="method-has_layer"></a>
### bool has_layer(layer_name: StringName)

Whether there's a layer called `layer_name`.

---

<a id="method-remap_frames"></a>
### void remap_frames(new_frame_size: Vector2i, offset: Vector2i)

Moves every frame's content by `offset` into frames of `new_frame_size`, cutting off whatever falls outside, in every layer. Padding is a bigger size and a positive offset; trimming a smaller size and a negative one.

---

<a id="method-reset_source_mapping"></a>
### void reset_source_mapping()

For ops that move pixels in ways [to_source()](#method-to_source) can't follow (rotating, repacking): from now on the source frame is taken to be stretched over the whole current frame.

---

<a id="method-scale_buffer"></a>
### [BitKilnBuffer](BitKilnBuffer.md) scale_buffer(src: [BitKilnBuffer](BitKilnBuffer.md), factor: int) static

`src` scaled up by a whole `factor`, nearest neighbour.

---

<a id="method-scale_nearest"></a>
### void scale_nearest(factor: int)

Scales every layer up by a whole `factor`, nearest neighbour. Ops with a smarter algorithm for the color layer replace it afterwards.

---

<a id="method-to_source"></a>
### Vector2i to_source(local: Vector2i)

The source pixel (within one source frame) that the pixel at `local` (within one current frame) came from, clamped to the source frame.

---

<a id="method-warn"></a>
### void warn(message: String)

Adds a message for the BitKiln dock and the bake result (once per message).
