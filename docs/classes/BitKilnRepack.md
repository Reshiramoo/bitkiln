# BitKilnRepack

**Inherits:** [BitKilnOp](BitKilnOp.md)

Rearranges frames into a new grid, or picks some of them: a 4×4 sheet into a 16-frame strip, a strip into rows of 8, or frames 5–8 of a sheet as their own animation. Frames are read and written row by row; leftover cells stay empty.

## Properties

| Type | Name | Default |
|---|---|---|
| int | [columns](#property-columns) | `0` |
| int | [count](#property-count) | `0` |
| int | [first](#property-first) | `0` |
| bool | [skip_empty](#property-skip_empty) | `false` |

## Property Descriptions

<a id="property-columns"></a>
### int columns = `0`

Frames per row in the new grid; 0 = all in one row.

---

<a id="property-count"></a>
### int count = `0`

How many frames to keep from [first](#property-first); 0 = all the rest.

---

<a id="property-first"></a>
### int first = `0`

The first frame to keep (counted row by row from 0).

---

<a id="property-skip_empty"></a>
### bool skip_empty = `false`

Leave out frames with no visible pixels.
