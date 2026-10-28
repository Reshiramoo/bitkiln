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
| Array[Dictionary] | [sprite_frames](#property-sprite_frames) | `[]` |
| Array[Dictionary] | [tile_sets](#property-tile_sets) | `[]` |
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

<a id="property-sprite_frames"></a>
### Array[Dictionary] sprite_frames = `[]`

[SpriteFrames](https://docs.godotengine.org/en/stable/classes/class_spriteframes.html) outputs, made by the editor once their PNGs are imported: `path`, `texture` (the PNG), `frames`, `frame_size`, `empty` (indices of frames with no visible pixels), `animations`, `names`, `fps`, `loop` and `skip_empty`.

---

<a id="property-tile_sets"></a>
### Array[Dictionary] tile_sets = `[]`

[TileSet](https://docs.godotengine.org/en/stable/classes/class_tileset.html) outputs, made by the editor once their PNGs are imported: `path`, `texture`, `frames`, `frame_size`, `empty`, `masks` (each cell's neighbour bits from [BitKilnAutotile](BitKilnAutotile.md), -1 for none, or empty without one), `terrain_name` and `terrain_color`.

---

<a id="property-warnings"></a>
### PackedStringArray warnings = `[]`

Problems that didn't stop the bake, from the ops and the outputs.

---

<a id="property-written"></a>
### PackedStringArray written = `[]`

Files written (unchanged files are skipped, so they don't reimport for nothing).
