@tool
extends EditorContextMenuPlugin
## FileSystem dock entries: "New BitKiln Recipe" on images, "New BitKiln Canvas" on
## folders, "Bake" on recipes.

const Library := preload("kiln_library.gd")

var library: Library
var open: Callable # (recipe: BitKilnRecipe)


func _popup_menu(paths: PackedStringArray) -> void:
	var images := PackedStringArray()
	var recipes := PackedStringArray()
	var folders := PackedStringArray()
	for path in paths:
		if DirAccess.dir_exists_absolute(path):
			folders.append(path)
		elif path.get_extension().to_lower() in BitKilnBaker.IMAGE_EXTENSIONS:
			images.append(path)
		elif path in library.get_recipe_paths():
			recipes.append(path)
	var theme := EditorInterface.get_editor_theme()
	var icon := load(_icon_path("recipe.svg")) as Texture2D if ResourceLoader.exists(_icon_path("recipe.svg")) else null
	if not images.is_empty():
		add_context_menu_item("New BitKiln Recipe" if images.size() == 1 else "New BitKiln Recipes",
			func(_selected: Array) -> void: _create_recipes(images), icon)
	if folders.size() == 1:
		add_context_menu_item("New BitKiln Canvas", func(_selected: Array) -> void: _create_canvas(folders[0]), icon)
	if not recipes.is_empty():
		add_context_menu_item("Bake" if recipes.size() == 1 else "Bake Recipes",
			func(_selected: Array) -> void: _bake(recipes), theme.get_icon(&"ImageTexture", &"EditorIcons"))


func _create_recipes(images: PackedStringArray) -> void:
	var last: BitKilnRecipe
	for image in images:
		var recipe := BitKilnRecipe.new()
		recipe.source = load(image) as Texture2D
		if recipe.source != null:
			recipe.frames = BitKilnSheet.guess_frames(BitKilnBaker.load_source(recipe))
		var path := _free_path(image.get_basename() + "_kiln", "tres")
		if ResourceSaver.save(recipe, path) != OK:
			push_error("BitKiln: couldn't save %s." % path)
			continue
		EditorInterface.get_resource_filesystem().update_file(path)
		recipe.take_over_path(path)
		library.add_recipe_path(path)
		last = recipe
	if last != null:
		EditorInterface.edit_resource(last)
		open.call(last)


## A recipe without a source in [param folder], for generators to draw on.
func _create_canvas(folder: String) -> void:
	var recipe := BitKilnRecipe.new()
	recipe.ops = [BitKilnShape.new()]
	var path := _free_path(folder.path_join("canvas_kiln"), "tres")
	if ResourceSaver.save(recipe, path) != OK:
		push_error("BitKiln: couldn't save %s." % path)
		return
	EditorInterface.get_resource_filesystem().update_file(path)
	recipe.take_over_path(path)
	library.add_recipe_path(path)
	EditorInterface.edit_resource(recipe)
	open.call(recipe)


func _bake(recipes: PackedStringArray) -> void:
	for path in recipes:
		var recipe := library.load_recipe(path)
		if recipe != null:
			library.bake(recipe)


## [param base].[param extension], or base_2, base_3… when taken.
static func _free_path(base: String, extension: String) -> String:
	var path := "%s.%s" % [base, extension]
	var n := 2
	while FileAccess.file_exists(path):
		path = "%s_%d.%s" % [base, n, extension]
		n += 1
	return path


func _icon_path(file: String) -> String:
	return (get_script() as Script).resource_path.get_base_dir().path_join("../icons").path_join(file).simplify_path()
