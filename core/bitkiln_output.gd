@tool
@icon("res://addons/bitkiln/icons/output.svg")
class_name BitKilnOutput
extends Resource
## A file a [BitKilnRecipe] writes when baked: a layer saved as a PNG, the result's
## palette, a [CanvasTexture] that pairs the recipe's color and normal PNGs, the
## [SpriteFrames] of an animated sheet, a [TileSet], or an animated GIF.

enum Kind {
	COLOR, ## The color layer, as a PNG.
	NORMAL, ## The normal map from a [BitKilnNormalMap], as a PNG.
	CANVAS_TEXTURE, ## A [CanvasTexture] [code].tres[/code] using the recipe's Color and Normal outputs, ready for a Sprite2D with 2D lights.
	PALETTE, ## Every color of the result, darkest to brightest, as a one-row PNG: usable as a palette by [BitKilnPaletteSwap], [BitKilnQuantize] or Pocket's shaders.
	SPRITE_FRAMES, ## A [SpriteFrames] [code].tres[/code] for an AnimatedSprite2D, cutting the recipe's Color output into its frames.
	TILE_SET, ## A [TileSet] [code].tres[/code] with the recipe's Color output as an atlas, one tile per non-empty frame; after a [BitKilnAutotile], with a terrain set up for painting.
	GIF, ## The frames as an animated GIF, for sharing outside the game.
}
enum Animations {
	ONE, ## Every frame in one animation, row by row.
	PER_ROW, ## One animation per row of frames: walk cycles per direction, for example.
}

## Where [code]{out}[/code] puts baked files (Project Settings → BitKiln → Output → Layout).
enum Layout {
	NEXT_TO_SOURCE, ## Beside the source: [code]art/hero_baked.png[/code].
	FOLDER_PER_SOURCE, ## In a folder beside the source: [code]art/hero_baked/hero.png[/code].
	SEPARATE_FOLDER, ## Under one folder, mirroring the project's folders, one folder per source: [code]baked/art/hero/hero.png[/code].
}

## Project setting: the [enum Layout] for [code]{out}[/code].
const SETTING_LAYOUT := "bitkiln/output/layout"
## Project setting: the folder [constant SEPARATE_FOLDER] uses.
const SETTING_FOLDER := "bitkiln/output/folder"
## The layout new projects use.
const DEFAULT_LAYOUT := Layout.SEPARATE_FOLDER
## The folder [constant SEPARATE_FOLDER] uses unless the project sets another.
const DEFAULT_FOLDER := "res://baked"

## Default [member path] for each [enum Kind].
const DEFAULT_PATHS := {
	Kind.COLOR: "{out}{variant}.png",
	Kind.NORMAL: "{out}{variant}_n.png",
	Kind.CANVAS_TEXTURE: "{out}{variant}_lit.tres",
	Kind.PALETTE: "{out}{variant}_palette.png",
	Kind.SPRITE_FRAMES: "{out}{variant}_frames.tres",
	Kind.TILE_SET: "{out}{variant}_tiles.tres",
	Kind.GIF: "{out}{variant}.gif",
}

## What to write. Changing it also changes [member path] while it's still a default one.
@export var kind := Kind.COLOR:
	set(value):
		if path == DEFAULT_PATHS.get(kind):
			path = DEFAULT_PATHS[value]
		kind = value
		notify_property_list_changed()
## Where to save. [code]{out}[/code] is where the project's output layout puts this
## source's files, without extension (see [enum Layout]). [code]{dir}[/code] is the source
## image's folder and [code]{name}[/code] its file name without extension (without a source,
## the recipe's folder and name). [code]{recipe}[/code] is the recipe's file name without
## extension, and [code]{variant}[/code] an underscore and the variant's name (or nothing
## for the main image). Without [code]{variant}[/code], variants get it before the
## extension anyway, so they never overwrite each other.
@export var path := "{out}{variant}.png"
## Ops this output leaves out: it's written from the result of the other ops. Edited as a
## checklist in the Inspector. Lets one recipe write several versions of each sprite, say
## with and without a glow.
@export_storage var skip_ops: Array[BitKilnOp] = []

@export_group("Animation")
## How frames are grouped into animations.
@export var animations := Animations.ONE
## Animation names, in order (one per row with Per Row). Missing names are "default" (One)
## or "row_0", "row_1"… (Per Row).
@export var animation_names: PackedStringArray = []
## Frames per second. 0 = the speed the recipe's animation is made for: the fps of its last
## [BitKilnAnimate], [BitKilnParticles] or [BitKilnFxSheet] this output uses (10 without
## one). See [method BitKilnRecipe.get_fps].
@export_range(0.0, 120.0, 0.1, "or_greater", "suffix:fps") var fps := 0.0
## Whether the animations loop.
@export var loop := true
## Leave out frames with no visible pixels (the unused cells at the end of a sheet).
@export var skip_empty := true
## For GIFs: each pixel becomes a block this many pixels wide, so small sprites are easy to see.
@export_range(1, 16, 1) var gif_scale := 4
@export_group("Tile Set")
## Name of the terrain, after a [BitKilnAutotile]. Empty = the file's name.
@export var terrain_name := ""
## Color the terrain is shown with in the TileMap editor.
@export var terrain_color := Color(0.4, 0.75, 0.35)
@export_group("")


func _validate_property(property: Dictionary) -> void:
	if property.name in ["animations", "animation_names"] and kind != Kind.SPRITE_FRAMES:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name in ["fps", "loop", "skip_empty"] and not kind in [Kind.SPRITE_FRAMES, Kind.GIF]:
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "gif_scale" and kind != Kind.GIF:
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
	result = result.replace("{out}", out_base(source_path)) \
		.replace("{dir}", source_path.get_base_dir()) \
		.replace("{name}", source_path.get_file().get_basename()) \
		.replace("{recipe}", recipe_path.get_file().get_basename()) \
		.replace("{variant}", suffix)
	return result.simplify_path()


## Where the project's output layout puts the files of the source at [param source_path],
## without extension: [code]res://baked/art/hero/hero[/code] for [code]res://art/hero.png[/code].
static func out_base(source_path: String) -> String:
	var dir := source_path.get_base_dir()
	var name := source_path.get_file().get_basename()
	match int(ProjectSettings.get_setting(SETTING_LAYOUT, DEFAULT_LAYOUT)):
		Layout.NEXT_TO_SOURCE:
			return dir.path_join(name + "_baked")
		Layout.FOLDER_PER_SOURCE:
			return dir.path_join(name + "_baked").path_join(name)
	var root := String(ProjectSettings.get_setting(SETTING_FOLDER, DEFAULT_FOLDER))
	if root.is_empty():
		root = DEFAULT_FOLDER
	var relative := dir.trim_prefix("res://").trim_prefix("user://")
	return root.path_join(relative).path_join(name).path_join(name)


## Whether this output uses [param op] (it isn't in [member skip_ops]).
func uses_op(op: BitKilnOp) -> bool:
	return not op in skip_ops
