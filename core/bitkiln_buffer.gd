@tool
class_name BitKilnBuffer
extends RefCounted
## RGBA8 pixels stored as packed ints, for fast per-pixel work in GDScript.
##
## A pixel is [code]r | g << 8 | b << 16 | a << 24[/code] as a signed 32-bit int (the
## layout of [method PackedByteArray.to_int32_array] on RGBA8 data). Fully transparent
## pixels are always [code]0[/code], whatever their color, so equal colors compare equal
## with [code]==[/code]. Use [method pack] to make pixel values, never shifts by hand.

## Width in pixels.
var width := 0
## Height in pixels.
var height := 0
## Row by row, [code]y * width + x[/code]. Packed arrays are copied on write: to change many
## pixels, copy it to a local variable, change that, and assign it back.
var pixels := PackedInt32Array()


## A transparent buffer of [param w]×[param h] pixels.
static func create(w: int, h: int) -> BitKilnBuffer:
	var buffer := BitKilnBuffer.new()
	buffer.width = w
	buffer.height = h
	buffer.pixels.resize(w * h)
	return buffer


## A copy of [param image] converted to RGBA8.
static func from_image(image: Image) -> BitKilnBuffer:
	var copy := image.duplicate() as Image
	if copy.is_compressed():
		copy.decompress()
	copy.convert(Image.FORMAT_RGBA8)
	var buffer := BitKilnBuffer.new()
	buffer.width = copy.get_width()
	buffer.height = copy.get_height()
	buffer.pixels = copy.get_data().to_int32_array()
	var p := buffer.pixels
	for i in p.size():
		if (p[i] >> 24) & 0xFF == 0:
			p[i] = 0
	buffer.pixels = p
	return buffer


## An RGBA8 [Image] of the pixels.
func to_image() -> Image:
	return Image.create_from_data(width, height, false, Image.FORMAT_RGBA8, pixels.to_byte_array())


## An [ImageTexture] of the pixels.
func to_texture() -> ImageTexture:
	return ImageTexture.create_from_image(to_image())


## An independent copy.
func copy() -> BitKilnBuffer:
	var buffer := BitKilnBuffer.new()
	buffer.width = width
	buffer.height = height
	buffer.pixels = pixels.duplicate()
	return buffer


## The pixel at ([param x], [param y]), or [code]0[/code] (transparent) outside the buffer.
func get_px(x: int, y: int) -> int:
	if x < 0 or y < 0 or x >= width or y >= height:
		return 0
	return pixels[y * width + x]


## Sets the pixel at ([param x], [param y]); does nothing outside the buffer.
func set_px(x: int, y: int, value: int) -> void:
	if x >= 0 and y >= 0 and x < width and y < height:
		pixels[y * width + x] = value


## Every distinct color, transparent excluded, in order of first appearance.
func get_colors() -> PackedInt32Array:
	var seen := {}
	for c in pixels:
		if c != 0 and not seen.has(c):
			seen[c] = true
	return PackedInt32Array(seen.keys())


## A pixel value from 0–255 channels. Alpha 0 gives [code]0[/code], whatever the color.
static func pack(r: int, g: int, b: int, a: int) -> int:
	if a <= 0:
		return 0
	var v := clampi(r, 0, 255) | clampi(g, 0, 255) << 8 | clampi(b, 0, 255) << 16 | mini(a, 255) << 24
	return v - 0x100000000 if v >= 0x80000000 else v


## Red channel of [param c], 0–255.
static func red(c: int) -> int:
	return c & 0xFF


## Green channel of [param c], 0–255.
static func green(c: int) -> int:
	return (c >> 8) & 0xFF


## Blue channel of [param c], 0–255.
static func blue(c: int) -> int:
	return (c >> 16) & 0xFF


## Alpha channel of [param c], 0–255.
static func alpha(c: int) -> int:
	return (c >> 24) & 0xFF


## The same color with alpha [param a].
static func with_alpha(c: int, a: int) -> int:
	return pack(c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, a)


## A pixel value as a [Color].
static func to_color(c: int) -> Color:
	return Color8(c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF, (c >> 24) & 0xFF)


## A [Color] as a pixel value.
static func from_color(color: Color) -> int:
	return pack(color.r8, color.g8, color.b8, color.a8)


## [param top] composited over [param bottom] (straight alpha).
static func blend(top: int, bottom: int) -> int:
	var ta := (top >> 24) & 0xFF
	if ta == 255 or bottom == 0:
		return top
	if ta == 0:
		return bottom
	var ba := (bottom >> 24) & 0xFF
	var a := ta + ba * (255 - ta) / 255
	var r := ((top & 0xFF) * ta + (bottom & 0xFF) * ba * (255 - ta) / 255) / a
	var g := (((top >> 8) & 0xFF) * ta + ((bottom >> 8) & 0xFF) * ba * (255 - ta) / 255) / a
	var b := (((top >> 16) & 0xFF) * ta + ((bottom >> 16) & 0xFF) * ba * (255 - ta) / 255) / a
	return pack(r, g, b, a)
