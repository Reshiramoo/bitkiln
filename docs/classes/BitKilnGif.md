# BitKilnGif

**Inherits:** [RefCounted](https://docs.godotengine.org/en/stable/classes/class_refcounted.html)

Encodes animated GIFs (GIF89a) from frames, for sharing animations outside the game.

## Description

All frames share one palette of up to 255 colors plus a transparent one; images with more colors are reduced by median cut first. Pixels less than half opaque become transparent.

## Methods

| Return | Signature |
|---|---|
| PackedByteArray | [encode](#method-encode)(frames: Array[[Image](https://docs.godotengine.org/en/stable/classes/class_image.html)], fps: float, loop: bool = true, scale: int = 1) static |
| PackedByteArray | [lzw](#method-lzw)(indices: PackedByteArray, min_code: int) static |

## Method Descriptions

<a id="method-encode"></a>
### PackedByteArray encode(frames: Array[[Image](https://docs.godotengine.org/en/stable/classes/class_image.html)], fps: float, loop: bool = true, scale: int = 1) static

A GIF of `frames` (same-size images), each shown for 1 / `fps` seconds, looping forever unless `loop` is off, scaled up by a whole `scale`.

---

<a id="method-lzw"></a>
### PackedByteArray lzw(indices: PackedByteArray, min_code: int) static

GIF-style LZW (least significant bit first, codes up to 12 bits) of `indices`, whose values fit in `min_code` bits. Follows Go's compress/lzw writer.
