@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnMaterial
extends BitKilnOp
## Renders the image through a CanvasItem material and keeps the result: design an
## effect live with a shader (a hit flash, a dissolve, a palette shader, your
## own), then freeze it into the PNG so the game doesn't run the shader. The material
## itself isn't changed.
##
## Rendering needs the editor or a game window: in [code]--headless[/code] runs (the
## bake_all script) this op does nothing and says so. Effects that change over time
## ([code]TIME[/code]) are caught at an arbitrary moment. Effects that draw outside the
## sprite (outlines, shadows) need room: put a [BitKilnPad] before it.

## The material to render with: a ShaderMaterial (canvas_item shader) or a
## CanvasItemMaterial.
@export var material: Material
## Set the shader's [code]sheet_frames[/code] uniform, if it has one ([code]vec2[/code]: columns
## and rows), to the frame grid, so per-frame effects stay inside their frames.
@export var set_sheet_frames := true
## Shader parameters for this bake only, by name: they override the material's values
## without changing it. For example [code]{"flash_amount": 1.0}[/code].
@export var parameters := {}


func _apply(context: BitKilnContext) -> void:
	if material == null:
		context.warn("Bake Material: no material.")
		return
	if DisplayServer.get_name() == "headless":
		context.warn("Bake Material: needs a renderer (the editor or a game window); skipped.")
		return
	var used := material.duplicate() as Material
	var shader_material := used as ShaderMaterial
	if shader_material != null and shader_material.shader != null:
		var uniforms := {}
		for uniform in shader_material.shader.get_shader_uniform_list():
			uniforms[uniform.name] = true
		if set_sheet_frames and uniforms.has("sheet_frames"):
			shader_material.set_shader_parameter(&"sheet_frames", Vector2(context.frames))
		for key: Variant in parameters:
			if not uniforms.has(str(key)):
				context.warn("Bake Material: the shader has no parameter \"%s\"." % key)
			shader_material.set_shader_parameter(StringName(str(key)), parameters[key])

	# Drawn straight through the RenderingServer: a node would only draw on its next
	# deferred redraw, too late for this frame.
	var rs := RenderingServer
	var texture := context.color.to_texture()
	var viewport := rs.viewport_create()
	rs.viewport_set_size(viewport, context.width, context.height)
	rs.viewport_set_transparent_background(viewport, true)
	rs.viewport_set_disable_3d(viewport, true)
	rs.viewport_set_default_canvas_item_texture_filter(viewport, RenderingServer.CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
	rs.viewport_set_update_mode(viewport, RenderingServer.VIEWPORT_UPDATE_ONCE)
	rs.viewport_set_active(viewport, true)
	var canvas := rs.canvas_create()
	rs.viewport_attach_canvas(viewport, canvas)
	var item := rs.canvas_item_create()
	rs.canvas_item_set_parent(item, canvas)
	rs.canvas_item_set_material(item, used.get_rid())
	rs.canvas_item_add_texture_rect(item, Rect2(0, 0, context.width, context.height), texture.get_rid())
	rs.force_draw(false)
	var image := rs.texture_2d_get(rs.viewport_get_texture(viewport))
	rs.free_rid(item)
	rs.free_rid(canvas)
	rs.free_rid(viewport)
	if image == null or image.is_empty():
		context.warn("Bake Material: nothing was rendered; skipped.")
		return
	image.convert(Image.FORMAT_RGBA8)
	context.color = BitKilnBuffer.from_image(image)
