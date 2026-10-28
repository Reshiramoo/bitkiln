# BitKilnAutotile

**Inherits:** [BitKilnOp](BitKilnOp.md)

Builds a full 47-tile "blob" tile set from five hand-drawn tiles, so a terrain (grass, water, walls) paints with every edge and corner right. Add a TileSet output to get a Godot TileSet with the terrain already set up for the TileMap terrain tools.

## Description

The source is five tiles in a row (set [BitKilnRecipe.frames](BitKilnRecipe.md#property-frames) to 5×1), each drawn in one style all around:
1. **Island**: a tile with nothing around it, outer corners on all four sides.
2. **Column**: connected above and below, so its left and right edges show.
3. **Row**: connected left and right, so its top and bottom edges show.
4. **Cross**: connected on all four sides but not diagonally: inner corners.
5. **Fill**: the middle of the terrain.
Every output tile is put together from quarters of these, so tiles need an even size.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [columns](#property-columns) | `8` |

## Methods

| Return | Signature |
|---|---|
| PackedInt32Array | [blob_masks](#method-blob_masks)() static |
| int | [normalize](#method-normalize)(mask: int) static |
| [Piece](#enum-piece) | [quarter_piece](#method-quarter_piece)(mask: int, quarter: int) static |

## Enumerations

<a id="enum-piece"></a>
### enum Piece

- **ISLAND** = `0`: Outer corners all around.
- **COLUMN** = `1`: Left and right edges.
- **ROW** = `2`: Top and bottom edges.
- **CROSS** = `3`: Inner corners.
- **FILL** = `4`: The middle.

## Constants

- **N** = `1`: Neighbour bit: connected above.
- **NE** = `2`: Neighbour bit: connected above and to the right.
- **E** = `4`: Neighbour bit: connected to the right.
- **SE** = `8`: Neighbour bit: connected below and to the right.
- **S** = `16`: Neighbour bit: connected below.
- **SW** = `32`: Neighbour bit: connected below and to the left.
- **W** = `64`: Neighbour bit: connected to the left.
- **NW** = `128`: Neighbour bit: connected above and to the left.

## Property Descriptions

<a id="property-columns"></a>
### int columns = `8`

Tiles per row in the output (47 tiles plus one empty cell).

## Method Descriptions

<a id="method-blob_masks"></a>
### PackedInt32Array blob_masks() static

The 47 neighbour combinations that look different: a corner only counts when both sides next to it are connected. Sorted, so the layout never changes.

---

<a id="method-normalize"></a>
### int normalize(mask: int) static

`mask` without corners whose two neighbouring sides aren't both connected.

---

<a id="method-quarter_piece"></a>
### [Piece](#enum-piece) quarter_piece(mask: int, quarter: int) static

Which template tile quarter number `quarter` (0 top-left, 1 top-right, 2 bottom-left, 3 bottom-right) comes from, for a tile with neighbours `mask`.
