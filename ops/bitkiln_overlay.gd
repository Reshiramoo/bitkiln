@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnOverlay
extends BitKilnOp
## Draws a texture on top of the image (or behind it): stickers and accessories, damage
## and dirt, patterns and cloth textures, light and shade drawn by hand, backgrounds.
##
## The texture is placed in every frame at its own size (no blurry scaling), at
## [member align] plus [member offset], tiled across the frame, or stretched to it pixel by
## pixel. A texture cut into [member texture_frames] puts its frames on the image's frames
## in turn, so an animated overlay follows an animated sheet. Blend modes other than Normal
## and Behind only change pixels the image already has, keeping its shape.

enum Placement {
	PLACE, ## Once per frame, at [member align] and [member offset].
	TILE, ## Repeated across the frame, starting at [member offset].
	STRETCH, ## Scaled to the frame's size, nearest neighbour.
}
enum Blend {
	NORMAL, ## Covers the image.
	BEHIND, ## Goes behind the image: backgrounds, glows, platforms.
	MULTIPLY, ## Darkens the image's pixels: shading, dirt, patterns.
	SCREEN, ## Lightens the image's pixels.
	OVERLAY, ## Darkens the dark parts and lightens the light parts: texture and contrast.
	ADD, ## Adds light to the image's pixels.
}
enum Layer {
	COLOR, ## The colors.
	NORMAL, ## The normal map from a [BitKilnNormalMap], for adding surface detail by hand.
}

## The image to draw.
@export var texture: Texture2D
## Columns and rows of [member texture]. Frame 1 of the image gets the texture's frame 1,
## frame 2 its frame 2, and so on, starting over when the texture has fewer frames.
@export var texture_frames := Vector2i.ONE:
	set(value):
		texture_frames = value.maxi(1)
## How the texture is laid out in each frame.
@export var placement := Placement.PLACE:
	set(value):
		placement = value
		notify_property_list_changed()
## Where the texture goes in the frame: (0, 0) top left, (0.5, 0.5) centered, (0.5, 1)
## bottom middle. The same point of the texture lands there.
@export var align := Vector2(0.5, 0.5)
## Moves the texture, in pixels: (1, 0) is one pixel right.
@export var offset := Vector2i.ZERO
## How the texture combines with the image.
@export var blend := Blend.NORMAL:
	set(value):
		blend = value
		notify_property_list_changed()
## For Normal: only draw over the image's own pixels, keeping its shape (a clipping mask).
@export var clip_to_sprite := false
## How strongly the texture shows, 0–1.
@export_range(0.0, 1.0, 0.01) var opacity := 1.0
## Below full opacity, draw whole pixels in an ordered pattern instead of mixing colors, so
## no new colors appear.
@export var dither := true
## Which layer to draw on.
@export var layer := Layer.COLOR
## Draw on this frame only (counted row by row from 0); -1 = every frame.
@export_range(-1, 1024, 1) var frame := -1


func _validate_property(property: Dictionary) -> void:
	if property.name == "align" and placement != Placement.PLACE:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "offset" and placement == Placement.STRETCH:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "clip_to_sprite" and blend != Blend.NORMAL:
		property.usage = PROPERTY_USAGE_STORAGE


func _apply(context: BitKilnContext) -> void:
	if texture == null or opacity <= 0.0:
		return
	var image := BitKilnBaker.load_texture_image(texture)
	if image == null or image.is_empty():
		context.warn("Overlay: couldn't read %s." % texture.resource_path)
		return
	var target := context.get_layer(BitKilnContext.NORMAL if layer == Layer.NORMAL else BitKilnContext.COLOR)
	if target == null:
		context.warn("Overlay: there's no normal map to draw on. Add a BitKilnNormalMap op before it.")
		return
	var over := BitKilnBuffer.from_image(image)
	var grid := texture_frames
	var piece := Vector2i(over.width / grid.x, over.height / grid.y)
	if piece.x == 0 or piece.y == 0:
		context.warn("Overlay: %s is smaller than its %dx%d frame grid." % [texture.resource_path.get_file(), grid.x, grid.y])
		return
	var pieces := grid.x * grid.y
	var size := context.frame_size
	var total := context.frames.x * context.frames.y
	var corner := Vector2i(((Vector2(size - piece)) * align).floor()) + offset
	var op := over.pixels
	var tp := target.pixels
	var w := target.width
	var partial := opacity < 1.0
	for index in total:
		if frame >= 0 and index != frame:
			continue
		var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
		var k := index % pieces
		var piece_origin := Vector2i(k % grid.x, k / grid.x) * piece
		for y in size.y:
			for x in size.x:
				var sx: int
				var sy: int
				match placement:
					Placement.TILE:
						sx = posmod(x - offset.x, piece.x)
						sy = posmod(y - offset.y, piece.y)
					Placement.STRETCH:
						sx = x * piece.x / size.x
						sy = y * piece.y / size.y
					_:
						sx = x - corner.x
						sy = y - corner.y
						if sx < 0 or sy < 0 or sx >= piece.x or sy >= piece.y:
							continue
				var top := op[(piece_origin.y + sy) * over.width + piece_origin.x + sx]
				var top_alpha := (top >> 24) & 0xFF
				if top_alpha == 0:
					continue
				if partial:
					if dither:
						if opacity <= BitKilnFilter.BAYER_4[(y % 4) * 4 + x % 4]:
							continue
					else:
						top_alpha = roundi(top_alpha * opacity)
						top = BitKilnBuffer.with_alpha(top, top_alpha)
				var i := (origin.y + y) * w + origin.x + x
				tp[i] = mix(top, tp[i], blend, clip_to_sprite)
	target.pixels = tp


## [param top] combined with [param bottom] by [param mode] (see [enum Blend]).
## [param clip] keeps Normal inside [param bottom]'s pixels.
static func mix(top: int, bottom: int, mode: Blend, clip := false) -> int:
	match mode:
		Blend.NORMAL:
			if not clip:
				return BitKilnBuffer.blend(top, bottom)
		Blend.BEHIND:
			return BitKilnBuffer.blend(bottom, top)
	var bottom_alpha := (bottom >> 24) & 0xFF
	if bottom_alpha == 0:
		return bottom
	var a := ((top >> 24) & 0xFF) / 255.0
	var result := PackedInt32Array([0, 0, 0])
	for channel in 3:
		var shift := channel * 8
		var b := (bottom >> shift) & 0xFF
		var t := (top >> shift) & 0xFF
		var m := t
		match mode:
			Blend.MULTIPLY:
				m = b * t / 255
			Blend.SCREEN:
				m = 255 - (255 - b) * (255 - t) / 255
			Blend.OVERLAY:
				m = 2 * b * t / 255 if b < 128 else 255 - 2 * (255 - b) * (255 - t) / 255
			Blend.ADD:
				m = mini(b + t, 255)
		result[channel] = roundi(lerpf(b, m, a))
	return BitKilnBuffer.pack(result[0], result[1], result[2], bottom_alpha)
