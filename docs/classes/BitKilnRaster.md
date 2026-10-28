# BitKilnRaster

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Pixel-perfect shapes for generator ops, as masks: one byte per pixel of a `w`×`h` area, 1 inside. A pixel is inside a shape when its center is, which gives the symmetric, hand-drawn-looking circles and polygons of pixel art.

## Methods

| Return | Signature |
|---|---|
| PackedByteArray | [edge](#method-edge)(mask: PackedByteArray, w: int, h: int, width: int = 1) static |
| PackedByteArray | [ellipse](#method-ellipse)(w: int, h: int, rect: [Rect2](https://docs.godotengine.org/en/stable/classes/class_rect2.html)) static |
| PackedByteArray | [line](#method-line)(w: int, h: int, from: Vector2i, to: Vector2i, width: int = 1) static |
| void | [paint](#method-paint)(buffer: [BitKilnBuffer](BitKilnBuffer.md), origin: Vector2i, mask: PackedByteArray, w: int, h: int, color: int) static |
| PackedByteArray | [polygon](#method-polygon)(w: int, h: int, points: [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html)) static |
| PackedByteArray | [rectangle](#method-rectangle)(w: int, h: int, rect: [Rect2](https://docs.godotengine.org/en/stable/classes/class_rect2.html)) static |
| [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html) | [regular_polygon](#method-regular_polygon)(center: Vector2, radius: Vector2, sides: int, degrees: float = 0.0) static |
| [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html) | [star](#method-star)(center: Vector2, radius: Vector2, tips: int, inner: float, degrees: float = 0.0) static |

## Method Descriptions

<a id="method-edge"></a>
### PackedByteArray edge(mask: PackedByteArray, w: int, h: int, width: int = 1) static

The pixels of `mask` within `width` pixels of its edge (4-neighbour steps): an inner outline.

---

<a id="method-ellipse"></a>
### PackedByteArray ellipse(w: int, h: int, rect: [Rect2](https://docs.godotengine.org/en/stable/classes/class_rect2.html)) static

A filled ellipse inside `rect` (pixel coordinates, fractional allowed).

---

<a id="method-line"></a>
### PackedByteArray line(w: int, h: int, from: Vector2i, to: Vector2i, width: int = 1) static

A line from `from` to `to` (Bresenham, pixel coordinates) drawn with a square brush `width` pixels wide.

---

<a id="method-paint"></a>
### void paint(buffer: [BitKilnBuffer](BitKilnBuffer.md), origin: Vector2i, mask: PackedByteArray, w: int, h: int, color: int) static

Draws `color` over `buffer` where `mask` (frame-sized) is set, in the frame whose top-left corner is `origin`.

---

<a id="method-polygon"></a>
### PackedByteArray polygon(w: int, h: int, points: [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html)) static

A filled polygon (even-odd rule).

---

<a id="method-rectangle"></a>
### PackedByteArray rectangle(w: int, h: int, rect: [Rect2](https://docs.godotengine.org/en/stable/classes/class_rect2.html)) static

A filled rectangle.

---

<a id="method-regular_polygon"></a>
### [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html) regular_polygon(center: Vector2, radius: Vector2, sides: int, degrees: float = 0.0) static

Corners of a regular polygon around `center` (first corner straight up, turned clockwise by `degrees`).

---

<a id="method-star"></a>
### [PackedVector2Array](https://docs.godotengine.org/en/stable/classes/class_packedvector2array.html) star(center: Vector2, radius: Vector2, tips: int, inner: float, degrees: float = 0.0) static

Points of a star: `tips` outer points, inner corners at `inner` of the radius.
