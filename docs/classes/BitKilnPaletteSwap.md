# BitKilnPaletteSwap

**Inherits:** [BitKilnOp](BitKilnOp.md)

Replaces colors, and makes one variant per palette: shiny forms, team colors, enemy tiers from one sprite.

## Description

A palette is either two rows, the layout many palette swap shaders use (row 0 = colors to find, row 1 = their replacements), or a single row of replacements for the colors in [base_palette](#property-base_palette), such as a Lospec palette. With more than one palette, each variant is named after its palette's file and baked to its own file. Ops after this one run on every variant, so an outline or glow after a swap follows the new colors.

## Properties

| Type | Name | Default |
|---|---|---|
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [base_palette](#property-base_palette) |  |
| bool | [keep_original](#property-keep_original) | `false` |
| Array[[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)] | [palettes](#property-palettes) | `[]` |
| float | [tolerance](#property-tolerance) | `0.0` |

## Property Descriptions

<a id="property-base_palette"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) base_palette

The colors one-row palettes replace, in the same order. Usually a palette of the sprite's original colors.

---

<a id="property-keep_original"></a>
### bool keep_original = `false`

Also keep the image with its original colors, as a variant named "original".

---

<a id="property-palettes"></a>
### Array[[Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html)] palettes = `[]`

One variant each. Two-row palettes map row 0 to row 1; one-row palettes replace the colors of [base_palette](#property-base_palette), in order.

---

<a id="property-tolerance"></a>
### float tolerance = `0.0`

How far (0–1, per channel) a color may be from a palette color and still be replaced. Keep it at 0 for clean pixel art.
