@tool
extends RefCounted
## The editor's view of every BitKilnRecipe in the project: finds them, bakes them (then
## imports what was written and builds CanvasTexture outputs), remembers what each one
## was baked from, and rebakes recipes whose source or palettes were reimported.

signal recipes_changed
## A recipe was baked: its path and the [BitKilnBaker.Result].
signal baked(recipe_path: String, result: RefCounted)

const RECIPE_CLASS := &"BitKilnRecipe"
const SETTING_DEFAULT_FILTER := "rendering/textures/canvas_textures/default_texture_filter"
const CACHE_FILE := "bitkiln.cfg"

enum Status { NEVER, BAKED, STALE, ERROR }

var _recipe_paths := PackedStringArray()
var _fingerprints := ConfigFile.new() # recipe path -> fingerprint of the last successful bake
var _errors := {} # recipe path -> true when its last bake failed
var _recipe_files := {} # resource path -> [modified time, is a recipe]
var _cascade := {} # recipes baked automatically this frame: each bakes once, so chains can't loop
var _cascade_queued := false


func _init() -> void:
	_fingerprints.load(_cache_path())


## Every recipe file, sorted.
func get_recipe_paths() -> PackedStringArray:
	return _recipe_paths


## Rescans the filesystem for recipes.
func refresh() -> void:
	var found := PackedStringArray()
	_collect(EditorInterface.get_resource_filesystem().get_filesystem(), found)
	for path in _recipe_paths:
		# Added by add_recipe_path() and not scanned yet.
		if not path in found and FileAccess.file_exists(path) and EditorInterface.get_resource_filesystem().is_scanning():
			found.append(path)
	found.sort()
	if found != _recipe_paths:
		_recipe_paths = found
		recipes_changed.emit()


## Lists a recipe file right away, before the editor's next filesystem scan knows its class.
func add_recipe_path(path: String) -> void:
	if not path in _recipe_paths:
		_recipe_paths.append(path)
		_recipe_paths.sort()
		recipes_changed.emit()


func load_recipe(path: String) -> BitKilnRecipe:
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as BitKilnRecipe


func get_status(recipe: BitKilnRecipe) -> Status:
	var path := recipe.resource_path
	if _errors.has(path):
		return Status.ERROR
	var stored: String = _fingerprints.get_value("fingerprints", path, "")
	if stored.is_empty():
		return Status.NEVER
	if stored != BitKilnBaker.fingerprint(recipe) or not _outputs_exist(recipe):
		return Status.STALE
	return Status.BAKED


## Bakes [param recipe], imports the files it wrote and builds its CanvasTexture outputs.
func bake(recipe: BitKilnRecipe) -> BitKilnBaker.Result:
	var result := BitKilnBaker.bake(recipe)
	var filesystem := EditorInterface.get_resource_filesystem()
	if not result.written.is_empty():
		for path in result.written:
			filesystem.update_file(path)
		filesystem.reimport_files(result.written)
	for spec in result.canvas_textures:
		var error := _save_canvas_texture(spec)
		if not error.is_empty():
			result.errors.append(error)
	for spec in result.sprite_frames:
		var error := _save_sprite_frames(spec)
		if not error.is_empty():
			result.errors.append(error)
	for spec in result.tile_sets:
		var error := _save_tile_set(spec)
		if not error.is_empty():
			result.errors.append(error)
	var path := recipe.resource_path
	if result.ok:
		_errors.erase(path)
		if not path.is_empty():
			_fingerprints.set_value("fingerprints", path, BitKilnBaker.fingerprint(recipe))
			_fingerprints.set_value("outputs", path, result.files)
			_fingerprints.save(_cache_path())
	else:
		_errors[path] = true
	baked.emit(path, result)
	return result


## Called with the files the editor just reimported: recipes with auto bake on that use
## one of them bake again (once per frame at most, so chains of recipes can't loop).
func on_resources_reimported(paths: PackedStringArray) -> void:
	var changed := {}
	for path in paths:
		changed[path] = true
	for recipe_path in _recipe_paths:
		if _cascade.has(recipe_path):
			continue
		var recipe := load_recipe(recipe_path)
		if recipe == null or not recipe.auto_bake:
			continue
		for dependency in dependencies(recipe):
			if changed.has(dependency):
				_cascade[recipe_path] = true
				_bake_later.call_deferred(recipe_path)
				break
	if not _cascade_queued and not _cascade.is_empty():
		_cascade_queued = true
		_clear_cascade.call_deferred()


## Files [param recipe]'s result depends on: its source and every texture its ops use.
static func dependencies(recipe: BitKilnRecipe) -> PackedStringArray:
	var result := PackedStringArray()
	if recipe.source != null:
		result.append(recipe.source.resource_path)
	for op in recipe.ops:
		if op == null:
			continue
		for property in op.get_property_list():
			if property.usage & PROPERTY_USAGE_STORAGE == 0:
				continue
			var value: Variant = op.get(property.name)
			var items: Array = value if value is Array else [value]
			for item: Variant in items:
				if item is Texture2D and not (item as Texture2D).resource_path.is_empty():
					result.append((item as Texture2D).resource_path)
	return result


## Problems with how pixel art is imported or displayed, for the dock:
## [code]{"message": String, "fix": Callable}[/code] each.
func get_import_issues(recipe: BitKilnRecipe) -> Array[Dictionary]:
	var issues: Array[Dictionary] = []
	if int(ProjectSettings.get_setting(SETTING_DEFAULT_FILTER, 1)) != 0:
		issues.append({
			"message": "Project Settings: the default texture filter isn't Nearest, so pixel art looks blurry when scaled.",
			"fix": func() -> void:
				ProjectSettings.set_setting(SETTING_DEFAULT_FILTER, 0)
				ProjectSettings.save(),
		})
	var files := PackedStringArray()
	if recipe.source != null:
		files.append(recipe.source.resource_path)
	files.append_array(get_output_files(recipe))
	var lossy := PackedStringArray()
	var mipmapped := PackedStringArray()
	for file in files:
		var import := ConfigFile.new()
		if file.get_extension() == "tres" or import.load(file + ".import") != OK:
			continue
		if int(import.get_value("params", "compress/mode", 0)) != 0:
			lossy.append(file)
		if bool(import.get_value("params", "mipmaps/generate", false)):
			mipmapped.append(file)
	if not lossy.is_empty():
		issues.append({
			"message": "%s %s compressed lossily or for the GPU, which changes colors. Lossless keeps them exact."
				% [_file_list(lossy), "is" if lossy.size() == 1 else "are"],
			"fix": func() -> void: _set_import_params(lossy, {"compress/mode": 0}),
		})
	if not mipmapped.is_empty():
		issues.append({
			"message": "%s %s mipmaps, which blur pixel art when it's drawn smaller."
				% [_file_list(mipmapped), "has" if mipmapped.size() == 1 else "have"],
			"fix": func() -> void: _set_import_params(mipmapped, {"mipmaps/generate": false}),
		})
	return issues


## The files [param recipe] wrote when it was last baked.
func get_output_files(recipe: BitKilnRecipe) -> PackedStringArray:
	return _fingerprints.get_value("outputs", recipe.resource_path, PackedStringArray())


func _outputs_exist(recipe: BitKilnRecipe) -> bool:
	for file in get_output_files(recipe):
		if not FileAccess.file_exists(file):
			return false
	return true


func _bake_later(recipe_path: String) -> void:
	var recipe := load_recipe(recipe_path)
	if recipe != null and get_status(recipe) != Status.BAKED:
		bake(recipe)


func _clear_cascade() -> void:
	_cascade_queued = false
	_cascade.clear()


func _save_canvas_texture(spec: Dictionary) -> String:
	var path: String = spec.path
	var diffuse := ResourceLoader.load(spec.diffuse) as Texture2D
	var normal := ResourceLoader.load(spec.normal) as Texture2D
	if diffuse == null or normal == null:
		return "%s: the color or normal PNG isn't imported yet; bake again." % path.get_file()
	var texture: CanvasTexture
	if ResourceLoader.exists(path):
		texture = ResourceLoader.load(path) as CanvasTexture
	if texture == null:
		texture = CanvasTexture.new()
		texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if texture.diffuse_texture == diffuse and texture.normal_texture == normal:
		return ""
	texture.diffuse_texture = diffuse
	texture.normal_texture = normal
	var error := ResourceSaver.save(texture, path)
	if error != OK:
		return "Couldn't save %s: %s." % [path, error_string(error)]
	EditorInterface.get_resource_filesystem().update_file(path)
	return ""


func _save_sprite_frames(spec: Dictionary) -> String:
	var path: String = spec.path
	var texture := ResourceLoader.load(spec.texture) as Texture2D
	if texture == null:
		return "%s: the color PNG isn't imported yet; bake again." % path.get_file()
	var frames := ResourceLoader.load(path) as SpriteFrames if ResourceLoader.exists(path) else null
	if frames == null:
		frames = SpriteFrames.new()
	# Rebuilt in place, so scenes using it keep working.
	for animation in frames.get_animation_names():
		frames.remove_animation(animation)
	var grid: Vector2i = spec.frames
	var size: Vector2i = spec.frame_size
	var empty: PackedInt32Array = spec.empty
	var names: PackedStringArray = spec.names
	var per_row: bool = spec.animations == BitKilnOutput.Animations.PER_ROW
	for row in (grid.y if per_row else 1):
		var animation := StringName(names[row] if row < names.size() else ("row_%d" % row if per_row else "default"))
		frames.add_animation(animation)
		frames.set_animation_speed(animation, spec.fps)
		frames.set_animation_loop(animation, spec.loop)
		var indices := range(row * grid.x, (row + 1) * grid.x) if per_row else range(grid.x * grid.y)
		for index: int in indices:
			if spec.skip_empty and index in empty:
				continue
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(Vector2i(index % grid.x, index / grid.x) * size), Vector2(size))
			frames.add_frame(animation, atlas)
	var error := ResourceSaver.save(frames, path)
	if error != OK:
		return "Couldn't save %s: %s." % [path, error_string(error)]
	EditorInterface.get_resource_filesystem().update_file(path)
	return ""


const _PEERING := {
	1: TileSet.CELL_NEIGHBOR_TOP_SIDE, 2: TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	4: TileSet.CELL_NEIGHBOR_RIGHT_SIDE, 8: TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
	16: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE, 32: TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	64: TileSet.CELL_NEIGHBOR_LEFT_SIDE, 128: TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
}


func _save_tile_set(spec: Dictionary) -> String:
	var path: String = spec.path
	var texture := ResourceLoader.load(spec.texture) as Texture2D
	if texture == null:
		return "%s: the color PNG isn't imported yet; bake again." % path.get_file()
	var size: Vector2i = spec.frame_size
	var grid: Vector2i = spec.frames
	var masks: PackedInt32Array = spec.masks
	var empty: PackedInt32Array = spec.empty
	# Rebuilt in place (one atlas source, one terrain set), so TileMaps using it keep working.
	var tile_set := ResourceLoader.load(path) as TileSet if ResourceLoader.exists(path) else null
	if tile_set == null:
		tile_set = TileSet.new()
	tile_set.tile_size = size
	while tile_set.get_source_count() > 0:
		tile_set.remove_source(tile_set.get_source_id(0))
	while tile_set.get_terrain_sets_count() > 0:
		tile_set.remove_terrain_set(0)
	var terrain := not masks.is_empty()
	if terrain:
		tile_set.add_terrain_set()
		tile_set.set_terrain_set_mode(0, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
		tile_set.add_terrain(0)
		tile_set.set_terrain_name(0, 0, spec.terrain_name)
		tile_set.set_terrain_color(0, 0, spec.terrain_color)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = size
	tile_set.add_source(source, 0)
	for index in grid.x * grid.y:
		if index in empty or (terrain and (index >= masks.size() or masks[index] < 0)):
			continue
		var coords := Vector2i(index % grid.x, index / grid.x)
		source.create_tile(coords)
		if terrain:
			var data := source.get_tile_data(coords, 0)
			data.terrain_set = 0
			data.terrain = 0
			for bit: int in _PEERING:
				if masks[index] & bit:
					data.set_terrain_peering_bit(_PEERING[bit], 0)
	var error := ResourceSaver.save(tile_set, path)
	if error != OK:
		return "Couldn't save %s: %s." % [path, error_string(error)]
	EditorInterface.get_resource_filesystem().update_file(path)
	return ""


func _set_import_params(files: PackedStringArray, params: Dictionary) -> void:
	for file in files:
		var import := ConfigFile.new()
		if import.load(file + ".import") != OK:
			continue
		for key: String in params:
			import.set_value("params", key, params[key])
		import.save(file + ".import")
	EditorInterface.get_resource_filesystem().reimport_files(files)


func _collect(dir: EditorFileSystemDirectory, found: PackedStringArray) -> void:
	if dir == null:
		return
	for i in dir.get_file_count():
		if dir.get_file_type(i) == &"Resource" and _is_recipe_file(dir.get_file_path(i)):
			found.append(dir.get_file_path(i))
	for i in dir.get_subdir_count():
		_collect(dir.get_subdir(i), found)


## Whether a resource file holds a recipe. Text resources name their script class in the
## first line, so only that is read (cached until the file changes); binary ones are loaded.
func _is_recipe_file(path: String) -> bool:
	var modified := FileAccess.get_modified_time(path)
	var cached: Array = _recipe_files.get(path, [])
	if not cached.is_empty() and cached[0] == modified:
		return cached[1]
	var is_recipe := false
	if path.get_extension() == "tres":
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			is_recipe = 'script_class="%s"' % RECIPE_CLASS in file.get_line()
	elif path.get_extension() == "res":
		is_recipe = ResourceLoader.load(path) is BitKilnRecipe
	_recipe_files[path] = [modified, is_recipe]
	return is_recipe


static func _file_list(files: PackedStringArray) -> String:
	var names := PackedStringArray()
	for file in files.slice(0, 3):
		names.append(file.get_file())
	return ", ".join(names) + (" and %d more" % (files.size() - 3) if files.size() > 3 else "")


static func _cache_path() -> String:
	return EditorInterface.get_editor_paths().get_project_settings_dir().path_join(CACHE_FILE)
