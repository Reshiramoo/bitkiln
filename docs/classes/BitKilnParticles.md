# BitKilnParticles

**Inherits:** [BitKilnOp](BitKilnOp.md)

Simulates particles and draws them across the frames, as pixel art: fire, smoke, sparks, explosions, magic, rain, snow. Each frame shows the particles at its moment of [duration](#property-duration), so set the recipe's frames to the number of frames (8×1, 12×1…).

## Description

The same settings always give the same sheet: every particle's randomness comes from [seed](#property-seed) and its own number. With [loop](#property-loop), emission repeats exactly every [duration](#property-duration) and the simulation is warmed up first, so the last frame flows into the first. Particles snap to whole pixels, fade by dropping pixels in an ordered pattern, and can snap to a palette.

## Properties

| Type | Name | Default |
|---|---|---|
| [Blend](#enum-blend) | [blend](#property-blend) | `NORMAL` |
| [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html) | [bursts](#property-bursts) | `PackedVector2Array()` |
| int | [color_steps](#property-color_steps) | `5` |
| [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) | [colors](#property-colors) |  |
| float | [direction](#property-direction) | `-90.0` |
| bool | [dither_fades](#property-dither_fades) | `true` |
| float | [drag](#property-drag) | `0.0` |
| float | [duration](#property-duration) | `1.0` |
| [Emitter](#enum-emitter) | [emitter](#property-emitter) | `POINT` |
| Vector2 | [emitter_offset](#property-emitter_offset) | `Vector2(0, 0)` |
| Vector2 | [emitter_size](#property-emitter_size) | `Vector2(4, 4)` |
| Vector2 | [gravity](#property-gravity) | `Vector2(0, 0)` |
| float | [lifetime](#property-lifetime) | `1.0` |
| float | [lifetime_random](#property-lifetime_random) | `0.3` |
| bool | [loop](#property-loop) | `true` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [palette](#property-palette) |  |
| float | [radial_accel](#property-radial_accel) | `0.0` |
| float | [rate](#property-rate) | `20.0` |
| int | [seed](#property-seed) | `1` |
| [Shape](#enum-shape) | [shape](#property-shape) | `CIRCLE` |
| [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) | [size_curve](#property-size_curve) |  |
| float | [size_end](#property-size_end) | `1.0` |
| float | [size_random](#property-size_random) | `0.2` |
| float | [size_start](#property-size_start) | `3.0` |
| Vector2 | [speed](#property-speed) | `Vector2(8, 18)` |
| float | [spread](#property-spread) | `40.0` |
| [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) | [sprite](#property-sprite) |  |
| Vector2i | [sprite_frames](#property-sprite_frames) | `Vector2i(1, 1)` |
| float | [streak](#property-streak) | `0.05` |
| int | [substeps](#property-substeps) | `4` |
| float | [swirl](#property-swirl) | `0.0` |

## Methods

| Return | Signature |
|---|---|
| Dictionary | [make_preset](#method-make_preset)(preset: String) static |
| PackedStringArray | [preset_names](#method-preset_names)() static |
| Array[Array] | [simulate](#method-simulate)(frame_count: int, extra: int = 0) |

## Enumerations

<a id="enum-emitter"></a>
### enum Emitter

- **POINT** = `0`: From one point.
- **CIRCLE** = `1`: Anywhere inside a circle of [emitter_size](#property-emitter_size).x radius.
- **RING** = `2`: On the edge of a circle of [emitter_size](#property-emitter_size).x radius.
- **RECTANGLE** = `3`: Anywhere inside a rectangle of [emitter_size](#property-emitter_size).
- **LINE** = `4`: Along a horizontal line [emitter_size](#property-emitter_size).x long.

<a id="enum-shape"></a>
### enum Shape

- **PIXEL** = `0`: Single pixels (size is ignored).
- **CIRCLE** = `1`: Filled circles [size_start](#property-size_start)…[size_end](#property-size_end) wide.
- **SQUARE** = `2`: Filled squares.
- **DIAMOND** = `3`: Diamonds.
- **STAR** = `4`: Four-pointed sparkles.
- **STREAK** = `5`: Lines trailing behind the particle's movement, [streak](#property-streak) seconds long.
- **SPRITE** = `6`: Frames of [sprite](#property-sprite), played over each particle's life.

<a id="enum-blend"></a>
### enum Blend

- **NORMAL** = `0`: Particles cover what's behind them.
- **ADD** = `1`: Particles lighten what's behind them, like light.

## Property Descriptions

<a id="property-blend"></a>
### [Blend](#enum-blend) blend = `NORMAL`

How particles combine with what's behind them.

---

<a id="property-bursts"></a>
### [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html) bursts = `PackedVector2Array()`

Extra particles all at once: x = when (0–1 of [duration](#property-duration)), y = how many.

---

<a id="property-color_steps"></a>
### int color_steps = `5`

Colors change in this many steps over a particle's life instead of blending smoothly, so the sheet keeps a small palette; 0 = smooth.

---

<a id="property-colors"></a>
### [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) colors

Color over each particle's life, left (birth) to right (death); its alpha fades particles. Empty = white fading out.

---

<a id="property-direction"></a>
### float direction = `-90.0`

Direction particles start moving, in degrees clockwise from right (-90 = up).

---

<a id="property-dither_fades"></a>
### bool dither_fades = `true`

Fades drop pixels in an ordered pattern; off, they turn half transparent.

---

<a id="property-drag"></a>
### float drag = `0.0`

Slows particles down: 0 = none, 3 = strongly.

---

<a id="property-duration"></a>
### float duration = `1.0`

Seconds the frames cover.

---

<a id="property-emitter"></a>
### [Emitter](#enum-emitter) emitter = `POINT`

Where particles are born.

---

<a id="property-emitter_offset"></a>
### Vector2 emitter_offset = `Vector2(0, 0)`

From the frame's center to the emitter, in pixels.

---

<a id="property-emitter_size"></a>
### Vector2 emitter_size = `Vector2(4, 4)`

Radius (circle, ring), width and height (rectangle) or length (line), in pixels.

---

<a id="property-gravity"></a>
### Vector2 gravity = `Vector2(0, 0)`

Constant acceleration, pixels per second²: (0, 60) falls, (0, -30) rises.

---

<a id="property-lifetime"></a>
### float lifetime = `1.0`

Seconds each particle lives.

---

<a id="property-lifetime_random"></a>
### float lifetime_random = `0.3`

How much lifetimes vary, 0–1 (0.3 = up to 30% shorter).

---

<a id="property-loop"></a>
### bool loop = `true`

Seamless loop: emission repeats every [duration](#property-duration) and the simulation is warmed up, so the last frame leads into the first. Off: the effect starts empty (bursts, one-shots).

---

<a id="property-palette"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) palette

Snap every particle color to this palette.

---

<a id="property-radial_accel"></a>
### float radial_accel = `0.0`

Push away from (positive) or pull toward (negative) the emitter, pixels per second².

---

<a id="property-rate"></a>
### float rate = `20.0`

Particles per second, emitted evenly.

---

<a id="property-seed"></a>
### int seed = `1`

Changes every random choice.

---

<a id="property-shape"></a>
### [Shape](#enum-shape) shape = `CIRCLE`

How each particle is drawn.

---

<a id="property-size_curve"></a>
### [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) size_curve

How size goes from start (0) to end (1) over each particle's life. Empty = evenly.

---

<a id="property-size_end"></a>
### float size_end = `1.0`

Size at death, in pixels.

---

<a id="property-size_random"></a>
### float size_random = `0.2`

How much sizes vary, 0–1.

---

<a id="property-size_start"></a>
### float size_start = `3.0`

Size at birth, in pixels.

---

<a id="property-speed"></a>
### Vector2 speed = `Vector2(8, 18)`

Starting speed, pixels per second: anywhere from x to y.

---

<a id="property-spread"></a>
### float spread = `40.0`

How far directions spread around [direction](#property-direction), in degrees (360 = every way).

---

<a id="property-sprite"></a>
### [Texture2D](https://docs.godotengine.org/en/stable/classes/class_texture2d.html) sprite

For the Sprite shape: a sheet of frames played over each particle's life.

---

<a id="property-sprite_frames"></a>
### Vector2i sprite_frames = `Vector2i(1, 1)`

For the Sprite shape: columns and rows of [sprite](#property-sprite).

---

<a id="property-streak"></a>
### float streak = `0.05`

For streaks: how far back the line reaches, in seconds of movement.

---

<a id="property-substeps"></a>
### int substeps = `4`

Simulation steps per frame; more is smoother for fast particles.

---

<a id="property-swirl"></a>
### float swirl = `0.0`

Swirl around the emitter, pixels per second² (positive = clockwise).

## Method Descriptions

<a id="method-make_preset"></a>
### Dictionary make_preset(preset: String) static

A ready-made effect, as property values to set on the op.

---

<a id="method-preset_names"></a>
### PackedStringArray preset_names() static

Names of the ready-made effects, for [make_preset()](#method-make_preset). They're tuned for 32×32 frames.

---

<a id="method-simulate"></a>
### Array[Array] simulate(frame_count: int, extra: int = 0)

The particles alive at each of `frame_count` frames: `[x, y, vx, vy, age, life, id]` each, positions from the emitter's center. `extra` more frames continue past the end (with [loop](#property-loop), frame `frame_count` is the first one again).
