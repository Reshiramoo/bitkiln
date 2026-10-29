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


## Source number [param index] of [param recipe] as an [Image]: read from the file itself
## when it's an image file (exact pixels, whatever the import settings), from the texture
## otherwise. [code]null[/code] without that source.
static func load_source(recipe: BitKilnRecipe, index := 0) -> Image:
	var texture := recipe.get_source(index)
	if texture == null:
		return null
	return load_texture_image(texture)


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


## Runs the recipe's first [param op_count] ops (all of them when negative), leaving out
## the ones in [param skip], on source number [param source_index], and returns one
## context per variant, or nothing when the source can't be read. Without sources, the ops
## start from a blank canvas.
static func run(recipe: BitKilnRecipe, op_count := -1, source_index := 0, skip: Array[BitKilnOp] = []) -> Array[BitKilnContext]:
	var result: Array[BitKilnContext] = []
	var image: Image
	var grid := recipe.frames
	if recipe.get_source(source_index) == null:
		var size := recipe.canvas_size * grid
		image = Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	else:
		image = load_source(recipe, source_index)
		if image != null and recipe.auto_frames:
			grid = BitKilnSheet.guess_frames(image)
	if image == null or image.is_empty():
		return result
	var context := BitKilnContext.create(image, grid)
	context.source_path = recipe.get_naming_path(source_index)
	result.append(context)
	var count := recipe.ops.size() if op_count < 0 else mini(op_count, recipe.ops.size())
	for i in count:
		var op := recipe.ops[i]
		if op == null or not op.enabled or op in skip:
			continue
		var next: Array[BitKilnContext] = []
		for c in result:
			next.append_array(op.process(c))
		result = next
	return result


## Runs the recipe on every source and saves the outputs. Outputs that leave out ops
## ([member BitKilnOutput.skip_ops]) get their own run; outputs with the same ops share one.
## [param before_save] is called as [code](path, index)[/code] before each file is saved,
## [code]index[/code] being its place in [member Result.files]; the editor uses it to move
## a file whose path changed, so references to it keep working.
static func bake(recipe: BitKilnRecipe, before_save := Callable()) -> Result:
	var result := Result.new()
	if recipe.outputs.is_empty():
		result.warnings.append("No outputs: nothing to write.")
	var seen := {}
	for source_index in recipe.get_run_count():
		var source_path := recipe.get_naming_path(source_index)
		if source_path.is_empty():
			result.errors.append("Save the recipe first: without a source image, outputs are named after the recipe.")
			return result
		for group in output_groups(recipe):
			var outputs: Array[BitKilnOutput] = group.outputs
			var contexts := run(recipe, -1, source_index, group.skip)
			if contexts.is_empty():
				result.errors.append("Couldn't read the source image %s." % source_path)
				break
			for context in contexts:
				for warning in context.warnings:
					if not warning in result.warnings:
						result.warnings.append(warning)
				_write_outputs(recipe, outputs, context, source_path, seen, result, before_save)
	return result


## The recipe's outputs grouped by the ops they leave out:
## [code]{"skip": Array[BitKilnOp], "outputs": Array[BitKilnOutput]}[/code] each.
static func output_groups(recipe: BitKilnRecipe) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var by_key := {}
	for output in recipe.outputs:
		if output == null:
			continue
		var skip: Array[BitKilnOp] = []
		var ids := PackedStringArray()
		for op in recipe.ops:
			if op != null and not output.uses_op(op):
				skip.append(op)
				ids.append(str(op.get_instance_id()))
		var key := ",".join(ids)
		if not by_key.has(key):
			var empty: Array[BitKilnOutput] = []
			by_key[key] = {"skip": skip, "outputs": empty}
			groups.append(by_key[key])
		(by_key[key].outputs as Array[BitKilnOutput]).append(output)
	return groups


## Every file [param recipe] writes with its current sources, ops and outputs, in the
## order [method bake] writes them. Runs the ops, since variants decide the files.
static func planned_files(recipe: BitKilnRecipe) -> PackedStringArray:
	var files := PackedStringArray()
	for source_index in recipe.get_run_count():
		var source_path := recipe.get_naming_path(source_index)
		for group in output_groups(recipe):
			var outputs: Array[BitKilnOutput] = group.outputs
			for context in run(recipe, -1, source_index, group.skip):
				for kind_pass in [0, 1]:
					for output in outputs:
						var editor_made := output.kind in [BitKilnOutput.Kind.CANVAS_TEXTURE, BitKilnOutput.Kind.SPRITE_FRAMES,
							BitKilnOutput.Kind.TILE_SET]
						if editor_made == (kind_pass == 1):
							files.append(output.resolve(source_path, recipe.resource_path, context.variant))
	return files


static func _write_outputs(recipe: BitKilnRecipe, outputs: Array[BitKilnOutput], context: BitKilnContext,
		source_path: String, seen: Dictionary, result: Result, before_save: Callable) -> void:
	var written_layers := {} # Kind -> path, for the outputs built from them
	for output in outputs:
		if output.kind in [BitKilnOutput.Kind.CANVAS_TEXTURE, BitKilnOutput.Kind.SPRITE_FRAMES, BitKilnOutput.Kind.TILE_SET]:
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
		if before_save.is_valid():
			before_save.call(path, result.files.size())
		if output.kind == BitKilnOutput.Kind.GIF:
			_save_bytes(gif_bytes(context, output, recipe.get_fps(output)), path, result)
			continue
		var image := palette_image(context.color) if output.kind == BitKilnOutput.Kind.PALETTE \
			else context.get_layer(layer).to_image()
		if _save_png(image, path, result):
			written_layers[output.kind] = path
	for output in outputs:
		if not output.kind in [BitKilnOutput.Kind.CANVAS_TEXTURE, BitKilnOutput.Kind.SPRITE_FRAMES, BitKilnOutput.Kind.TILE_SET]:
			continue
		var path := output.resolve(source_path, recipe.resource_path, context.variant)
		var error := _check_path(path, source_path, seen)
		if not error.is_empty():
			result.errors.append(error)
			continue
		var needs_normal := output.kind == BitKilnOutput.Kind.CANVAS_TEXTURE
		if not written_layers.has(BitKilnOutput.Kind.COLOR) or (needs_normal and not written_layers.has(BitKilnOutput.Kind.NORMAL)):
			result.errors.append("%s needs a Color%s output with the same ops in this recipe."
				% [path.get_file(), " and a Normal" if needs_normal else ""])
			continue
		seen[path] = true
		if before_save.is_valid():
			before_save.call(path, result.files.size())
		result.files.append(path)
		match output.kind:
			BitKilnOutput.Kind.CANVAS_TEXTURE:
				result.canvas_textures.append({
					"path": path,
					"diffuse": written_layers[BitKilnOutput.Kind.COLOR],
					"normal": written_layers[BitKilnOutput.Kind.NORMAL],
				})
			BitKilnOutput.Kind.SPRITE_FRAMES:
				result.sprite_frames.append({
					"path": path,
					"texture": written_layers[BitKilnOutput.Kind.COLOR],
					"frames": context.frames,
					"frame_size": context.frame_size,
					"empty": empty_frames(context),
					"animations": output.animations,
					"names": output.animation_names,
					"fps": recipe.get_fps(output),
					"loop": output.loop,
					"skip_empty": output.skip_empty,
				})
			BitKilnOutput.Kind.TILE_SET:
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
	parts.append(_describe(recipe, true))
	# Where files go is part of the result too.
	parts.append(str(ProjectSettings.get_setting(BitKilnOutput.SETTING_LAYOUT, BitKilnOutput.DEFAULT_LAYOUT)))
	parts.append(str(ProjectSettings.get_setting(BitKilnOutput.SETTING_FOLDER, BitKilnOutput.DEFAULT_FOLDER)))
	return "\n".join(parts).md5_text()


## Like [method fingerprint], but cheap enough to check many times a second: files count by
## their modification time instead of their contents. Changes whenever the recipe is edited.
static func edit_signature(recipe: BitKilnRecipe) -> String:
	return _describe(recipe, false).md5_text()


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
	return _save_bytes(image.save_png_to_buffer(), path, result)


## [param output]'s animated GIF of [param context]'s frames, at [param fps] frames per second
## ([member BitKilnOutput.fps] when 0 or less, or 10 if that's 0 too).
static func gif_bytes(context: BitKilnContext, output: BitKilnOutput, fps := 0.0) -> PackedByteArray:
	var empty := empty_frames(context) if output.skip_empty else PackedInt32Array()
	var frames: Array[Image] = []
	var image := context.color.to_image()
	var size := context.frame_size
	for index in context.frames.x * context.frames.y:
		if index in empty:
			continue
		frames.append(image.get_region(Rect2i(Vector2i(index % context.frames.x, index / context.frames.x) * size, size)))
	if frames.is_empty():
		frames.append(image.get_region(Rect2i(Vector2i.ZERO, size)))
	if fps <= 0.0:
		fps = output.fps if output.fps > 0.0 else BitKilnRecipe.DEFAULT_FPS
	return BitKilnGif.encode(frames, fps, output.loop, output.gif_scale)


## Saves [param bytes] unless the file already holds exactly them. True when the file is
## up to date afterwards.
static func _save_bytes(bytes: PackedByteArray, path: String, result: Result) -> bool:
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


static func _describe(value: Variant, hash_files: bool) -> String:
	if value is Resource:
		var resource := value as Resource
		var path := resource.resource_path
		if not path.is_empty() and not "::" in path and not resource is BitKilnRecipe:
			# A file of its own (an image, a palette, a saved op): its contents count.
			return "%s#%s" % [path, FileAccess.get_md5(path) if hash_files else str(FileAccess.get_modified_time(path))]
		var text := resource.get_class()
		var script := resource.get_script() as Script
		if script != null:
			text = "%s#%s" % [script.resource_path, FileAccess.get_md5(script.resource_path)]
		for property in resource.get_property_list():
			if property.usage & PROPERTY_USAGE_STORAGE == 0 or property.name in _IGNORED_PROPERTIES:
				continue
			if resource is BitKilnRecipe and property.name == "auto_bake":
				continue
			text += "\n%s=%s" % [property.name, _describe(resource.get(property.name), hash_files)]
		return text
	if value is Array:
		var items := PackedStringArray()
		for item: Variant in value:
			items.append(_describe(item, hash_files))
		return "[%s]" % ", ".join(items)
	return var_to_str(value)
