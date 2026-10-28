@tool
class_name BitKilnPalette
extends RefCounted
## Reads palettes from textures: a row of colors per palette, as in Pocket's palette
## swap images and Lospec palettes imported by BitKiln ([code].hex[/code], [code].gpl[/code]).


## The colors in row [param row] of [param texture], left to right, transparent pixels
## skipped. With [param row] negative: every distinct color, row by row.
static func load_colors(texture: Texture2D, row := -1) -> PackedInt32Array:
	if texture == null:
		return PackedInt32Array()
	var image := BitKilnBaker.load_texture_image(texture)
	if image == null or image.is_empty():
		return PackedInt32Array()
	var buffer := BitKilnBuffer.from_image(image)
	if row < 0:
		return buffer.get_colors()
	var colors := PackedInt32Array()
	if row >= buffer.height:
		return colors
	for x in buffer.width:
		var c := buffer.pixels[row * buffer.width + x]
		if c != 0:
			colors.append(c)
	return colors


## Rows in [param texture]'s image.
static func row_count(texture: Texture2D) -> int:
	return texture.get_height() if texture != null else 0


## Squared distance between two colors, weighted for how the eye sees them
## ("redmean"); alpha counts fully.
static func distance(a: int, b: int) -> float:
	var r1 := a & 0xFF
	var r2 := b & 0xFF
	var rm := (r1 + r2) * 0.5
	var dr := float(r1 - r2)
	var dg := float(((a >> 8) & 0xFF) - ((b >> 8) & 0xFF))
	var db := float(((a >> 16) & 0xFF) - ((b >> 16) & 0xFF))
	var da := float(((a >> 24) & 0xFF) - ((b >> 24) & 0xFF))
	return (2.0 + rm / 256.0) * dr * dr + 4.0 * dg * dg + (2.0 + (255.0 - rm) / 256.0) * db * db + 3.0 * da * da


## The index of the color in [param palette] closest to [param c].
static func nearest(c: int, palette: PackedInt32Array) -> int:
	var best := -1
	var best_distance := INF
	for i in palette.size():
		var d := distance(c, palette[i])
		if d < best_distance:
			best_distance = d
			best = i
	return best
