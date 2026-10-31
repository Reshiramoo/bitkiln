# BitKilnAnimate

**Inherits:** [BitKilnOp](BitKilnOp.md)

Turns a still sprite into an animation: hit flashes, squash and stretch, hops, shakes, wobbles, spins, waves, fades, dissolves and afterimages, from a stack of [BitKilnMotion](BitKilnMotion.md) effects. Each frame of the source becomes a row of frames (so a sheet of poses gets an animation per pose). After an op that already animated the image (a [BitKilnParticles](BitKilnParticles.md), say), it applies its effects across that animation instead, keeping its frames and speed (see [source_frames](#property-source_frames)).

## Description

How many frames: set how long the animation lasts ([duration](#property-duration)) and the speed it plays at ([fps](#property-fps)), and [frame_count](#property-frame_count) at Auto works out the count. Sprite Frames and GIF outputs play at the same speed.  It stays pixel art: movement snaps to whole pixels, rotation and skewing use RotSprite (no new colors, clean lines), and fades and dissolves remove whole pixels instead of making them half transparent. Effects apply in order, so a squash then a spin squashes first. Frames grow by [margin](#property-margin) on every side to give the motion room.

## Properties

| Type | Name | Default |
|---|---|---|
| bool | [dither_fades](#property-dither_fades) | `true` |
| float | [duration](#property-duration) | `0.8` |
| Array[[BitKilnMotion](BitKilnMotion.md)] | [effects](#property-effects) | `[]` |
| float | [fps](#property-fps) | `10.0` |
| int | [frame_count](#property-frame_count) | `0` |
| [Layout](#enum-layout) | [layout](#property-layout) | `ROWS` |
| bool | [loop](#property-loop) | `true` |
| int | [margin](#property-margin) | `4` |
| [SourceFrames](#enum-sourceframes) | [source_frames](#property-source_frames) | `AUTO` |

## Methods

| Return | Signature |
|---|---|
| bool | [follows_animation](#method-follows_animation)(earlier: float) |
| float | [get_duration](#method-get_duration)() |
| float | [get_fps](#method-get_fps)() |
| int | [get_frame_count](#method-get_frame_count)() |
| Dictionary | [make_preset](#method-make_preset)(preset: String) static |
| float | [playback_fps](#method-playback_fps)(earlier: float) |
| [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) | [preset_names](#method-preset_names)() static |

## Enumerations

<a id="enum-sourceframes"></a>
### enum SourceFrames

- **AUTO** = `0`: An animation when an earlier op made one ([BitKilnParticles](BitKilnParticles.md), [BitKilnFxSheet](BitKilnFxSheet.md), another Animate), poses otherwise.
- **POSES** = `1`: Each frame is a still pose that gets its own animation.
- **ANIMATION** = `2`: The frames are already an animation, played at [fps](#property-fps): the effects run across them.

<a id="enum-layout"></a>
### enum Layout

- **ROWS** = `0`: Each source frame gets its own row of frames.
- **STRIP** = `1`: All frames in one row, source frame after source frame.

## Property Descriptions

<a id="property-dither_fades"></a>
### bool dither_fades = `true`

Fades, blinks and afterimages remove whole pixels in an ordered pattern instead of making them half transparent.

---

<a id="property-duration"></a>
### float duration = `0.8`

How long the animation lasts, in seconds. Hidden when [frame_count](#property-frame_count) is set: the length is then the frame count at [fps](#property-fps).

---

<a id="property-effects"></a>
### Array[[BitKilnMotion](BitKilnMotion.md)] effects = `[]`

What happens over the animation, applied in order.

---

<a id="property-fps"></a>
### float fps = `10.0`

Frames per second the animation is made for. Sprite Frames and GIF outputs play at this speed unless they set their own, and so does the BitKiln dock's preview.

---

<a id="property-frame_count"></a>
### int frame_count = `0`

Frames in the animation. 0 = Auto: [duration](#property-duration) × [fps](#property-fps), nudged (by up to a quarter) so effects that repeat get the same number of frames every cycle.

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

---

<a id="property-source_frames"></a>
### [SourceFrames](#enum-sourceframes) source_frames = `AUTO`

What the frames coming into the op are. An animation keeps its frames (with [frame_count](#property-frame_count) at Auto) and, when an earlier op made it, its speed.

## Method Descriptions

<a id="method-follows_animation"></a>
### bool follows_animation(earlier: float)

Whether the frames coming in are treated as an animation, given the speed `earlier` ops gave them (0 when they didn't animate it).

---

<a id="method-get_duration"></a>
### float get_duration()

How long the animation plays, in seconds, at [fps](#property-fps).

---

<a id="method-get_fps"></a>
### float get_fps()

---

<a id="method-get_frame_count"></a>
### int get_frame_count()

How many frames each source frame becomes: [frame_count](#property-frame_count), or with Auto, [duration](#property-duration) × [fps](#property-fps) nudged so repeating effects divide evenly.

---

<a id="method-make_preset"></a>
### Dictionary make_preset(preset: String) static

A ready-made animation: [code]{"duration": float, "frame_count": 0 (Auto), "loop": bool,
"margin": int, "effects": Array[BitKilnMotion](BitKilnMotion.md)}[/code]. It leaves [fps](#property-fps) as it is.

---

<a id="method-playback_fps"></a>
### float playback_fps(earlier: float)

---

<a id="method-preset_names"></a>
### [PackedStringArray](https://docs.godotengine.org/en/stable/classes/class_packedstringarray.html) preset_names() static

Names of the ready-made animations, for [make_preset()](#method-make_preset).
