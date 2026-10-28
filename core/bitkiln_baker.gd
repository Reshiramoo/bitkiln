@tool
class_name BitKilnBaker
extends RefCounted
## Runs [BitKilnRecipe]s and writes their outputs.
##
## [method run] only computes, so it works anywhere, including in a running game (for
## example to recolor a sprite at runtime). [method bake] also saves files, which only
## makes sense in the editor or a [code]--headless[/code] script.

## What [method bake] did.
class Result:
	extends RefCounted
	## Files written (unchanged files are skipped, so they don't reimport for nothing).
	var written: PackedStringArray = []
	## Every output file, written or already up to date.
	var files: PackedStringArray = []
	## Why files couldn't be written. Empty when the bake worked.
	var errors: PackedStringArray = []
	## Problems that didn't stop the bake, from the ops and the outputs.
	var warnings: PackedStringArray = []
	## [CanvasTexture] outputs, made by the editor once their PNGs are imported:
	## [code]{"path": String, "diffuse": String, "normal": String}[/code] each.
	var canvas_textures: Array[Dictionary] = []
	## [SpriteFrames] outputs, made by the editor once their PNGs are imported: [code]path[/code],
	## [code]texture[/code] (the PNG), [code]frames[/code], [code]frame_size[/code],
	## [code]empty[/code] (indices of frames with no visible pixels), [code]animations[/code],
	## [code]names[/code], [code]fps[/code], [code]loop[/code] and [code]skip_empty[/code].
	var sprite_frames: Array[Dictionary] = []
	## [TileSet] outputs, made by the editor once their PNGs are imported: [code]path[/code],
	## [code]texture[/code], [code]frames[/code], [code]frame_size[/code], [code]empty[/code],
	## [code]masks[/code] (each cell's neighbour bits from [BitKilnAutotile], -1 for none, or
	## empty without one), [code]terrain_name[/code] and [code]terrain_color[/code].
	var tile_sets: Array[Dictionary] = []

	## True when there are no [member errors].
	var ok: bool:
		get:
			return errors.is_empty()


## Image files BitKiln reads directly.
const IMAGE_EXTENSIONS: Array[String] = ["png", "webp", "jpg", "jpeg", "bmp", "tga", "svg"]
## Properties every Resource has, left out of fingerprints.
const _IGNORED_PROPERTIES: Array[String] = ["resource_path", "resource_name", "resource_local_to_scene",
	"resource_scene_unique_id", "script"]


## The recipe's source as an [Image]: read from the file itself when it's an image file
## (exact pixels, whatever the import settings), from the texture otherwise.
static func load_source(recipe: BitKilnRecipe) -> Image:
	if recipe.source == null:
		return null
	return load_texture_image(recipe.source)


## [param texture]'s pixels, from its file when possible. Palettes and other textures
## ops use go through this too.
static func load_texture_image(texture: Texture2D) -> Image:
	var from_file := load_image_file(texture.resource_path)
	if from_file != null:
		return from_file
	var image := texture.get_image()
	if image != null and image.is_compressed():
		image.decompress()
	return image


## The image file at [param path] decoded as is, or [code]null[/code] when it isn't a
## readable image file (exported games only have the imported versions).
static func load_image_file(path: String) -> Image:
	var extension := path.get_extension().to_lower()
	if not extension in IMAGE_EXTENSIONS or not FileAccess.file_exists(path):
		return null
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var image := Image.new()
	var error: Error
	match extension:
		"png":
			error = image.load_png_from_buffer(bytes)
		"webp":
			error = image.load_webp_from_buffer(bytes)
		"jpg", "jpeg":
			error = image.load_jpg_from_buffer(bytes)
		"bmp":
			error = image.load_bmp_from_buffer(bytes)
		"tga":
			error = image.load_tga_from_buffer(bytes)
		"svg":
			error = image.load_svg_from_buffer(bytes)
	return image if error == OK and not image.is_empty() else null


## Runs the recipe's first [param op_count] ops (all of them when negative) and returns
## one context per variant, or nothing when the source can't be read. Without a source,
## the ops start from a blank canvas.
static func run(recipe: BitKilnRecipe, op_count := -1) -> Array[BitKilnContext]:
	var result: Array[BitKilnContext] = []
	var image: Image
	if recipe.source == null:
		var size := recipe.canvas_size * recipe.frames
		image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	else:
		image = load_source(recipe)
	if image == null or image.is_empty():
		return result
	var context := BitKilnContext.create(image, recipe.frames)
	context.source_path = recipe.get_naming_path()
	result.append(context)
	var count := recipe.ops.size() if op_count < 0 else mini(op_count, recipe.ops.size())
	for i in count:
		var op := recipe.ops[i]
		if op == null or not op.enabled:
			continue
		var next: Array[BitKilnContext] = []
		for c in result:
			next.append_array(op.process(c))
		result = next
	return result


## Runs the recipe and saves its outputs.
static func bake(recipe: BitKilnRecipe) -> Result:
	var result := Result.new()
	var source_path := recipe.get_naming_path()
	if source_path.is_empty():
		result.errors.append("Save the recipe first: without a source image, outputs are named after the recipe.")
		return result
	var contexts := run(recipe)
	if contexts.is_empty():
		result.errors.append("Couldn't read the source image %s." % source_path)
		return result
	if recipe.outputs.is_empty():
		result.warnings.append("No outputs: nothing to write.")

	var seen := {}
	for context in contexts:
		for warning in context.warnings:
			if not warning in result.warnings:
				result.warnings.append(warning)
		var written_layers := {} # Kind -> path, for canvas textures
		for output in recipe.outputs:
			if output == null or output.kind in [BitKilnOutput.Kind.CANVAS_TEXTURE, BitKilnOutput.Kind.SPRITE_FRAMES,
					BitKilnOutput.Kind.TILE_SET]:
				continue
			var path := output.resolve(source_path, recipe.resource_path, context.variant)
			var layer := BitKilnContext.NORMAL if output.kind == BitKilnOutput.Kind.NORMAL else BitKilnContext.COLOR
			var error := _check_path(path, source_path, seen)
			if not error.is_empty():
				result.errors.append(error)
				continue
			if not context.has_layer(layer):
				result.errors.append("%s: there's no normal map to save. Add a BitKilnNormalMap op." % path.get_file())
				continue
			seen[path] = true
			var image := palette_image(context.color) if output.kind == BitKilnOutput.Kind.PALETTE \
				else context.get_layer(layer).to_image()
			if _save_png(image, path, result):
				written_layers[output.kind] = path
		for output in recipe.outputs:
			if output == null or output.kind != BitKilnOutput.Kind.TILE_SET:
				continue
			var path := output.resolve(source_path, recipe.resource_path, context.variant)
			var error := _check_path(path, source_path, seen)
			if not error.is_empty():
				result.errors.append(error)
				continue
			if not written_layers.has(BitKilnOutput.Kind.COLOR):
				result.errors.append("%s needs a Color output in the same recipe." % path.get_file())
				continue
			seen[path] = true
			result.files.append(path)
			result.tile_sets.append({
				"path": path,
				"texture": written_layers[BitKilnOutput.Kind.COLOR],
				"frames": context.frames,
				"frame_size": context.frame_size,
				"empty": empty_frames(context),
				"masks": context.meta.get("autotile_masks", PackedInt32Array()),
				"terrain_name": output.terrain_name if not output.terrain_name.is_empty() else path.get_file().get_basename(),
				"terrain_color": output.terrain_color,
			})
		for output in recipe.outputs:
			if output == null or output.kind != BitKilnOutput.Kind.SPRITE_FRAMES:
				continue
			var path := output.resolve(source_path, recipe.resource_path, context.variant)
			var error := _check_path(path, source_path, seen)
			if not error.is_empty():
				result.errors.append(error)
				continue
			if not written_layers.has(BitKilnOutput.Kind.COLOR):
				result.errors.append("%s needs a Color output in the same recipe." % path.get_file())
				continue
			seen[path] = true
			result.files.append(path)
			result.sprite_frames.append({
				"path": path,
				"texture": written_layers[BitKilnOutput.Kind.COLOR],
				"frames": context.frames,
				"frame_size": context.frame_size,
				"empty": empty_frames(context),
				"animations": output.animations,
				"names": output.animation_names,
				"fps": output.fps,
				"loop": output.loop,
				"skip_empty": output.skip_empty,
			})
		for output in recipe.outputs:
			if output == null or output.kind != BitKilnOutput.Kind.CANVAS_TEXTURE:
				continue
			var path := output.resolve(source_path, recipe.resource_path, context.variant)
			var error := _check_path(path, source_path, seen)
			if not error.is_empty():
				result.errors.append(error)
				continue
			if not written_layers.has(BitKilnOutput.Kind.COLOR) or not written_layers.has(BitKilnOutput.Kind.NORMAL):
				result.errors.append("%s needs a Color and a Normal output in the same recipe." % path.get_file())
				continue
			seen[path] = true
			result.files.append(path)
			result.canvas_textures.append({
				"path": path,
				"diffuse": written_layers[BitKilnOutput.Kind.COLOR],
				"normal": written_layers[BitKilnOutput.Kind.NORMAL],
			})
	return result


## Indices (row by row) of [param context]'s frames with no visible pixels.
static func empty_frames(context: BitKilnContext) -> PackedInt32Array:
	var result := PackedInt32Array()
	var size := context.frame_size
	var p := context.color.pixels
	for index in context.frames.x * context.frames.y:
		var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
		var empty := true
		for y in size.y:
			var row := (origin.y + y) * context.width + origin.x
			for x in size.x:
				if p[row + x] != 0:
					empty = false
					break
			if not empty:
				break
		if empty:
			result.append(index)
	return result


## Every distinct color of [param buffer], opaque, darkest first, as a one-row image.
static func palette_image(buffer: BitKilnBuffer) -> Image:
	var opaque := {}
	for c in buffer.get_colors():
		opaque[BitKilnBuffer.with_alpha(c, 255)] = true
	var colors: Array = opaque.keys()
	colors.sort_custom(func(a: int, b: int) -> bool:
		var la := (a & 0xFF) * 299 + ((a >> 8) & 0xFF) * 587 + ((a >> 16) & 0xFF) * 114
		var lb := (b & 0xFF) * 299 + ((b >> 8) & 0xFF) * 587 + ((b >> 16) & 0xFF) * 114
		return la < lb if la != lb else a < b)
	var strip := BitKilnBuffer.create(maxi(colors.size(), 1), 1)
	var p := strip.pixels
	for i in colors.size():
		p[i] = colors[i]
	strip.pixels = p
	return strip.to_image()


## Changes whenever anything that affects the result changes: the source file, the ops
## (and their scripts), files they use, and the outputs.
static func fingerprint(recipe: BitKilnRecipe) -> String:
	var parts := PackedStringArray()
	parts.append(_describe(recipe))
	return "\n".join(parts).md5_text()


## [code]""[/code] when [param path] can be written.
static func _check_path(path: String, source_path: String, seen: Dictionary) -> String:
	if not path.begins_with("res://") and not path.begins_with("user://") and not path.is_absolute_path():
		return "Invalid output path %s." % path
	if path == source_path:
		return "An output would overwrite the source image %s." % path.get_file()
	if seen.has(path):
		return "Two outputs write %s." % path.get_file()
	return ""


## Saves [param image] unless the file already holds exactly these bytes. True when the
## file is up to date afterwards.
static func _save_png(image: Image, path: String, result: Result) -> bool:
	var bytes := image.save_png_to_buffer()
	result.files.append(path)
	if FileAccess.file_exists(path) and FileAccess.get_file_as_bytes(path) == bytes:
		return true
	var dir := path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		result.errors.append("Couldn't write %s: %s." % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_buffer(bytes)
	file.close()
	result.written.append(path)
	return true


static func _describe(value: Variant) -> String:
	if value is Resource:
		var resource := value as Resource
		var path := resource.resource_path
		if not path.is_empty() and not "::" in path and not resource is BitKilnRecipe:
			# A file of its own (an image, a palette, a saved op): its contents count.
			return "%s#%s" % [path, FileAccess.get_md5(path)]
		var text := resource.get_class()
		var script := resource.get_script() as Script
		if script != null:
			text = "%s#%s" % [script.resource_path, FileAccess.get_md5(script.resource_path)]
		for property in resource.get_property_list():
			if property.usage & PROPERTY_USAGE_STORAGE == 0 or property.name in _IGNORED_PROPERTIES:
				continue
			if resource is BitKilnRecipe and property.name == "auto_bake":
				continue
			text += "\n%s=%s" % [property.name, _describe(resource.get(property.name))]
		return text
	if value is Array:
		var items := PackedStringArray()
		for item: Variant in value:
			items.append(_describe(item))
		return "[%s]" % ", ".join(items)
	return var_to_str(value)
