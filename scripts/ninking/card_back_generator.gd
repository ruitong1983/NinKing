class_name CardBackGenerator
extends RefCounted

## Generate NinKing card back texture — 140×196 pixel art ninja shuriken design.
## Usage: CardBackGenerator.generate("res://assets/images/cards/card_back.png")

static func generate(save_path: String = "res://assets/images/cards/card_back.png") -> int:
	const W: int = 140
	const H: int = 196
	var img: Image = Image.create(W, H, false, Image.FORMAT_RGBA8)

	# ── Colors ──
	const BG: Color = Color(0.102, 0.102, 0.18, 1.0)
	const GOLD_BORDER: Color = Color(0.753, 0.627, 0.188, 1.0)
	const GOLD_STAR: Color = Color(0.831, 0.686, 0.216, 1.0)
	const BRONZE: Color = Color(0.545, 0.451, 0.333, 1.0)
	const HATCH: Color = Color(0.137, 0.137, 0.216, 1.0)
	const BRIGHT: Color = Color(1.0, 0.9, 0.5, 1.0)

	img.fill(BG)

	# ── Diagonal crosshatch grid ──
	_draw_crosshatch(img, W, H, HATCH)

	# ── 2px outer border ──
	_draw_outer_border(img, W, H, GOLD_BORDER)

	# ── 1px inner border (inset 4px) ──
	_draw_inner_border(img, W, H, 4, BRONZE)

	# ── 4 corner diamonds ──
	_draw_diamond(img, 12, 12, 4, BRONZE)
	_draw_diamond(img, W - 13, 12, 4, BRONZE)
	_draw_diamond(img, 12, H - 13, 4, BRONZE)
	_draw_diamond(img, W - 13, H - 13, 4, BRONZE)

	# ── Center shuriken (4-point star) ──
	const CX: int = 70
	const CY: int = 98
	const STAR_R: int = 38
	const ARM_WIDTH: int = 5
	_draw_shuriken(img, W, H, CX, CY, STAR_R, ARM_WIDTH, GOLD_STAR, BG, BRIGHT)

	# ── Accent diamonds on cross arms ──
	const AO: int = 24
	_draw_diamond(img, CX + AO, CY, 2, BRONZE)
	_draw_diamond(img, CX - AO, CY, 2, BRONZE)
	_draw_diamond(img, CX, CY + AO, 2, BRONZE)
	_draw_diamond(img, CX, CY - AO, 2, BRONZE)

	# ── Bottom decorative line ──
	_draw_deco_line(img, W, H, BRONZE)

	# ── Save ──
	var err: int = img.save_png(save_path)
	return err


# ═══ Drawing helpers ═══

static func _draw_crosshatch(img: Image, w: int, h: int, color: Color) -> void:
	var y: int = 8
	while y < h - 8:
		var x: int = 8
		while x < w - 8:
			var d: int = 0
			while d < 3:
				var x1: int = x + d
				var y1: int = y + d
				if x1 < w - 8 and y1 < h - 8:
					img.set_pixel(x1, y1, color)
				var x2: int = x + 7 - d
				var y2: int = y + d
				if x2 >= 8 and y2 < h - 8:
					img.set_pixel(x2, y2, color)
				d += 1
			x += 8
		y += 8


static func _draw_outer_border(img: Image, w: int, h: int, color: Color) -> void:
	var bx: int = 0
	while bx < 2:
		var i: int = 0
		while i < w:
			img.set_pixel(i, bx, color)
			img.set_pixel(i, h - 1 - bx, color)
			i += 1
		var j: int = 0
		while j < h:
			img.set_pixel(bx, j, color)
			img.set_pixel(w - 1 - bx, j, color)
			j += 1
		bx += 1


static func _draw_inner_border(img: Image, w: int, h: int, inset: int, color: Color) -> void:
	var x: int = inset
	while x < w - inset:
		img.set_pixel(x, inset, color)
		img.set_pixel(x, h - 1 - inset, color)
		x += 1
	var y: int = inset
	while y < h - inset:
		img.set_pixel(inset, y, color)
		img.set_pixel(w - 1 - inset, y, color)
		y += 1


static func _draw_diamond(img: Image, cx: int, cy: int, size: int, color: Color) -> void:
	var dy: int = -size
	while dy <= size:
		var half_w: int = size - absi(dy)
		var dx: int = -half_w
		while dx <= half_w:
			var px: int = cx + dx
			var py: int = cy + dy
			if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
				img.set_pixel(px, py, color)
			dx += 1
		dy += 1


static func _draw_shuriken(img: Image, w: int, h: int, cx: int, cy: int, star_r: int, arm_w: int, gold: Color, bg: Color, bright: Color) -> void:
	# Cross arms (horizontal + vertical)
	var r: int = 0
	while r < star_r:
		var t: int = -arm_w
		while t <= arm_w:
			# Horizontal
			var hx: int = cx + r
			var hy: int = cy + t
			if hx > 2 and hx < w - 3 and hy > 2 and hy < h - 3:
				img.set_pixel(hx, hy, gold)
				img.set_pixel(cx - r, hy, gold)
			# Vertical
			var vx: int = cx + t
			var vy: int = cy + r
			if vx > 2 and vx < w - 3 and vy > 2 and vy < h - 3:
				img.set_pixel(vx, vy, gold)
				img.set_pixel(vx, cy - r, gold)
			t += 1
		r += 1

	# Diagonal tapered blades
	r = 0
	while r < star_r:
		var taper: int = arm_w - r / 6
		if taper < 0:
			taper = 0
		var t2: int = -taper
		while t2 <= taper:
			var dx: int = r + t2
			var dy: int = r - t2
			var dist: float = sqrt(float(dx * dx + dy * dy))
			var fade: float = 1.0 - dist / float(star_r)
			if fade < 0.0: fade = 0.0
			if fade > 1.0: fade = 1.0
			var clr: Color = gold.lerp(bg, 1.0 - fade)
			var px: int = cx + dx
			var py: int = cy - dy
			if px > 2 and px < w - 3 and py > 2 and py < h - 3:
				img.set_pixel(px, py, clr)
			px = cx - dx
			if px > 2 and px < w - 3 and py > 2 and py < h - 3:
				img.set_pixel(px, py, clr)
			t2 += 1
		r += 1

	# Center ring
	const RING_R: int = 6
	var ry: int = -RING_R
	while ry <= RING_R:
		var rx: int = -RING_R
		while rx <= RING_R:
			var dist2: float = sqrt(float(rx * rx + ry * ry))
			if dist2 >= RING_R - 1.5 and dist2 <= RING_R + 0.5:
				var rxi: int = cx + rx
				var ryi: int = cy + ry
				if rxi > 2 and rxi < w - 3 and ryi > 2 and ryi < h - 3:
					img.set_pixel(rxi, ryi, gold)
			rx += 1
		ry += 1

	# Center bright dot
	var dy2: int = -1
	while dy2 <= 1:
		var dx2: int = -1
		while dx2 <= 1:
			img.set_pixel(cx + dx2, cy + dy2, bright)
			dx2 += 1
		dy2 += 1


static func _draw_deco_line(img: Image, w: int, h: int, color: Color) -> void:
	var dl_y: int = h - 28
	var dl_x: int = 12
	while dl_x < w - 12:
		var d: int = 0
		while d < 3:
			if dl_x + d < w - 12:
				img.set_pixel(dl_x + d, dl_y, color)
			d += 1
		dl_x += 4


# ═══ Slot background generator (V6) ═══

## Generate NinKing ability slot background — 100×140 pixel art ninja frame.
static func generate_slot_bg(save_path: String = "res://assets/images/cards/slot_bg.png") -> int:
	const W: int = 100
	const H: int = 140
	var img: Image = Image.create(W, H, false, Image.FORMAT_RGBA8)

	# ── Colors ──
	const BG: Color = Color(0.09, 0.09, 0.16, 1.0)
	const GOLD_BORDER: Color = Color(0.753, 0.627, 0.188, 1.0)
	const BRONZE: Color = Color(0.545, 0.451, 0.333, 1.0)
	const RECESS: Color = Color(0.06, 0.06, 0.12, 1.0)
	const HATCH: Color = Color(0.12, 0.12, 0.20, 1.0)
	const DIM_GOLD: Color = Color(0.50, 0.42, 0.22, 1.0)

	img.fill(BG)

	# ── Diagonal crosshatch (more sparse than card back — every 10px) ──
	var y: int = 10
	while y < H - 10:
		var x: int = 10
		while x < W - 10:
			var d: int = 0
			while d < 2:
				var x1: int = x + d
				var y1: int = y + d
				if x1 < W - 10 and y1 < H - 10:
					img.set_pixel(x1, y1, HATCH)
				var x2: int = x + 9 - d
				var y2: int = y + d
				if x2 >= 10 and y2 < H - 10:
					img.set_pixel(x2, y2, HATCH)
				d += 1
			x += 10
		y += 10

	# ── 2px outer border ──
	_draw_outer_border(img, W, H, GOLD_BORDER)

	# ── Inner recessed border (1px, inset 4px) ──
	_draw_inner_border(img, W, H, 4, BRONZE)

	# ── Recessed center area (slightly darker, inset 6px) ──
	var inset: int = 6
	var ry: int = inset + 1
	while ry < H - inset - 1:
		var rx: int = inset + 1
		while rx < W - inset - 1:
			img.set_pixel(rx, ry, RECESS)
			rx += 1
		ry += 1

	# ── 4 corner diamonds (smaller than card back) ──
	const DOFF: int = 10
	_draw_diamond(img, DOFF, DOFF, 3, BRONZE)
	_draw_diamond(img, W - 1 - DOFF, DOFF, 3, BRONZE)
	_draw_diamond(img, DOFF, H - 1 - DOFF, 3, BRONZE)
	_draw_diamond(img, W - 1 - DOFF, H - 1 - DOFF, 3, BRONZE)

	# ── Center ninja star (small 4-point, subtle) ──
	const CX: int = 50
	const CY: int = 70
	const SR: int = 16
	const AW: int = 2
	_draw_shuriken(img, W, H, CX, CY, SR, AW, DIM_GOLD, RECESS, DIM_GOLD)

	# ── Top accent line ──
	var ty: int = inset + 3
	var tx: int = inset + 6
	while tx < W - inset - 6:
		var dl: int = 0
		while dl < 2:
			if tx + dl < W - inset - 6:
				img.set_pixel(tx + dl, ty, BRONZE)
			dl += 1
		tx += 6

	# ── Bottom accent line ──
	var by: int = H - inset - 4
	var bx: int = inset + 6
	while bx < W - inset - 6:
		var dl2: int = 0
		while dl2 < 2:
			if bx + dl2 < W - inset - 6:
				img.set_pixel(bx + dl2, by, BRONZE)
			dl2 += 1
		bx += 6

	# ── Save ──
	var err: int = img.save_png(save_path)
	return err
