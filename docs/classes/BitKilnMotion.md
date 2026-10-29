# BitKilnMotion

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

One effect of a [BitKilnAnimate](BitKilnAnimate.md): how the sprite moves, deforms or changes color over the animation. Pick the [effect](#property-effect), then set its [amount](#property-amount); the Inspector shows only the settings that effect uses.

## Description

Time runs from 0 (first frame) to 1 (end of the animation). [start](#property-start) and [end](#property-end) limit the effect to part of it. [curve](#property-curve), when set, shapes the effect over that window: for effects that swing back and forth (squash, shake, wobble, skew, wave, jump) it scales the swings; for the others it is the effect's value itself.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [amount](#property-amount) | `0.2` |
| Color | [color](#property-color) | `Color(1, 1, 1, 1)` |
| [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) | [curve](#property-curve) |  |
| float | [cycles](#property-cycles) | `1.0` |
| Vector2 | [direction](#property-direction) | `Vector2(1, 0)` |
| [Effect](#enum-effect) | [effect](#property-effect) | `SQUASH` |
| bool | [enabled](#property-enabled) | `true` |
| float | [end](#property-end) | `1.0` |
| int | [ghost_spacing](#property-ghost_spacing) | `1` |
| int | [ghosts](#property-ghosts) | `3` |
| Vector2 | [pivot](#property-pivot) | `Vector2(0.5, 1)` |
| int | [seed](#property-seed) | `0` |
| float | [start](#property-start) | `0.0` |

## Methods

| Return | Signature |
|---|---|
| [BitKilnMotion](BitKilnMotion.md) | [create](#method-create)(motion_effect: [Effect](#enum-effect), motion_amount: float) static |
| float | [envelope](#method-envelope)(u: float) |
| float | [local_time](#method-local_time)(t: float) |

## Enumerations

<a id="enum-effect"></a>
### enum Effect

- **SQUASH** = `0`: Squash and stretch: wider and flatter, then taller and thinner, [cycles](#property-cycles) times. [amount](#property-amount) 0.2 = 20%.
- **JUMP** = `1`: Hops up [amount](#property-amount) pixels and lands, [cycles](#property-cycles) times.
- **SHAKE** = `2`: Jitters up to [amount](#property-amount) pixels in random directions, fading out.
- **WOBBLE** = `3`: Rocks side to side up to [amount](#property-amount) degrees around [pivot](#property-pivot), settling down.
- **SKEW** = `4`: Leans like jelly, top swaying [amount](#property-amount) times its height relative to the base, settling down.
- **SPIN** = `5`: Turns [amount](#property-amount) full turns clockwise around [pivot](#property-pivot).
- **WAVE** = `6`: Rows (or columns) ripple sideways up to [amount](#property-amount) pixels, [cycles](#property-cycles) waves tall.
- **MOVE** = `7`: Slides by [direction](#property-direction) × [amount](#property-amount) pixels.
- **SCALE** = `8`: Grows by [amount](#property-amount) (0.5 = half again as big) around [pivot](#property-pivot).
- **FLASH** = `9`: Turns [color](#property-color) while active (hit flash). [amount](#property-amount) 1 = solid color.
- **TINT** = `10`: Mixes in [color](#property-color) by [amount](#property-amount) while active.
- **FADE** = `11`: Fades out by [amount](#property-amount) (1 = gone), in whole pixels with dithering.
- **BLINK** = `12`: Disappears and reappears [cycles](#property-cycles) times while active.
- **DISSOLVE** = `13`: Crumbles away pixel by pixel; [color](#property-color) lights the crumbling edge.
- **AFTERIMAGE** = `14`: Ghost copies of earlier frames trail behind, [amount](#property-amount) = their opacity.

<a id="enum-bitkilnmotion.effect[]"></a>
### enum BitKilnMotion.Effect[]

- **SWINGING** = `Array[int]([0, 1, 2, 3, 4, 6])`: Effects that swing back and forth: the curve scales their swings.
- **HOLDING** = `Array[int]([5, 7, 8, 11, 13])`: Effects that keep their last value after [end](#property-end) (the others stop).

## Property Descriptions

<a id="property-amount"></a>
### float amount = `0.2`

How strong the effect is; its meaning depends on the effect (see [Effect](https://docs.godotengine.org/en/stable/classes/class_effect.html)(#enum-effect)).

---

<a id="property-color"></a>
### Color color = `Color(1, 1, 1, 1)`

For flash, tint, dissolve edges and afterimages (alpha 0 = keep the sprite's colors).

---

<a id="property-curve"></a>
### [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) curve

Shapes the effect over its window (see the class description). Empty = the effect's natural shape.

---

<a id="property-cycles"></a>
### float cycles = `1.0`

Swings, hops, blinks or waves during the window.

---

<a id="property-direction"></a>
### Vector2 direction = `Vector2(1, 0)`

For Move: which way; for Shake: the axes it shakes along; for Wave: (1, 0) ripples rows sideways, (0, 1) ripples columns up and down.

---

<a id="property-effect"></a>
### [Effect](#enum-effect) effect = `SQUASH`

What the effect does.

---

<a id="property-enabled"></a>
### bool enabled = `true`

Skipped while off.

---

<a id="property-end"></a>
### float end = `1.0`

When the effect ends, 0–1 of the animation.

---

<a id="property-ghost_spacing"></a>
### int ghost_spacing = `1`

For Afterimage: frames between ghosts.

---

<a id="property-ghosts"></a>
### int ghosts = `3`

For Afterimage: how many ghosts.

---

<a id="property-pivot"></a>
### Vector2 pivot = `Vector2(0.5, 1)`

The point that stays put when squashing, scaling, wobbling, skewing or spinning, relative to the sprite's bounds: (0.5, 1) is the bottom middle, (0.5, 0.5) the center.

---

<a id="property-seed"></a>
### int seed = `0`

Changes the randomness of Shake and Dissolve.

---

<a id="property-start"></a>
### float start = `0.0`

When the effect starts, 0–1 of the animation.

## Method Descriptions

<a id="method-create"></a>
### [BitKilnMotion](BitKilnMotion.md) create(motion_effect: [Effect](#enum-effect), motion_amount: float) static

A motion with `motion_effect` and `motion_amount`, the rest left at their defaults.

---

<a id="method-envelope"></a>
### float envelope(u: float)

The effect's strength at window time `u`: the curve's value, or the natural shape.

---

<a id="method-local_time"></a>
### float local_time(t: float)

How far into its window the effect is at animation time `t` (0–1), or -1 when it's inactive then.
