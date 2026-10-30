class_name ArcanaExtra
extends RefCounted
## Ilustraciones (54x70) de los doce Arcanos Mayores que completan la baraja, con ayudantes para figuras con
## túnica, alas, columnas y personas pequeñas. Misma técnica que Arcana: capas, rampas, contorno y biselado.

const AW := 54
const AH := 70
const SMALL := ["..hh....", ".hssh...", ".ssss...", "..ss....", ".aaaa...", "aaaaaa..", "s.aa.s..", "..aa....", ".a..a...", ".a..a...", "kk..kk.."]


static func art(a: Image, id: String) -> void:
	match id:
		"sacerdotisa": _sacerdotisa(a)
		"emperatriz": _emperatriz(a)
		"emperador": _emperador(a)
		"hierofante": _hierofante(a)
		"enamorados": _enamorados(a)
		"carro": _carro(a)
		"ermitano": _ermitano(a)
		"justicia": _justicia(a)
		"templanza": _templanza(a)
		"diablo": _diablo(a)
		"estrella": _estrella(a)
		"juicio": _juicio(a)


# --- Ayudantes ---

## Figura con túnica. o: hood, hair, beard (Color), crown (gold/triple/moon/stars/horns), trim (Color), hands [Vector2, Vector2].
static func robed(l: Image, cx: int, top: int, h: int, robe: Color, o: Dictionary = {}) -> Array:
	var rr := Paint.ramp(robe)
	var hy := top + 6
	var hands: Array = o.get("hands", [Vector2(cx - 9, top + 23), Vector2(cx + 9, top + 23)])
	if o.get("hood", false):
		Paint.ellipse(l, cx, hy, 7.5, 7.5, rr[1])
	if o.has("hair"):
		var hr := Paint.ramp(o.hair)
		Paint.sphere(l, cx, hy - 1, 6.2, hr, 1.0, false)
		Pix.rect(l, cx - 6, hy, 3, 9, hr[1])
		Pix.rect(l, cx + 4, hy, 3, 9, hr[1])
	var body := Paint.layer(AW, AH)
	var neck := top + 11
	Paint.poly(body, PackedVector2Array([Vector2(cx - 5, neck), Vector2(cx + 5, neck), Vector2(cx + 12, top + h), Vector2(cx - 12, top + h)]), rr[2])
	for k in [-7, -3, 2, 6]:
		for y in range(neck + 8, top + h):
			var x: int = cx + k + (y - neck) * k / 22
			if body.get_pixel(clampi(x, 0, AW - 1), clampi(y, 0, AH - 1)).a > 0.0 and y % 2 == 0:
				Pix.px(body, x, y, rr[1])
				Pix.px(body, x + 1, y, rr[3])
	if o.has("trim"):
		var tr := Paint.ramp(o.trim)
		for y in range(neck, top + h):
			Pix.rect(body, cx - 1, y, 3, 1, tr[2] if y % 3 else tr[3])
		Pix.rect(body, cx - 12, top + h - 2, 25, 2, tr[2])
	Paint.bevel(body, rr[4], rr[0])
	for side in 2:
		var sh := Vector2(cx + (-5 if side == 0 else 5), neck + 2)
		var hd: Vector2 = hands[side]
		Paint.thick_line(body, sh, hd, 3, rr[3] if side == 0 else rr[1])
	Paint.put(l, body, 0, 0)
	for hd in hands:
		Pix.rect(l, roundi(hd.x) - 1, roundi(hd.y) - 1, 3, 3, o.get("skin", Pix.SKIN))
		Pix.px(l, roundi(hd.x) + 1, roundi(hd.y) + 1, Color(o.get("skin", Pix.SKIN)).darkened(0.2))
	var skin: Color = o.get("skin", Pix.SKIN)
	Paint.sphere(l, cx, hy, 5.2, Paint.ramp(skin), 1.0, false)
	var eye: Color = o.get("eyes", Pix.INK)
	Pix.px(l, cx - 2, hy, eye)
	Pix.px(l, cx + 2, hy, eye)
	Pix.px(l, cx - 3, hy + 2, Pix.BLUSH)
	Pix.px(l, cx + 3, hy + 2, Pix.BLUSH)
	Pix.px(l, cx, hy + 3, Color("a8504a"))
	if o.has("beard"):
		var br := Paint.ramp(o.beard)
		Paint.poly(l, PackedVector2Array([Vector2(cx - 5, hy + 2), Vector2(cx + 5, hy + 2), Vector2(cx + 1, hy + 11), Vector2(cx - 1, hy + 11)]), br[3])
		for y in range(hy + 3, hy + 10, 2):
			Pix.px(l, cx - 1, y, br[1])
			Pix.px(l, cx + 2, y + 1, br[1])
		Pix.rect(l, cx - 2, hy + 2, 5, 1, br[4])
		Pix.px(l, cx, hy + 3, Color("a8504a"))
	if o.get("hood", false):
		for x in range(cx - 7, cx + 8):
			var yy := hy - roundi(sqrt(maxf(0.0, 49.0 - (x - cx) * (x - cx))) * 0.95)
			Pix.px(l, x, yy, rr[3])
			Pix.px(l, x, yy + 1, rr[1])
	var gold := Paint.ramp(Pix.GOLD)
	match o.get("crown", ""):
		"gold":
			Pix.rect(l, cx - 5, hy - 7, 11, 3, gold[2])
			for k in 3:
				Pix.rect(l, cx - 5 + k * 5, hy - 9, 1, 2, gold[3])
			Pix.px(l, cx, hy - 6, Color("ff3a4a"))
			Pix.rect(l, cx - 5, hy - 7, 11, 1, gold[4])
		"triple":
			for k in 3:
				Pix.rect(l, cx - 4 + k, hy - 7 - k * 3, 9 - k * 2, 3, gold[2 + (k % 2)])
				Pix.rect(l, cx - 4 + k, hy - 7 - k * 3, 9 - k * 2, 1, gold[4])
			Pix.px(l, cx, hy - 16, gold[4])
		"moon":
			Paint.sphere(l, cx, hy - 8, 2.4, Paint.ramp(Color("f4f0ff")), 1.0, false)
			for s in [-1, 1]:
				Pix.px(l, cx + s * 3, hy - 9, Color("f4f0ff"))
				Pix.px(l, cx + s * 4, hy - 10, Color("f4f0ff"))
		"stars":
			for k in 7:
				var ang := PI + PI * (k + 0.5) / 7.0
				Paint.sparkle(l, cx + roundi(cos(ang) * 8.0), hy - 2 + roundi(sin(ang) * 8.0), Pix.GOLD)
		"horns":
			var hn := Paint.ramp(Color("d8c8a8"))
			for s in [-1, 1]:
				Paint.bezier(l, Vector2(cx + s * 3, hy - 4), Vector2(cx + s * 12, hy - 12), Vector2(cx + s * 7, hy - 15), 2, hn[3])
				Pix.px(l, cx + s * 7, hy - 15, hn[1])
	return hands


static func wings(l: Image, cx: float, cy: float, span: float, col: Color) -> void:
	var rp := Paint.ramp(col)
	for side in [-1.0, 1.0]:
		for k in 7:
			var t := k / 6.0
			var p := Vector2(cx + side * (3.0 + t * span), cy - 4.0 + t * t * 8.0 - sin(t * PI) * 5.0)
			Paint.sphere(l, p.x, p.y + 5.0, 2.4, rp, 2.6 - t, false)
		Paint.sphere(l, cx + side * span * 0.45, cy - 2.0, 3.0, rp, 1.0, false)


static func pillar(l: Image, x: int, y0: int, y1: int, col: Color) -> void:
	var rp := Paint.ramp(col)
	Pix.rect(l, x, y0 + 3, 6, y1 - y0 - 6, rp[2])
	Pix.rect(l, x + 1, y0 + 3, 1, y1 - y0 - 6, rp[4])
	Pix.rect(l, x + 4, y0 + 3, 1, y1 - y0 - 6, rp[1])
	Pix.rect(l, x - 1, y0, 8, 3, rp[3])
	Pix.rect(l, x - 1, y1 - 3, 8, 3, rp[1])
	Pix.rect(l, x - 1, y0, 8, 1, rp[4])


static func small(pal: Dictionary, flip := false) -> Image:
	var im := Arcana._sprite(SMALL, pal)
	if flip:
		im.flip_x()
	return im


static func heart(l: Image, cx: float, cy: float, r: float, col: Color) -> void:
	var rp := Paint.ramp(col)
	Paint.sphere(l, cx - r * 0.55, cy, r * 0.62, rp, 1.0, false)
	Paint.sphere(l, cx + r * 0.55, cy, r * 0.62, rp, 1.0, false)
	Paint.poly(l, PackedVector2Array([Vector2(cx - r * 1.15, cy + 0.5), Vector2(cx + r * 1.15, cy + 0.5), Vector2(cx, cy + r * 1.3)]), rp[2])


static func _floor_tiles(a: Image, y0: int, c1: Color, c2: Color) -> void:
	for y in range(y0, AH):
		for x in AW:
			var t := ((x / 6) + ((y - y0) / 4)) % 2 == 0
			Pix.px(a, x, y, c1 if t else c2)
	Pix.rect(a, 0, y0, AW, 1, c1.lightened(0.3))


# --- Cartas ---

static func _sacerdotisa(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("1a2a5a"), Color("6a8ad0"), 7)
	_floor_tiles(a, 60, Color("2a2a4a"), Color("4a4a6a"))
	var vl := Paint.layer(AW, AH)
	var veil := Paint.ramp(Color("6a2a8a"))
	Pix.rect(vl, 9, 7, 36, 52, veil[2])
	for y in range(9, 58, 7):
		for x in range(12 + (y / 7 % 2) * 4, 44, 8):
			Paint.sphere(vl, x, y, 2.1, Paint.ramp(Color("e8384f")), 1.0, false)
			Pix.px(vl, x, y - 3, Color("37c25a"))
	Paint.bevel(vl, veil[3], veil[0])
	Paint.outline_in(vl)
	Paint.put(a, vl, 0, 0)
	var pl := Paint.layer(AW, AH)
	pillar(pl, 2, 6, 64, Color("3a3a4a"))
	pillar(pl, 46, 6, 64, Color("e8e0d0"))
	Paint.outline_in(pl)
	Paint.put(a, pl, 0, 0)
	Pix.stamp_text(a, 3, 30, "B", Color("e8e0d0"))
	Pix.stamp_text(a, 47, 30, "J", Color("3a3a4a"))
	var fg := Paint.layer(AW, AH)
	robed(fg, 27, 13, 47, Color("3a6ad8"), {"crown": "moon", "hair": Color("2a1a3a"), "trim": Color("f4f0ff"), "hands": [Vector2(23, 37), Vector2(31, 37)]})
	Pix.rect(fg, 22, 35, 11, 4, Color("fbefd5"))
	Pix.rect(fg, 22, 35, 11, 1, Color.WHITE)
	Pix.px(fg, 25, 37, Color("8a7a5a"))
	Pix.px(fg, 28, 37, Color("8a7a5a"))
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)
	var mn := Paint.layer(AW, AH)
	for y in range(58, 66):
		for x in range(18, 37):
			var d1 := Vector2(x + 0.5 - 27.0, y + 0.5 - 60.0).length()
			var d2 := Vector2(x + 0.5 - 27.0, y + 0.5 - 57.0).length()
			if d1 <= 6.5 and d2 > 6.0:
				Pix.px(mn, x, y, Color("fff2c4") if d1 < 5.5 else Color("e8c96a"))
	Paint.outline_in(mn)
	Paint.put(a, mn, 0, 0)
	Paint.glow(a, 27, 11, 6, Color.WHITE, 0.5)


static func _emperatriz(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("8ad0ff"), Color("ffe0a0"), 7)
	var bg := Paint.layer(AW, AH)
	var leaf := Paint.ramp(Color("2a8a4a"))
	for p in [Vector2(6, 16), Vector2(14, 10), Vector2(4, 30)]:
		Paint.foliage(bg, p.x, p.y, 7.0, leaf, int(p.x * 3 + p.y))
	Paint.outline_in(bg, Color("1a4a3a"))
	Paint.put(a, bg, 0, 0)
	var wf := Paint.ramp(Color("4a9ae8"))
	for y in range(10, 52):
		for x in range(44, 51):
			Pix.px(a, x, y, wf[3] if (x + y / 2) % 3 == 0 else wf[2])
	for k in 8:
		Pix.px(a, 44 + k % 7, 50 + k % 3, Color.WHITE)
	var th := Paint.layer(AW, AH)
	Paint.sphere(th, 27, 40, 15, Paint.ramp(Color("c0302a")), 1.2, false)
	Paint.outline_in(th)
	Paint.put(a, th, 0, 0)
	var fg := Paint.layer(AW, AH)
	robed(fg, 27, 15, 42, Color("f4f0ff"), {"crown": "stars", "hair": Color("e8a84a"), "hands": [Vector2(20, 38), Vector2(35, 32)]})
	for y in range(30, 56, 4):
		for x in range(20 + (y / 4 % 2) * 2, 35, 4):
			if fg.get_pixel(x, y).a > 0.0:
				Pix.px(fg, x, y, Color("e8384f"))
	Paint.thick_line(fg, Vector2(35, 32), Vector2(41, 14), 1, Pix.GOLD)
	Paint.sphere(fg, 41, 13, 2.2, Paint.ramp(Pix.GOLD), 1.0, false)
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)
	var wh := Paint.ramp(Color("e8c04a"))
	for x in range(0, AW, 2):
		var h := 8 + (x * 7) % 5
		for y in range(AH - h, AH):
			Pix.px(a, x, y, wh[2] if y > AH - h + 2 else wh[4])
		Pix.px(a, x + 1, AH - h + 1, wh[3])
	var hs := Paint.layer(AW, AH)
	heart(hs, 10, 54, 5.0, Color("ff8ab0"))
	Paint.outline_in(hs)
	Paint.put(a, hs, 0, 0)
	Pix.ring(a, 10, 54, 2.0, 1, Pix.GOLD)
	Pix.px(a, 10, 57, Pix.GOLD)
	Pix.px(a, 9, 58, Pix.GOLD)
	Pix.px(a, 11, 58, Pix.GOLD)


static func _emperador(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("ff9a5a"), Color("ffd08a"), 7)
	var mt := Paint.layer(AW, AH)
	Paint.poly(mt, PackedVector2Array([Vector2(0, 40), Vector2(6, 24), Vector2(12, 34), Vector2(20, 18), Vector2(30, 32), Vector2(40, 16), Vector2(48, 30), Vector2(54, 22), Vector2(54, 60), Vector2(0, 60)]), Color("c0503a"))
	Paint.bevel(mt, Color("e8805a"), Color("8a302a"))
	Paint.put(a, mt, 0, 0)
	var tn := Paint.layer(AW, AH)
	var stone := Paint.ramp(Color("8a8a9a"))
	Pix.rect(tn, 8, 14, 38, 52, stone[2])
	for y in range(18, 66, 6):
		Pix.rect(tn, 8, y, 38, 1, stone[1])
	Paint.bevel(tn, stone[4], stone[0])
	for c in [Vector2(10, 15), Vector2(44, 15)]:
		Pix.ring(tn, c.x, c.y, 3.5, 1.5, Color("d8c8a8"))
		Pix.px(tn, roundi(c.x), roundi(c.y), Color("8a7a5a"))
	Paint.outline_in(tn)
	Paint.put(a, tn, 0, 0)
	var fg := Paint.layer(AW, AH)
	robed(fg, 27, 16, 50, Color("c0302a"), {"crown": "gold", "beard": Color("c8c8d0"), "hands": [Vector2(18, 38), Vector2(36, 34)]})
	Pix.rect(fg, 21, 52, 4, 14, Color("9a9ab0"))
	Pix.rect(fg, 29, 52, 4, 14, Color("9a9ab0"))
	Pix.rect(fg, 21, 52, 1, 14, Color("d8d8e8"))
	Pix.rect(fg, 29, 52, 1, 14, Color("d8d8e8"))
	var gold := Paint.ramp(Pix.GOLD)
	Paint.thick_line(fg, Vector2(36, 34), Vector2(36, 18), 1, gold[2])
	Pix.ring(fg, 36, 15, 2.5, 1, gold[3])
	Pix.rect(fg, 33, 18, 7, 1, gold[3])
	Paint.sphere(fg, 18, 36, 3.0, gold)
	Pix.px(fg, 18, 32, gold[4])
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)


static func _hierofante(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("6a2a2a"), Color("d08a4a"), 7)
	_floor_tiles(a, 58, Color("5a3a3a"), Color("7a5a4a"))
	var pl := Paint.layer(AW, AH)
	pillar(pl, 3, 4, 58, Color("9a9aa8"))
	pillar(pl, 45, 4, 58, Color("9a9aa8"))
	Paint.outline_in(pl)
	Paint.put(a, pl, 0, 0)
	var fg := Paint.layer(AW, AH)
	robed(fg, 27, 16, 40, Color("c0302a"), {"crown": "triple", "trim": Color("f4f0ff"), "hands": [Vector2(17, 34), Vector2(37, 22)]})
	Pix.rect(fg, 36, 18, 1, 2, Pix.SKIN)
	Pix.rect(fg, 38, 18, 1, 2, Pix.SKIN)
	var gold := Paint.ramp(Pix.GOLD)
	Paint.thick_line(fg, Vector2(17, 54), Vector2(17, 12), 1, gold[2])
	for k in 3:
		Pix.rect(fg, 15 - k, 13 + k * 3, 5 + k * 2, 1, gold[3])
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)
	var ky := Paint.layer(AW, AH)
	for s in [-1, 1]:
		var col: Color = Pix.GOLD if s < 0 else Color("d8d8e8")
		Paint.thick_line(ky, Vector2(27 - s * 8, 56), Vector2(27 + s * 8, 66), 1, col)
		Pix.ring(ky, 27 - s * 8, 56, 2.0, 1, col)
		Pix.rect(ky, 27 + s * 8 - 1, 65, 3, 2, col)
	Paint.outline_in(ky)
	Paint.put(a, ky, 0, 0)
	for x0 in [8, 38]:
		var ac := Paint.layer(AW, AH)
		Paint.sphere(ac, x0 + 4, 60, 3.2, Paint.ramp(Color("3a2a2a")), 1.0, false)
		Paint.poly(ac, PackedVector2Array([Vector2(x0, 64), Vector2(x0 + 8, 64), Vector2(x0 + 10, 70), Vector2(x0 - 2, 70)]), Color("e8384f") if x0 < 20 else Color("f4f0ff"))
		Paint.outline_in(ac)
		Paint.put(a, ac, 0, 0)
	for p in [Vector2i(27, 4), Vector2i(10, 20), Vector2i(44, 26)]:
		Paint.sparkle(a, p.x, p.y, GOLD_L())


static func GOLD_L() -> Color:
	return Arcana.GOLD_L


static func _enamorados(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("7fd0ff"), Color("ffe0c0"), 7)
	Paint.glow(a, 27, 10, 18, Color("fff3a0"), 0.6)
	Paint.sphere(a, 27, 9, 7, Paint.ramp(Pix.GOLD), 1.0, false)
	var mt := Paint.layer(AW, AH)
	Paint.poly(mt, PackedVector2Array([Vector2(14, 60), Vector2(27, 34), Vector2(40, 60)]), Color("b8a8e0"))
	Paint.bevel(mt, Color("e0d8f8"), Color("8a7ab8"))
	Paint.put(a, mt, 0, 0)
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 62, 1.0, 0.3, 0.0, Paint.ramp(Color("6ad06a")), 4)
	Paint.put(a, g, 0, 0)
	var tr := Paint.layer(AW, AH)
	Pix.rect(tr, 3, 30, 3, 32, Color("8a5524"))
	Pix.rect(tr, 48, 30, 3, 32, Color("8a5524"))
	Paint.foliage(tr, 5, 28, 6.5, Paint.ramp(Color("37c25a")), 3)
	Paint.foliage(tr, 49, 28, 6.5, Paint.ramp(Color("ff8a3a")), 5)
	for p in [Vector2i(3, 27), Vector2i(7, 31), Vector2i(5, 24)]:
		Pix.px(tr, p.x, p.y, Color("e8384f"))
	for y in range(32, 52):
		Pix.px(tr, 4 + roundi(sin(y * 0.6) * 2.0), y, Color("c8d84a"))
	Paint.outline_in(tr)
	Paint.put(a, tr, 0, 0)
	var an := Paint.layer(AW, AH)
	wings(an, 27, 18, 15, Color("ffb0d0"))
	Paint.cloud(an, 27, 27, 22, Paint.ramp(Color("f4f0ff")))
	Paint.outline_in(an)
	Paint.put(a, an, 0, 0)
	var hd := Paint.layer(AW, AH)
	robed(hd, 27, 9, 16, Color("8a4ab8"), {"hair": Color("e8584a"), "hands": [Vector2(19, 18), Vector2(35, 18)]})
	Paint.outline_in(hd)
	Paint.put(a, hd, 0, 0)
	var j1 := Arcana.jester(0, Arcana.J_STAND, Arcana.J_ARMS_HOLD)
	Paint.put(a, j1, 0, 32)
	var j2 := Arcana.jester(1, Arcana.J_STAND, Arcana.J_ARMS_HOLD)
	j2.flip_x()
	Paint.put(a, j2, 28, 32)
	var hs := Paint.layer(AW, AH)
	heart(hs, 27, 45, 3.2, Color("ff4a6a"))
	Paint.outline_in(hs)
	Paint.put(a, hs, 0, 0)


static func _carro(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("2a6aa8"), Color("a8d8ff"), 7)
	var ct := Paint.layer(AW, AH)
	var st := Paint.ramp(Color("8a9ab8"))
	Pix.rect(ct, 0, 30, AW, 12, st[2])
	for x in range(0, AW, 4):
		Pix.rect(ct, x, 28, 2, 2, st[2])
	for t in [Vector2i(4, 22), Vector2i(44, 20)]:
		Pix.rect(ct, t.x, t.y, 7, 10, st[2])
		Paint.poly(ct, PackedVector2Array([Vector2(t.x - 1, t.y), Vector2(t.x + 3.5, t.y - 6), Vector2(t.x + 8, t.y)]), Color("c0402a"))
	Paint.bevel(ct, st[4], st[0])
	Paint.outline_in(ct, Color("2a3a6a"))
	Paint.put(a, ct, 0, 0)
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 42, 0.5, 0.2, 0.0, Paint.ramp(Color("7ab06a")), 6)
	Paint.put(a, g, 0, 0)
	var cn := Paint.layer(AW, AH)
	var cloth := Paint.ramp(Color("2a3a8a"))
	for x in [11, 42]:
		Pix.rect(cn, x, 10, 1, 26, Color("c9892a"))
	Paint.poly(cn, PackedVector2Array([Vector2(8, 8), Vector2(46, 8), Vector2(44, 13), Vector2(10, 13)]), cloth[2])
	for x in range(12, 44, 5):
		Paint.sparkle(cn, x, 10, Pix.GOLD)
	Paint.outline_in(cn)
	Paint.put(a, cn, 0, 0)
	Paint.put(a, Arcana.jester(2, Arcana.J_STAND, Arcana.J_ARMS_HOLD), 14, 10)
	var bx := Paint.layer(AW, AH)
	var stn := Paint.ramp(Color("9a9ab0"))
	Pix.rect(bx, 9, 34, 36, 20, stn[2])
	Paint.bevel(bx, stn[4], stn[0])
	Paint.sphere(bx, 27, 42, 3.5, Paint.ramp(Pix.GOLD), 1.0, false)
	for s in [-1, 1]:
		for k in 4:
			Pix.rect(bx, 27 + s * (5 + k * 2), 41 - k % 2, 2, 2, Pix.GOLD if k % 2 == 0 else Color("c9892a"))
	for wx in [13, 41]:
		Pix.ring(bx, wx, 54, 6, 2, Color("6a4a2a"))
		for k in 4:
			var ang := k * PI / 4.0
			Paint.thick_line(bx, Vector2(wx, 54) - Vector2.from_angle(ang) * 4.5, Vector2(wx, 54) + Vector2.from_angle(ang) * 4.5, 1, Color("8a6a3a"))
	Paint.outline_in(bx)
	Paint.put(a, bx, 0, 0)
	for side in 2:
		var sx := 2 + side * 30
		var col := Color("2a2a3a") if side == 0 else Color("f4f0ff")
		var sp := Paint.layer(AW, AH)
		var rp := Paint.ramp(col)
		Paint.sphere(sp, sx + 11, 66, 8, rp, 0.45, false)
		Paint.sphere(sp, sx + (16 if side == 0 else 6), 60, 3.4, Paint.ramp(Pix.SKIN), 1.0, false)
		Pix.rect(sp, sx + (13 if side == 0 else 3), 56, 7, 3, Color("3a6ad8"))
		Pix.rect(sp, sx + (13 if side == 0 else 3), 58, 1, 5, Color("e8c04a"))
		Pix.rect(sp, sx + (19 if side == 0 else 9), 58, 1, 5, Color("e8c04a"))
		Pix.px(sp, sx + (16 if side == 0 else 6), 60, Pix.INK)
		var fx_: int = sx + (14 if side == 0 else 1)
		Pix.rect(sp, fx_, 66, 6, 2, rp[3])
		Pix.rect(sp, fx_, 67, 6, 1, rp[1])
		var tx: int = sx + (2 if side == 0 else 20)
		Pix.rect(sp, tx, 62, 1, 4, rp[2])
		Pix.px(sp, tx, 61, rp[3])
		Paint.outline_in(sp)
		Paint.put(a, sp, 0, 0)


static func _ermitano(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("0a0a2a"), Color("3a3a6a"), 7)
	Paint.speckle(a, Rect2i(0, 0, AW, 40), Color(1, 1, 1, 0.8), 0.03, 41)
	var pk := Paint.layer(AW, AH)
	var snow := Paint.ramp(Color("c8d0f0"))
	Paint.poly(pk, PackedVector2Array([Vector2(0, 70), Vector2(0, 58), Vector2(18, 52), Vector2(34, 54), Vector2(54, 62), Vector2(54, 70)]), snow[2])
	Paint.speckle(pk, Rect2i(0, 52, AW, 18), Color(snow[0], 0.5), 0.1, 3)
	Paint.bevel(pk, snow[4], snow[0])
	Paint.outline_in(pk, Color("1a1a3a"))
	Paint.put(a, pk, 0, 0)
	Paint.glow(a, 38, 26, 22, Color("ffd88a"), 0.55)
	var fg := Paint.layer(AW, AH)
	robed(fg, 24, 16, 38, Color("8a8aa0"), {"hood": true, "beard": Color("f4f0ff"), "hands": [Vector2(14, 34), Vector2(38, 25)]})
	Paint.thick_line(fg, Vector2(14, 20), Vector2(12, 56), 1, Color("b08a4a"))
	Pix.rect(fg, 13, 19, 3, 2, Color("8a6a3a"))
	var gold := Paint.ramp(Pix.GOLD)
	Pix.rect(fg, 38, 25, 1, 3, gold[1])
	Paint.poly(fg, PackedVector2Array([Vector2(35, 28), Vector2(41, 28), Vector2(42, 32), Vector2(40, 36), Vector2(36, 36), Vector2(34, 32)]), Color("fff3c0"))
	Pix.rect(fg, 35, 28, 7, 1, gold[2])
	Pix.rect(fg, 35, 36, 7, 1, gold[2])
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)
	Paint.sparkle(a, 38, 32, Pix.GOLD, true)


static func _justicia(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("4a1a5a"), Color("c0508a"), 7)
	_floor_tiles(a, 60, Color("6a4a5a"), Color("8a6a7a"))
	var vl := Paint.layer(AW, AH)
	Pix.rect(vl, 9, 10, 36, 50, Color("7a2a8a"))
	for x in range(11, 44, 4):
		Pix.rect(vl, x, 10, 1, 50, Color("5a1a6a"))
	Paint.put(a, vl, 0, 0)
	var pl := Paint.layer(AW, AH)
	pillar(pl, 2, 8, 60, Color("a8a8b8"))
	pillar(pl, 46, 8, 60, Color("a8a8b8"))
	Paint.outline_in(pl)
	Paint.put(a, pl, 0, 0)
	var fg := Paint.layer(AW, AH)
	robed(fg, 27, 16, 44, Color("c0302a"), {"crown": "gold", "hair": Color("4a2a1a"), "trim": Color("37a85a"), "hands": [Vector2(17, 34), Vector2(37, 30)]})
	var metal := Paint.ramp(Color("d8d8e8"))
	Paint.thick_line(fg, Vector2(37, 28), Vector2(37, 6), 1, metal[4])
	Pix.rect(fg, 38, 8, 1, 20, metal[1])
	Pix.rect(fg, 34, 28, 7, 1, Pix.GOLD)
	var gold := Paint.ramp(Pix.GOLD)
	Pix.rect(fg, 17, 26, 1, 8, gold[2])
	Pix.rect(fg, 9, 26, 17, 1, gold[3])
	for px in [10, 24]:
		Paint.thick_line(fg, Vector2(px - 1, 27), Vector2(px - 2, 32), 1, gold[1])
		Paint.thick_line(fg, Vector2(px + 1, 27), Vector2(px + 2, 32), 1, gold[1])
		Pix.rect(fg, px - 3, 32, 7, 2, gold[2])
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)
	Paint.glow(a, 37, 6, 6, Color.WHITE, 0.5)


static func _templanza(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("8ad0ff"), Color("fff0c0"), 7)
	var mt := Paint.layer(AW, AH)
	Paint.poly(mt, PackedVector2Array([Vector2(30, 46), Vector2(42, 30), Vector2(54, 42), Vector2(54, 50), Vector2(30, 50)]), Color("a8b8e0"))
	Paint.bevel(mt, Color("d8e0f8"), Color("7a8ab8"))
	Paint.put(a, mt, 0, 0)
	Paint.glow(a, 42, 28, 7, Color("fff3a0"), 0.6)
	Paint.sphere(a, 42, 28, 3, Paint.ramp(Pix.GOLD), 1.0, false)
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 50, 1.0, 0.2, 0.0, Paint.ramp(Color("6ad06a")), 2)
	Paint.put(a, g, 0, 0)
	var pt := Paint.ramp(Color("e8d0a0"))
	for y in range(50, 70):
		var t := (y - 50) / 20.0
		var cx := 40.0 - t * 6.0
		for x in range(roundi(cx - 1 - t * 3), roundi(cx + 1 + t * 3)):
			Pix.px(a, x, y, pt[3] if (x + y) % 3 else pt[2])
	var pool := Paint.layer(AW, AH)
	Paint.ellipse(pool, 12, 64, 13, 5, Paint.ramp(Color("2a8ad0"))[2])
	Pix.rect(pool, 4, 63, 6, 1, Color("8ad0ff"))
	Paint.outline_in(pool, Color("1a3a6a"))
	Paint.put(a, pool, 0, 0)
	for x in [44, 48, 51]:
		Pix.rect(a, x, 58, 1, 8, Color("2a8a4a"))
		Paint.sphere(a, x, 57, 1.8, Paint.ramp(Color("8a5ad8")), 1.0, false)
	var an := Paint.layer(AW, AH)
	wings(an, 25, 22, 15, Color("ff8a6a"))
	Paint.outline_in(an)
	Paint.put(a, an, 0, 0)
	var fg := Paint.layer(AW, AH)
	robed(fg, 25, 12, 50, Color("f4f0ff"), {"hair": Color("e8c04a"), "hands": [Vector2(16, 26), Vector2(34, 40)]})
	Paint.poly(fg, PackedVector2Array([Vector2(22, 30), Vector2(28, 30), Vector2(25, 35)]), Color("ff8a3a"))
	Pix.px(fg, 25, 15, Pix.GOLD)
	var gold := Paint.ramp(Pix.GOLD)
	Paint.poly(fg, PackedVector2Array([Vector2(13, 22), Vector2(19, 22), Vector2(18, 27), Vector2(14, 27)]), gold[2])
	Paint.poly(fg, PackedVector2Array([Vector2(31, 38), Vector2(37, 38), Vector2(36, 43), Vector2(32, 43)]), gold[2])
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)
	Paint.bezier(a, Vector2(18, 23), Vector2(30, 22), Vector2(34, 38), 1, Color("7ad0ff"))
	Paint.bezier(a, Vector2(18, 24), Vector2(29, 24), Vector2(33, 38), 1, Color("c8f0ff"))


static func _diablo(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("0a0208"), Color("3a0a1a"), 7)
	Paint.glow(a, 27, 30, 26, Color("ff3a2a"), 0.3)
	var wg := Paint.layer(AW, AH)
	var wr := Paint.ramp(Color("3a1a2a"))
	for s in [-1, 1]:
		Paint.poly(wg, PackedVector2Array([Vector2(27 + s * 4, 24), Vector2(27 + s * 24, 12), Vector2(27 + s * 22, 22), Vector2(27 + s * 25, 30), Vector2(27 + s * 18, 30), Vector2(27 + s * 16, 36), Vector2(27 + s * 8, 32)]), wr[2])
		for k in 3:
			Paint.thick_line(wg, Vector2(27 + s * 5, 25), Vector2(27 + s * (14 + k * 4), 14 + k * 6), 1, wr[4])
	Paint.outline_in(wg)
	Paint.put(a, wg, 0, 0)
	var fg := Paint.layer(AW, AH)
	robed(fg, 27, 16, 38, Color("4a1a2a"), {"crown": "horns", "beard": Color("2a1a1a"), "skin": Color("d0403a"), "eyes": Color("ffd447"), "hands": [Vector2(15, 40), Vector2(39, 20)]})
	Pix.rect(fg, 38, 18, 1, 2, Color("d0403a"))
	Pix.rect(fg, 40, 18, 1, 2, Color("d0403a"))
	Paint.thick_line(fg, Vector2(15, 40), Vector2(11, 52), 1, Color("8a5524"))
	Paint.sphere(fg, 11, 54, 2.6, Paint.ramp(Color("ff6a2a")), 1.3, false)
	Paint.outline_in(fg)
	Paint.put(a, fg, 0, 0)
	Paint.glow(a, 11, 55, 5, Color("ffb04a"), 0.6)
	var pd := Paint.layer(AW, AH)
	var blk := Paint.ramp(Color("3a3a4a"))
	Pix.rect(pd, 17, 54, 20, 9, blk[2])
	Paint.bevel(pd, blk[4], blk[0])
	var pts := []
	for k in 5:
		pts.append(Vector2(27, 58) + Vector2.from_angle(PI / 2.0 + k * TAU / 5.0) * 3.5)
	for k in 5:
		Pix.line(pd, roundi(pts[k].x), roundi(pts[k].y), roundi(pts[(k + 2) % 5].x), roundi(pts[(k + 2) % 5].y), Pix.GOLD)
	Paint.outline_in(pd)
	Paint.put(a, pd, 0, 0)
	for s in [-1, 1]:
		var sm := small({"h": Color("3a2a1a"), "s": Pix.SKIN, "a": Color("e8384f") if s < 0 else Color("3b8bea"), "k": Pix.INK}, s > 0)
		var sx := 4 if s < 0 else 40
		Paint.put(a, sm, sx, 57)
		Pix.px(a, sx + 2, 57, Color("d8c8a8"))
		Pix.px(a, sx + 5, 57, Color("d8c8a8"))
		Paint.thick_line(a, Vector2(27 + s * 9, 58), Vector2(sx + 4, 62), 1, Color("8a8a9a"))
		Pix.px(a, sx + (8 if s < 0 else 0), 66, Color("ff6a2a"))


static func _estrella(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("0a1440"), Color("2a4a8a"), 7)
	Paint.speckle(a, Rect2i(0, 0, AW, 44), Color(1, 1, 1, 0.8), 0.03, 51)
	Paint.glow(a, 27, 12, 18, Color("fff3c0"), 0.55)
	for k in 8:
		var ang := k * TAU / 8.0
		var r := 11.0 if k % 2 == 0 else 7.0
		Paint.poly(a, PackedVector2Array([Vector2(27, 12), Vector2(27, 12) + Vector2.from_angle(ang - 0.25) * 3.0, Vector2(27, 12) + Vector2.from_angle(ang) * r, Vector2(27, 12) + Vector2.from_angle(ang + 0.25) * 3.0]), Pix.GOLD if k % 2 == 0 else Color("fff3c0"))
	Paint.sphere(a, 27, 12, 2.5, Paint.ramp(Color("fff8e0")), 1.0, false)
	for p in [Vector2i(8, 8), Vector2i(46, 7), Vector2i(12, 24), Vector2i(42, 22), Vector2i(4, 36), Vector2i(50, 34), Vector2i(27, 30)]:
		Paint.sparkle(a, p.x, p.y, Color("fff3c0"))
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 50, 2.0, 0.15, 0.5, Paint.ramp(Color("3a8a5a")), 8)
	Paint.put(a, g, 0, 0)
	var tr := Paint.layer(AW, AH)
	Pix.rect(tr, 47, 32, 2, 20, Color("6a4a2a"))
	Paint.foliage(tr, 48, 30, 6.0, Paint.ramp(Color("2a7a4a")), 9)
	Paint.sphere(tr, 49, 24, 1.8, Paint.ramp(Color("ff5a4a")), 1.0, false)
	Pix.px(tr, 51, 24, Color("ffd447"))
	Paint.outline_in(tr)
	Paint.put(a, tr, 0, 0)
	var pool := Paint.layer(AW, AH)
	Paint.ellipse(pool, 14, 64, 15, 5, Paint.ramp(Color("2a6ab0"))[2])
	for x in range(4, 24, 5):
		Pix.rect(pool, x, 63 + x % 2, 3, 1, Color("8ad0ff"))
	Paint.outline_in(pool, Color("1a2a4a"))
	Paint.put(a, pool, 0, 0)
	Paint.put(a, Arcana.jester(3, Arcana.J_STAND, Arcana.J_ARMS_HOLD), 18, 27)
	var jg := Paint.layer(AW, AH)
	var gold := Paint.ramp(Pix.GOLD)
	Paint.sphere(jg, 22, 49, 2.6, gold, 1.0, false)
	Paint.sphere(jg, 42, 49, 2.6, gold, 1.0, false)
	Paint.outline_in(jg)
	Paint.put(a, jg, 0, 0)
	Paint.bezier(a, Vector2(20, 50), Vector2(16, 55), Vector2(14, 62), 1, Color("8ad0ff"))
	Paint.bezier(a, Vector2(44, 50), Vector2(46, 56), Vector2(44, 60), 1, Color("8ad0ff"))


static func _juicio(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("5a8ad0"), Color("e0e8ff"), 7)
	var mt := Paint.layer(AW, AH)
	Paint.poly(mt, PackedVector2Array([Vector2(0, 50), Vector2(10, 38), Vector2(18, 46), Vector2(30, 34), Vector2(42, 46), Vector2(54, 36), Vector2(54, 56), Vector2(0, 56)]), Color("e8f0ff"))
	Paint.bevel(mt, Color.WHITE, Color("a8b8d8"))
	Paint.put(a, mt, 0, 0)
	var wt := Paint.ramp(Color("3a8a9a"))
	for y in range(54, AH):
		for x in AW:
			Pix.px(a, x, y, wt[3] if (x + y * 3) % 9 == 0 else wt[2])
	for k in 3:
		var cx := 8 + k * 17
		var cf := Paint.layer(AW, AH)
		var wood := Paint.ramp(Color("8a5a2a"))
		Pix.rect(cf, cx - 5, 60, 11, 6, wood[2])
		Paint.bevel(cf, wood[4], wood[0])
		Paint.outline_in(cf)
		Paint.put(a, cf, 0, 0)
		var pr := small({"h": Color("4a2a1a"), "s": Pix.SKIN, "a": Color("f0d8c8"), "k": Color("f0d8c8")})
		Paint.put(a, pr, cx - 4, 50)
		for d in [Vector2i(-4, 49), Vector2i(-5, 48), Vector2i(3, 49), Vector2i(4, 48)]:
			Pix.px(a, cx + d.x, d.y, Pix.SKIN)
	var an := Paint.layer(AW, AH)
	wings(an, 27, 14, 16, Color("ffb0d0"))
	Paint.outline_in(an, Color("8a4a6a"))
	Paint.put(a, an, 0, 0)
	var hd := Paint.layer(AW, AH)
	var robe := Paint.ramp(Color("3a6ad8"))
	Paint.poly(hd, PackedVector2Array([Vector2(21, 21), Vector2(33, 21), Vector2(31, 14), Vector2(23, 14)]), robe[2])
	Paint.bevel(hd, robe[4], robe[0])
	Paint.sphere(hd, 27, 9, 5.8, Paint.ramp(Color("e8c04a")), 1.0, false)
	Paint.sphere(hd, 27, 10, 4.6, Paint.ramp(Pix.SKIN), 1.0, false)
	Pix.px(hd, 25, 10, Pix.INK)
	Pix.px(hd, 29, 10, Pix.INK)
	Pix.px(hd, 24, 12, Pix.BLUSH)
	var gold := Paint.ramp(Pix.GOLD)
	Paint.thick_line(hd, Vector2(29, 12), Vector2(45, 21), 1, gold[3])
	Paint.thick_line(hd, Vector2(29, 13), Vector2(45, 22), 1, gold[1])
	Paint.poly(hd, PackedVector2Array([Vector2(44, 18), Vector2(50, 21), Vector2(45, 26)]), gold[2])
	Pix.rect(hd, 36, 17, 6, 6, Color.WHITE)
	Pix.rect(hd, 38, 17, 2, 6, Color("e8384f"))
	Pix.rect(hd, 36, 19, 6, 2, Color("e8384f"))
	Pix.rect(hd, 31, 15, 3, 3, Pix.SKIN)
	Paint.outline_in(hd)
	Paint.put(a, hd, 0, 0)
	Paint.glow(a, 27, 9, 9, Color("fff3a0"), 0.45)
	var cl := Paint.layer(AW, AH)
	Paint.cloud(cl, 27, 25, 36, Paint.ramp(Color("f4f0ff")))
	Paint.cloud(cl, 12, 28, 14, Paint.ramp(Color("e0e0f8")))
	Paint.outline_in(cl, Color("5a6a9a"))
	Paint.put(a, cl, 0, 0)
	for k in 6:
		Pix.px(a, 48 + k % 3, 27 + k, Color(1, 1, 0.8, 0.8))
