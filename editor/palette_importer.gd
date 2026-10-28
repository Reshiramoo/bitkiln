@tool
extends EditorImportPlugin
## Imports palette files from Lospec and other pixel-art tools as one-row textures:
## [code].hex[/code] (one RRGGBB per line), [code].gpl[/code] (GIMP / Aseprite) and
## [code].pal[/code] (JASC, as saved by Paint Shop Pro and many editors).


func _get_importer_name() -> String:
	return "bitkiln.palette"


func _get_visible_name() -> String:
	return "BitKiln Palette"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["hex", "gpl", "pal"])


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	return "ImageTexture"


func _get_preset_count() -> int:
	return 1


func _get_preset_name(_preset_index: int) -> String:
	return "Default"


func _get_import_options(_path: String, _preset_index: int) -> Array[Dictionary]:
	return []


func _get_option_visibility(_path: String, _option_name: StringName, _options: Dictionary) -> bool:
	return true


func _get_priority() -> float:
	return 1.0


func _get_import_order() -> int:
	return 0


func _import(source_file: String, save_path: String, _options: Dictionary, _platform_variants: Array[String],
		_gen_files: Array[String]) -> Error:
	var text := FileAccess.get_file_as_string(source_file)
	if text.is_empty() and FileAccess.get_open_error() != OK:
		return FileAccess.get_open_error()
	var colors := parse(text, source_file.get_extension().to_lower())
	if colors.is_empty():
		push_error("BitKiln: no colors found in %s." % source_file)
		return ERR_PARSE_ERROR
	var image := Image.create_empty(colors.size(), 1, false, Image.FORMAT_RGBA8)
	for i in colors.size():
		image.set_pixel(i, 0, colors[i])
	return ResourceSaver.save(ImageTexture.create_from_image(image), "%s.%s" % [save_path, _get_save_extension()])


## The colors in a palette file's text, in order.
static func parse(text: String, extension: String) -> PackedColorArray:
	var colors := PackedColorArray()
	var lines := text.replace("\r", "").split("\n")
	match extension:
		"hex":
			for line in lines:
				var value := line.strip_edges().trim_prefix("#")
				if value.length() in [6, 8] and value.is_valid_hex_number():
					colors.append(Color.html(value))
		"gpl":
			for line in lines:
				var values := _leading_ints(line)
				if values.size() >= 3:
					colors.append(Color8(values[0], values[1], values[2]))
		"pal":
			if lines.is_empty() or lines[0].strip_edges() != "JASC-PAL":
				return colors
			for line in lines.slice(3):
				var values := _leading_ints(line)
				if values.size() >= 3:
					colors.append(Color8(values[0], values[1], values[2], values[3] if values.size() >= 4 else 255))
	return colors


## The whole numbers a line starts with: "255 0 77	Red" -> [255, 0, 77]. Headers
## ("Name: …") and comments give none.
static func _leading_ints(line: String) -> PackedInt32Array:
	var values := PackedInt32Array()
	for token in line.strip_edges().replace("\t", " ").split(" ", false):
		if not token.is_valid_int():
			break
		values.append(clampi(token.to_int(), 0, 255))
	return values
