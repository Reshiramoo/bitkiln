# BitKilnExtrude

**Inherits:** [BitKilnOp](BitKilnOp.md)

Grows every frame by [amount](#property-amount) pixels on each side, filled with copies of its edge pixels. For tiles and atlas frames: when the GPU samples slightly past a frame's edge (filtering, camera zoom, subpixel positions), it finds the same colors instead of a gap or the neighbouring frame. Set the TileSet's separation and margins to match.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [amount](#property-amount) | `1` |

## Property Descriptions

<a id="property-amount"></a>
### int amount = `1`

Pixels added on each side.
