@tool
@abstract
class_name BitKilnOp
extends Resource
## One step of a [BitKilnRecipe]. Extend it and override [method _apply] to make your own.
##
## Ops change a [BitKilnContext] in place. An op that turns one image into several
## variants (like [BitKilnPaletteSwap]) overrides [method process] instead and returns
## a context per variant; the ops after it then run on each one.

## Skipped while off, so you can compare the result with and without it.
@export var enabled := true


## The contexts that continue after this op: [param context] itself, changed by
## [method _apply], unless overridden.
func process(context: BitKilnContext) -> Array[BitKilnContext]:
	_apply(context)
	return [context]


## Changes [param context] in place.
func _apply(_context: BitKilnContext) -> void:
	pass


## Whether [param pixel] counts as part of the sprite: alpha at least [param alpha_threshold] (0–255).
static func is_solid(pixel: int, alpha_threshold: int) -> bool:
	return (pixel >> 24) & 0xFF >= alpha_threshold
