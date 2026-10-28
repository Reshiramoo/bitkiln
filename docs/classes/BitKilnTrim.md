# BitKilnTrim

**Inherits:** [BitKilnOp](BitKilnOp.md)

Cuts away empty space around the sprite. On a sheet, every frame is trimmed by the same amount (to the smallest box that fits all of them), so frames stay aligned.

## Properties

| Type | Name | Default |
|---|---|---|
| float | [alpha_threshold](#property-alpha_threshold) | `0.01` |
| int | [margin](#property-margin) | `0` |

## Property Descriptions

<a id="property-alpha_threshold"></a>
### float alpha_threshold = `0.01`

Pixels with less alpha than this count as empty.

---

<a id="property-margin"></a>
### int margin = `0`

Empty space to keep around the content.
