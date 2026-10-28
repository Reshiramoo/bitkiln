@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnRotate
extends BitKilnOp
## Rotates every frame by any angle with RotSprite: the frame is scaled to 8× with
## Scale2x (three times), then sampled at the rotated positions. Lines stay clean and no
## new colors appear, unlike ordinary rotation, which smears or breaks pixel art.
##
## With [member directions], one sprite becomes a set facing every direction (8 for
## top-down characters, 16 for vehicles), either as variants (one file each) or as rows
## of one sheet.

enum Layout {
	VARIANTS, ## Each direction is its own variant, baked to its own file.
	ROWS, ## Directions are stacked as rows of one sheet: the frames of direction 0, then direction 1, and so on.
}

## Clockwise, in degrees. With [member directions], the first direction's angle.
@export_range(-360.0, 360.0, 0.1, "suffix:°") var angle := 45.0
## How many directions to make, evenly around the circle starting at [member angle]:
## 8 = every 45°. 0 or 1 = just [member angle].
@export_range(0, 64, 1) var directions := 0
@export var layout := Layout.VARIANTS
## Grow frames to fit the rotated frame's corners (the same size for every angle, so
## frames stay aligned). Off: keep the size and cut off what falls outside.
@export var expand := true


func _process(context: BitKilnContext) -> Array[BitKilnContext]:
	var angles := PackedFloat32Array()
	if directions <= 1:
		angles.append(angle)
	else:
		for i in directions:
			angles.append(angle + 360.0 * i / directions)
	var size := context.frame_size
	var out_size := size
	if expand:
		var diagonal := ceili(Vector2(size).length())
		out_size = Vector2i(diagonal, diagonal)
		# Keep the parity of the original, so the sprite stays centered on whole pixels.
		if (out_size.x - size.x) % 2 != 0:
			out_size.x += 1
		if (out_size.y - size.y) % 2 != 0:
			out_size.y += 1
	var big := scale8(context.color, context)
	var result: Array[BitKilnContext] = []
	if layout == Layout.ROWS and angles.size() > 1:
		var sheet := context.copy()
		var rows := context.frames.y * angles.size()
		for layer_name: StringName in context.layers:
			sheet.layers[layer_name] = BitKilnBuffer.create(out_size.x * context.frames.x, out_size.y * rows)
		for a in angles.size():
			_rotate_into(context, big, angles[a], out_size, sheet, a * context.frames.y)
		sheet.frames = Vector2i(context.frames.x, rows)
		sheet.reset_source_mapping()
		result.append(sheet)
		return result
	for a in angles:
		var rotated := context.copy()
		for layer_name: StringName in context.layers:
			rotated.layers[layer_name] = BitKilnBuffer.create(out_size.x * context.frames.x, out_size.y * context.frames.y)
		_rotate_into(context, big, a, out_size, rotated, 0)
		rotated.reset_source_mapping()
		if angles.size() > 1:
			var tag := "r%03d" % posmod(roundi(a), 360)
			rotated.variant = tag if context.variant.is_empty() else context.variant + "_" + tag
		result.append(rotated)
	return result


## The color layer at 8×, each frame scaled on its own with Scale2x three times.
static func scale8(color: BitKilnBuffer, context: BitKilnContext) -> BitKilnBuffer:
	var frame := context.frame_size
	var big := BitKilnScale.scale2x(color, frame)
	big = BitKilnScale.scale2x(big, frame * 2)
	return BitKilnScale.scale2x(big, frame * 4)


## Writes every frame of [param context], rotated by [param degrees], into the layers of
## [param target], starting at frame row [param row_offset].
func _rotate_into(context: BitKilnContext, big: BitKilnBuffer, degrees: float, out_size: Vector2i,
		target: BitKilnContext, row_offset: int) -> void:
	var size := context.frame_size
	# Exact quarter turns need no smoothing: sample the original pixels.
	var exact := is_zero_approx(fposmod(degrees + 0.0001, 90.0) - 0.0001)
	var scale := 1 if exact else 8
	if exact:
		big = context.color
	var theta := deg_to_rad(degrees)
	var cos_t := cos(theta)
	var sin_t := sin(theta)
	var bp := big.pixels
	var bw := big.width
	var source_center := Vector2(size) * 0.5
	var out_center := Vector2(out_size) * 0.5
	var normal := context.get_layer(BitKilnContext.NORMAL)
	var np := normal.pixels if normal != null else PackedInt32Array()
	var color_out: BitKilnBuffer = target.layers[BitKilnContext.COLOR]
	var cp := color_out.pixels
	var normal_out: BitKilnBuffer = target.layers.get(BitKilnContext.NORMAL)
	var nop := normal_out.pixels if normal_out != null else PackedInt32Array()
	var other_layers: Array[StringName] = []
	for layer_name: StringName in context.layers:
		if layer_name != BitKilnContext.COLOR and layer_name != BitKilnContext.NORMAL:
			other_layers.append(layer_name)
	for fy in context.frames.y:
		for fx in context.frames.x:
			var out_x0 := fx * out_size.x
			var out_y0 := (fy + row_offset) * out_size.y
			for y in out_size.y:
				for x in out_size.x:
					# Back from the destination pixel's center to the source frame.
					var p := Vector2(x + 0.5, y + 0.5) - out_center
					var sx := p.x * cos_t + p.y * sin_t + source_center.x
					var sy := -p.x * sin_t + p.y * cos_t + source_center.y
					if sx < 0.0 or sy < 0.0 or sx >= size.x or sy >= size.y:
						continue
					var bx := fx * size.x * scale + int(sx * scale)
					var by := fy * size.y * scale + int(sy * scale)
					var o := (out_y0 + y) * color_out.width + out_x0 + x
					cp[o] = bp[by * bw + bx]
					var src_index := (fy * size.y + int(sy)) * context.width + fx * size.x + int(sx)
					if normal_out != null:
						nop[o] = _rotate_normal(np[src_index], cos_t, sin_t)
					for layer_name in other_layers:
						var dst: BitKilnBuffer = target.layers[layer_name]
						dst.pixels[o] = (context.layers[layer_name] as BitKilnBuffer).pixels[src_index]
	color_out.pixels = cp
	if normal_out != null:
		normal_out.pixels = nop


## A normal map pixel turned clockwise by the angle (normals point up = positive y).
static func _rotate_normal(c: int, cos_t: float, sin_t: float) -> int:
	if c == 0:
		return 0
	var x := (c & 0xFF) - 127.5
	var y := ((c >> 8) & 0xFF) - 127.5
	return BitKilnBuffer.pack(roundi(x * cos_t + y * sin_t + 127.5), roundi(-x * sin_t + y * cos_t + 127.5),
		(c >> 16) & 0xFF, (c >> 24) & 0xFF)
