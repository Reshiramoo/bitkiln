# BitKilnNoise

**Inherits:** [BitKilnOp](BitKilnOp.md)

Fills every frame with noise, banded through a gradient: grass, dirt, water, stone and cloud textures, star fields, terrain maps. Seamless noise tiles, so the frames work as repeating textures or tiles. Each frame gets its own part of the noise, for variations.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [color_steps](#property-color_steps) | `4` |
| [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) | [colors](#property-colors) |  |
| bool | [dither](#property-dither) | `false` |
| [FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html) | [noise](#property-noise) |  |
| bool | [normalize](#property-normalize) | `true` |
| bool | [seamless](#property-seamless) | `true` |

## Property Descriptions

<a id="property-color_steps"></a>
### int color_steps = `4`

Bands of color; 0 = smooth.

---

<a id="property-colors"></a>
### [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) colors

Low noise values (left) to high ones (right). Its alpha is kept, so transparent parts make holes (clouds). Empty = black to white.

---

<a id="property-dither"></a>
### bool dither = `false`

Pick between neighbouring bands with an ordered pattern, for softer edges.

---

<a id="property-noise"></a>
### [FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html) noise

The noise to sample (type, frequency, octaves…). Empty = smooth simplex, 3 octaves.

---

<a id="property-normalize"></a>
### bool normalize = `true`

Stretch the noise's values to the whole gradient.

---

<a id="property-seamless"></a>
### bool seamless = `true`

Tile seamlessly: the left edge continues the right one, the top the bottom.
