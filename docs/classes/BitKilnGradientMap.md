# BitKilnGradientMap

**Inherits:** [BitKilnOp](BitKilnOp.md)

Recolors by brightness: dark pixels take the gradient's left colors, bright ones its right colors. Turns greyscale art into any color scheme, or remaps a sprite onto a ramp. With a Constant gradient (or [steps](#property-steps)), only the gradient's colors appear.

## Properties

| Type | Name | Default |
|---|---|---|
| [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) | [gradient](#property-gradient) |  |
| bool | [normalize](#property-normalize) | `true` |
| int | [steps](#property-steps) | `0` |

## Methods

| Return | Signature |
|---|---|
| float | [luminance](#method-luminance)(c: int) static |

## Property Descriptions

<a id="property-gradient"></a>
### [Gradient](https://docs.godotengine.org/en/stable/classes/class_gradient.html) gradient

Colors from darkest (offset 0) to brightest (offset 1). Set its interpolation to Constant for hard bands of exactly its colors.

---

<a id="property-normalize"></a>
### bool normalize = `true`

Stretch the brightness range of the image to the whole gradient, so its darkest pixel gets the first color and its brightest the last.

---

<a id="property-steps"></a>
### int steps = `0`

Brightness levels to snap to before looking up the gradient; 0 = smooth.

## Method Descriptions

<a id="method-luminance"></a>
### float luminance(c: int) static

Perceived brightness of `c`, 0–1.
