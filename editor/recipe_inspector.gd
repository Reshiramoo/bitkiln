@tool
extends EditorInspectorPlugin
## Adds a "Guess Frame Grid" button next to a recipe's Frames property.


func _can_handle(object: Object) -> bool:
	return object is BitKilnRecipe


func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String,
		_usage_flags: int, _wide: bool) -> bool:
	if name != "frames":
		return false
	var recipe := object as BitKilnRecipe
	var button := Button.new()
	button.text = "Guess Frame Grid"
	button.tooltip_text = "Set Frames from the source image: the most frames whose edges cut no sprite"
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
