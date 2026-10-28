@tool
extends EditorPlugin

const Library := preload("editor/kiln_library.gd")
const KilnDock := preload("editor/kiln_dock.gd")
const ContextMenu := preload("editor/context_menu.gd")
const PaletteImporter := preload("editor/palette_importer.gd")
const RecipeInspector := preload("editor/recipe_inspector.gd")

var _library: Library
var _dock: KilnDock
var _context_menu: ContextMenu
var _importer: PaletteImporter
var _inspector: RecipeInspector
var _refresh_queued := false


func _enter_tree() -> void:
	_library = Library.new()
	_importer = PaletteImporter.new()
	add_import_plugin(_importer)
	_inspector = RecipeInspector.new()
	add_inspector_plugin(_inspector)
	_dock = KilnDock.new()
	_dock.setup(self, _library)
	add_dock(_dock)
	_context_menu = ContextMenu.new()
	_context_menu.library = _library
	_context_menu.open = _dock.edit
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_FILESYSTEM, _context_menu)

	var filesystem := EditorInterface.get_resource_filesystem()
	filesystem.filesystem_changed.connect(_queue_refresh)
	filesystem.resources_reimported.connect(_library.on_resources_reimported)
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)
	get_undo_redo().version_changed.connect(_dock.queue_preview)
	_library.refresh()


func _exit_tree() -> void:
	get_undo_redo().version_changed.disconnect(_dock.queue_preview)
	EditorInterface.get_inspector().property_edited.disconnect(_on_property_edited)
	var filesystem := EditorInterface.get_resource_filesystem()
	filesystem.resources_reimported.disconnect(_library.on_resources_reimported)
	filesystem.filesystem_changed.disconnect(_queue_refresh)
	remove_context_menu_plugin(_context_menu)
	remove_dock(_dock)
	_dock.queue_free()
	remove_inspector_plugin(_inspector)
	remove_import_plugin(_importer)


## Inspecting a recipe shows it in the dock. Its ops and outputs are handled too, so
## editing one of them keeps the recipe shown.
func _handles(object: Object) -> bool:
	return object is BitKilnRecipe or object is BitKilnOp or object is BitKilnOutput


func _edit(object: Object) -> void:
	var recipe := object as BitKilnRecipe
	if recipe != null and not recipe.resource_path.is_empty() and not "::" in recipe.resource_path:
		_dock.edit(recipe)


func _on_property_edited(_property: String) -> void:
	_dock.queue_preview()


## The filesystem often changes in bursts; rescan once per frame at most.
func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_refresh.call_deferred()


func _refresh() -> void:
	_refresh_queued = false
	_library.refresh()
	_dock.refresh_list()
