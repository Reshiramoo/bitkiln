# BitKilnOp

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

One step of a [BitKilnRecipe](BitKilnRecipe.md). Extend it and override [_apply()](#method-_apply) to make your own.

## Description

Ops change a [BitKilnContext](BitKilnContext.md) in place. An op that turns one image into several variants (like [BitKilnPaletteSwap](BitKilnPaletteSwap.md)) overrides [_process()](#method-_process) instead and returns a context per variant; the ops after it then run on each one.  Any op that keeps the image's size can be limited to part of it with a [mask](#property-mask): outside the mask, every layer keeps the pixels it had before the op.

## Properties

| Type | Name | Default |
|---|---|---|
| bool | [enabled](#property-enabled) | `true` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [mask](#property-mask) |  |
| bool | [mask_by_color](#property-mask_by_color) | `false` |
| Color | [mask_color](#property-mask_color) | `Color(1, 1, 1, 1)` |
| bool | [mask_invert](#property-mask_invert) | `false` |

## Methods

| Return | Signature |
|---|---|
| void | [_apply](#method-_apply)(_context: [BitKilnContext](BitKilnContext.md)) |
| float | [get_fps](#method-get_fps)() |
| bool | [is_solid](#method-is_solid)(pixel: int, alpha_threshold: int) static |
| PackedByteArray | [mask_pixels](#method-mask_pixels)(context: [BitKilnContext](BitKilnContext.md)) |
| Array[[BitKilnContext](BitKilnContext.md)] | [process](#method-process)(context: [BitKilnContext](BitKilnContext.md)) |
| Array[[BitKilnContext](BitKilnContext.md)] | [_process](#method-_process)(context: [BitKilnContext](BitKilnContext.md)) |

## Property Descriptions

<a id="property-enabled"></a>
### bool enabled = `true`

Skipped while off, so you can compare the result with and without it.

---

<a id="property-mask"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) mask

Limits the op to part of the image. Drawn over the source: either one frame's size (used for every frame) or the whole source sheet. White pixels are inside (or pixels of [mask_color](#property-mask_color) with [mask_by_color](#property-mask_by_color)), black or transparent ones outside. The mask follows padding, trimming and scaling done by earlier ops.

---

<a id="property-mask_by_color"></a>
### bool mask_by_color = `false`

Only pixels of [mask_color](#property-mask_color) are inside, so one region map with a color per part (hair, armor, cape) can serve several ops.

---

<a id="property-mask_color"></a>
### Color mask_color = `Color(1, 1, 1, 1)`

With [mask_by_color](#property-mask_by_color): the color of the region this op works on.

---

<a id="property-mask_invert"></a>
### bool mask_invert = `false`

Work outside the mask instead of inside it.

## Method Descriptions

<a id="method-_apply"></a>
### void _apply(_context: [BitKilnContext](BitKilnContext.md))

Changes `context` in place.

---

<a id="method-get_fps"></a>
### float get_fps()

Frames per second the op's animation is made for, which Sprite Frames and GIF outputs play at unless they set their own; 0 for ops that don't animate.

---

<a id="method-is_solid"></a>
### bool is_solid(pixel: int, alpha_threshold: int) static

Whether `pixel` counts as part of the sprite: alpha at least `alpha_threshold` (0–255).

---

<a id="method-mask_pixels"></a>
### PackedByteArray mask_pixels(context: [BitKilnContext](BitKilnContext.md))

1 for each pixel of `context`'s layers inside the mask, 0 outside; empty when there's no usable mask.

---

<a id="method-process"></a>
### Array[[BitKilnContext](BitKilnContext.md)] process(context: [BitKilnContext](BitKilnContext.md))

Runs the op, then puts back the pixels outside the [mask](#property-mask). Returns the contexts that continue: usually `context` itself.

---

<a id="method-_process"></a>
### Array[[BitKilnContext](BitKilnContext.md)] _process(context: [BitKilnContext](BitKilnContext.md))

The contexts that continue after this op: `context` itself, changed by [_apply()](#method-_apply), unless overridden.
