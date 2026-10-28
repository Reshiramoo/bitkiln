# BitKilnBaker.Result

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

What [bake()](#method-bake) did.

## Properties

| Type | Name | Default |
|---|---|---|
| Array[Dictionary] | [canvas_textures](#property-canvas_textures) | `[]` |
| PackedStringArray | [errors](#property-errors) | `[]` |
| PackedStringArray | [files](#property-files) | `[]` |
| bool | [ok](#property-ok) |  |
| PackedStringArray | [warnings](#property-warnings) | `[]` |
| PackedStringArray | [written](#property-written) | `[]` |

## Property Descriptions

<a id="property-canvas_textures"></a>
### Array[Dictionary] canvas_textures = `[]`

[CanvasTexture](https://docs.godotengine.org/en/stable/classes/class_canvastexture.html) outputs, made by the editor once their PNGs are imported: `{"path": String, "diffuse": String, "normal": String}` each.

---

<a id="property-errors"></a>
### PackedStringArray errors = `[]`

Why files couldn't be written. Empty when the bake worked.

---

<a id="property-files"></a>
### PackedStringArray files = `[]`

Every output file, written or already up to date.

---

<a id="property-ok"></a>
### bool ok

True when there are no [errors](#property-errors).

---

<a id="property-warnings"></a>
### PackedStringArray warnings = `[]`

Problems that didn't stop the bake, from the ops and the outputs.

---

<a id="property-written"></a>
### PackedStringArray written = `[]`

Files written (unchanged files are skipped, so they don't reimport for nothing).
