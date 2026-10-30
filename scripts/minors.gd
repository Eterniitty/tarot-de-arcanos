class_name Minors
extends RefCounted
## Arcanos Menores (56 cartas): cuatro palos del 1 al 10 más Sota, Caballo, Reina y Rey. Mismo marco y pergamino
## que los Mayores; la ilustración (54x70) son los símbolos del palo pintados por capas sobre un paisaje propio
## de cada palo, el As sale de una mano entre nubes y las figuras son personajes con túnica del color del palo.

const AW := 54
const AH := 70

const SUITS := [
	{"id": "bastos", "name": "BASTOS", "robe": Color("3a8a4a"), "sky": [Color("bfe8a0"), Color("fff2c8")], "ground": Color("6ab04a")},
	{"id": "copas", "name": "COPAS", "robe": Color("c0304a"), "sky": [Color("ffc0c8"), Color("fff0e8")], "ground": Color("5a9ad8")},
	{"id": "espadas", "name": "ESPADAS", "robe": Color("3a5ab8"), "sky": [Color("a8c8f0"), Color("eef4ff")], "ground": Color("8a9ab0")},
	{"id": "oros", "name": "OROS", "robe": Color("c9892a"), "sky": [Color("ffd890"), Color("fff6d8")], "ground": Color("c0a050")},
]
const VALUE_NAMES := ["", "AS", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "SOTA", "CABALLO", "REINA", "REY"]

# Posiciones de los símbolos en la ilustración para las cartas del 2 al 10.
const LAYOUTS := {
	2: [[27, 18], [27, 52]],
	3: [[27, 13], [27, 35], [27, 57]],
	4: [[16, 18], [38, 18], [16, 52], [38, 52]],
	5: [[16, 16], [38, 16], [27, 35], [16, 54], [38, 54]],
	6: [[16, 14], [38, 14], [16, 35], [38, 35], [16, 56], [38, 56]],
	7: [[16, 13], [38, 13], [27, 24], [16, 36], [38, 36], [16, 58], [38, 58]],
	8: [[16, 12], [38, 12], [27, 23], [16, 35], [38, 35], [27, 47], [16, 58], [38, 58]],
	9: [[15, 10], [39, 10], [15, 27], [39, 27], [27, 35], [15, 43], [39, 43], [15, 60], [39, 60]],
	10: [[15, 10], [39, 10], [27, 19], [15, 28], [39, 28], [15, 42], [39, 42], [27, 51], [15, 60], [39, 60]],
}


static func art(a: Image, suit: int, value: int) -> void:
	_backdrop(a, suit, value)
	if value == 1:
		_ace(a, suit)
	elif value <= 10:
		for p in LAYOUTS[value]:
			var flip: bool = suit >= 2 and p[1] > 36  # espadas y oros de la mitad de abajo, del revés como en la baraja
			_put_center(a, pip(suit, 0, flip and suit == 2), p[0], p[1])
	else:
		_court(a, suit, value)


# --- Fondos ---

static func _backdrop(a: Image, suit: int, value: int) -> void:
	var s: Dictionary = SUITS[suit]
	Pix.dither_v(a, 0, 0, AW, AH, s.sky[0], s.sky[1], 7)
	var court := value > 10
	match s.id:
		"bastos":
			var g := Paint.layer(AW, AH)
			Paint.hills(g, 56 if not court else 50, 3.0, 0.16, 0.5, Paint.ramp(s.ground), 11 + value)
			Paint.put(a, g, 0, 0)
			_grass(a, 58 if not court else 52, s.ground, value)
		"copas":
			var w := Paint.layer(AW, AH)
			var wr := Paint.ramp(s.ground)
			for y in range(58 if not court else 54, AH):
				for x in AW:
					var c: Color = wr[2]
					if (y + int(sin(x * 0.5 + y) * 1.5)) % 4 == 0:
						c = wr[3]
					if (x * 3 + y * 5) % 23 == 0:
						c = wr[4]
					Pix.px(w, x, y, c)
			Paint.put(a, w, 0, 0)
		"espadas":
			for k in 3:
				var cl := Paint.layer(AW, AH)
				Paint.cloud(cl, 8 + k * 19, 62 - (k % 2) * 4, 10, Paint.ramp(Color("dce6f8")))
				Paint.put(a, cl, 0, 0)
			for k in 4:
				var y := 8 + k * 15
				for x in range(2 + k * 7 % 20, 16 + k * 7 % 20):
					Paint.blendpx(a, x, y, Color(1, 1, 1, 0.55))
		"oros":
			var g := Paint.layer(AW, AH)
			Paint.hills(g, 60 if not court else 54, 1.5, 0.1, 1.2, Paint.ramp(s.ground), 31 + value)
			Paint.put(a, g, 0, 0)
			Paint.speckle(a, Rect2i(0, 0, AW, 50), Color(1, 1, 1, 0.8), 0.015, 77 + value)


static func _grass(a: Image, y0: int, col: Color, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v * 13
	var gr := Paint.ramp(col)
	for k in 30:
		var x := rng.randi_range(0, AW - 1)
		var y := rng.randi_range(y0, AH - 2)
		if a.get_pixel(x, y).a > 0.0:
			Pix.px(a, x, y - 1, gr[4])
	Arcana._flowers(a, y0 + 2, AH - 2, 6, seed_v)


static func _put_center(dst: Image, src: Image, cx: int, cy: int) -> void:
	Paint.put(dst, src, cx - src.get_width() / 2, cy - src.get_height() / 2)


# --- Símbolos del palo ---

## Símbolo pintado. size 0 = pequeño (cartas numeradas), 1 = mediano (figuras), 2 = grande (As).
static func pip(suit: int, size: int, flip := false) -> Image:
	var im: Image
	match SUITS[suit].id:
		"bastos": im = _wand(size)
		"copas": im = _cup(size)
		"espadas": im = _sword(size)
		_: im = _coin(size)
	if flip:
		im.flip_y()
	return im


static func _coin(size: int) -> Image:
	var r: float = [5.0, 7.0, 12.0][size]
	var n := int(r * 2.0) + 4
	var l := Paint.layer(n, n)
	var c := n / 2.0
	var g := Paint.ramp(Pix.GOLD)
	Paint.sphere(l, c, c, r, g, 1.0, false)
	Pix.ring(l, c, c, r - 1.2, 1.0, g[1])
	# Pentáculo grabado
	var pts: Array = []
	for k in 5:
		pts.append(Vector2(c, c) + Vector2.from_angle(-PI / 2.0 + k * TAU / 5.0) * (r - 2.6))
	for k in 5:
		Paint.thick_line(l, pts[k], pts[(k + 2) % 5], 1, g[1] if size > 0 else g[2])
	if size == 2:
		Pix.ring(l, c, c, r - 3.6, 1.0, Color(g[1], 0.5))
		for k in 12:
			var p := Vector2(c, c) + Vector2.from_angle(k * TAU / 12.0) * (r - 0.6)
			Pix.px(l, roundi(p.x), roundi(p.y), g[4] if k % 2 == 0 else g[2])
	Pix.px(l, roundi(c - r * 0.45), roundi(c - r * 0.55), Color.WHITE)
	if size == 2:
		Pix.px(l, roundi(c - r * 0.45) + 1, roundi(c - r * 0.55), g[4])
	Paint.outline_in(l)
	return l


static func _cup(size: int) -> Image:
	var k: float = [1.0, 1.35, 2.3][size]
	var w := int(12 * k) + 4
	var h := int(14 * k) + 4
	var l := Paint.layer(w, h)
	var g := Paint.ramp(Pix.GOLD)
	var cx := w / 2.0
	var top := 2.0
	var bw := 5.5 * k
	# Copa: cuenco, nudo, pie
	Paint.poly(l, PackedVector2Array([Vector2(cx - bw, top), Vector2(cx + bw, top), Vector2(cx + bw * 0.7, top + 5.0 * k), Vector2(cx + 1.5 * k, top + 7.0 * k), Vector2(cx - 1.5 * k, top + 7.0 * k), Vector2(cx - bw * 0.7, top + 5.0 * k)]), g[2])
	Pix.rect(l, roundi(cx - 0.8 * k), roundi(top + 7.0 * k), maxi(2, roundi(1.6 * k)), roundi(3.0 * k), g[2])
	Paint.sphere(l, cx, top + 8.5 * k, 1.5 * k, g, 1.0, false)
	Paint.poly(l, PackedVector2Array([Vector2(cx - 1.2 * k, top + 10.0 * k), Vector2(cx + 1.2 * k, top + 10.0 * k), Vector2(cx + 4.0 * k, top + 12.0 * k), Vector2(cx - 4.0 * k, top + 12.0 * k)]), g[2])
	Paint.bevel(l, g[4], g[0])
	# Borde y vino
	Pix.rect(l, roundi(cx - bw), roundi(top), roundi(bw * 2.0), 1, g[4])
	if size > 0:
		Pix.rect(l, roundi(cx - bw) + 1, roundi(top) + 1, roundi(bw * 2.0) - 2, 1, Color("8a1a3a"))
	# Gema
	Pix.rect(l, roundi(cx) - 1, roundi(top + 2.5 * k), 2, 2, Color("ff3a5a"))
	Pix.px(l, roundi(cx) - 1, roundi(top + 2.5 * k), Color("ffb0c0"))
	if size == 2:
		for s in [-1, 1]:
			Pix.rect(l, roundi(cx + s * 3.5 * k) - 1, roundi(top + 2.8 * k), 2, 2, Color("3a8aff"))
		Pix.rect(l, roundi(cx - 4.0 * k), roundi(top + 11.2 * k), roundi(8.0 * k), 1, g[1])
	Paint.outline_in(l)
	return l


static func _sword(size: int) -> Image:
	var k: float = [0.78, 1.4, 2.4][size]
	var w := int(10 * k) + 4
	var h := int(16 * k) + 4
	var l := Paint.layer(w, h)
	var st := Paint.ramp(Color("c8d4e8"))
	var g := Paint.ramp(Pix.GOLD)
	var cx := roundi(w / 2.0)
	var bw := maxi(1, roundi(1.2 * k))
	var tip := 2
	var guard := roundi(2 + 10.5 * k)
	# Hoja con filo y vaceo
	for y in range(tip, guard):
		var ww := bw if y > tip + bw else maxi(0, y - tip)
		Pix.rect(l, cx - ww, y, ww * 2 + 1, 1, st[2])
		Pix.px(l, cx - ww, y, st[4])
		Pix.px(l, cx + ww, y, st[1])
		if size > 0 and y > tip + 3:
			Pix.px(l, cx, y, st[3])
	# Guarda, puño y pomo
	var gw := roundi(4.0 * k)
	Pix.rect(l, cx - gw, guard, gw * 2 + 1, maxi(1, roundi(k)), g[2])
	Pix.rect(l, cx - gw, guard, gw * 2 + 1, 1, g[4])
	Pix.px(l, cx - gw, guard + maxi(1, roundi(k)), g[1])
	Pix.px(l, cx + gw, guard + maxi(1, roundi(k)), g[1])
	var grip_end := guard + maxi(1, roundi(k)) + roundi(3.0 * k)
	for y in range(guard + maxi(1, roundi(k)), grip_end):
		Pix.rect(l, cx - maxi(0, bw - 1), y, maxi(1, bw * 2 - 1), 1, Color("6a3a2a") if y % 2 else Color("8a5a3a"))
	Paint.sphere(l, cx + 0.5, grip_end + 1.0 * k, maxf(1.2, 1.3 * k), g, 1.0, false)
	if size == 2:
		Pix.rect(l, cx - 1, guard, 3, 2, Color("3a8aff"))
	Paint.outline_in(l)
	return l


static func _wand(size: int) -> Image:
	var k: float = [0.8, 1.4, 2.3][size]
	var n := int(13 * k) + 4
	var l := Paint.layer(n, n)
	var wd := Paint.ramp(Color("9a6a3a"))
	var lf := Paint.ramp(Color("4ab04a"))
	var a := Vector2(2.5, n - 3.0)
	var b := Vector2(n - 3.5, 3.0)
	var thick := maxi(2, roundi(2.0 * k))
	Paint.thick_line(l, a, b, thick, wd[2])
	# Luz en un lado del palo y nudos
	var dir := (b - a).normalized()
	var nrm := dir.orthogonal()
	for t in range(0, int(a.distance_to(b)), 1):
		var p := a + dir * t + nrm * (thick * 0.4)
		Pix.px(l, roundi(p.x), roundi(p.y), wd[4] if t % 5 != 0 else wd[3])
	for t in [0.3, 0.62]:
		var p := a.lerp(b, t)
		Pix.rect(l, roundi(p.x) - 1, roundi(p.y), 2, 1, wd[0])
	# Brotes de hojas
	for t in ([0.45, 0.8] if size == 0 else [0.25, 0.5, 0.72, 0.9]):
		var p := a.lerp(b, t)
		var side := 1.0 if int(t * 10.0) % 2 == 0 else -1.0
		var q := p + nrm * side * (2.5 * k)
		Paint.sphere(l, q.x, q.y, maxf(1.2, 1.3 * k), lf, 1.0, false)
	Paint.sphere(l, b.x, b.y, maxf(1.0, 1.1 * k), lf, 1.0, false)
	Paint.outline_in(l)
	return l


# --- As: el símbolo sale de una mano entre nubes, con rayos ---

static func _ace(a: Image, suit: int) -> void:
	var cx := 27.0
	var cy := 31.0
	for k in 16:
		var ang := k * TAU / 16.0
		var r1 := 26.0 if k % 2 == 0 else 19.0
		Paint.thick_line(a, Vector2(cx, cy) + Vector2.from_angle(ang) * 9.0, Vector2(cx, cy) + Vector2.from_angle(ang) * r1, 1, Color(1, 1, 1, 0.5) if k % 2 == 0 else Color(Pix.GOLD, 0.45))
	Paint.glow(a, cx, cy, 20, Color.WHITE, 0.5)
	var sym := pip(suit, 2)
	_put_center(a, sym, int(cx), int(cy) - 2)
	# Mano saliendo de una nube por la izquierda que sujeta el símbolo por abajo
	var hand := Paint.layer(AW, AH)
	var sk := Paint.ramp(Pix.SKIN)
	var hy := int(cy) + sym.get_height() / 2 - 2
	Paint.thick_line(hand, Vector2(6, hy + 9), Vector2(int(cx) - 4, hy + 3), 4, Color("e8e0f8"))
	Paint.ellipse(hand, cx - 1, hy + 3, 5, 3, sk[2])
	for f in 4:
		Pix.rect(hand, int(cx) - 5 + f * 2, hy, 2, 3, sk[3] if f % 2 == 0 else sk[2])
	Pix.rect(hand, int(cx) + 3, hy + 2, 3, 2, sk[2])
	Paint.bevel(hand, sk[4], sk[1])
	Paint.outline_in(hand)
	Paint.put(a, hand, 0, 0)
	var cl := Paint.layer(AW, AH)
	Paint.cloud(cl, 7, hy + 9, 9, Paint.ramp(Color("f0ecff")))
	Paint.put(a, cl, 0, 0)
	for p in [Vector2i(10, 10), Vector2i(44, 14), Vector2i(42, 50), Vector2i(12, 48)]:
		Paint.sparkle(a, p.x, p.y, Color.WHITE, p.x < 20)
	# Gotas de luz que caen (como en la baraja clásica)
	for k in 5:
		var x := 14 + k * 6
		var y := 52 + (k % 2) * 4
		Pix.rect(a, x, y, 1, 2, Pix.GOLD)
		Pix.px(a, x, y + 2, Color("c9892a"))


# --- Figuras ---

static func _court(a: Image, suit: int, value: int) -> void:
	var s: Dictionary = SUITS[suit]
	var robe: Color = s.robe
	var fg := Paint.layer(AW, AH)
	var sym := pip(suit, 1)
	match value:
		11:  # Sota: joven de pie que levanta el símbolo
			var hands: Array = ArcanaExtra.robed(fg, 26, 14, 48, robe, {"hair": Color("8a5a2a"), "trim": Color("f4e4c1"),
				"hands": [Vector2(16, 28), Vector2(36, 36)]})
			Pix.rect(fg, 21, 61, 4, 6, Color("5a3a2a"))
			Pix.rect(fg, 28, 61, 4, 6, Color("5a3a2a"))
			_cap(fg, 26, 14, Paint.ramp(robe.lightened(0.3)))
			Paint.outline_in(fg)
			Paint.put(a, fg, 0, 0)
			_put_center(a, sym, int(hands[0].x), int(hands[0].y) - sym.get_height() / 2 + 2)
		12:  # Caballo: jinete sobre su caballo con el símbolo en alto
			_horse(a, suit)
			var rider := Paint.layer(AW, AH)
			var hands: Array = ArcanaExtra.robed(rider, 25, 10, 30, robe, {"hands": [Vector2(36, 18), Vector2(19, 30)], "trim": Color("c0c8d8")})
			_helmet(rider, 25, 10)
			Paint.outline_in(rider)
			Paint.put(a, rider, 0, 0)
			_put_center(a, sym, int(hands[0].x) + 3, int(hands[0].y) - sym.get_height() / 2)
		13, 14:  # Reina y Rey: en el trono
			_throne(a, robe)
			var o := {"crown": "gold", "trim": Pix.GOLD, "hands": [Vector2(16, 38), Vector2(38, 38)]}
			if value == 13:
				o["hair"] = Color("e8b84a") if suit != 3 else Color("8a3a2a")
			else:
				o["beard"] = Color("d8d0c8")
			ArcanaExtra.robed(fg, 27, 16, 50, robe, o)
			Pix.rect(fg, 20, 62, 5, 4, Color("3a2a3a"))
			Pix.rect(fg, 29, 62, 5, 4, Color("3a2a3a"))
			Paint.outline_in(fg)
			Paint.put(a, fg, 0, 0)
			_put_center(a, sym, 14, 34)
			if value == 14:
				var g := Paint.ramp(Pix.GOLD)
				var sc := Paint.layer(AW, AH)
				Paint.thick_line(sc, Vector2(39, 42), Vector2(39, 22), 1, g[2])
				Paint.sphere(sc, 39.5, 20, 2.4, g, 1.0, false)
				Pix.px(sc, 39, 18, Color("ff3a4a"))
				Paint.outline_in(sc)
				Paint.put(a, sc, 0, 0)
			else:
				Paint.put(a, _flower(), 36, 32)


static func _cap(l: Image, cx: int, top: int, rp: Array) -> void:
	var hy := top + 6
	Paint.poly(l, PackedVector2Array([Vector2(cx - 7, hy - 3), Vector2(cx + 6, hy - 6), Vector2(cx + 9, hy - 3), Vector2(cx - 6, hy - 1)]), rp[2])
	Pix.rect(l, cx - 6, hy - 3, 13, 1, rp[4])
	Pix.rect(l, cx + 6, hy - 9, 1, 4, Color("ff6a7a"))
	Pix.px(l, cx + 7, hy - 10, Color("ffb0c0"))


static func _helmet(l: Image, cx: int, top: int) -> void:
	var hy := top + 6
	var st := Paint.ramp(Color("c0c8d8"))
	for x in range(cx - 6, cx + 7):
		var yy := hy - roundi(sqrt(maxf(0.0, 36.0 - (x - cx) * (x - cx))))
		Pix.rect(l, x, yy - 1, 1, 3, st[2])
		Pix.px(l, x, yy - 1, st[4])
	Pix.rect(l, cx - 1, hy - 10, 2, 4, Color("ff4a5a"))
	Pix.px(l, cx - 2, hy - 11, Color("ff8a9a"))


static func _flower() -> Image:
	var l := Paint.layer(7, 12)
	Pix.rect(l, 3, 4, 1, 8, Color("3a8a3a"))
	Pix.px(l, 4, 7, Color("5ab05a"))
	for p in [Vector2i(3, 1), Vector2i(2, 2), Vector2i(4, 2), Vector2i(3, 3)]:
		Pix.px(l, p.x, p.y, Color("ff8ab0"))
	Pix.px(l, 3, 2, Pix.GOLD)
	Paint.outline_in(l)
	return l


static func _throne(a: Image, robe: Color) -> void:
	var tn := Paint.layer(AW, AH)
	var st := Paint.ramp(robe.darkened(0.25).lerp(Color("8a8a9a"), 0.5))
	Pix.rect(tn, 11, 10, 32, 56, st[2])
	Paint.poly(tn, PackedVector2Array([Vector2(11, 10), Vector2(27, 4), Vector2(43, 10)]), st[3])
	for y in range(16, 66, 7):
		Pix.rect(tn, 12, y, 30, 1, st[1])
	Paint.bevel(tn, st[4], st[0])
	for c in [Vector2(13, 12), Vector2(41, 12)]:
		Paint.sphere(tn, c.x, c.y, 2.2, Paint.ramp(Pix.GOLD), 1.0, false)
	Paint.outline_in(tn)
	Paint.put(a, tn, 0, 0)


static func _horse(a: Image, suit: int) -> void:
	var hc: Color = [Color("f4f0e8"), Color("8a5a3a"), Color("4a4a5a"), Color("e8c890")][suit]
	var hr := Paint.ramp(hc)
	var l := Paint.layer(AW, AH)
	# Patas (las de atrás más oscuras), cuerpo, cuello y cabeza
	for p in [[14, 46, 11, 62], [38, 46, 41, 62]]:
		Paint.thick_line(l, Vector2(p[0], p[1]), Vector2(p[2], p[3]), 2, hr[1])
	for p in [[18, 46, 17, 63], [35, 46, 37, 63]]:
		Paint.thick_line(l, Vector2(p[0], p[1]), Vector2(p[2], p[3]), 2, hr[2])
	Paint.ellipse(l, 26, 42, 15, 7, hr[2])
	Paint.poly(l, PackedVector2Array([Vector2(36, 40), Vector2(41, 26), Vector2(46, 26), Vector2(44, 42)]), hr[2])
	Paint.poly(l, PackedVector2Array([Vector2(40, 24), Vector2(48, 25), Vector2(52, 31), Vector2(49, 33), Vector2(42, 30)]), hr[2])
	Paint.bevel(l, hr[4], hr[0])
	Pix.px(l, 46, 27, Pix.INK)
	Pix.rect(l, 42, 22, 1, 3, hr[1])
	# Crin, cola, montura y cascos
	var mane := Paint.ramp(hc.darkened(0.5))
	for k in 6:
		Pix.rect(l, 39 - k / 3, 24 + k * 3, 2, 3, mane[2] if k % 2 else mane[3])
	Paint.bezier(l, Vector2(11, 40), Vector2(3, 42), Vector2(5, 54), 2, mane[2])
	var cloth := Paint.ramp(SUITS[suit].robe)
	Pix.rect(l, 19, 35, 14, 9, cloth[2])
	Pix.rect(l, 19, 35, 14, 1, cloth[4])
	Pix.rect(l, 19, 43, 14, 1, Pix.GOLD)
	for x in range(20, 33, 3):
		Pix.px(l, x, 44, Pix.GOLD)
	for x in [10, 16, 36, 40]:
		Pix.rect(l, x, 63, 3, 2, Pix.INK)
	Paint.outline_in(l)
	Paint.put(a, l, 0, 0)


# --- Índice de esquina (para leer la carta en abanico) ---

const MINI := {
	"0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"], "2": ["##.", "..#", ".#.", "#..", "###"],
	"3": ["##.", "..#", ".#.", "..#", "##."], "4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."],
	"6": [".##", "#..", "###", "#.#", "###"], "7": ["###", "..#", ".#.", ".#.", ".#."], "8": ["###", "#.#", "###", "#.#", "###"],
	"9": ["###", "#.#", "###", "..#", "##."], "S": [".##", "#..", ".#.", "..#", "##."], "C": [".##", "#..", "#..", "#..", ".##"],
	"D": ["##.", "#.#", "#.#", "#.#", "##."], "R": ["##.", "#.#", "##.", "#.#", "#.#"], "A": [".#.", "#.#", "###", "#.#", "#.#"],
}
const MINI_PIPS := [
	[".g...", ".gg..", "..g..", "..gg.", "...g."],
	["rrrrr", ".rrr.", "..r..", ".rrr.", "....."],
	["..b..", "..b..", "..b..", ".yyy.", "..y.."],
	[".yyy.", "yyyyy", "yyyyy", "yyyyy", ".yyy."],
]
const MINI_COLS := {"g": Color("3a9a3a"), "r": Color("d83a4a"), "b": Color("5a7ad8"), "y": Color("e8a82a"), "p": Color("7a3ab0")}


## Índice de esquina grande (fuente de 5x7) con el palo debajo: se lee aunque la carta esté tapada en el abanico.
static func corner_tag(i: Image, label: String, pip_rows: Array, col: Color) -> void:
	var tw := maxi(5, label.length() * 6 - 1)
	var w := tw + 6
	var h := 19
	Pix.rect(i, 2, 2, w, h, Pix.INK)
	Pix.rect(i, 3, 3, w - 2, h - 2, Color("efdcb0"))
	Pix.rect(i, 3, 3, w - 2, 1, Color("fbefd5"))
	Pix.rect(i, 3, h, w - 2, 1, Color("c9a46a"))
	Pix.rect(i, w, 4, 1, h - 3, Color("c9a46a"))
	if label != "":
		Pix.stamp_text(i, 2 + (w - tw) / 2, 5, label, col)
	var px0 := 2 + (w - 5) / 2
	var py0 := 13 if label != "" else 9
	for gy in pip_rows.size():
		for gx in 5:
			var ch: String = pip_rows[gy][gx]
			if ch != ".":
				Pix.px(i, px0 + gx, py0 + gy, MINI_COLS[ch])
