@tool
class_name BitKilnGif
extends RefCounted
## Encodes animated GIFs (GIF89a) from frames, for sharing animations outside the game.
##
## All frames share one palette of up to 255 colors plus a transparent one; images with
## more colors are reduced by median cut first. Pixels less than half opaque become
## transparent.


## A GIF of [param frames] (same-size images), each shown for 1 / [param fps] seconds,
## looping forever unless [param loop] is off, scaled up by a whole [param scale].
static func encode(frames: Array[Image], fps: float, loop := true, scale := 1) -> PackedByteArray:
	var out := PackedByteArray()
	if frames.is_empty():
		return out
	var buffers: Array[BitKilnBuffer] = []
	for image in frames:
		var buffer := BitKilnBuffer.from_image(image)
		if scale > 1:
			buffer = BitKilnContext.scale_buffer(buffer, scale)
		buffers.append(buffer)
	var w := buffers[0].width
	var h := buffers[0].height

	# One palette for every frame; index 0 is transparent.
	var counts := {}
	for buffer in buffers:
		for c in buffer.pixels:
			if (c >> 24) & 0xFF >= 128:
				var opaque := BitKilnBuffer.with_alpha(c, 255)
				counts[opaque] = counts.get(opaque, 0) + 1
	var palette := PackedInt32Array(counts.keys())
	if palette.size() > 255:
		palette = BitKilnReduce.median_cut(counts, 255)
	var index_of := {}
	var exact := counts.size() <= 255
	for i in palette.size():
		index_of[palette[i]] = i + 1
	var bits := 1
	while (1 << bits) < palette.size() + 1:
		bits += 1

	out.append_array("GIF89a".to_ascii_buffer())
	_u16(out, w)
	_u16(out, h)
	out.append(0x80 | ((bits - 1) << 4) | (bits - 1)) # global color table, its size
	out.append(0) # background color index
	out.append(0) # pixel aspect ratio
	for i in 1 << bits:
		var c := palette[i - 1] if i >= 1 and i - 1 < palette.size() else 0
		out.append_array(PackedByteArray([c & 0xFF, (c >> 8) & 0xFF, (c >> 16) & 0xFF]))
	if loop:
		out.append_array(PackedByteArray([0x21, 0xFF, 0x0B]))
		out.append_array("NETSCAPE2.0".to_ascii_buffer())
		out.append_array(PackedByteArray([0x03, 0x01, 0x00, 0x00, 0x00]))
	var delay := maxi(2, roundi(100.0 / maxf(fps, 0.1)))
	var nearest_cache := {}
	for buffer in buffers:
		# Graphic control: clear to the background before the next frame, index 0 transparent.
		out.append_array(PackedByteArray([0x21, 0xF9, 0x04, (2 << 2) | 0x01]))
		_u16(out, delay)
		out.append_array(PackedByteArray([0x00, 0x00]))
		out.append(0x2C)
		_u16(out, 0)
		_u16(out, 0)
		_u16(out, w)
		_u16(out, h)
		out.append(0x00)
		var indices := PackedByteArray()
		indices.resize(w * h)
		var p := buffer.pixels
		for i in w * h:
			var c := p[i]
			if (c >> 24) & 0xFF < 128:
				continue
			var opaque := BitKilnBuffer.with_alpha(c, 255)
			if exact:
				indices[i] = index_of[opaque]
			else:
				if not nearest_cache.has(opaque):
					nearest_cache[opaque] = BitKilnPalette.nearest(opaque, palette) + 1
				indices[i] = nearest_cache[opaque]
		var min_code := maxi(2, bits)
		out.append(min_code)
		var data := lzw(indices, min_code)
		var at := 0
		while at < data.size():
			var block := mini(255, data.size() - at)
			out.append(block)
			out.append_array(data.slice(at, at + block))
			at += block
		out.append(0x00)
	out.append(0x3B)
	return out


## GIF-style LZW (least significant bit first, codes up to 12 bits) of [param indices],
## whose values fit in [param min_code] bits. Follows Go's compress/lzw writer.
static func lzw(indices: PackedByteArray, min_code: int) -> PackedByteArray:
	const MAX_CODE := 4095
	var out := PackedByteArray()
	var clear := 1 << min_code
	var eof := clear + 1
	var width := min_code + 1
	var hi := eof
	var overflow := 1 << width
	var table := {}
	var bit_buffer := 0
	var bit_count := 0
	# Codes and the width each is written with, packed into bits at the end.
	var codes := PackedInt32Array()
	var widths := PackedInt32Array()
	codes.append(clear)
	widths.append(width)
	if indices.is_empty():
		codes.append(eof)
		widths.append(width)
	else:
		var code := int(indices[0])
		for k in range(1, indices.size()):
			var literal := int(indices[k])
			var key := (code << 8) | literal
			if table.has(key):
				code = table[key]
				continue
			codes.append(code)
			widths.append(width)
			code = literal
			hi += 1
			if hi == overflow:
				width += 1
				overflow <<= 1
			if hi == MAX_CODE:
				codes.append(clear)
				widths.append(width)
				width = min_code + 1
				hi = eof
				overflow = clear << 1
				table.clear()
				continue
			table[key] = hi
		codes.append(code)
		widths.append(width)
		hi += 1
		if hi == overflow:
			width += 1
			overflow <<= 1
		if hi == MAX_CODE:
			codes.append(clear)
			widths.append(width)
			width = min_code + 1
		codes.append(eof)
		widths.append(width)
	for i in codes.size():
		bit_buffer |= codes[i] << bit_count
		bit_count += widths[i]
		while bit_count >= 8:
			out.append(bit_buffer & 0xFF)
			bit_buffer >>= 8
			bit_count -= 8
	if bit_count > 0:
		out.append(bit_buffer & 0xFF)
	return out


static func _u16(out: PackedByteArray, value: int) -> void:
	out.append(value & 0xFF)
	out.append((value >> 8) & 0xFF)
