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


## Bakes [param recipe], imports the files it wrote and builds its CanvasTexture, SpriteFrames
## and TileSet outputs. When it creates folders, it waits for a filesystem scan: await it.
func bake(recipe: BitKilnRecipe) -> BitKilnBaker.Result:
	# Files written last time whose place changed (a new output layout, a renamed source or
	# output) are moved there first, with their import settings and UIDs, so scenes and
	# resources using them keep working.
	var old_files: PackedStringArray = _fingerprints.get_value("outputs", recipe.resource_path, PackedStringArray())
	var planned := BitKilnBaker.planned_files(recipe) if not old_files.is_empty() else PackedStringArray()
	var moved: Array[String] = [] # from, to, from, to… (an Array: lambdas share it, unlike packed arrays)
	var relocate := func(new_path: String, index: int) -> void:
		if index >= old_files.size():
			return
		var old_path := old_files[index]
		if old_path == new_path or old_path in planned or not FileAccess.file_exists(old_path) \
				or FileAccess.file_exists(new_path):
			return
		if move_file(old_path, new_path):
			moved.append_array([old_path, new_path])
	var result := BitKilnBaker.bake(recipe, relocate)
	for old_path in old_files:
		if not old_path in result.files and not old_path in moved and FileAccess.file_exists(old_path):
			result.warnings.append("%s isn't written any more; delete it if nothing uses it." % old_path)
	var filesystem := EditorInterface.get_resource_filesystem()
	var to_import := PackedStringArray()
	for path in result.written:
		if path.get_extension() == "png": # GIFs aren't imported
			to_import.append(path)
	for k in range(1, moved.size(), 2):
		if moved[k].get_extension() != "tres" and not moved[k] in to_import:
			to_import.append(moved[k])
	var all_known := true
	for path in Array(to_import) + moved:
		if filesystem.get_filesystem_path(path.get_base_dir()) == null:
			all_known = false
	if all_known:
		for path in moved:
			filesystem.update_file(path)
		for path in result.written:
			if not path in to_import:
				filesystem.update_file(path)
		if not to_import.is_empty():
			for path in to_import:
				filesystem.update_file(path)
			filesystem.reimport_files(to_import)
	else:
		# New folders: only a scan makes the editor see them (and import what's inside).
		await _scan(to_import)
	for k in range(0, moved.size(), 2):
		result.warnings.append("Moved %s to %s." % [moved[k], moved[k + 1]])
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


## Scans the filesystem and waits until it's done and [param imported] are imported.
func _scan(imported: PackedStringArray) -> void:
	var filesystem := EditorInterface.get_resource_filesystem()
	var tree := Engine.get_main_loop() as SceneTree
	filesystem.scan()
	for frame in 600:
		await tree.process_frame
		if filesystem.is_scanning():
			continue
		var done := true
		for path in imported:
			if not ResourceLoader.exists(path):
				done = false
				break
		if done:
			return


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
	for texture in recipe.sources:
		if texture != null:
			result.append(texture.resource_path)
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
	for texture in recipe.sources:
		if texture != null:
			files.append(texture.resource_path)
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
		await bake(recipe)


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


## Moves a file and its [code].import[/code] (which keeps its UID) to [param to], and
## removes folders left empty. True when it moved.
static func move_file(from: String, to: String) -> bool:
	var dir := to.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	if DirAccess.rename_absolute(from, to) != OK:
		return false
	if FileAccess.file_exists(from + ".import"):
		DirAccess.rename_absolute(from + ".import", to + ".import")
	var old_dir := from.get_base_dir()
	while old_dir != "res://" and old_dir.begins_with("res://") and _is_empty_dir(old_dir):
		DirAccess.remove_absolute(old_dir)
		old_dir = old_dir.get_base_dir()
	return true


static func _is_empty_dir(path: String) -> bool:
	var dir := DirAccess.open(path)
	if dir == null:
		return false
	dir.include_hidden = true
	return dir.get_files().is_empty() and dir.get_directories().is_empty()


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
