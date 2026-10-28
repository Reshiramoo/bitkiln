# BitKilnReduce

**Inherits:** [BitKilnOp](BitKilnOp.md)

Reduces the image to at most [colors](#property-colors) colors, picking them from the image itself (median cut, weighted by how many pixels use each color). Good for cleaning up painted or scaled art into a pixel-art palette; add a Palette output to save the colors it picked.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [alpha_threshold](#property-alpha_threshold) | `0.5` |
| int | [colors](#property-colors) | `16` |
| bool | [hard_alpha](#property-hard_alpha) | `true` |

## Methods

| Return | Signature |
|---|---|
| PackedInt32Array | [median_cut](#method-median_cut)(counts: Dictionary, count: int) static |

## Property Descriptions

<a id="property-alpha_threshold"></a>
### float alpha_threshold = `0.5`

With [hard_alpha](#property-hard_alpha): pixels with at least this alpha become opaque.

---

<a id="property-colors"></a>
### int colors = `16`

Most colors to keep, across all frames.

---

<a id="property-hard_alpha"></a>
### bool hard_alpha = `true`

Make every pixel fully opaque or fully transparent.

## Method Descriptions

<a id="method-median_cut"></a>
### PackedInt32Array median_cut(counts: Dictionary, count: int) static

Up to `count` colors that represent `counts` (opaque color -> pixel count).
