# BitKilnOp

**Inherits:** [Resource](https://docs.godotengine.org/en/stable/classes/class_resource.html)

One step of a [BitKilnRecipe](BitKilnRecipe.md). Extend it and override [_apply()](#method-_apply) to make your own.

## Description

Ops change a [BitKilnContext](BitKilnContext.md) in place. An op that turns one image into several variants (like [BitKilnPaletteSwap](BitKilnPaletteSwap.md)) overrides [process()](#method-process) instead and returns a context per variant; the ops after it then run on each one.

## Properties

| Type | Name | Default |
|---|---|---|
| bool | [enabled](#property-enabled) | `true` |

## Methods

| Return | Signature |
|---|---|
| void | [_apply](#method-_apply)(_context: [BitKilnContext](BitKilnContext.md)) |
| bool | [is_solid](#method-is_solid)(pixel: int, alpha_threshold: int) static |
| Array[[BitKilnContext](BitKilnContext.md)] | [process](#method-process)(context: [BitKilnContext](BitKilnContext.md)) |

## Property Descriptions

<a id="property-enabled"></a>
### bool enabled = `true`

Skipped while off, so you can compare the result with and without it.

## Method Descriptions

<a id="method-_apply"></a>
### void _apply(_context: [BitKilnContext](BitKilnContext.md))

Changes `context` in place.

---

<a id="method-is_solid"></a>
### bool is_solid(pixel: int, alpha_threshold: int) static

Whether `pixel` counts as part of the sprite: alpha at least `alpha_threshold` (0–255).

---

<a id="method-process"></a>
### Array[[BitKilnContext](BitKilnContext.md)] process(context: [BitKilnContext](BitKilnContext.md))

The contexts that continue after this op: `context` itself, changed by [_apply()](#method-_apply), unless overridden.
