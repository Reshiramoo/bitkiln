@tool
@icon("res://addons/bitkiln/icons/op.svg")
class_name BitKilnScale
extends BitKilnOp
## Scales up by a whole factor with a pixel-art scaler.
##
## Nearest keeps every pixel a crisp block. The Scale2x family (also known as EPX/AdvMAME)
## rounds off diagonal staircases, the smoothed look of emulators and of some DS-era
## sprite upscales. MMPX (McGuire and Gagiu, 2021) builds on it with rules for lines,
## slopes and single-pixel details, so results look closer to hand-drawn. None of them
## add colors. Other layers (a normal map) are scaled nearest. Frames are scaled one by
## one, so edges never mix with the next frame.

enum Algorithm {
	NEAREST, ## Blocks of [member factor]×[member factor].
	SCALE2X, ## 2×, smoothed diagonals.
	SCALE3X, ## 3×, smoothed diagonals.
	SCALE4X, ## 4×: Scale2x twice.
	MMPX, ## 2×, style-preserving: keeps thin lines and details intact.
	MMPX_4X, ## 4×: MMPX twice.
}

## The scaler to use.
@export var algorithm := Algorithm.SCALE2X
## Factor for Nearest; the others have their own.
@export_range(1, 16, 1) var factor := 2


func _apply(context: BitKilnContext) -> void:
	var frame := context.frame_size
	var color := context.color
	match algorithm:
		Algorithm.NEAREST:
			if factor > 1:
				context.scale_nearest(factor)
			return
		Algorithm.SCALE2X:
			context.scale_nearest(2)
			context.color = scale2x(color, frame)
		Algorithm.SCALE3X:
			context.scale_nearest(3)
			context.color = scale3x(color, frame)
		Algorithm.SCALE4X:
			context.scale_nearest(4)
			context.color = scale2x(scale2x(color, frame), frame * 2)
		Algorithm.MMPX:
			context.scale_nearest(2)
			context.color = mmpx(color, frame)
		Algorithm.MMPX_4X:
			context.scale_nearest(4)
			context.color = mmpx(mmpx(color, frame), frame * 2)


## [param src] scaled 2× with Scale2x (EPX), each [param frame]-sized cell on its own.
static func scale2x(src: BitKilnBuffer, frame: Vector2i) -> BitKilnBuffer:
	var w := src.width
	var dst := BitKilnBuffer.create(w * 2, src.height * 2)
	var sp := src.pixels
	var dp := dst.pixels
	var dw := dst.width
	for y in src.height:
		var fy0 := (y / frame.y) * frame.y
		var up := maxi(y - 1, fy0) * w
		var down := mini(y + 1, fy0 + frame.y - 1) * w
		var row := y * w
		for x in w:
			var fx0 := (x / frame.x) * frame.x
			var left := maxi(x - 1, fx0)
			var right := mini(x + 1, fx0 + frame.x - 1)
			var e := sp[row + x]
			var b := sp[up + x]
			var d := sp[row + left]
			var f := sp[row + right]
			var h := sp[down + x]
			var e0 := e
			var e1 := e
			var e2 := e
			var e3 := e
			if b != h and d != f:
				if d == b:
					e0 = d
				if b == f:
					e1 = f
				if d == h:
					e2 = d
				if h == f:
					e3 = f
			var o := (y * 2) * dw + x * 2
			dp[o] = e0
			dp[o + 1] = e1
			dp[o + dw] = e2
			dp[o + dw + 1] = e3
	dst.pixels = dp
	return dst


## [param src] scaled 3× with Scale3x, each [param frame]-sized cell on its own.
static func scale3x(src: BitKilnBuffer, frame: Vector2i) -> BitKilnBuffer:
	var w := src.width
	var dst := BitKilnBuffer.create(w * 3, src.height * 3)
	var sp := src.pixels
	var dp := dst.pixels
	var dw := dst.width
	for y in src.height:
		var fy0 := (y / frame.y) * frame.y
		var up := maxi(y - 1, fy0) * w
		var down := mini(y + 1, fy0 + frame.y - 1) * w
		var row := y * w
		for x in w:
			var fx0 := (x / frame.x) * frame.x
			var left := maxi(x - 1, fx0)
			var right := mini(x + 1, fx0 + frame.x - 1)
			var a := sp[up + left]
			var b := sp[up + x]
			var c := sp[up + right]
			var d := sp[row + left]
			var e := sp[row + x]
			var f := sp[row + right]
			var g := sp[down + left]
			var h := sp[down + x]
			var i := sp[down + right]
			var out := [e, e, e, e, e, e, e, e, e]
			if b != h and d != f:
				if d == b:
					out[0] = d
				if (d == b and e != c) or (b == f and e != a):
					out[1] = b
				if b == f:
					out[2] = f
				if (d == b and e != g) or (d == h and e != a):
					out[3] = d
				if (b == f and e != i) or (h == f and e != c):
					out[5] = f
				if d == h:
					out[6] = d
				if (d == h and e != i) or (h == f and e != g):
					out[7] = h
				if h == f:
					out[8] = f
			var o := (y * 3) * dw + x * 3
			for k in 9:
				dp[o + (k / 3) * dw + k % 3] = out[k]
	dst.pixels = dp
	return dst


## MMPX 2× magnification. Ported from the MIT-licensed reference by Morgan McGuire and
## Mara Gagiu (algorithm and C++ implementation, 2020) via Kyle Moore's Rust port (2021).
## Neighbours are clamped to the pixel's frame. Unlike the reference, transparent pixels
## count as brighter than any color, so the background never grows into the sprite.
static func mmpx(src: BitKilnBuffer, frame: Vector2i) -> BitKilnBuffer:
	var w := src.width
	var dst := BitKilnBuffer.create(w * 2, src.height * 2)
	var sp := src.pixels
	var dp := dst.pixels
	var dw := dst.width
	var lumas := {}
	# Clamped column (x) and row start (y * w) for offsets -3..3, index offset + 3.
	var cols := PackedInt32Array()
	cols.resize(7)
	var rows := PackedInt32Array()
	rows.resize(7)
	for y in src.height:
		var fy0 := (y / frame.y) * frame.y
		for n in 7:
			rows[n] = clampi(y + n - 3, fy0, fy0 + frame.y - 1) * w
		for x in w:
			var fx0 := (x / frame.x) * frame.x
			for n in 7:
				cols[n] = clampi(x + n - 3, fx0, fx0 + frame.x - 1)
			var a := sp[rows[2] + cols[2]]
			var b := sp[rows[2] + cols[3]]
			var c := sp[rows[2] + cols[4]]
			var d := sp[rows[3] + cols[2]]
			var e := sp[rows[3] + cols[3]]
			var f := sp[rows[3] + cols[4]]
			var g := sp[rows[4] + cols[2]]
			var h := sp[rows[4] + cols[3]]
			var i := sp[rows[4] + cols[4]]
			var p := sp[rows[1] + cols[3]]
			var q := sp[rows[3] + cols[1]]
			var r := sp[rows[3] + cols[5]]
			var s := sp[rows[5] + cols[3]]
			var bl := _luma(b, lumas)
			var dl := _luma(d, lumas)
			var el := _luma(e, lumas)
			var fl := _luma(f, lumas)
			var hl := _luma(h, lumas)
			var j := e
			var k := e
			var l := e
			var m := e

			# 1:1 slope rules
			if (d == b and d != h and d != f) and (el >= dl or e == a) and (e == a or e == c or e == g) \
					and (el < dl or a != d or e != p or e != q):
				j = d
			if (b == f and b != d and b != h) and (el >= bl or e == c) and (e == a or e == c or e == i) \
					and (el < bl or c != b or e != p or e != r):
				k = b
			if (h == d and h != f and h != b) and (el >= hl or e == g) and (e == a or e == g or e == i) \
					and (el < hl or g != h or e != s or e != q):
				l = h
			if (f == h and f != b and f != d) and (el >= fl or e == i) and (e == c or e == g or e == i) \
					and (el < fl or i != h or e != r or e != s):
				m = f

			# Intersection rules
			if e != f and e == c and e == i and e == d and e == q and f == b and f == h \
					and f != sp[rows[3] + cols[6]]:
				k = f
				m = f
			if e != d and e == a and e == g and e == f and e == r and d == b and d == h \
					and d != sp[rows[3] + cols[0]]:
				j = d
				l = d
			if e != h and e == g and e == i and e == b and e == p and h == d and h == f \
					and h != sp[rows[6] + cols[3]]:
				l = h
				m = h
			if e != b and e == a and e == c and e == h and e == s and b == d and b == f \
					and b != sp[rows[0] + cols[3]]:
				j = b
				k = b

			if bl < el and e == g and e == h and e == i and e == s and e != a and e != d and e != c and e != f:
				j = b
				k = b
			if hl < el and e == a and e == b and e == c and e == p and e != d and e != g and e != i and e != f:
				l = h
				m = h
			if fl < el and e == a and e == d and e == g and e == q and e != b and e != c and e != i and e != h:
				k = f
				m = f
			if dl < el and e == c and e == f and e == i and e == r and e != b and e != a and e != g and e != h:
				j = d
				l = d

			# 2:1 slope rules
			if h != b:
				if h != a and h != e and h != c:
					if h == g and h == f and h == r and h != d and h != sp[rows[2] + cols[5]]:
						l = m
					if h == i and h == d and h == q and h != f and h != sp[rows[2] + cols[1]]:
						m = l
				if b != i and b != g and b != e:
					if b == a and b == f and b == r and b != d and b != sp[rows[4] + cols[5]]:
						j = k
					if b == c and b == d and b == q and b != f and b != sp[rows[4] + cols[1]]:
						k = j
			if f != d:
				if d != i and d != e and d != c:
					if d == a and d == h and d == s and d != b and d != sp[rows[5] + cols[4]]:
						j = l
					if d == g and d == b and d == p and d != h and d != sp[rows[1] + cols[4]]:
						l = j
				if f != e and f != a and f != g:
					if f == c and f == h and f == s and f != b and f != sp[rows[5] + cols[2]]:
						k = m
					if f == i and f == b and f == p and f != h and f != sp[rows[1] + cols[2]]:
						m = k

			var o := (y * 2) * dw + x * 2
			dp[o] = j
			dp[o + 1] = k
			dp[o + dw] = l
			dp[o + dw + 1] = m
	dst.pixels = dp
	return dst


## Brightness for MMPX's rules; transparent is brightest, partly transparent in between.
static func _luma(c: int, cache: Dictionary) -> int:
	if cache.has(c):
		return cache[c]
	var a := (c >> 24) & 0xFF
	var sum := (c & 0xFF) + ((c >> 8) & 0xFF) + ((c >> 16) & 0xFF)
	var luma := (sum * a + 1024 * (255 - a)) / 255
	cache[c] = luma
	return luma
