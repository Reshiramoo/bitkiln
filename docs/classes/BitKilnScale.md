# BitKilnScale

**Inherits:** [BitKilnOp](BitKilnOp.md)

Scales up by a whole factor with a pixel-art scaler.

## Description

Nearest keeps every pixel a crisp block. The Scale2x family (also known as EPX/AdvMAME) rounds off diagonal staircases, the smoothed look of emulators and of some DS-era sprite upscales. MMPX (McGuire and Gagiu, 2021) builds on it with rules for lines, slopes and single-pixel details, so results look closer to hand-drawn. None of them add colors. Other layers (a normal map) are scaled nearest. Frames are scaled one by one, so edges never mix with the next frame.

## Properties

| Type | Name | Default |
|---|---|---|
| [Algorithm](#enum-algorithm) | [algorithm](#property-algorithm) | `SCALE2X` |
| int | [factor](#property-factor) | `2` |

## Methods

| Return | Signature |
|---|---|
| [BitKilnBuffer](BitKilnBuffer.md) | [mmpx](#method-mmpx)(src: [BitKilnBuffer](BitKilnBuffer.md), frame: Vector2i) static |
| [BitKilnBuffer](BitKilnBuffer.md) | [scale2x](#method-scale2x)(src: [BitKilnBuffer](BitKilnBuffer.md), frame: Vector2i) static |
| [BitKilnBuffer](BitKilnBuffer.md) | [scale3x](#method-scale3x)(src: [BitKilnBuffer](BitKilnBuffer.md), frame: Vector2i) static |

## Enumerations

<a id="enum-algorithm"></a>
### enum Algorithm

- **NEAREST** = `0`: Blocks of [factor](#property-factor)×[factor](#property-factor).
- **SCALE2X** = `1`: 2×, smoothed diagonals.
- **SCALE3X** = `2`: 3×, smoothed diagonals.
- **SCALE4X** = `3`: 4×: Scale2x twice.
- **MMPX** = `4`: 2×, style-preserving: keeps thin lines and details intact.
- **MMPX_4X** = `5`: 4×: MMPX twice.

## Property Descriptions

<a id="property-algorithm"></a>
### [Algorithm](#enum-algorithm) algorithm = `SCALE2X`

The scaler to use.

---

<a id="property-factor"></a>
### int factor = `2`

Factor for Nearest; the others have their own.

## Method Descriptions

<a id="method-mmpx"></a>
### [BitKilnBuffer](BitKilnBuffer.md) mmpx(src: [BitKilnBuffer](BitKilnBuffer.md), frame: Vector2i) static

MMPX 2× magnification. Ported from the MIT-licensed reference by Morgan McGuire and Mara Gagiu (algorithm and C++ implementation, 2020) via Kyle Moore's Rust port (2021). Neighbours are clamped to the pixel's frame. Unlike the reference, transparent pixels count as brighter than any color, so the background never grows into the sprite.

---

<a id="method-scale2x"></a>
### [BitKilnBuffer](BitKilnBuffer.md) scale2x(src: [BitKilnBuffer](BitKilnBuffer.md), frame: Vector2i) static

`src` scaled 2× with Scale2x (EPX), each `frame`-sized cell on its own.

---

<a id="method-scale3x"></a>
### [BitKilnBuffer](BitKilnBuffer.md) scale3x(src: [BitKilnBuffer](BitKilnBuffer.md), frame: Vector2i) static

`src` scaled 3× with Scale3x, each `frame`-sized cell on its own.
