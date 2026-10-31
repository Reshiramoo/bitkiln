@tool
extends EditorDock
## The BitKiln dock: every recipe in the project with its bake status, a live preview of
## the selected one (any source, variant, layer, number of ops or output), its output files,
## import checks and the bake log. Recipes themselves are edited in the Inspector; the
## preview follows every change.

const Library := preload("kiln_library.gd")
const Preview := preload("kiln_preview.gd")

enum Layer { COLOR, NORMAL, LIT }

const PREVIEW_DELAY := 0.12
## How often the shown recipe is checked for edits the editor doesn't report (sub-resources
## edited in place, gradient and curve editors).
const WATCH_INTERVAL := 0.3
const AS_OUTPUT := 1000 # ops menu ids from here: preview as output (id - AS_OUTPUT)
var _plugin: EditorPlugin
var _library: Library
var _recipe: BitKilnRecipe
var _contexts: Array[BitKilnContext] = []

var _filter: LineEdit
var _tree: Tree
var _bake_all: Button
var _title: Label
var _source_pick: OptionButton
var _variant: OptionButton
var _layer: OptionButton
var _view: OptionButton
var _ops: OptionButton
var _grid: Button
var _zoom_label: Label
var _info: Label
var _play_bar: HBoxContainer
var _animate: Button
var _play: Button
var _frame_slider: HSlider
var _frame_label: Label
var _fps: SpinBox
var _length: Label # how long the frames play at the fps box's speed
var _synced_fps := 0.0 # the recipe's speed the fps box was last set to
var _play_timer := Timer.new()
var _preview: Preview
var _placeholder: Label
var _bake: Button
var _outputs: MenuButton
var _status: Label
var _issues: VBoxContainer
var _log: RichTextLabel
var _timer := Timer.new()
var _watch := Timer.new()
var _signature := ""


func setup(plugin: EditorPlugin, library: Library) -> void:
	_plugin = plugin
	_library = library
	title = "BitKiln"
	_set_dock_icon(self, "bitkiln.svg")
	layout_key = "bitkiln"
	default_slot = DOCK_SLOT_BOTTOM
	available_layouts = DOCK_LAYOUT_HORIZONTAL | DOCK_LAYOUT_FLOATING

	_timer.one_shot = true
	_timer.wait_time = PREVIEW_DELAY
	_timer.timeout.connect(_update_preview)
	add_child(_timer)
	_watch.wait_time = WATCH_INTERVAL
	_watch.autostart = true
	_watch.timeout.connect(_check_for_edits)
	add_child(_watch)

	var split := HSplitContainer.new()
	split.custom_minimum_size.y = 240.0
	add_child(split)
	split.add_child(_build_list())
	var right := HSplitContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	right.add_child(_build_preview())
	right.add_child(_build_side())

	_library.recipes_changed.connect(refresh_list)
	_library.baked.connect(_on_baked)
	refresh_list()
	_show_recipe(null)


func _build_list() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 200.0
	_filter = LineEdit.new()
	_filter.placeholder_text = "Filter recipes"
	_filter.clear_button_enabled = true
	_filter.right_icon = _icon("Search")
	_filter.text_changed.connect(func(_text: String) -> void: refresh_list())
	box.add_child(_filter)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(func() -> void:
		var item := _tree.get_selected()
		if item != null:
			EditorInterface.edit_resource(_library.load_recipe(item.get_metadata(0))))
	box.add_child(_tree)
	_bake_all = Button.new()
	_bake_all.text = "Bake All Stale"
	_bake_all.icon = _icon("Reload")
	_bake_all.tooltip_text = "Bake every recipe whose source, ops or outputs changed since it was last baked"
	_bake_all.pressed.connect(_bake_stale)
	box.add_child(_bake_all)
	return box


func _build_preview() -> Control:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.custom_minimum_size.x = 320.0
	var bar := HBoxContainer.new()
	box.add_child(bar)
	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	bar.add_child(_title)
	_source_pick = _option(bar, [], "Source to show (every source is baked)")
	_variant = _option(bar, [], "Variant to show (palette swaps make one per palette)")
	_layer = _option(bar, ["Color", "Normal", "Lit"], "Layer: the colors, the normal map, or the colors lit by a light that follows the mouse")
	_view = _option(bar, ["Result", "Source", "Side by Side"], "Show the result, the source, or both")
	_ops = _option(bar, [], "Preview the result after only the first ops, or as one of the outputs that leave ops out")
	_grid = Button.new()
	_grid.icon = _icon("Grid")
	_grid.toggle_mode = true
	_grid.button_pressed = true
	_grid.flat = true
	_grid.tooltip_text = "Show the frame grid"
	_grid.toggled.connect(func(on: bool) -> void: _preview.show_grid = on)
	bar.add_child(_grid)
	_add_tool_button(bar, "ZoomLess", "Zoom out", func() -> void: _preview.zoom_by(-1))
	_zoom_label = Label.new()
	_zoom_label.custom_minimum_size.x = 32.0
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bar.add_child(_zoom_label)
	_add_tool_button(bar, "ZoomMore", "Zoom in", func() -> void: _preview.zoom_by(1))
	_add_tool_button(bar, "DistractionFree", "Zoom to fit", func() -> void: _preview.fit())

	var stack := Control.new()
	stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(stack)
	_preview = Preview.new()
	_preview.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview.zoom_changed.connect(func(zoom: int) -> void: _zoom_label.text = "%d×" % zoom)
	stack.add_child(_preview)
	_placeholder = Label.new()
	_placeholder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_placeholder.modulate = Color(1, 1, 1, 0.6)
	stack.add_child(_placeholder)

	box.add_child(_build_play_bar())
	_info = Label.new()
	_info.modulate = Color(1, 1, 1, 0.7)
	_info.clip_text = true
	box.add_child(_info)
	_zoom_label.text = "%d×" % _preview.zoom
	return box


## Animation controls: one frame at a time, play, scrub, frames per second.
func _build_play_bar() -> Control:
	_play_bar = HBoxContainer.new()
	_play_bar.visible = false
	_animate = Button.new()
	_animate.icon = _icon("Animation")
	_animate.toggle_mode = true
	_animate.flat = true
	_animate.tooltip_text = "Show one frame at a time, to play the sheet as an animation"
	_animate.toggled.connect(func(on: bool) -> void:
		_preview.frame = int(_frame_slider.value) if on else -1
		_set_playing(on))
	_play_bar.add_child(_animate)
	_play = Button.new()
	_play.icon = _icon("Play")
	_play.toggle_mode = true
	_play.flat = true
	_play.tooltip_text = "Play / pause"
	_play.toggled.connect(func(on: bool) -> void:
		if on and not _animate.button_pressed:
			_animate.button_pressed = true # plays too
		else:
			_set_playing(on))
	_play_bar.add_child(_play)
	_add_tool_button(_play_bar, "PagePrevious", "Previous frame", func() -> void: _step_frame(-1))
	_add_tool_button(_play_bar, "PageNext", "Next frame", func() -> void: _step_frame(1))
	_frame_slider = HSlider.new()
	_frame_slider.step = 1.0
	_frame_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_frame_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_frame_slider.value_changed.connect(func(value: float) -> void:
		_frame_label.text = "%d / %d" % [int(value) + 1, int(_frame_slider.max_value) + 1]
		if _animate.button_pressed:
			_preview.frame = int(value))
	_play_bar.add_child(_frame_slider)
	_frame_label = Label.new()
	_frame_label.custom_minimum_size.x = 56.0
	_frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_bar.add_child(_frame_label)
	_fps = SpinBox.new()
	_fps.min_value = 1.0
	_fps.max_value = 60.0
	_fps.value = 10.0
	_fps.suffix = "fps"
	_fps.step = 0.5
	_fps.tooltip_text = "Playback speed. Follows the recipe's animation (its op's or Sprite Frames output's fps); change it here to try another speed."
	_fps.value_changed.connect(func(value: float) -> void:
		_play_timer.wait_time = 1.0 / value
		_update_length())
	_play_bar.add_child(_fps)
	_length = Label.new()
	_length.custom_minimum_size.x = 48.0
	_length.modulate = Color(1, 1, 1, 0.7)
	_length.tooltip_text = "How long the frames last at this speed"
	_play_bar.add_child(_length)
	_play_timer.wait_time = 0.1
	_play_timer.timeout.connect(func() -> void: _step_frame(1))
	add_child(_play_timer)
	return _play_bar


func _set_playing(on: bool) -> void:
	_play.set_pressed_no_signal(on)
	_play.icon = _icon("Pause" if on else "Play")
	if on and _animate.button_pressed:
		_play_timer.start()
	else:
		_play_timer.stop()


func _step_frame(step: int) -> void:
	var count := int(_frame_slider.max_value) + 1
	if count <= 1:
		return
	if not _animate.button_pressed:
		_animate.set_pressed_no_signal(true)
	_frame_slider.value = posmod(int(_frame_slider.value) + step, count)
	_preview.frame = int(_frame_slider.value)


## Shows the play bar for sheets, keeping the frame shown inside the new frame count.
func _update_play_bar() -> void:
	var count := _preview.get_frame_count()
	_play_bar.visible = count > 1
	if count <= 1:
		_animate.button_pressed = false
		_frame_slider.max_value = 0.0
		return
	_frame_slider.max_value = count - 1
	_frame_slider.value = mini(int(_frame_slider.value), count - 1)
	_frame_label.text = "%d / %d" % [int(_frame_slider.value) + 1, count]
	_update_length()
	if _animate.button_pressed:
		_preview.frame = int(_frame_slider.value)


func _update_length() -> void:
	if _length != null:
		_length.text = "%.2f s" % ((_frame_slider.max_value + 1.0) / _fps.value)


## Sets the fps box to the speed of the recipe's animation when that speed changes, keeping
## a speed typed in the box until then.
func _sync_fps() -> void:
	if _recipe == null:
		return
	var animated: BitKilnOutput = null
	for output in _recipe.outputs:
		if output != null and output.kind in [BitKilnOutput.Kind.SPRITE_FRAMES, BitKilnOutput.Kind.GIF]:
			animated = output
			break
	var recipe_fps := _recipe.get_fps(animated)
	if not is_equal_approx(recipe_fps, _synced_fps):
		_synced_fps = recipe_fps
		_fps.value = recipe_fps


func _build_side() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 240.0
	var row := HBoxContainer.new()
	box.add_child(row)
	_bake = Button.new()
	_bake.text = "Bake"
	_bake.icon = _icon("ImageTexture")
	_bake.tooltip_text = "Write this recipe's outputs"
	_bake.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bake.pressed.connect(func() -> void:
		if _recipe != null:
			_library.bake(_recipe))
	row.add_child(_bake)
	_outputs = MenuButton.new()
	_outputs.text = "Outputs"
	_outputs.icon = _icon("Folder")
	_outputs.flat = false
	_outputs.tooltip_text = "Open this recipe's output files"
	_outputs.about_to_popup.connect(_fill_outputs_menu)
	_outputs.get_popup().id_pressed.connect(_on_output_chosen)
	row.add_child(_outputs)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_status)
	_issues = VBoxContainer.new()
	box.add_child(_issues)
	_log = RichTextLabel.new()
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.context_menu_enabled = true
	box.add_child(_log)
	return box


## Shows [param recipe] (when it's a saved recipe or null) and makes the dock visible.
func edit(recipe: BitKilnRecipe) -> void:
	if recipe != _recipe:
		_show_recipe(recipe)
	make_visible()


## The recipe shown in the dock, or null.
func get_recipe() -> BitKilnRecipe:
	return _recipe


## Something in the editor changed (an Inspector edit, undo, redo): preview again shortly.
func queue_preview() -> void:
	if _recipe != null:
		_timer.start()


## Catches every edit of the shown recipe, including ones the editor sends no signal for.
func _check_for_edits() -> void:
	if _recipe == null or not is_visible_in_tree():
		return
	var signature := BitKilnBaker.edit_signature(_recipe)
	if signature != _signature:
		_signature = signature
		queue_preview()
		refresh_list() # the recipe's status icon


func refresh_list() -> void:
	if _tree == null:
		return
	var filter := _filter.text.strip_edges()
	_tree.clear()
	var root := _tree.create_item()
	for path in _library.get_recipe_paths():
		if not filter.is_empty() and not filter.is_subsequence_ofn(path.get_file()):
			continue
		var item := _tree.create_item(root)
		item.set_text(0, path.get_file().get_basename())
		item.set_tooltip_text(0, path)
		item.set_metadata(0, path)
		var recipe := _library.load_recipe(path)
		if recipe != null:
			_set_status_icon(item, _library.get_status(recipe))
		if _recipe != null and path == _recipe.resource_path:
			item.select(0)
	_update_status()


func _show_recipe(recipe: BitKilnRecipe) -> void:
	_recipe = recipe
	_synced_fps = 0.0
	_signature = BitKilnBaker.edit_signature(recipe) if recipe != null else ""
	_contexts.clear()
	_variant.clear()
	_source_pick.clear()
	_rebuild_ops()
	_title.text = recipe.resource_path.get_file() if recipe != null else ""
	_bake.disabled = recipe == null
	if recipe == null:
		_preview.set_images(null, null, null, Vector2i.ONE, Vector2i.ONE, true)
		_update_play_bar()
		_source_pick.visible = false
		_placeholder.text = "Select a recipe, or right-click an image in the FileSystem dock and choose New BitKiln Recipe (or a folder for a blank canvas to draw on)."
		_placeholder.visible = true
		_info.text = ""
		_update_status()
		return
	_update_preview(true)
	_update_status()


func _update_preview(refit := false) -> void:
	if _recipe == null:
		return
	_rebuild_ops()
	_rebuild_sources()
	var source_index := maxi(_source_pick.selected, 0)
	var id := _ops.get_selected_id() if _ops.selected > 0 else -1
	var op_count := id if id >= 0 and id < AS_OUTPUT else -1
	var skip: Array[BitKilnOp] = []
	if id >= AS_OUTPUT and id - AS_OUTPUT < _recipe.outputs.size() and _recipe.outputs[id - AS_OUTPUT] != null:
		skip = _recipe.outputs[id - AS_OUTPUT].skip_ops
	_sync_fps()
	var started := Time.get_ticks_usec()
	_contexts = BitKilnBaker.run(_recipe, op_count, source_index, skip)
	var elapsed := (Time.get_ticks_usec() - started) / 1000.0
	if _contexts.is_empty():
		_preview.set_images(null, null, null, Vector2i.ONE, Vector2i.ONE, true)
		_update_play_bar()
		_placeholder.text = "Couldn't read %s." % _recipe.get_naming_path(source_index)
		_placeholder.visible = true
		_info.text = ""
		return
	_placeholder.visible = false

	var previous := _variant.get_item_text(_variant.selected) if _variant.selected >= 0 else ""
	_variant.clear()
	var selected := 0
	for i in _contexts.size():
		var variant_name := _contexts[i].variant
		_variant.add_item(variant_name if not variant_name.is_empty() else "Main")
		if _variant.get_item_text(i) == previous:
			selected = i
	_variant.select(selected)
	_variant.visible = _contexts.size() > 1

	var context := _contexts[selected]
	var layer := _layer.selected
	var normal := context.get_layer(BitKilnContext.NORMAL)
	var shown := normal if layer == Layer.NORMAL and normal != null else context.color
	var source := BitKilnBaker.load_source(_recipe, source_index)
	_preview.lit = layer == Layer.LIT
	_preview.view = _view.selected
	_preview.set_images(ImageTexture.create_from_image(source) if source != null else null, shown.to_texture(),
		normal.to_texture() if normal != null else null, _source_grid(source), context.frames, refit)
	_update_play_bar()

	var notes := PackedStringArray()
	notes.append("%d×%d" % [context.width, context.height])
	if context.frames != Vector2i.ONE:
		notes.append("%d×%d frames of %d×%d" % [context.frames.x, context.frames.y, context.frame_size.x, context.frame_size.y])
	notes.append("%d colors" % context.color.get_colors().size())
	if layer != Layer.COLOR and normal == null:
		notes.append("no normal map: add a BitKilnNormalMap op")
	notes.append("%.1f ms" % elapsed)
	_info.text = "  ·  ".join(notes)
	_info.tooltip_text = "\n".join(context.warnings)
	if not context.warnings.is_empty():
		_info.text += "  ·  ⚠ %d" % context.warnings.size()
	_update_status()


func _rebuild_ops() -> void:
	var previous := _ops.get_selected_id() if _ops.selected >= 0 else -1
	_ops.clear()
	_ops.add_item("All Ops", -1)
	if _recipe != null:
		for i in _recipe.ops.size():
			var op := _recipe.ops[i]
			var op_name := _op_name(op)
			_ops.add_item("Up to %d: %s" % [i + 1, op_name], i + 1)
		var first_output := true
		for i in _recipe.outputs.size():
			var output := _recipe.outputs[i]
			if output == null or output.skip_ops.is_empty():
				continue
			if first_output:
				_ops.add_separator()
				first_output = false
			_ops.add_item("As Output %d: %s" % [i + 1, output.path.get_file()], AS_OUTPUT + i)
	var index := _ops.get_item_index(previous)
	_ops.select(index if index >= 0 else 0)
	_ops.visible = _recipe != null and not _recipe.ops.is_empty()


func _rebuild_sources() -> void:
	var previous := _source_pick.selected
	_source_pick.clear()
	if _recipe == null:
		return
	for i in _recipe.get_run_count():
		var source := _recipe.get_source(i)
		_source_pick.add_item(source.resource_path.get_file() if source != null else "Blank Canvas")
	_source_pick.select(clampi(previous, 0, _source_pick.item_count - 1))
	_source_pick.visible = _source_pick.item_count > 1


## The frame grid the recipe uses for [param source].
func _source_grid(source: Image) -> Vector2i:
	if source != null and _recipe.auto_frames:
		return BitKilnSheet.guess_frames(source)
	return _recipe.frames


func _fill_outputs_menu() -> void:
	var popup := _outputs.get_popup()
	popup.clear()
	if _recipe == null:
		return
	var files := _library.get_output_files(_recipe)
	var baked := not files.is_empty()
	if not baked:
		files = BitKilnBaker.planned_files(_recipe)
	for i in files.size():
		var path := files[i]
		var exists := FileAccess.file_exists(path)
		popup.add_icon_item(_icon("ImageTexture" if path.get_extension() == "png" else "Object"),
			path.trim_prefix("res://") + ("" if exists else "  (not baked)"), i)
		popup.set_item_metadata(popup.item_count - 1, path)
		popup.set_item_disabled(popup.item_count - 1, not exists)
		popup.set_item_tooltip(popup.item_count - 1, "Select it in the FileSystem dock and open it")
	if files.is_empty():
		popup.add_item("No outputs", -2)
		popup.set_item_disabled(0, true)
		return
	popup.add_separator()
	popup.add_icon_item(_icon("Filesystem"), "Show Folder in File Manager", -1)
	popup.set_item_metadata(popup.item_count - 1, files[0])


func _on_output_chosen(id: int) -> void:
	var popup := _outputs.get_popup()
	var path: String = popup.get_item_metadata(popup.get_item_index(id))
	if id == -1:
		OS.shell_show_in_file_manager(ProjectSettings.globalize_path(path))
		return
	EditorInterface.get_file_system_dock().navigate_to_path(path)
	if path.get_extension() == "gif":
		OS.shell_open(ProjectSettings.globalize_path(path)) # Godot doesn't show GIFs: open the system viewer
	elif ResourceLoader.exists(path):
		EditorInterface.edit_resource(load(path))


func _update_status() -> void:
	for child in _issues.get_children():
		child.queue_free()
	if _recipe == null:
		_status.text = ""
		return
	if _recipe.resource_path.is_empty() or "::" in _recipe.resource_path:
		_status.text = "Save the recipe as its own .tres file to bake it."
		_bake.disabled = true
		return
	_bake.disabled = false
	match _library.get_status(_recipe):
		Library.Status.NEVER:
			_status.text = "Not baked yet."
		Library.Status.BAKED:
			_status.text = "Up to date."
		Library.Status.STALE:
			_status.text = "Changed since the last bake." + (" Bakes when the source is reimported." if _recipe.auto_bake else "")
		Library.Status.ERROR:
			_status.text = "The last bake failed; see the log."
	for issue in _library.get_import_issues(_recipe):
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = issue.message
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.modulate = EditorInterface.get_editor_theme().get_color(&"warning_color", &"Editor")
		row.add_child(label)
		var fix := Button.new()
		fix.text = "Fix"
		var callback: Callable = issue.fix
		fix.pressed.connect(func() -> void:
			callback.call()
			_update_status.call_deferred())
		row.add_child(fix)
		_issues.add_child(row)


func _on_baked(recipe_path: String, result: BitKilnBaker.Result) -> void:
	var theme := EditorInterface.get_editor_theme()
	var time := Time.get_time_string_from_system()
	var head := "[color=#%s]%s[/color] %s: " % [theme.get_color(&"font_disabled_color", &"Editor").to_html(false), time,
		recipe_path.get_file()]
	if result.ok:
		var written := result.written.size()
		_log.append_text(head + ("%d file%s written" % [written, "" if written == 1 else "s"] if written > 0 else "up to date") + "\n")
	for error in result.errors:
		_log.append_text("%s[color=#%s]%s[/color]\n" % [head, theme.get_color(&"error_color", &"Editor").to_html(false), error])
	for warning in result.warnings:
		_log.append_text("%s[color=#%s]%s[/color]\n" % [head, theme.get_color(&"warning_color", &"Editor").to_html(false), warning])
	refresh_list()
	queue_preview()


func _bake_stale() -> void:
	for path in _library.get_recipe_paths():
		var recipe := _library.load_recipe(path)
		if recipe != null and _library.get_status(recipe) != Library.Status.BAKED:
			await _library.bake(recipe)


func _on_item_selected() -> void:
	var item := _tree.get_selected()
	if item == null:
		return
	var recipe := _library.load_recipe(item.get_metadata(0))
	if recipe != _recipe:
		_show_recipe(recipe)


func _option(parent: Control, items: Array, tooltip: String) -> OptionButton:
	var option := OptionButton.new()
	option.tooltip_text = tooltip
	option.fit_to_longest_item = false
	for item: String in items:
		option.add_item(item)
	option.item_selected.connect(func(_index: int) -> void: _update_preview())
	parent.add_child(option)
	return option


func _add_tool_button(parent: Control, icon_name: String, tooltip: String, callback: Callable) -> void:
	var button := Button.new()
	button.icon = _icon(icon_name)
	button.flat = true
	button.tooltip_text = tooltip
	button.pressed.connect(callback)
	parent.add_child(button)


func _set_status_icon(item: TreeItem, status: Library.Status) -> void:
	match status:
		Library.Status.BAKED:
			item.set_icon(0, _icon("StatusSuccess"))
			item.set_tooltip_text(0, item.get_tooltip_text(0) + "\nUp to date")
		Library.Status.STALE, Library.Status.NEVER:
			item.set_icon(0, _icon("StatusWarning"))
			item.set_tooltip_text(0, item.get_tooltip_text(0) + ("\nNot baked yet" if status == Library.Status.NEVER else "\nChanged since the last bake"))
		Library.Status.ERROR:
			item.set_icon(0, _icon("StatusError"))
			item.set_tooltip_text(0, item.get_tooltip_text(0) + "\nThe last bake failed")


static func _op_name(op: BitKilnOp) -> String:
	if op == null:
		return "(empty)"
	var script := op.get_script() as Script
	var class_name_ := script.get_global_name() if script != null else &""
	var text := String(class_name_).trim_prefix("BitKiln").capitalize() if not class_name_.is_empty() else op.get_class()
	return text + ("" if op.enabled else " (off)")


func _icon(icon_name: String) -> Texture2D:
	var theme := EditorInterface.get_editor_theme()
	return theme.get_icon(icon_name, &"EditorIcons") if theme.has_icon(icon_name, &"EditorIcons") else null


## Loaded (not preloaded) so a freshly pulled icon that isn't imported yet can't break the plugin.
static func _set_dock_icon(dock: EditorDock, file: String) -> void:
	var path: String = (dock.get_script() as Script).resource_path.get_base_dir().path_join("../icons").path_join(file).simplify_path()
	if ResourceLoader.exists(path):
		dock.dock_icon = load(path)
		dock.force_show_icon = true
