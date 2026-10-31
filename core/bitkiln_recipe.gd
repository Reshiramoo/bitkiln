@tool
@icon("res://addons/bitkiln/icons/recipe.svg")
class_name BitKilnRecipe
extends Resource
## How to turn source images into baked files: a stack of [BitKilnOp]s and the
## [BitKilnOutput]s to write.
##
## Every source goes through the same ops and gets its own files, so one recipe can serve
## a whole set of sprites. Sources are never changed. In the editor, a recipe bakes again
## by itself when a source changes (see [member auto_bake]), so you can keep editing the
## original art. Without sources, ops start from a blank canvas: generators like
## [BitKilnShape] draw on it. Baked files are plain PNGs: exported games don't need BitKiln.

## Frames per second animations play at when nothing sets a speed.
const DEFAULT_FPS := 10.0

## The images to start from, each baked with the same ops into its own files. Their files
## are read directly, so import settings (compression, mipmaps) don't affect the pixels.
## Leave it empty to start from a blank canvas of [member canvas_size], for generator ops
## like [BitKilnShape] to draw on.
@export var sources: Array[Texture2D] = []:
	set(value):
		sources = value
		notify_property_list_changed()
## Columns and rows of frames, for sprite sheets. Ops treat each frame as its own image.
@export var frames := Vector2i.ONE:
	set(value):
		frames = value.maxi(1)
## Guess each source's frame grid instead of using [member frames] for all of them, for
## sources with different layouts.
@export var auto_frames := false
## Without sources: the size of one blank frame, in pixels.
@export var canvas_size := Vector2i(16, 16):
	set(value):
		canvas_size = value.maxi(1)
## Applied in order, top to bottom.
@export var ops: Array[BitKilnOp] = []
## Files to write when baked, for every source.
@export var outputs: Array[BitKilnOutput] = [BitKilnOutput.create(BitKilnOutput.Kind.COLOR)]
## Bake again whenever a source image (or a palette or texture an op uses) is reimported.
@export var auto_bake := true

## The first source. Setting it puts it first in [member sources]. Recipes saved before
## [member sources] existed load into it this way.
var source: Texture2D:
	get:
		return get_source(0)
	set(value):
		var rest: Array[Texture2D] = []
		for texture in sources:
			if texture != value:
				rest.append(texture)
		if value != null:
			rest.insert(0, value)
		sources = rest


func _validate_property(property: Dictionary) -> void:
	if property.name == "canvas_size" and not sources.is_empty():
		property.usage = PROPERTY_USAGE_STORAGE


## How many times the ops run per bake: once per source, or once for a blank canvas.
func get_run_count() -> int:
	var count := 0
	for texture in sources:
		if texture != null:
			count += 1
	return maxi(count, 1)


## Source number [param index], skipping empty slots; [code]null[/code] for a blank canvas.
func get_source(index := 0) -> Texture2D:
	var k := 0
	for texture in sources:
		if texture == null:
			continue
		if k == index:
			return texture
		k += 1
	return null


## The path outputs of run [param index] are named after: its source image's, or without
## sources the recipe's own, minus a "_kiln" suffix ([code]res://fx/spark_kiln.tres[/code]
## names files "spark").
func get_naming_path(index := 0) -> String:
	var texture := get_source(index)
	if texture != null:
		return texture.resource_path
	if resource_path.is_empty():
		return ""
	return resource_path.get_base_dir().path_join(resource_path.get_file().get_basename().trim_suffix("_kiln") + ".tres")


## Frames per second [param output] plays at: its own [member BitKilnOutput.fps] when set,
## otherwise the speed the enabled ops it uses give the image (see
## [method BitKilnOp.playback_fps]: the op that first animates it sets the speed, and ops
## that animate it further keep it), otherwise 10. Without an output, the speed the ops give.
func get_fps(output: BitKilnOutput = null) -> float:
	if output != null and output.fps > 0.0:
		return output.fps
	var result := fps_before(ops.size(), output)
	return result if result > 0.0 else DEFAULT_FPS


## The speed the enabled ops before op number [param index] give the image (that
## [param output] uses, when given); 0 when none of them animates it.
func fps_before(index: int, output: BitKilnOutput = null) -> float:
	var result := 0.0
	for i in mini(index, ops.size()):
		var op := ops[i]
		if op == null or not op.enabled or (output != null and not output.uses_op(op)):
			continue
		result = op.playback_fps(result)
	return result


## Runs the ops on source [param source_index] and returns one context per variant; see
## [method BitKilnBaker.run].
func run(op_count := -1, source_index := 0, skip: Array[BitKilnOp] = []) -> Array[BitKilnContext]:
	return BitKilnBaker.run(self, op_count, source_index, skip)


## Runs the ops on every source and writes the outputs; see [method BitKilnBaker.bake].
func bake() -> BitKilnBaker.Result:
	return BitKilnBaker.bake(self)
