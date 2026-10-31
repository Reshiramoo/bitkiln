@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnNoise
extends BitKilnOp
## Fills every frame with noise, banded through a gradient: grass, dirt, water, stone and
## cloud textures, star fields, terrain maps. Seamless noise tiles, so the frames work as
## repeating textures or tiles. Each frame gets its own part of the noise, for variations.

## The noise to sample (type, frequency, octaves…). Empty = smooth simplex, 3 octaves.
@export var noise: FastNoiseLite
## Low noise values (left) to high ones (right). Its alpha is kept, so transparent parts
## make holes (clouds). Empty = black to white.
@export var colors: Gradient
## Bands of color; 0 = smooth.
@export_range(0, 16, 1) var color_steps := 4
## Pick between neighbouring bands with an ordered pattern, for softer edges.
@export var dither := false
## Tile seamlessly: the left edge continues the right one, the top the bottom.
@export var seamless := true
## Stretch the noise's values to the whole gradient.
@export var normalize := true


func _apply(context: BitKilnContext) -> void:
	var source: FastNoiseLite = noise.duplicate() if noise != null else _default_noise()
	var gradient := colors if colors != null else _default_colors()
	var size := context.frame_size
	var total := context.frames.x * context.frames.y
	var p := context.color.pixels
	for index in total:
		var image: Image
		var offset_before := source.offset
		# Each frame samples a different area of the same noise (on a copy: the op's own
		# resource stays untouched).
		source.offset = offset_before + Vector3(index * size.x * 3.0, 0.0, 0.0)
		if seamless:
			image = source.get_seamless_image(size.x, size.y, false, false, 0.1, normalize)
		else:
			image = source.get_image(size.x, size.y, false, false, normalize)
		source.offset = offset_before
		image.convert(Image.FORMAT_L8)
		var values := image.get_data()
		var origin := Vector2i(index % context.frames.x, index / context.frames.x) * size
		for y in size.y:
			var row := (origin.y + y) * context.width + origin.x
			for x in size.x:
				var c := BitKilnFilter.gradient_color(gradient, values[y * size.x + x] / 255.0, color_steps, dither, x, y)
				p[row + x] = BitKilnBuffer.blend(c, p[row + x])
	context.color.pixels = p


static func _default_noise() -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.08
	n.fractal_octaves = 3
	return n


static func _default_colors() -> Gradient:
	var gradient := Gradient.new()
	gradient.set_color(0, Color.BLACK)
	gradient.set_color(1, Color.WHITE)
	return gradient
