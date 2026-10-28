# BitKilnOutput

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

A file a [BitKilnRecipe](BitKilnRecipe.md) writes when baked: a layer saved as a PNG, the result's palette, a [CanvasTexture](https://docs.godotengine.org/en/stable/classes/class_canvastexture.html) that pairs the recipe's color and normal PNGs, or the [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html) of an animated sheet.

## Properties

| Type | Name | Default |
|---|---|---|
| PackedStringArray | [animation_names](#property-animation_names) | `[]` |
| [Animations](#enum-animations) | [animations](#property-animations) | `ONE` |
| float | [fps](#property-fps) | `10.0` |
| [Kind](#enum-kind) | [kind](#property-kind) | `COLOR` |
| bool | [loop](#property-loop) | `true` |
| String | [path](#property-path) | `"{dir}/{name}_baked{variant}.png"` |
| bool | [skip_empty](#property-skip_empty) | `true` |

## Methods

| Return | Signature |
|---|---|
| [BitKilnOutput](BitKilnOutput.md) | [create](#method-create)(output_kind: [Kind](#enum-kind), output_path: String = "") static |
| String | [resolve](#method-resolve)(source_path: String, recipe_path: String, variant: String) |

## Enumerations

<a id="enum-kind"></a>
### enum Kind

- **COLOR** = `0`: The color layer, as a PNG.
- **NORMAL** = `1`: The normal map from a [BitKilnNormalMap](BitKilnNormalMap.md), as a PNG.
- **CANVAS_TEXTURE** = `2`: A [CanvasTexture](https://docs.godotengine.org/en/stable/classes/class_canvastexture.html) `.tres` using the recipe's Color and Normal outputs, ready for a Sprite2D with 2D lights.
- **PALETTE** = `3`: Every color of the result, darkest to brightest, as a one-row PNG: usable as a palette by [BitKilnPaletteSwap](BitKilnPaletteSwap.md), [BitKilnQuantize](BitKilnQuantize.md) or Pocket's shaders.
- **SPRITE_FRAMES** = `4`: A [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html) `.tres` for an AnimatedSprite2D, cutting the recipe's Color output into its frames.

<a id="enum-animations"></a>
### enum Animations

- **ONE** = `0`: Every frame in one animation, row by row.
- **PER_ROW** = `1`: One animation per row of frames: walk cycles per direction, for example.

## Constants

- **DEFAULT_PATHS** = `{0: "{dir}/{name}_baked{variant}.png", 1: "{dir}/{name}_baked{variant}_n.png", 2: "{dir}/{name}_lit{variant}.tres", 3: "{dir}/{name}_palette{variant}.png", 4: "{dir}/{name}_frames{variant}.tres"}`: Default [path](#property-path) for each [Kind](https://docs.godotengine.org/en/stable/classes/class_kind.html)(#enum-kind).

## Property Descriptions

<a id="property-animation_names"></a>
### PackedStringArray animation_names = `[]`

Animation names, in order (one per row with Per Row). Missing names are "default" (One) or "row_0", "row_1"… (Per Row).

---

<a id="property-animations"></a>
### [Animations](#enum-animations) animations = `ONE`

How frames are grouped into animations.

---

<a id="property-fps"></a>
### float fps = `10.0`

Frames per second.

---

<a id="property-kind"></a>
### [Kind](#enum-kind) kind = `COLOR`

What to write. Changing it also changes [path](#property-path) while it's still a default one.

---

<a id="property-loop"></a>
### bool loop = `true`

Whether the animations loop.

---

<a id="property-path"></a>
### String path = `"{dir}/{name}_baked{variant}.png"`

Where to save. `{dir}` is the source image's folder, `{name}` its file name without extension, `{recipe}` the recipe's file name without extension, and `{variant}` an underscore and the variant's name (or nothing for the main image). Without `{variant}`, variants get it before the extension anyway, so they never overwrite each other.

---

<a id="property-skip_empty"></a>
### bool skip_empty = `true`

Leave out frames with no visible pixels (the unused cells at the end of a sheet).

## Method Descriptions

<a id="method-create"></a>
### [BitKilnOutput](BitKilnOutput.md) create(output_kind: [Kind](#enum-kind), output_path: String = "") static

An output of `output_kind`, at `output_path` or the default path for that kind.

---

<a id="method-resolve"></a>
### String resolve(source_path: String, recipe_path: String, variant: String)

[path](#property-path) with its placeholders filled in.
