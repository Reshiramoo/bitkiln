@tool
extends EditorInspectorPlugin
## Recipe helpers in the Inspector: a "Guess Frame Grid" button next to a recipe's Frames,
## on each output a checklist of the recipe's ops it uses, preset menus for ops that have
## presets, and for ops that animate, how many frames they make and how long those play.

var current_recipe: Callable # () -> BitKilnRecipe: the recipe shown in the BitKiln dock


func _can_handle(object: Object) -> bool:
	return object is BitKilnRecipe or object is BitKilnOutput or object is BitKilnAnimate or object is BitKilnParticles \
		or object is BitKilnFxSheet


## A note under the property being parsed that keeps itself up to date with [param describe]
## (() -> String) while it's shown.
func _add_live_note(describe: Callable, tooltip := "") -> void:
	var label := Label.new()
	label.modulate = Color(1, 1, 1, 0.7)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.tooltip_text = tooltip
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.text = describe.call()
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.autostart = true
	timer.timeout.connect(func() -> void: label.text = describe.call())
	label.add_child(timer)
	add_custom_control(label)


## [param fps] without a needless ".0": "12", "12.5".
static func fps_text(fps: float) -> String:
	return str(roundi(fps)) if is_equal_approx(fps, roundf(fps)) else "%.1f" % fps


## "Auto: 8 frames = 0.80 s at 10 fps" for an op that animates, or how it follows the
## animation an earlier op of [param recipe] made.
static func timing_note(op: Variant, recipe: BitKilnRecipe = null) -> String:
	var index := recipe.ops.find(op) if recipe != null else -1
	var earlier := recipe.fps_before(index) if index >= 0 else 0.0
	if earlier > 0.0:
		if not op is BitKilnAnimate:
			return "Draws on the animation before it, at its %s fps." % fps_text(earlier)
		if op.follows_animation(earlier):
			if op.frame_count > 0:
				return "%d frames, resampling the animation before it, at %s fps." % [op.frame_count, fps_text(earlier)]
			return "Runs across the animation before it: its frames, at %s fps." % fps_text(earlier)
	var count: int = op.get_frame_count()
	var text := "%d frames = %.2f s at %s fps" % [count, op.get_duration(), fps_text(op.get_fps())]
	return ("Auto: " + text) if op.frame_count == 0 else text


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
	# Notes go before the property they're parsed with, so these land under Frame Count and Fps.
	if (object is BitKilnAnimate or object is BitKilnParticles) and name == "loop" \
			or object is BitKilnFxSheet and name == "timing":
		var op: Variant = object
		var tooltip := "Set Frame Count to 0 for Auto: Duration × Fps."
		if not object is BitKilnAnimate:
			tooltip += "\nOver a sheet that already has several frames, the op draws on those instead."
		tooltip += "\nAfter an op that already animated the image, it follows that animation's frames and speed."
		_add_live_note(func() -> String:
			return timing_note(op, current_recipe.call() if current_recipe.is_valid() else null), tooltip)
		return false
	var output := object as BitKilnOutput
	if output != null and name == "loop" and output.kind in [BitKilnOutput.Kind.SPRITE_FRAMES, BitKilnOutput.Kind.GIF]:
		_add_live_note(func() -> String:
			if output.fps > 0.0:
				return "Set Fps to 0 to follow the recipe's animation."
			var recipe := _recipe_of(output)
			return "Plays at %s fps, from the recipe's ops." % fps_text(recipe.get_fps(output) if recipe != null else BitKilnRecipe.DEFAULT_FPS))
		return false
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
