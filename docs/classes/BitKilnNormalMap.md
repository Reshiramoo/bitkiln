# BitKilnNormalMap

**Inherits:** [BitKilnOp](BitKilnOp.md)

Makes a normal map from the sprite, for 2D lights. Save it with a Normal output, or pair it with the color in a [CanvasTexture](https://docs.godotengine.org/en/stable/classes/class_canvastexture.html) output.

## Description

The surface is built from a height map: a bevel that rises from the sprite's edge toward its middle (as if inflated), plus detail from the colors' brightness. Snapping limits the normals to a few directions and steepnesses, so lights fall on the sprite in clean bands, as a pixel artist would shade it, instead of smooth gradients. Ops after this one (scaling, padding) keep the normal layer aligned with the colors.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [alpha_threshold](#property-alpha_threshold) | `0.5` |
| bool | [bevel_frame_edges](#property-bevel_frame_edges) | `true` |
| [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) | [bevel_profile](#property-bevel_profile) |  |
| int | [bevel_radius](#property-bevel_radius) | `3` |
| float | [detail_depth](#property-detail_depth) | `0.5` |
| bool | [flip_green](#property-flip_green) | `false` |
| bool | [invert_detail](#property-invert_detail) | `false` |
| int | [snap_directions](#property-snap_directions) | `8` |
| int | [snap_steepness](#property-snap_steepness) | `2` |
| float | [strength](#property-strength) | `1.0` |

## Property Descriptions

<a id="property-alpha_threshold"></a>
### float alpha_threshold = `0.5`

Pixels with at least this alpha count as part of the sprite.

---

<a id="property-bevel_frame_edges"></a>
### bool bevel_frame_edges = `true`

The frame's edges count as the sprite's edge, so sprites cut off by the frame still bevel there. Turn off for tiles that continue into the next one.

---

<a id="property-bevel_profile"></a>
### [Curve](https://docs.godotengine.org/en/stable/classes/class_curve.html) bevel_profile

Shape of the bevel from the edge (0) to [bevel_radius](#property-bevel_radius) (1). Empty = rounded.

---

<a id="property-bevel_radius"></a>
### int bevel_radius = `3`

How far in from the edge the bevel rises, in pixels. 0 = no bevel.

---

<a id="property-detail_depth"></a>
### float detail_depth = `0.5`

Height the colors' brightness adds, in pixels: bright areas stand out.

---

<a id="property-flip_green"></a>
### bool flip_green = `false`

DirectX convention (green = down). Godot uses OpenGL's (green = up), so leave it off for Godot's 2D lights.

---

<a id="property-invert_detail"></a>
### bool invert_detail = `false`

Dark areas stand out instead of bright ones.

---

<a id="property-snap_directions"></a>
### int snap_directions = `8`

Directions a normal can face around the circle; 0 = any (smooth).

---

<a id="property-snap_steepness"></a>
### int snap_steepness = `2`

With snapping: how many steepness steps (besides facing the viewer).

---

<a id="property-strength"></a>
### float strength = `1.0`

Multiplies every slope: above 1 exaggerates the relief, below 1 flattens it.
