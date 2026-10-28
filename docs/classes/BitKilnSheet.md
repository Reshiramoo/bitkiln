# BitKilnSheet

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Helpers for sprite sheets.

## Methods

| Return | Signature |
|---|---|
| Vector2i | [guess_frames](#method-guess_frames)(image: [Image](https://docs.godotengine.org/en/stable/classes/class_image.html)) static |
| Array[Rect2i] | [island_bounds](#method-island_bounds)(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static |

## Method Descriptions

<a id="method-guess_frames"></a>
### Vector2i guess_frames(image: [Image](https://docs.godotengine.org/en/stable/classes/class_image.html)) static

A likely frame grid (columns, rows) for `image`: the most frames such that no sprite (a group of touching pixels) is cut by a frame edge and every frame fits the largest sprite. Images with nothing to go on give (1, 1).

---

<a id="method-island_bounds"></a>
### Array[Rect2i] island_bounds(buffer: [BitKilnBuffer](BitKilnBuffer.md)) static

Bounding boxes of every group of touching (8-connected) non-transparent pixels.
