# BitKilnFxSheet

**Inherits:** [BitKilnOp](BitKilnOp.md)

Draws an animated effect across the frames: sparkles, impact bursts, smoke puffs, slashes, pulsing orbs and shockwave rings. Use it on a recipe without a source (a blank canvas), and play the result with a Sprite Frames output, a `PocketSpriteVfx` or an AnimatedSprite2D.

## Description

How many frames: set how long the effect lasts ([duration](#property-duration)) and the speed it plays at ([fps](#property-fps)), and [frame_count](#property-frame_count) at Auto works out the count. Starting from one frame, the op makes that many frames in a row; over a sheet that already has several frames, it draws on those instead.  Each pixel gets a "heat" from 0 (the hot, bright core) to 1 (the cool, fading edge), colored by [colors](#property-colors) in [color_steps](#property-color_steps) hard steps, so the sheet stays in a small palette.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [color_steps](#property-color_steps) | `4` |
| [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) | [colors](#property-colors) |  |
| int | [count](#property-count) | `6` |
| float | [direction](#property-direction) | `-90.0` |
| bool | [dither](#property-dither) | `false` |
| float | [duration](#property-duration) | `0.8` |
| [Effect](#enum-effect) | [effect](#property-effect) | `IMPACT` |
| float | [fps](#property-fps) | `10.0` |
| int | [frame_count](#property-frame_count) | `0` |
| float | [scale](#property-scale) | `0.9` |
| int | [seed](#property-seed) | `1` |
| [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) | [timing](#property-timing) |  |

## Methods

| Return | Signature |
|---|---|
| float | [get_duration](#method-get_duration)() |
| float | [get_fps](#method-get_fps)() |
| int | [get_frame_count](#method-get_frame_count)() |

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

<a id="property-duration"></a>
### float duration = `0.8`

Seconds the effect lasts. Hidden when [frame_count](#property-frame_count) is set: the length is then the frame count at [fps](#property-fps).

---

<a id="property-effect"></a>
### [Effect](#enum-effect) effect = `IMPACT`

Which effect to draw.

---

<a id="property-fps"></a>
### float fps = `10.0`

Frames per second the effect is made for. Sprite Frames and GIF outputs play at this speed unless they set their own, and so does the BitKiln dock's preview.

---

<a id="property-frame_count"></a>
### int frame_count = `0`

Frames to make. 0 = Auto: [duration](#property-duration) × [fps](#property-fps). Ignored over a sheet that already has several frames.

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

## Method Descriptions

<a id="method-get_duration"></a>
### float get_duration()

Seconds the frames the op makes cover, playing at [fps](#property-fps).

---

<a id="method-get_fps"></a>
### float get_fps()

---

<a id="method-get_frame_count"></a>
### int get_frame_count()

How many frames the op makes from a single frame: [frame_count](#property-frame_count), or with Auto, [duration](#property-duration) × [fps](#property-fps).
