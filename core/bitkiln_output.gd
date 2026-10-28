@tool
@icon("res://addons/bitkiln/icons/output.svg")
class_name BitKilnOutput
extends Resource
## A file a [BitKilnRecipe] writes when baked: a layer saved as a PNG, the result's
## palette, a [CanvasTexture] that pairs the recipe's color and normal PNGs, the
## [SpriteFrames] of an animated sheet, or a [TileSet].

enum Kind {
	COLOR, ## The color layer, as a PNG.
	NORMAL, ## The normal map from a [BitKilnNormalMap], as a PNG.
	CANVAS_TEXTURE, ## A [CanvasTexture] [code].tres[/code] using the recipe's Color and Normal outputs, ready for a Sprite2D with 2D lights.
	PALETTE, ## Every color of the result, darkest to brightest, as a one-row PNG: usable as a palette by [BitKilnPaletteSwap], [BitKilnQuantize] or Pocket's shaders.
	SPRITE_FRAMES, ## A [SpriteFrames] [code].tres[/code] for an AnimatedSprite2D, cutting the recipe's Color output into its frames.
	TILE_SET, ## A [TileSet] [code].tres[/code] with the recipe's Color output as an atlas, one tile per non-empty frame; after a [BitKilnAutotile], with a terrain set up for painting.
}
enum Animations {
	ONE, ## Every frame in one animation, row by row.
	PER_ROW, ## One animation per row of frames: walk cycles per direction, for example.
}

## Default [member path] for each [enum Kind].
const DEFAULT_PATHS := {
	Kind.COLOR: "{dir}/{name}_baked{variant}.png",
	Kind.NORMAL: "{dir}/{name}_baked{variant}_n.png",
	Kind.CANVAS_TEXTURE: "{dir}/{name}_lit{variant}.tres",
	Kind.PALETTE: "{dir}/{name}_palette{variant}.png",
	Kind.SPRITE_FRAMES: "{dir}/{name}_frames{variant}.tres",
	Kind.TILE_SET: "{dir}/{name}_tiles{variant}.tres",
}

## What to write. Changing it also changes [member path] while it's still a default one.
@export var kind := Kind.COLOR:
	set(value):
		if path == DEFAULT_PATHS.get(kind):
			path = DEFAULT_PATHS[value]
		kind = value
		notify_property_list_changed()
## Where to save. [code]{dir}[/code] is the source image's folder, [code]{name}[/code]
## its file name without extension (the recipe's folder and name without a source), [code]{recipe}[/code] the recipe's file name without
## extension, and [code]{variant}[/code] an underscore and the variant's name (or nothing
## for the main image). Without [code]{variant}[/code], variants get it before the
## extension anyway, so they never overwrite each other.
@export var path := "{dir}/{name}_baked{variant}.png"

@export_group("Sprite Frames")
## How frames are grouped into animations.
@export var animations := Animations.ONE
## Animation names, in order (one per row with Per Row). Missing names are "default" (One)
## or "row_0", "row_1"… (Per Row).
@export var animation_names: PackedStringArray = []
## Frames per second.
@export_range(0.1, 120.0, 0.1, "or_greater") var fps := 10.0
## Whether the animations loop.
@export var loop := true
## Leave out frames with no visible pixels (the unused cells at the end of a sheet).
@export var skip_empty := true
@export_group("Tile Set")
## Name of the terrain, after a [BitKilnAutotile]. Empty = the file's name.
@export var terrain_name := ""
## Color the terrain is shown with in the TileMap editor.
@export var terrain_color := Color(0.4, 0.75, 0.35)
@export_group("")


func _validate_property(property: Dictionary) -> void:
	if property.name in ["animations", "animation_names", "fps", "loop", "skip_empty"] and kind != Kind.SPRITE_FRAMES:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name in ["terrain_name", "terrain_color"] and kind != Kind.TILE_SET:
		property.usage = PROPERTY_USAGE_STORAGE


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
