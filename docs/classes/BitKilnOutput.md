# BitKilnOutput

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

A file a [BitKilnRecipe](BitKilnRecipe.md) writes when baked: a layer saved as a PNG, the result's palette, a [CanvasTexture](https://docs.godotengine.org/en/stable/classes/class_canvastexture.html) that pairs the recipe's color and normal PNGs, the [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html) of an animated sheet, a [TileSet](https://docs.godotengine.org/en/stable/classes/class_tileset.html), or an animated GIF.

## Properties

| Type | Name | Default |
|---|---|---|
| PackedStringArray | [animation_names](#property-animation_names) | `[]` |
| [Animations](#enum-animations) | [animations](#property-animations) | `ONE` |
| float | [fps](#property-fps) | `0.0` |
| int | [gif_scale](#property-gif_scale) | `4` |
| [Kind](#enum-kind) | [kind](#property-kind) | `COLOR` |
| bool | [loop](#property-loop) | `true` |
| String | [path](#property-path) | `"{out}{variant}.png"` |
| bool | [skip_empty](#property-skip_empty) | `true` |
| Array[[BitKilnOp](BitKilnOp.md)] | [skip_ops](#property-skip_ops) | `[]` |
| Color | [terrain_color](#property-terrain_color) | `Color(0.4, 0.75, 0.35, 1)` |
| String | [terrain_name](#property-terrain_name) | `""` |

## Methods

| Return | Signature |
|---|---|
| [BitKilnOutput](BitKilnOutput.md) | [create](#method-create)(output_kind: [Kind](#enum-kind), output_path: String = "") static |
| String | [out_base](#method-out_base)(source_path: String) static |
| String | [resolve](#method-resolve)(source_path: String, recipe_path: String, variant: String) |
| bool | [uses_op](#method-uses_op)(op: [BitKilnOp](BitKilnOp.md)) |

## Enumerations

<a id="enum-kind"></a>
### enum Kind

- **COLOR** = `0`: The color layer, as a PNG.
- **NORMAL** = `1`: The normal map from a [BitKilnNormalMap](BitKilnNormalMap.md), as a PNG.
- **CANVAS_TEXTURE** = `2`: A [CanvasTexture](https://docs.godotengine.org/en/stable/classes/class_canvastexture.html) `.tres` using the recipe's Color and Normal outputs, ready for a Sprite2D with 2D lights.
- **PALETTE** = `3`: Every color of the result, darkest to brightest, as a one-row PNG: usable as a palette by [BitKilnPaletteSwap](BitKilnPaletteSwap.md), [BitKilnQuantize](BitKilnQuantize.md) or Pocket's shaders.
- **SPRITE_FRAMES** = `4`: A [SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html) `.tres` for an AnimatedSprite2D, cutting the recipe's Color output into its frames.
- **TILE_SET** = `5`: A [TileSet](https://docs.godotengine.org/en/stable/classes/class_tileset.html) `.tres` with the recipe's Color output as an atlas, one tile per non-empty frame; after a [BitKilnAutotile](BitKilnAutotile.md), with a terrain set up for painting.
- **GIF** = `6`: The frames as an animated GIF, for sharing outside the game.

<a id="enum-animations"></a>
### enum Animations

- **ONE** = `0`: Every frame in one animation, row by row.
- **PER_ROW** = `1`: One animation per row of frames: walk cycles per direction, for example.

<a id="enum-layout"></a>
### enum Layout

- **NEXT_TO_SOURCE** = `0`: Beside the source: `art/hero_baked.png`.
- **FOLDER_PER_SOURCE** = `1`: In a folder beside the source: `art/hero_baked/hero.png`.
- **SEPARATE_FOLDER** = `2`: Under one folder, mirroring the project's folders, one folder per source: `baked/art/hero/hero.png`.

<a id="enum-bitkilnoutput.layout"></a>
### enum BitKilnOutput.Layout

- **DEFAULT_LAYOUT** = `2`: The layout new projects use.

## Constants

- **SETTING_LAYOUT** = `"bitkiln/output/layout"`: Project setting: the [Layout](https://docs.godotengine.org/en/stable/classes/class_layout.html)(#enum-layout) for `{out}`.
- **SETTING_FOLDER** = `"bitkiln/output/folder"`: Project setting: the folder [constant SEPARATE_FOLDER] uses.
- **DEFAULT_FOLDER** = `"res://baked"`: The folder [constant SEPARATE_FOLDER] uses unless the project sets another.
- **DEFAULT_PATHS** = `{0: "{out}{variant}.png", 1: "{out}{variant}_n.png", 2: "{out}{variant}_lit.tres", 3: "{out}{variant}_palette.png", 4: "{out}{variant}_frames.tres", 5: "{out}{variant}_tiles.tres", 6: "{out}{variant}.gif"}`: Default [path](#property-path) for each [Kind](https://docs.godotengine.org/en/stable/classes/class_kind.html)(#enum-kind).

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
### float fps = `0.0`

Frames per second. 0 = the speed the recipe's animation is made for: the fps of its last [BitKilnAnimate](BitKilnAnimate.md), [BitKilnParticles](BitKilnParticles.md) or [BitKilnFxSheet](BitKilnFxSheet.md) this output uses (10 without one). See [BitKilnRecipe.get_fps()](BitKilnRecipe.md#method-get_fps).

---

<a id="property-gif_scale"></a>
### int gif_scale = `4`

For GIFs: each pixel becomes a block this many pixels wide, so small sprites are easy to see.

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
### String path = `"{out}{variant}.png"`

Where to save. `{out}` is where the project's output layout puts this source's files, without extension (see [Layout](https://docs.godotengine.org/en/stable/classes/class_layout.html)(#enum-layout)). `{dir}` is the source image's folder and `{name}` its file name without extension (without a source, the recipe's folder and name). `{recipe}` is the recipe's file name without extension, and `{variant}` an underscore and the variant's name (or nothing for the main image). Without `{variant}`, variants get it before the extension anyway, so they never overwrite each other.

---

<a id="property-skip_empty"></a>
### bool skip_empty = `true`

Leave out frames with no visible pixels (the unused cells at the end of a sheet).

---

<a id="property-skip_ops"></a>
### Array[[BitKilnOp](BitKilnOp.md)] skip_ops = `[]`

Ops this output leaves out: it's written from the result of the other ops. Edited as a checklist in the Inspector. Lets one recipe write several versions of each sprite, say with and without a glow.

---

<a id="property-terrain_color"></a>
### Color terrain_color = `Color(0.4, 0.75, 0.35, 1)`

Color the terrain is shown with in the TileMap editor.

---

<a id="property-terrain_name"></a>
### String terrain_name = `""`

Name of the terrain, after a [BitKilnAutotile](BitKilnAutotile.md). Empty = the file's name.

## Method Descriptions

<a id="method-create"></a>
### [BitKilnOutput](BitKilnOutput.md) create(output_kind: [Kind](#enum-kind), output_path: String = "") static

An output of `output_kind`, at `output_path` or the default path for that kind.

---

<a id="method-out_base"></a>
### String out_base(source_path: String) static

Where the project's output layout puts the files of the source at `source_path`, without extension: `res://baked/art/hero/hero` for `res://art/hero.png`.

---

<a id="method-resolve"></a>
### String resolve(source_path: String, recipe_path: String, variant: String)

[path](#property-path) with its placeholders filled in.

---

<a id="method-uses_op"></a>
### bool uses_op(op: [BitKilnOp](BitKilnOp.md))

Whether this output uses `op` (it isn't in [skip_ops](#property-skip_ops)).
