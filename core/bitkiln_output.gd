@tool
@icon("res://addons/bitkiln/icons/output.svg")
class_name BitKilnOutput
extends Resource
## A file a [BitKilnRecipe] writes when baked: a layer saved as a PNG, the result's
## palette, or a [CanvasTexture] that pairs the recipe's color and normal PNGs.

enum Kind {
	COLOR, ## The color layer, as a PNG.
	NORMAL, ## The normal map from a [BitKilnNormalMap], as a PNG.
	CANVAS_TEXTURE, ## A [CanvasTexture] [code].tres[/code] using the recipe's Color and Normal outputs, ready for a Sprite2D with 2D lights.
	PALETTE, ## Every color of the result, darkest to brightest, as a one-row PNG: usable as a palette by [BitKilnPaletteSwap], [BitKilnQuantize] or Pocket's shaders.
}

## Default [member path] for each [enum Kind].
const DEFAULT_PATHS := {
	Kind.COLOR: "{dir}/{name}_baked{variant}.png",
	Kind.NORMAL: "{dir}/{name}_baked{variant}_n.png",
	Kind.CANVAS_TEXTURE: "{dir}/{name}_lit{variant}.tres",
	Kind.PALETTE: "{dir}/{name}_palette{variant}.png",
}

## What to write. Changing it also changes [member path] while it's still a default one.
@export var kind := Kind.COLOR:
	set(value):
		if path == DEFAULT_PATHS.get(kind):
			path = DEFAULT_PATHS[value]
		kind = value
## Where to save. [code]{dir}[/code] is the source image's folder, [code]{name}[/code]
## its file name without extension, [code]{recipe}[/code] the recipe's file name without
## extension, and [code]{variant}[/code] an underscore and the variant's name (or nothing
## for the main image). Without [code]{variant}[/code], variants get it before the
## extension anyway, so they never overwrite each other.
@export var path := "{dir}/{name}_baked{variant}.png"


## An output of [param output_kind], at [param output_path] or the default path for that kind.
static func create(output_kind: Kind, output_path := "") -> BitKilnOutput:
	var output := BitKilnOutput.new()
	output.kind = output_kind
	if not output_path.is_empty():
		output.path = output_path
	return output


## [member path] with its placeholders filled in.
func resolve(source_path: String, recipe_path: String, variant: String) -> String:
	var suffix := "" if variant.is_empty() else "_" + variant
	var result := path
	if not "{variant}" in result and not variant.is_empty():
		result = result.get_basename() + "{variant}." + result.get_extension()
	result = result.replace("{dir}", source_path.get_base_dir()) \
		.replace("{name}", source_path.get_file().get_basename()) \
		.replace("{recipe}", recipe_path.get_file().get_basename()) \
		.replace("{variant}", suffix)
	return result.simplify_path()
