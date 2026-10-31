@tool
extends Control
## Shows a recipe's result at whole-number zoom on a checkerboard: the result, the source,
## or both side by side, with an optional frame grid, as a whole sheet or one frame at a
## time (for playing animations). In lit mode the result is shaded by its normal map with a
## light that follows the mouse.

enum View { RESULT, SOURCE, SIDE_BY_SIDE }

const MAX_ZOOM := 32
const GAP := 16.0
const CHECKER := 8.0
const PAN_SPEED := 20.0 # screen pixels per unit of trackpad pan or wheel scroll
const MAGNIFY_STEP := 1.2 # pinch this much for one zoom step
const LIT_SHADER := """
shader_type canvas_item;
uniform sampler2D normal_map : filter_nearest;
uniform vec2 light_uv = vec2(0.25, 0.25); // in the whole texture's UV, even when one frame is shown
uniform vec2 texture_size = vec2(16.0);
uniform float light_height = 12.0;
uniform float ambient = 0.3;
void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec3 n = texture(normal_map, UV).rgb * 2.0 - 1.0;
	n.y = -n.y; // green points up, UV.y down
	vec3 to_light = normalize(vec3((light_uv - UV) * texture_size, light_height));
	float diffuse = max(dot(normalize(n), to_light), 0.0);
	COLOR = vec4(base.rgb * (ambient + (1.0 - ambient) * diffuse), base.a);
}
"""

signal zoom_changed(zoom: int)

var view := View.RESULT:
	set(value):
		view = value
		_layout()
var show_grid := true:
	set(value):
		show_grid = value
		_overlay.queue_redraw()
var lit := false:
	set(value):
		lit = value
		_update_material()
var zoom := 4:
	set(value):
		zoom = clampi(value, 1, MAX_ZOOM)
		_layout()
		zoom_changed.emit(zoom)
## The frame shown (counted row by row from 0), or -1 for the whole sheet.
var frame := -1:
	set(value):
		frame = value if value < get_frame_count() else -1
		_apply_frame()

var _source: Texture2D
var _result: Texture2D
var _normal: Texture2D
var _source_frames := Vector2i.ONE
var _result_frames := Vector2i.ONE
var _pan := Vector2.ZERO
var _dragging := false
var _magnify := 1.0 # pinch gathered toward the next zoom step
var _source_rect := TextureRect.new()
var _result_rect := TextureRect.new()
var _overlay := Control.new()
var _lit_material := ShaderMaterial.new()
var _auto_fit := true # fit on every resize until the user zooms or pans
var _source_scale := 1 # the source is drawn this much bigger, to match a scaled-up result
var _region := Rect2(0.0, 0.0, 1.0, 1.0) # the frame shown, in the result's UV


func _init() -> void:
	clip_contents = true
	focus_mode = Control.FOCUS_CLICK
	for rect: TextureRect in [_source_rect, _result_rect]:
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_SCALE
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	var shader := Shader.new()
	shader.code = LIT_SHADER
	_lit_material.shader = shader
	resized.connect(_layout)


## Shows new images. Zoom and pan are kept unless [param refit] or nothing was shown yet.
func set_images(source: Texture2D, result: Texture2D, normal: Texture2D, source_frames: Vector2i,
		result_frames: Vector2i, refit := false) -> void:
	_source = source
	_result = result
	_normal = normal
	_source_frames = source_frames
	_result_frames = result_frames
	_source_rect.texture = source
	_result_rect.texture = result
	_source_scale = 1
	if source != null and result != null:
		var source_frame := source.get_size() / Vector2(source_frames)
		var result_frame := result.get_size() / Vector2(result_frames)
		var ratio := result_frame / source_frame
		if ratio.x == ratio.y and ratio.x >= 2.0 and ratio.x == floorf(ratio.x):
			_source_scale = int(ratio.x)
	if refit:
		_auto_fit = true
	if frame >= get_frame_count():
		frame = -1
	_apply_frame()


## Frames in the result sheet.
func get_frame_count() -> int:
	return _result_frames.x * _result_frames.y if _result != null else 0


## Zooms in or out by [param steps]; stops fitting to the panel's size.
func zoom_by(steps: int) -> void:
	_auto_fit = false
	zoom += steps


## The largest whole zoom at which everything shown fits, centered.
func fit() -> void:
	var content := _content_size(1)
	if content.x <= 0.0 or content.y <= 0.0 or size.x <= 0.0:
		return
	var room := size - Vector2(GAP, GAP) * 2.0
	_pan = Vector2.ZERO
	_auto_fit = true
	zoom = maxi(1, floori(minf(room.x / content.x, room.y / content.y)))


## Zooms by [param steps], keeping the point under [param at] in place.
func zoom_at(steps: int, at: Vector2) -> void:
	var before := zoom
	var after := clampi(zoom + steps, 1, MAX_ZOOM)
	if after == before:
		return
	var center := size * 0.5 + _pan
	_pan += (at - center) * (1.0 - float(after) / before)
	_auto_fit = false
	zoom = after


func _gui_input(event: InputEvent) -> void:
	# Trackpads: pinch zooms, two-finger scrolling pans.
	var magnify := event as InputEventMagnifyGesture
	if magnify != null:
		_magnify *= magnify.factor
		while _magnify >= MAGNIFY_STEP:
			_magnify /= MAGNIFY_STEP
			zoom_at(1, magnify.position)
		while _magnify <= 1.0 / MAGNIFY_STEP:
			_magnify *= MAGNIFY_STEP
			zoom_at(-1, magnify.position)
		accept_event()
		return
	var pan := event as InputEventPanGesture
	if pan != null:
		_pan -= pan.delta * PAN_SPEED
		_auto_fit = false
		_layout()
		accept_event()
		return
	var mouse := event as InputEventMouseButton
	if mouse != null:
		if mouse.pressed and mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and mouse.shift_pressed:
			# Shift + wheel scrolls sideways.
			_pan.x += (1.0 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else -1.0) * PAN_SPEED * maxf(mouse.factor, 1.0)
			_auto_fit = false
			_layout()
			accept_event()
		elif mouse.pressed and mouse.button_index in [MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
			_pan.x += (1.0 if mouse.button_index == MOUSE_BUTTON_WHEEL_LEFT else -1.0) * PAN_SPEED * maxf(mouse.factor, 1.0)
			_auto_fit = false
			_layout()
			accept_event()
		elif mouse.pressed and mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_at(1 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else -1, mouse.position)
			accept_event()
		elif mouse.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			_dragging = mouse.pressed
			accept_event()
	var motion := event as InputEventMouseMotion
	if motion != null:
		if _dragging:
			_pan += motion.relative
			_auto_fit = false
			_layout()
		elif lit and _result_rect.visible and _result_rect.size.x > 0.0:
			var uv := (motion.position - _result_rect.position) / _result_rect.size
			_lit_material.set_shader_parameter(&"light_uv", _region.position + uv * _region.size)


func _draw() -> void:
	for rect: TextureRect in [_source_rect, _result_rect]:
		if rect.visible and rect.texture != null:
			var pixel := zoom * (_source_scale if rect == _source_rect else 1)
			_draw_checker(Rect2(rect.position, rect.size), checker_cell(pixel))


## Size of a checkerboard cell for sprite pixels [param pixel] screen pixels wide: a whole
## number of sprite pixels, about [constant CHECKER] screen pixels or more, so the
## checkerboard lines up with the sprite's pixels at every zoom.
static func checker_cell(pixel: int) -> int:
	return pixel * maxi(1, ceili(CHECKER / pixel))


func _draw_checker(area: Rect2, cell: int) -> void:
	var light := Color(0.42, 0.42, 0.42)
	var dark := Color(0.32, 0.32, 0.32)
	draw_rect(area, dark)
	var step := float(cell)
	var y := 0.0
	var row := 0
	while y < area.size.y:
		var x := step if row % 2 == 0 else 0.0
		while x < area.size.x:
			var square := Rect2(area.position + Vector2(x, y), Vector2(step, step)).intersection(area)
			draw_rect(square, light)
			x += step * 2.0
		y += step
		row += 1


func _draw_overlay() -> void:
	if not show_grid:
		return
	var color := Color(1.0, 0.6, 0.3, 0.6)
	for pair: Array in [[_source_rect, _source_frames], [_result_rect, _result_frames]]:
		var rect: TextureRect = pair[0]
		var frames: Vector2i = pair[1] if frame < 0 else Vector2i.ONE
		if not rect.visible or rect.texture == null:
			continue
		var area := Rect2(rect.position, rect.size)
		_overlay.draw_rect(area, color, false, 1.0)
		for i in range(1, frames.x):
			var x := area.position.x + area.size.x * i / frames.x
			_overlay.draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), color)
		for i in range(1, frames.y):
			var y := area.position.y + area.size.y * i / frames.y
			_overlay.draw_line(Vector2(area.position.x, y), Vector2(area.end.x, y), color)


func _content_size(at_zoom: int) -> Vector2:
	var shown := _shown()
	var total := Vector2.ZERO
	for texture: Texture2D in shown:
		var s := Vector2(texture.get_size()) * at_zoom * (_source_scale if texture == _source_rect.texture else 1)
		total.x += s.x
		total.y = maxf(total.y, s.y)
	if shown.size() > 1:
		total.x += GAP
	return total


func _shown() -> Array[Texture2D]:
	var shown: Array[Texture2D] = []
	if view != View.RESULT and _source_rect.texture != null:
		shown.append(_source_rect.texture)
	if view != View.SOURCE and _result_rect.texture != null:
		shown.append(_result_rect.texture)
	return shown


## Shows the whole sheets, or frame [member frame] of each (of the source too when it has
## frames: the same frame number, wrapping around).
func _apply_frame() -> void:
	_region = Rect2(0.0, 0.0, 1.0, 1.0)
	if frame < 0 or _result == null:
		_source_rect.texture = _source
		_result_rect.texture = _result
	else:
		_result_rect.texture = _frame_texture(_result, _result_frames, frame)
		var size_uv := Vector2.ONE / Vector2(_result_frames)
		_region = Rect2(Vector2(frame % _result_frames.x, frame / _result_frames.x) * size_uv, size_uv)
		var source_count := _source_frames.x * _source_frames.y
		if _source == null or source_count <= 1:
			_source_rect.texture = _source
		else:
			_source_rect.texture = _frame_texture(_source, _source_frames, frame % source_count)
	_update_material()
	_layout()


static func _frame_texture(sheet: Texture2D, grid: Vector2i, index: int) -> AtlasTexture:
	var size := Vector2(sheet.get_size()) / Vector2(grid)
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(index % grid.x, index / grid.x) * size, size)
	return atlas


func _layout() -> void:
	if _auto_fit and size.x > 0.0 and not _shown().is_empty():
		var room := size - Vector2(GAP, GAP) * 2.0
		var content1 := _content_size(1)
		var fitting := maxi(1, floori(minf(room.x / content1.x, room.y / content1.y)))
		if fitting != zoom:
			zoom = fitting # lays out again
			return
	var content := _content_size(zoom)
	var origin := (size - content) * 0.5 + _pan
	_source_rect.visible = view != View.RESULT and _source != null
	_result_rect.visible = view != View.SOURCE and _result != null
	var x := origin.x
	for rect: TextureRect in [_source_rect, _result_rect]:
		if not rect.visible:
			continue
		var s := rect.texture.get_size() * zoom * (_source_scale if rect == _source_rect else 1)
		rect.position = Vector2(x, origin.y + (content.y - s.y) * 0.5).floor()
		rect.size = s
		x += s.x + GAP
	queue_redraw()
	_overlay.queue_redraw()


func _update_material() -> void:
	var use := lit and _normal != null and _result != null
	_result_rect.material = _lit_material if use else null
	if use:
		_lit_material.set_shader_parameter(&"normal_map", _normal)
		var tex_size := _result.get_size()
		_lit_material.set_shader_parameter(&"texture_size", tex_size)
		var frame_px := tex_size / Vector2(_result_frames)
		_lit_material.set_shader_parameter(&"light_height", maxf(frame_px.x, frame_px.y) * 0.5)
