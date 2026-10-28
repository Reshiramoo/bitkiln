# BitKilnShadow

**Inherits:** [BitKilnOp](BitKilnOp.md)

A hard drop shadow: the sprite's silhouette, moved by [offset](#property-offset), behind it. With [length](#property-length) above 1 it repeats along the offset into a long shadow. Put a [BitKilnPad](BitKilnPad.md) before it so the shadow has room inside the frame.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [alpha_threshold](#property-alpha_threshold) | `0.5` |
| Color | [color](#property-color) | `Color(0, 0, 0, 0.5)` |
| int | [length](#property-length) | `1` |
| Vector2i | [offset](#property-offset) | `Vector2i(1, 1)` |

## Property Descriptions

<a id="property-alpha_threshold"></a>
### float alpha_threshold = `0.5`

Pixels with at least this alpha cast a shadow.

---

<a id="property-color"></a>
### Color color = `Color(0, 0, 0, 0.5)`

Shadow color; its alpha is the shadow's opacity.

---

<a id="property-length"></a>
### int length = `1`

Steps of [offset](#property-offset): 1 = drop shadow, more = long shadow.

---

<a id="property-offset"></a>
### Vector2i offset = `Vector2i(1, 1)`

Where the shadow falls, in pixels: (1, 1) is down and to the right.
