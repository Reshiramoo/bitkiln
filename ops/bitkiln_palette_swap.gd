@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnPaletteSwap
extends BitKilnOp
## Replaces colors, and makes one variant per palette: shiny forms, team colors, enemy
## tiers from one sprite.
##
## A palette is either two rows, as used by Pocket's [code]sprite_fx[/code] palette swap
## (row 0 = colors to find, row 1 = their replacements), or a single row of replacements
## for the colors in [member base_palette], such as a Lospec palette. With more than one
## palette, each variant is named after its palette's file and baked to its own file.
## Ops after this one run on every variant, so an outline or glow after a swap follows
## the new colors.

## One variant each. Two-row palettes map row 0 to row 1; one-row palettes replace the
## colors of [member base_palette], in order.
@export var palettes: Array[Texture2D] = []
## The colors one-row palettes replace, in the same order. Usually a palette of the
## sprite's original colors.
@export var base_palette: Texture2D
## How far (0–1, per channel) a color may be from a palette color and still be replaced.
## Keep it at 0 for clean pixel art.
@export_range(0.0, 0.5, 0.005) var tolerance := 0.0
## Also keep the image with its original colors, as a variant named "original".
@export var keep_original := false


## One context per palette (plus the original with [member keep_original]).
func _process(context: BitKilnContext) -> Array[BitKilnContext]:
	var result: Array[BitKilnContext] = []
	var valid: Array[Texture2D] = []
	for palette in palettes:
		if palette != null:
			valid.append(palette)
	if valid.is_empty():
		context.warn("Palette Swap: no palettes.")
		result.append(context)
		return result
	var named := valid.size() > 1 or keep_original
	if keep_original:
		var original := context.copy()
		if named:
			original.variant = _join(context.variant, "original")
		result.append(original)
	var used_names := {}
	for palette in valid:
		var mapping := _mapping(palette, context)
		if mapping.is_empty():
			continue
		var variant := context.copy()
		if named:
			var palette_name := palette.resource_path.get_file().get_basename().validate_filename()
			if palette_name.is_empty():
				palette_name = "palette"
			if used_names.has(palette_name):
				used_names[palette_name] += 1
				palette_name += str(used_names[palette_name])
			else:
				used_names[palette_name] = 1
			variant.variant = _join(context.variant, palette_name)
		_swap(variant.color, mapping[0], mapping[1])
		result.append(variant)
	if result.is_empty():
		result.append(context)
	return result


## [find colors, replacement colors], or empty when the palette can't be used.
func _mapping(palette: Texture2D, context: BitKilnContext) -> Array:
	var find: PackedInt32Array
	var replace: PackedInt32Array
	if BitKilnPalette.row_count(palette) >= 2:
		find = _row(palette, 0)
		replace = _row(palette, 1)
	else:
		if base_palette == null:
			context.warn("Palette Swap: %s has one row, so it needs a base palette." % palette.resource_path.get_file())
			return []
		find = BitKilnPalette.load_colors(base_palette, 0)
		replace = BitKilnPalette.load_colors(palette, 0)
	if find.size() != replace.size():
		context.warn("Palette Swap: %s has %d colors but replaces %d; the extra ones are ignored."
			% [palette.resource_path.get_file(), replace.size(), find.size()])
	var count := mini(find.size(), replace.size())
	find.resize(count)
	replace.resize(count)
	return [find, replace]


## Row [param row] including transparent slots, so the two rows stay aligned.
static func _row(palette: Texture2D, row: int) -> PackedInt32Array:
	var image := BitKilnBaker.load_texture_image(palette)
	var buffer := BitKilnBuffer.from_image(image)
	var colors := PackedInt32Array()
	for x in buffer.width:
		colors.append(buffer.pixels[row * buffer.width + x])
	return colors


func _swap(buffer: BitKilnBuffer, find: PackedInt32Array, replace: PackedInt32Array) -> void:
	var limit := roundi(tolerance * 255.0)
	var cache := {}
	var p := buffer.pixels
	for i in p.size():
		var c := p[i]
		if c == 0:
			continue
		if not cache.has(c):
			cache[c] = _replacement(c, find, replace, limit)
		p[i] = cache[c]
	buffer.pixels = p


## The closest find color within [param limit] wins; the pixel shifts by the difference
## between it and its replacement (exact on exact matches), keeping its own alpha.
static func _replacement(c: int, find: PackedInt32Array, replace: PackedInt32Array, limit: int) -> int:
	var best := -1
	var best_diff := limit + 1
	for i in find.size():
		var f := find[i]
		if f == 0:
			continue
		var diff := maxi(absi((c & 0xFF) - (f & 0xFF)), maxi(absi(((c >> 8) & 0xFF) - ((f >> 8) & 0xFF)),
			absi(((c >> 16) & 0xFF) - ((f >> 16) & 0xFF))))
		if diff < best_diff:
			best_diff = diff
			best = i
	if best < 0:
		return c
	var f := find[best]
	var r := replace[best]
	if r == 0:
		return 0 # a transparent replacement erases the color
	return BitKilnBuffer.pack((c & 0xFF) + (r & 0xFF) - (f & 0xFF),
		((c >> 8) & 0xFF) + ((r >> 8) & 0xFF) - ((f >> 8) & 0xFF),
		((c >> 16) & 0xFF) + ((r >> 16) & 0xFF) - ((f >> 16) & 0xFF),
		(c >> 24) & 0xFF)


static func _join(a: String, b: String) -> String:
	return b if a.is_empty() else a + "_" + b
