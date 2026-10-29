@tool
extends EditorInspectorPlugin
## Recipe helpers in the Inspector: a "Guess Frame Grid" button next to a recipe's Frames,
## on each output a checklist of the recipe's ops it uses, and preset menus for ops that
## have presets.

var current_recipe: Callable # () -> BitKilnRecipe: the recipe shown in the BitKiln dock


func _can_handle(object: Object) -> bool:
	return object is BitKilnRecipe or object is BitKilnOutput or object is BitKilnAnimate or object is BitKilnParticles


## A menu that replaces [param target]'s settings with one of [param names]' presets.
func _add_preset_menu(target: Object, names: PackedStringArray, make: Callable, label: String) -> void:
	var menu := MenuButton.new()
	menu.text = label
	menu.flat = false
	menu.icon = EditorInterface.get_editor_theme().get_icon(&"Load", &"EditorIcons")
	menu.tooltip_text = "Replace this op's settings with a ready-made setup (undoable)"
	for name in names:
		menu.get_popup().add_item(name)
	menu.get_popup().index_pressed.connect(func(index: int) -> void:
		var preset: Dictionary = make.call(names[index])
		var undo := EditorInterface.get_editor_undo_redo()
		undo.create_action("Load Preset: %s" % names[index])
		for key: String in preset:
			undo.add_do_property(target, key, preset[key])
			undo.add_undo_property(target, key, target.get(key))
		undo.commit_action())
	add_custom_control(menu)


func _parse_begin(object: Object) -> void:
	if object is BitKilnAnimate:
		_add_preset_menu(object, BitKilnAnimate.preset_names(), BitKilnAnimate.make_preset, "Animation Presets")
		return
	if object is BitKilnParticles:
		_add_preset_menu(object, BitKilnParticles.preset_names(), BitKilnParticles.make_preset, "Particle Presets")
		return
	var output := object as BitKilnOutput
	if output == null:
		return
	var recipe := _recipe_of(output)
	var box := VBoxContainer.new()
	var title := Label.new()
	title.text = "Ops Used by This Output"
	title.tooltip_text = "Unchecked ops are left out when this output is written, so one recipe can write several versions of each sprite."
	box.add_child(title)
	if recipe == null:
		var note := Label.new()
		note.text = "Open this output from its recipe to choose its ops."
		note.modulate = Color(1, 1, 1, 0.6)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		box.add_child(note)
	elif recipe.ops.is_empty():
		var note := Label.new()
		note.text = "The recipe has no ops yet."
		note.modulate = Color(1, 1, 1, 0.6)
		box.add_child(note)
	else:
		for i in recipe.ops.size():
			var op := recipe.ops[i]
			if op == null:
				continue
			var check := CheckBox.new()
			check.text = "%d. %s%s" % [i + 1, op_label(op), "" if op.enabled else " (off)"]
			check.button_pressed = output.uses_op(op)
			check.toggled.connect(func(on: bool) -> void: _set_uses(output, op, on))
			box.add_child(check)
	add_custom_control(box)


func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String,
		_usage_flags: int, _wide: bool) -> bool:
	var recipe := object as BitKilnRecipe
	if recipe == null or name != "frames":
		return false
	var button := Button.new()
	button.text = "Guess Frame Grid"
	button.tooltip_text = "Set Frames from the first source image: the most frames whose edges cut no sprite"
	var theme := EditorInterface.get_editor_theme()
	if theme.has_icon(&"Grid", &"EditorIcons"):
		button.icon = theme.get_icon(&"Grid", &"EditorIcons")
	button.pressed.connect(func() -> void:
		if recipe.source == null:
			return
		var guess := BitKilnSheet.guess_frames(BitKilnBaker.load_source(recipe))
		var undo := EditorInterface.get_editor_undo_redo()
		undo.create_action("Guess Frame Grid")
		undo.add_do_property(recipe, &"frames", guess)
		undo.add_undo_property(recipe, &"frames", recipe.frames)
		undo.commit_action())
	add_custom_control(button)
	return false


## How an op is named in lists: its resource name, or its class without the prefix.
static func op_label(op: BitKilnOp) -> String:
	if not op.resource_name.is_empty():
		return op.resource_name
	var script := op.get_script() as Script
	var global := String(script.get_global_name()) if script != null else ""
	return global.trim_prefix("BitKiln").capitalize() if not global.is_empty() else op.get_class()


## The recipe [param output] belongs to: the one in the Inspector, or the dock's.
func _recipe_of(output: BitKilnOutput) -> BitKilnRecipe:
	var edited := EditorInterface.get_inspector().get_edited_object() as BitKilnRecipe
	if edited != null and output in edited.outputs:
		return edited
	var shown: BitKilnRecipe = current_recipe.call() if current_recipe.is_valid() else null
	if shown != null and output in shown.outputs:
		return shown
	return null


func _set_uses(output: BitKilnOutput, op: BitKilnOp, on: bool) -> void:
	var skip: Array[BitKilnOp] = output.skip_ops.duplicate()
	if on:
		skip.erase(op)
	elif not op in skip:
		skip.append(op)
	var undo := EditorInterface.get_editor_undo_redo()
	undo.create_action("Use Op in Output" if on else "Leave Op out of Output")
	undo.add_do_property(output, &"skip_ops", skip)
	undo.add_undo_property(output, &"skip_ops", output.skip_ops)
	undo.commit_action()
