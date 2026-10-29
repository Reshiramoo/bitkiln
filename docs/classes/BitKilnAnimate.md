# BitKilnAnimate

**Inherits:** [BitKilnOp](BitKilnOp.md)

Turns a still sprite into an animation: hit flashes, squash and stretch, hops, shakes, wobbles, spins, waves, fades, dissolves and afterimages, from a stack of [BitKilnMotion](BitKilnMotion.md) effects. Each frame of the source becomes a row of [frame_count](#property-frame_count) frames (so a sheet of poses gets an animation per pose).

## Description

It stays pixel art: movement snaps to whole pixels, rotation and skewing use RotSprite (no new colors, clean lines), and fades and dissolves remove whole pixels instead of making them half transparent. Effects apply in order, so a squash then a spin squashes first. Frames grow by [margin](#property-margin) on every side to give the motion room.

## Properties

| Type | Name | Default |
|---|---|---|
| bool | [dither_fades](#property-dither_fades) | `true` |
| Array[[BitKilnMotion](BitKilnMotion.md)] | [effects](#property-effects) | `[]` |
| int | [frame_count](#property-frame_count) | `8` |
| [Layout](#enum-layout) | [layout](#property-layout) | `ROWS` |
| bool | [loop](#property-loop) | `true` |
| int | [margin](#property-margin) | `4` |

## Methods

| Return | Signature |
|---|---|
| Dictionary | [make_preset](#method-make_preset)(preset: String) static |
| PackedStringArray | [preset_names](#method-preset_names)() static |

## Enumerations

<a id="enum-layout"></a>
### enum Layout

- **ROWS** = `0`: Each source frame gets its own row of frames.
- **STRIP** = `1`: All frames in one row, source frame after source frame.

## Property Descriptions

<a id="property-dither_fades"></a>
### bool dither_fades = `true`

Fades, blinks and afterimages remove whole pixels in an ordered pattern instead of making them half transparent.

---

<a id="property-effects"></a>
### Array[[BitKilnMotion](BitKilnMotion.md)] effects = `[]`

What happens over the animation, applied in order.

---

<a id="property-frame_count"></a>
### int frame_count = `8`

Frames in the animation.

---

<a id="property-layout"></a>
### [Layout](#enum-layout) layout = `ROWS`

How the frames are arranged when the source has several.

---

<a id="property-loop"></a>
### bool loop = `true`

The last frame leads back into the first (time stops one frame short of the end). Off: the last frame is the end of the animation, for one-shots like a death dissolve.

---

<a id="property-margin"></a>
### int margin = `4`

Transparent pixels added on every side of each frame, so the sprite can move and grow.

## Method Descriptions

<a id="method-make_preset"></a>
### Dictionary make_preset(preset: String) static

A ready-made animation: [code]{"frame_count": int, "loop": bool, "margin": int,
"effects": Array[BitKilnMotion](BitKilnMotion.md)}[/code].

---

<a id="method-preset_names"></a>
### PackedStringArray preset_names() static

Names of the ready-made animations, for [make_preset()](#method-make_preset).
