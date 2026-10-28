@tool
class_name BitKilnContext
extends RefCounted
## What a [BitKilnRecipe]'s ops work on: the image layers of one variant, and the frame
## grid they're cut into.
##
## Every layer has the same size. [member frames] splits them into equal cells; ops treat
## cell edges like image edges, so outlines, shadows and normals never reach into the
## neighbouring frame. Ops that change the size (padding, trimming, scaling) change every
## layer at once through [method remap_frames] or [method scale_nearest].

const COLOR := &"color"
const NORMAL := &"normal"

## Layer name -> [BitKilnBuffer]. [code]color[/code] always exists; [code]normal[/code]
## once a [BitKilnNormalMap] has run.
var layers := {}
## Columns and rows of frames.
var frames := Vector2i.ONE
## The variant's name, e.g. a palette's file name; empty for the main one.
var variant := ""
## The recipe's source image path, for messages.
var source_path := ""
## Messages collected while baking, shown in the BitKiln dock.
var warnings: PackedStringArray = []

var color: BitKilnBuffer:
	get:
		return layers[COLOR]
	set(value):
		layers[COLOR] = value

var width: int:
	get:
		return color.width

var height: int:
	get:
		return color.height

## Size of one frame in pixels.
var frame_size: Vector2i:
	get:
		return Vector2i(color.width / frames.x, color.height / frames.y)


static func create(image: Image, frame_grid := Vector2i.ONE) -> BitKilnContext:
	var context := BitKilnContext.new()
	context.color = BitKilnBuffer.from_image(image)
	context.frames = frame_grid.maxi(1)
	if context.width % context.frames.x != 0 or context.height % context.frames.y != 0:
		context.warn("Image size %dx%d isn't a multiple of the %dx%d frame grid; the leftover pixels are cut off."
			% [context.width, context.height, context.frames.x, context.frames.y])
		context.remap_frames(context.frame_size, Vector2i.ZERO)
	return context


func get_layer(layer_name: StringName) -> BitKilnBuffer:
	return layers.get(layer_name)


func has_layer(layer_name: StringName) -> bool:
	return layers.has(layer_name)


## A deep copy, for ops that split one context into variants.
func copy() -> BitKilnContext:
	var context := BitKilnContext.new()
	for layer_name: StringName in layers:
		context.layers[layer_name] = (layers[layer_name] as BitKilnBuffer).copy()
	context.frames = frames
	context.variant = variant
	context.source_path = source_path
	context.warnings = warnings.duplicate()
	return context


func warn(message: String) -> void:
	if not message in warnings:
		warnings.append(message)


## Moves every frame's content by [param offset] into frames of [param new_frame_size],
## cutting off whatever falls outside, in every layer. Padding is a bigger size and a
## positive offset; trimming a smaller size and a negative one.
func remap_frames(new_frame_size: Vector2i, offset: Vector2i) -> void:
	var old := frame_size
	for layer_name: StringName in layers:
		var src: BitKilnBuffer = layers[layer_name]
		var dst := BitKilnBuffer.create(new_frame_size.x * frames.x, new_frame_size.y * frames.y)
		var sp := src.pixels
		var dp := dst.pixels
		for fy in frames.y:
			for fx in frames.x:
				var sx0 := fx * old.x
				var sy0 := fy * old.y
				var dx0 := fx * new_frame_size.x
				var dy0 := fy * new_frame_size.y
				for y in new_frame_size.y:
					var sy := y - offset.y
					if sy < 0 or sy >= old.y:
						continue
					var src_row := (sy0 + sy) * src.width + sx0
					var dst_row := (dy0 + y) * dst.width + dx0
					for x in new_frame_size.x:
						var sx := x - offset.x
						if sx >= 0 and sx < old.x:
							dp[dst_row + x] = sp[src_row + sx]
		dst.pixels = dp
		layers[layer_name] = dst


## Scales every layer up by a whole [param factor], nearest neighbour. Ops with a smarter
## algorithm for the color layer replace it afterwards.
func scale_nearest(factor: int) -> void:
	for layer_name: StringName in layers:
		layers[layer_name] = scale_buffer(layers[layer_name], factor)


static func scale_buffer(src: BitKilnBuffer, factor: int) -> BitKilnBuffer:
	var dst := BitKilnBuffer.create(src.width * factor, src.height * factor)
	var sp := src.pixels
	var dp := dst.pixels
	for y in dst.height:
		var src_row := (y / factor) * src.width
		var dst_row := y * dst.width
		for x in dst.width:
			dp[dst_row + x] = sp[src_row + x / factor]
	dst.pixels = dp
	return dst

