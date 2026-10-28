extends SceneTree
## Bakes every BitKilnRecipe in the project without opening the editor, for build
## scripts and CI:
##
##     godot --headless --script res://addons/bitkiln/tools/bake_all.gd
##
## On a fresh checkout, run [code]godot --headless --import[/code] first, so the project's
## classes (BitKilnRecipe and the ops) are registered.
##
## Exits with code 1 if any recipe fails. CanvasTexture outputs need the editor to import
## their PNGs first, so they're reported and skipped here; open the editor once (or bake
## from the dock) to create them.


func _init() -> void:
	var recipes := PackedStringArray()
	_find_recipes("res://", recipes)
	var failed := 0
	for path in recipes:
		var recipe := load(path) as BitKilnRecipe
		if recipe == null:
			continue
		var result := BitKilnBaker.bake(recipe)
		var status := "ok" if result.ok else "FAILED"
		print("%s: %s (%d written, %d up to date)" % [path, status, result.written.size(),
			result.files.size() - result.written.size() - result.canvas_textures.size()])
		for error in result.errors:
			printerr("  error: ", error)
			failed += 1
		for warning in result.warnings:
			print("  warning: ", warning)
		for spec in result.canvas_textures:
			print("  skipped %s: CanvasTextures are made by the editor" % spec.path)
	print("%d recipe%s baked, %d error%s." % [recipes.size(), "" if recipes.size() == 1 else "s", failed,
		"" if failed == 1 else "s"])
	quit(1 if failed > 0 else 0)


func _find_recipes(dir_path: String, found: PackedStringArray) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		if not sub.begins_with("."):
			_find_recipes(dir_path.path_join(sub), found)
	for file in dir.get_files():
		if file.get_extension() != "tres":
			continue
		var path := dir_path.path_join(file)
		var handle := FileAccess.open(path, FileAccess.READ)
		if handle != null and 'script_class="BitKilnRecipe"' in handle.get_line():
			found.append(path)
