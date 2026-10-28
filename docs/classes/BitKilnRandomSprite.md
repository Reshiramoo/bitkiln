# BitKilnRandomSprite

**Inherits:** [BitKilnOp](BitKilnOp.md)

Generates a different random, mirrored sprite in every frame: creatures, ships or items, in the tradition of seeded pixel-sprite generators. Each sprite is a random half, mirrored, cleaned up into one piece, shaded from top to bottom, outlined, and (for creatures) given eyes. Use a recipe without a source and a big frame grid (8×8 = 64 sprites), then keep the ones you like, or bake a fresh set per game for procedural enemies and loot.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [density](#property-density) | `0.5` |
| [Kind](#enum-kind) | [kind](#property-kind) | `CREATURE` |
| int | [margin](#property-margin) | `1` |
| [Mirror](#enum-mirror) | [mirror](#property-mirror) | `HORIZONTAL` |
| Color | [outline](#property-outline) | `Color(0.08, 0.07, 0.12, 1)` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [palette](#property-palette) |  |
| int | [seed](#property-seed) | `1` |

## Enumerations

<a id="enum-kind"></a>
### enum Kind

- **CREATURE** = `0`: Round bodies with limbs, and eyes.
- **SHIP** = `1`: Pointed at the top, wide wings and engines at the bottom.
- **ITEM** = `2`: Compact, round-ish shapes: gems, potions, trinkets.

<a id="enum-mirror"></a>
### enum Mirror

- **HORIZONTAL** = `0`: Left and right halves mirror each other.
- **VERTICAL** = `1`: Top and bottom halves mirror each other.
- **BOTH** = `2`: All four quarters mirror each other.

## Property Descriptions

<a id="property-density"></a>
### float density = `0.5`

How much of the shape is filled (0–1).

---

<a id="property-kind"></a>
### [Kind](#enum-kind) kind = `CREATURE`

What kind of sprites to make.

---

<a id="property-margin"></a>
### int margin = `1`

Blank pixels kept around the sprite inside each frame (room for the outline).

---

<a id="property-mirror"></a>
### [Mirror](#enum-mirror) mirror = `HORIZONTAL`

Which halves mirror each other.

---

<a id="property-outline"></a>
### Color outline = `Color(0.08, 0.07, 0.12, 1)`

Outline color; alpha 0 = no outline.

---

<a id="property-palette"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) palette

Colors to pick from, two or three per sprite (any palette texture). Empty = a random hue per sprite, shaded in its own ramp.

---

<a id="property-seed"></a>
### int seed = `1`

Frame number n uses seed + n, so the same seed always makes the same set.
