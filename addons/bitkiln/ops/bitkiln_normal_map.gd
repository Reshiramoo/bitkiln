@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnNormalMap
extends BitKilnOp
## Makes a normal map from the sprite, for 2D lights. Save it with a Normal output, or
## pair it with the color in a [CanvasTexture] output.
##
## The surface is built from a height map: a bevel that rises from the sprite's edge
## toward its middle (as if inflated), plus detail from the colors' brightness. Snapping
## limits the normals to a few directions and steepnesses, so lights fall on the sprite
## in clean bands, as a pixel artist would shade it, instead of smooth gradients.
## Ops after this one (scaling, padding) keep the normal layer aligned with the colors.

## How far in from the edge the bevel rises, in pixels. 0 = no bevel.
@export_range(0, 32, 1, "or_greater", "suffix:px") var bevel_radius := 3
## Shape of the bevel from the edge (0) to [member bevel_radius] (1). Empty = rounded.
@export var bevel_profile: Curve
## Height the colors' brightness adds, in pixels: bright areas stand out.
@export_range(0.0, 8.0, 0.05, "or_greater", "suffix:px") var detail_depth := 0.5
## Dark areas stand out instead of bright ones.
@export var invert_detail := false
## Multiplies every slope: above 1 exaggerates the relief, below 1 flattens it.
@export_range(0.0, 4.0, 0.05, "or_greater") var strength := 1.0
## Directions a normal can face around the circle; 0 = any (smooth).
@export_range(0, 32, 1) var snap_directions := 8
## With snapping: how many steepness steps (besides facing the viewer).
@export_range(1, 8, 1) var snap_steepness := 2
## The frame's edges count as the sprite's edge, so sprites cut off by the frame still
## bevel there. Turn off for tiles that continue into the next one.
@export var bevel_frame_edges := true
## DirectX convention (green = down). Godot uses OpenGL's (green = up), so leave it off
## for Godot's 2D lights.
@export var flip_green := false
## Pixels with at least this alpha count as part of the sprite.
@export_range(0.01, 1.0, 0.01) var alpha_threshold := 0.5

const _MAX_TILT := deg_to_rad(70.0) # steepest snapped normal


func _apply(context: BitKilnContext) -> void:
	var color := context.color
	var w := color.width
	var h := color.height
	var size := context.frame_size
	var threshold := roundi(alpha_threshold * 255.0)
	var cp := color.pixels
	var solid := PackedByteArray()
	solid.resize(w * h)
	for i in w * h:
		solid[i] = 1 if (cp[i] >> 24) & 0xFF >= threshold else 0

	var heights := PackedFloat32Array()
	heights.resize(w * h)
	if bevel_radius > 0:
		var distances := _edge_distances(solid, w, h, size)
		for i in w * h:
			if solid[i]:
				heights[i] = _profile(clampf(distances[i] / bevel_radius, 0.0, 1.0)) * bevel_radius
	if detail_depth > 0.0:
		for i in w * h:
			if solid[i]:
				var c := cp[i]
				var luma := ((c & 0xFF) * 0.299 + ((c >> 8) & 0xFF) * 0.587 + ((c >> 16) & 0xFF) * 0.114) / 255.0
				heights[i] += (1.0 - luma if invert_detail else luma) * detail_depth

	var normal := BitKilnBuffer.create(w, h)
	var np := normal.pixels
	var green_sign := -1.0 if flip_green else 1.0
	for y in h:
		var fy0 := (y / size.y) * size.y
		var up := maxi(y - 1, fy0) * w
		var down := mini(y + 1, fy0 + size.y - 1) * w
		var row := y * w
		for x in w:
			if not solid[row + x]:
				continue
			var fx0 := (x / size.x) * size.x
			var left := maxi(x - 1, fx0)
			var right := mini(x + 1, fx0 + size.x - 1)
			# Sobel gradient of the height, per pixel.
			var dx := (heights[up + right] + 2.0 * heights[row + right] + heights[down + right]
				- heights[up + left] - 2.0 * heights[row + left] - heights[down + left]) / 8.0
			var dy := (heights[down + left] + 2.0 * heights[down + x] + heights[down + right]
				- heights[up + left] - 2.0 * heights[up + x] - heights[up + right]) / 8.0
			# Image y points down; the normal's y points up (OpenGL convention).
			var n := Vector3(-dx * strength, dy * strength, 1.0).normalized()
			if snap_directions > 0:
				n = _snap(n)
			np[row + x] = BitKilnBuffer.pack(roundi((n.x * 0.5 + 0.5) * 255.0),
				roundi((n.y * green_sign * 0.5 + 0.5) * 255.0), roundi((n.z * 0.5 + 0.5) * 255.0),
				(cp[row + x] >> 24) & 0xFF)
	normal.pixels = np
	context.layers[BitKilnContext.NORMAL] = normal


## Distance from each sprite pixel to the nearest empty one (an adjacent empty pixel is 1),
## per frame. Two-pass chamfer transform with 1 / √2 steps.
func _edge_distances(solid: PackedByteArray, w: int, h: int, size: Vector2i) -> PackedFloat32Array:
	const DIAGONAL := 1.41421356
	var far := float(w + h)
	var outside := 0.0 if bevel_frame_edges else far
	var d := PackedFloat32Array()
	d.resize(w * h)
	for i in w * h:
		d[i] = far if solid[i] else 0.0
	for y in h:
		var fy0 := (y / size.y) * size.y
		for x in w:
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var fx0 := (x / size.x) * size.x
			var fx1 := fx0 + size.x - 1
			var has_up := y > fy0
			var best := d[i]
			best = minf(best, (d[i - 1] if x > fx0 else outside) + 1.0)
			best = minf(best, (d[i - w] if has_up else outside) + 1.0)
			best = minf(best, (d[i - w - 1] if has_up and x > fx0 else outside) + DIAGONAL)
			best = minf(best, (d[i - w + 1] if has_up and x < fx1 else outside) + DIAGONAL)
			d[i] = best
	for y in range(h - 1, -1, -1):
		var fy1 := (y / size.y) * size.y + size.y - 1
		for x in range(w - 1, -1, -1):
			var i := y * w + x
			if d[i] == 0.0:
				continue
			var fx0 := (x / size.x) * size.x
			var fx1 := fx0 + size.x - 1
			var has_down := y < fy1
			var best := d[i]
			best = minf(best, (d[i + 1] if x < fx1 else outside) + 1.0)
			best = minf(best, (d[i + w] if has_down else outside) + 1.0)
			best = minf(best, (d[i + w + 1] if has_down and x < fx1 else outside) + DIAGONAL)
			best = minf(best, (d[i + w - 1] if has_down and x > fx0 else outside) + DIAGONAL)
			d[i] = best
	return d


func _profile(t: float) -> float:
	if bevel_profile != null:
		return bevel_profile.sample_baked(t)
	return sqrt(1.0 - (1.0 - t) * (1.0 - t)) # quarter circle: rounded


## [param n] turned to the nearest of the allowed directions and steepnesses.
func _snap(n: Vector3) -> Vector3:
	var tilt := acos(clampf(n.z, -1.0, 1.0))
	var step := _MAX_TILT / snap_steepness
	var level := clampi(roundi(tilt / step), 0, snap_steepness)
	if level == 0:
		return Vector3(0.0, 0.0, 1.0)
	var sector := TAU / snap_directions
	var angle := roundf(atan2(n.y, n.x) / sector) * sector
	var snapped_tilt := level * step
	return Vector3(cos(angle) * sin(snapped_tilt), sin(angle) * sin(snapped_tilt), cos(snapped_tilt))
