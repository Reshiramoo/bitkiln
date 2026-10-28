@tool
@icon("res://addons/bitkiln/icons/recipe.svg")
class_name BitKilnRecipe
extends Resource
## How to turn a source image into baked files: a stack of [BitKilnOp]s and the
## [BitKilnOutput]s to write.
##
## The source is never changed. In the editor, a recipe bakes again by itself when its
## source changes (see [member auto_bake]), so you can keep editing the original art.
## Without a source, ops start from a blank canvas: generators like [BitKilnShape] draw on
## it. Baked files are plain PNGs: exported games don't need BitKiln.

## The image to start from. Its file is read directly, so import settings (compression,
## mipmaps) don't affect the pixels. Leave it empty to start from a blank canvas of
## [member canvas_size], for generator ops like [BitKilnShape] to draw on.
@export var source: Texture2D:
	set(value):
		source = value
		notify_property_list_changed()
## Columns and rows of frames, for sprite sheets. Ops treat each frame as its own image.
@export var frames := Vector2i.ONE:
	set(value):
		frames = value.maxi(1)
## Without a source: the size of one blank frame, in pixels.
@export var canvas_size := Vector2i(16, 16):
	set(value):
		canvas_size = value.maxi(1)
## Applied in order, top to bottom.
@export var ops: Array[BitKilnOp] = []
## Files to write when baked.
@export var outputs: Array[BitKilnOutput] = [BitKilnOutput.create(BitKilnOutput.Kind.COLOR)]
## Bake again whenever the source image (or a palette or texture an op uses) is reimported.
@export var auto_bake := true


func _validate_property(property: Dictionary) -> void:
	if property.name == "canvas_size" and source != null:
		property.usage = PROPERTY_USAGE_STORAGE


## The path outputs are named after: the source image's, or without a source the recipe's
## own, minus a "_kiln" suffix ([code]res://fx/spark_kiln.tres[/code] names files "spark").
func get_naming_path() -> String:
	if source != null:
		return source.resource_path
	if resource_path.is_empty():
		return ""
	return resource_path.get_base_dir().path_join(resource_path.get_file().get_basename().trim_suffix("_kiln") + ".tres")


## Runs the ops and returns one context per variant; see [method BitKilnBaker.run].
func run(op_count := -1) -> Array[BitKilnContext]:
	return BitKilnBaker.run(self, op_count)


## Runs the ops and writes the outputs; see [method BitKilnBaker.bake].
func bake() -> BitKilnBaker.Result:
	return BitKilnBaker.bake(self)
