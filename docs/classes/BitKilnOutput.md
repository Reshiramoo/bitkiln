# BitKilnOutput

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

A file a [BitKilnRecipe](BitKilnRecipe.md) writes when baked: a layer saved as a PNG, or a [CanvasTexture](https://docs.godotengine.org/en/stable/classes/class_canvastexture.html) that pairs the recipe's color and normal PNGs.

## Properties

| Type | Name | Default |
|---|---|---|
| [Kind](#enum-kind) | [kind](#property-kind) | `COLOR` |
| String | [path](#property-path) | `"{dir}/{name}_baked{variant}.png"` |

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

## Constants

- **DEFAULT_PATHS** = `{0: "{dir}/{name}_baked{variant}.png", 1: "{dir}/{name}_baked{variant}_n.png", 2: "{dir}/{name}_lit{variant}.tres"}`: Default [path](#property-path) for each [Kind](https://docs.godotengine.org/en/stable/classes/class_kind.html)(#enum-kind).

## Property Descriptions

<a id="property-kind"></a>
### [Kind](#enum-kind) kind = `COLOR`

What to write. Changing it also changes [path](#property-path) while it's still a default one.

---

<a id="property-path"></a>
### String path = `"{dir}/{name}_baked{variant}.png"`

Where to save. `{dir}` is the source image's folder, `{name}` its file name without extension, `{recipe}` the recipe's file name without extension, and `{variant}` an underscore and the variant's name (or nothing for the main image). Without `{variant}`, variants get it before the extension anyway, so they never overwrite each other.

## Method Descriptions

<a id="method-create"></a>
### [BitKilnOutput](BitKilnOutput.md) create(output_kind: [Kind](#enum-kind), output_path: String = "") static

An output of `output_kind`, at `output_path` or the default path for that kind.

---

<a id="method-resolve"></a>
### String resolve(source_path: String, recipe_path: String, variant: String)

[path](#property-path) with its placeholders filled in.
