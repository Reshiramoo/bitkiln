# BitKilnFilter

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Soft image operations for ops like blur and glow: images as premultiplied float planes (red, green, blue, alpha), blurred frame by frame, then snapped back to a few alpha steps so the result still reads as pixel art.

## Methods

| Return | Signature |
|---|---|
| Array[PackedFloat32Array] | [blur](#method-blur)(planes: Array[PackedFloat32Array], w: int, h: int, frame: Vector2i, weights: PackedFloat32Array) static |
| [BitKilnBuffer](BitKilnBuffer.md) | [from_planes](#method-from_planes)(planes: Array[PackedFloat32Array], w: int, h: int) static |
| int | [gradient_color](#method-gradient_color)(gradient: [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html), value: float, steps: int, dither: bool, x: int, y: int) static |
| PackedFloat32Array | [kernel](#method-kernel)(kind: [Kernel](#enum-kernel), radius: int) static |
| Array | [nearest_sources](#method-nearest_sources)(sources: PackedByteArray, w: int, h: int, frame: Vector2i) static |
| Array[PackedFloat32Array] | [smear](#method-smear)(planes: Array[PackedFloat32Array], w: int, h: int, frame: Vector2i, direction: Vector2, length: int) static |
| float | [step_alpha](#method-step_alpha)(alpha: float, steps: int, dither: bool, x: int, y: int) static |
| void | [step_planes](#method-step_planes)(planes: Array[PackedFloat32Array], w: int, h: int, steps: int, dither: bool) static |
| Array[PackedFloat32Array] | [to_planes](#method-to_planes)(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static |

## Enumerations

<a id="enum-kernel"></a>
### enum Kernel

- **BOX** = `0`: Every pixel within the radius counts the same.
- **GAUSSIAN** = `1`: Nearer pixels count more: the softest look.

## Constants

- **BAYER_4** = `Array[float]([0.03125, 0.53125, 0.15625, 0.65625, 0.78125, 0.28125, 0.90625, 0.40625, 0.21875, 0.71875, 0.09375, 0.59375, 0.96875, 0.46875, 0.84375, 0.34375])`: 4×4 ordered-dithering (Bayer) thresholds, 0–1, row by row.

## Method Descriptions

<a id="method-blur"></a>
### Array[PackedFloat32Array] blur(planes: Array[PackedFloat32Array], w: int, h: int, frame: Vector2i, weights: PackedFloat32Array) static

Every plane blurred with `weights` across, then down, each frame of `frame` size on its own (outside the frame counts as transparent).

---

<a id="method-from_planes"></a>
### [BitKilnBuffer](BitKilnBuffer.md) from_planes(planes: Array[PackedFloat32Array], w: int, h: int) static

Premultiplied planes back to pixels.

---

<a id="method-gradient_color"></a>
### int gradient_color(gradient: [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html), value: float, steps: int, dither: bool, x: int, y: int) static

The color of `gradient` at `value` (0–1). With `steps` above 0, the value first snaps to the middle of one of that many bands (with `dither`, an ordered pattern at pixel (`x`, `y`) picks between neighbouring bands).

---

<a id="method-kernel"></a>
### PackedFloat32Array kernel(kind: [Kernel](#enum-kernel), radius: int) static

Weights for offsets -radius..radius, summing to 1.

---

<a id="method-nearest_sources"></a>
### Array nearest_sources(sources: PackedByteArray, w: int, h: int, frame: Vector2i) static

For every pixel: the distance to the nearest pixel where `sources` is 1 (0 on a source; `INF`-like when its frame has none), and that source's index. Two-pass chamfer transform with 1 / √2 steps, each frame of `frame` size on its own.

---

<a id="method-smear"></a>
### Array[PackedFloat32Array] smear(planes: Array[PackedFloat32Array], w: int, h: int, frame: Vector2i, direction: Vector2, length: int) static

Every plane smeared along `direction` over `length` pixels, trailing behind it (motion blur), each frame on its own.

---

<a id="method-step_alpha"></a>
### float step_alpha(alpha: float, steps: int, dither: bool, x: int, y: int) static

`alpha` (0–1) snapped to one of `steps` levels; with `dither`, pixels between two levels pick one by an ordered pattern instead of always rounding. `steps` 0 keeps it as is.

---

<a id="method-step_planes"></a>
### void step_planes(planes: Array[PackedFloat32Array], w: int, h: int, steps: int, dither: bool) static

Changes every pixel's alpha with [step_alpha()](#method-step_alpha), keeping the color.

---

<a id="method-to_planes"></a>
### Array[PackedFloat32Array] to_planes(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static

`buffer` as four premultiplied planes [r, g, b, a], values 0–1.
