@tool
@abstract
class_name BitKilnOp
extends Resource
## One step of a [BitKilnRecipe]. Extend it and override [method _apply] to make your own.
##
## Ops change a [BitKilnContext] in place. An op that turns one image into several
## variants (like [BitKilnPaletteSwap]) overrides [method _process] instead and returns
## a context per variant; the ops after it then run on each one.
##
## Any op that keeps the image's size can be limited to part of it with a [member mask]:
## outside the mask, every layer keeps the pixels it had before the op.

## Skipped while off, so you can compare the result with and without it.
@export var enabled := true

@export_group("Mask")
## Limits the op to part of the image. Drawn over the source: either one frame's size
## (used for every frame) or the whole source sheet. White pixels are inside (or pixels of
## [member mask_color] with [member mask_by_color]), black or transparent ones outside.
## The mask follows padding, trimming and scaling done by earlier ops.
@export var mask: Texture2D
## Only pixels of [member mask_color] are inside, so one region map with a color per
## part (hair, armor, cape) can serve several ops.
@export var mask_by_color := false
## With [member mask_by_color]: the color of the region this op works on.
@export var mask_color := Color.WHITE
## Work outside the mask instead of inside it.
@export var mask_invert := false
@export_group("")


## Runs the op, then puts back the pixels outside the [member mask]. Returns the contexts
## that continue: usually [param context] itself.
func process(context: BitKilnContext) -> Array[BitKilnContext]:
	if mask == null:
		return _process(context)
	var before := context.copy()
	var inside := mask_pixels(context)
	var result := _process(context)
	if inside.is_empty():
		return result
	for after in result:
		if after.width != before.width or after.height != before.height:
			after.warn("%s: masks only work on ops that keep the image's size." % _name())
			continue
		for layer_name: StringName in after.layers:
			var now: BitKilnBuffer = after.layers[layer_name]
			var old: BitKilnBuffer = before.layers.get(layer_name)
			var np := now.pixels
			var op := old.pixels if old != null else PackedInt32Array()
			for i in np.size():
				if not inside[i]:
					np[i] = op[i] if old != null else 0
			now.pixels = np
	return result


## The contexts that continue after this op: [param context] itself, changed by
## [method _apply], unless overridden.
func _process(context: BitKilnContext) -> Array[BitKilnContext]:
	_apply(context)
	return [context]


## Changes [param context] in place.
func _apply(_context: BitKilnContext) -> void:
	pass


## Frames per second the op's animation is made for, which Sprite Frames and GIF outputs
## play at unless they set their own; 0 for ops that don't animate.
func get_fps() -> float:
	return 0.0


## 1 for each pixel of [param context]'s layers inside the mask, 0 outside; empty when
## there's no usable mask.
func mask_pixels(context: BitKilnContext) -> PackedByteArray:
	var inside := PackedByteArray()
	if mask == null:
		return inside
	var image := BitKilnBaker.load_texture_image(mask)
	if image == null or image.is_empty():
		context.warn("%s: couldn't read the mask %s." % [_name(), mask.resource_path])
		return inside
	var m := BitKilnBuffer.from_image(image)
	var source_frame := context.source_frame_size
	var per_frame := m.width == source_frame.x and m.height == source_frame.y
	var sheet := source_frame * context.frames
	if not per_frame and (m.width != sheet.x or m.height != sheet.y):
		context.warn("%s: the mask is %dx%d, but should be one frame (%dx%d) or the whole source (%dx%d)."
			% [_name(), m.width, m.height, source_frame.x, source_frame.y, sheet.x, sheet.y])
		return inside
	var key := BitKilnBuffer.from_color(mask_color)
	var mp := m.pixels
	var size := context.frame_size
	var w := context.width
	inside.resize(w * context.height)
	# Source pixel for each column and row of a frame, worked out once.
	var columns := PackedInt32Array()
	columns.resize(size.x)
	for x in size.x:
		columns[x] = context.to_source(Vector2i(x, 0)).x
	var rows := PackedInt32Array()
	rows.resize(size.y)
	for y in size.y:
		rows[y] = context.to_source(Vector2i(0, y)).y
	for y in context.height:
		var fy := y / size.y
		var sy := rows[y % size.y] + (0 if per_frame else fy * source_frame.y)
		for x in w:
			var fx := x / size.x
			var sx := columns[x % size.x] + (0 if per_frame else fx * source_frame.x)
			var c := mp[sy * m.width + sx]
			var on: bool
			if mask_by_color:
				on = c == key
			else:
				var a := (c >> 24) & 0xFF
				on = ((c & 0xFF) + ((c >> 8) & 0xFF) + ((c >> 16) & 0xFF)) * a >= 3 * 128 * 255
			inside[y * w + x] = 1 if on != mask_invert else 0
	return inside


## Whether [param pixel] counts as part of the sprite: alpha at least [param alpha_threshold] (0–255).
static func is_solid(pixel: int, alpha_threshold: int) -> bool:
	return (pixel >> 24) & 0xFF >= alpha_threshold


## The op's class name without the prefix, for messages: "Outline".
func _name() -> String:
	var script := get_script() as Script
	var global := String(script.get_global_name()) if script != null else ""
	return global.trim_prefix("BitKiln") if not global.is_empty() else get_class()
