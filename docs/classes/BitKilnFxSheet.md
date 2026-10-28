# BitKilnFxSheet

**Inherits:** [BitKilnOp](BitKilnOp.md)

Draws an animated effect across the frames: sparkles, impact bursts, smoke puffs, slashes, pulsing orbs and shockwave rings. Use it on a recipe without a source, with [BitKilnRecipe.frames](BitKilnRecipe.md#property-frames) set to the number of frames (6×1, 8×1…), and play the result with a Sprite Frames output, a `PocketSpriteVfx` or an AnimatedSprite2D.

## Description

Each pixel gets a "heat" from 0 (the hot, bright core) to 1 (the cool, fading edge), colored by [colors](#property-colors) in [color_steps](#property-color_steps) hard steps, so the sheet stays in a small palette.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [color_steps](#property-color_steps) | `4` |
| [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) | [colors](#property-colors) |  |
| int | [count](#property-count) | `6` |
| float | [direction](#property-direction) | `-90.0` |
| bool | [dither](#property-dither) | `false` |
| [Effect](#enum-effect) | [effect](#property-effect) | `IMPACT` |
| float | [scale](#property-scale) | `0.9` |
| int | [seed](#property-seed) | `1` |
| [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) | [timing](#property-timing) |  |

## Enumerations

<a id="enum-effect"></a>
### enum Effect

- **SPARKLE** = `0`: Four-pointed twinkles that pop in and out at random spots; loops.
- **IMPACT** = `1`: A flash, then spikes bursting outward.
- **SMOKE** = `2`: Puffs drifting toward [direction](#property-direction), growing and fading.
- **SLASH** = `3`: A crescent swipe that sweeps around and thins out.
- **ORB** = `4`: A pulsing ball of light with a halo; loops.
- **RING** = `5`: A shockwave ring expanding and thinning.

## Property Descriptions

<a id="property-color_steps"></a>
### int color_steps = `4`

Heat levels, each a hard band of color; 0 = smooth.

---

<a id="property-colors"></a>
### [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) colors

From the hot core (left) to the fading edge (right). Its alpha is kept, so a gradient ending transparent fades out. With Constant interpolation and points at 0, 1/n, 2/n… ([color_steps](#property-color_steps) = n), every band is exactly one of its colors. Empty = white, yellow, orange, red.

---

<a id="property-count"></a>
### int count = `6`

Sparkles, spikes or puffs.

---

<a id="property-direction"></a>
### float direction = `-90.0`

Which way smoke drifts and slashes face, in degrees clockwise from right.

---

<a id="property-dither"></a>
### bool dither = `false`

Fading pixels pick their band with an ordered pattern, for softer fades.

---

<a id="property-effect"></a>
### [Effect](#enum-effect) effect = `IMPACT`

Which effect to draw.

---

<a id="property-scale"></a>
### float scale = `0.9`

How big the effect gets, relative to the frame (1 = touches the frame's edge).

---

<a id="property-seed"></a>
### int seed = `1`

Changes the random placement (sparkles, spikes, puffs).

---

<a id="property-timing"></a>
### [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) timing

How the effect advances over the frames (0 = first frame, 1 = last). Empty = evenly.
