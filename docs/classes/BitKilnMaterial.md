# BitKilnMaterial

**Inherits:** [BitKilnOp](BitKilnOp.md)

Renders the image through a CanvasItem material and keeps the result: design an effect live with a shader (a hit flash, a dissolve, a palette shader, your own), then freeze it into the PNG so the game doesn't run the shader. The material itself isn't changed.

## Description

Rendering needs the editor or a game window: in `--headless` runs (the bake_all script) this op does nothing and says so. Effects that change over time (`TIME`) are caught at an arbitrary moment. Effects that draw outside the sprite (outlines, shadows) need room: put a [BitKilnPad](BitKilnPad.md) before it.

## Properties

| Type | Name | Default |
|---|---|---|
| [Material](https://docs.godotengine.org/en/stable/classes/class_material.html) | [material](#property-material) |  |
| Dictionary | [parameters](#property-parameters) | `{}` |
| bool | [set_sheet_frames](#property-set_sheet_frames) | `true` |

## Property Descriptions

<a id="property-material"></a>
### [Material](https://docs.godotengine.org/en/stable/classes/class_material.html) material

The material to render with: a ShaderMaterial (canvas_item shader) or a CanvasItemMaterial.

---

<a id="property-parameters"></a>
### Dictionary parameters = `{}`

Shader parameters for this bake only, by name: they override the material's values without changing it. For example `{"flash_amount": 1.0}`.

---

<a id="property-set_sheet_frames"></a>
### bool set_sheet_frames = `true`

Set the shader's `sheet_frames` uniform, if it has one (`vec2`: columns and rows), to the frame grid, so per-frame effects stay inside their frames.
