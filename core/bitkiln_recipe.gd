@tool
@icon("res://addons/bitkiln/icons/recipe.svg")
class_name BitKilnRecipe
extends Resource
## How to turn a source image into baked files: a stack of [BitKilnOp]s and the
## [BitKilnOutput]s to write.
##
## The source is never changed. In the editor, a recipe bakes again by itself when its
## source changes (see [member auto_bake]), so you can keep editing the original art.
## Baked files are plain PNGs: exported games don't need BitKiln.

## The image to start from. Its file is read directly, so import settings (compression,
## mipmaps) don't affect the pixels.
@export var source: Texture2D
## Columns and rows of frames, for sprite sheets. Ops treat each frame as its own image.
@export var frames := Vector2i.ONE:
	set(value):
		frames = value.maxi(1)
## Applied in order, top to bottom.
@export var ops: Array[BitKilnOp] = []
## Files to write when baked.
@export var outputs: Array[BitKilnOutput] = [BitKilnOutput.create(BitKilnOutput.Kind.COLOR)]
## Bake again whenever the source image (or a palette or texture an op uses) is reimported.
@export var auto_bake := true


## Runs the ops and returns one context per variant; see [method BitKilnBaker.run].
func run(op_count := -1) -> Array[BitKilnContext]:
	return BitKilnBaker.run(self, op_count)


## Runs the ops and writes the outputs; see [method BitKilnBaker.bake].
func bake() -> BitKilnBaker.Result:
	return BitKilnBaker.bake(self)
