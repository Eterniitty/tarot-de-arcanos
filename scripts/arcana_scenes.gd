class_name ArcanaScenes
extends RefCounted
## Decorados animados que se dibujan detrás de la carta en la cinemática de cada Arcano Mayor (todo con
## rectángulos de píxel y líneas: círculos mágicos, columnas, enredaderas, ruedas, balanzas, alas, cadenas...).
## st = segundos desde que empezó el decorado; k = cuánto está aparecido (0..1).

const C := Vector2(320, 158)


static func px(ci: CanvasItem, p: Vector2, col: Color, s := 1.0) -> void:
	ci.draw_rect(Rect2(p.round(), Vector2(s, s)), col)


static func line(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, w := 1.0) -> void:
	ci.draw_line(a.round(), b.round(), col, w)


static func ring(ci: CanvasItem, c: Vector2, r: float, col: Color, step := 2, sq := 1.0) -> void:
	var n := maxi(16, int(r * 4.0))
	for i in n:
		if i % step == 0:
			var a := i * TAU / n
			px(ci, c + Vector2(cos(a) * r, sin(a) * r * sq), col)


static func draw(ci: CanvasItem, id: int, st: float, k: float) -> void:
	if k <= 0.01:
		return
	match id:
		0: _loco(ci, st, k)
		1: _mago(ci, st, k)
		2: _papisa(ci, st, k)
		3: _emperatriz(ci, st, k)
		4: _emperador(ci, st, k)
		5: _papa(ci, st, k)
		6: _enamorados(ci, st, k)
		7: _carro(ci, st, k)
		8: _fuerza(ci, st, k)
		9: _ermitano(ci, st, k)
		10: _rueda(ci, st, k)
		11: _justicia(ci, st, k)
		12: _colgado(ci, st, k)
		13: _muerte(ci, st, k)
		14: _templanza(ci, st, k)
		15: _diablo(ci, st, k)
		16: _torre(ci, st, k)
		17: _estrella(ci, st, k)
		18: _luna(ci, st, k)
		19: _sol(ci, st, k)
		20: _juicio(ci, st, k)
		21: _mundo(ci, st, k)


# Pelotas de malabares que giran alrededor de la carta y un perrito que salta abajo
static func _loco(ci: CanvasItem, st: float, k: float) -> void:
	var cols := [Color("ff6b7a"), Color("ffd447"), Color("7ab8ff"), Color("5ff0b0"), Color("ff8ad8")]
	for i in 5:
		var a := st * 4.0 + i * TAU / 5.0
		var p := C + Vector2(cos(a) * 100.0, sin(a) * 40.0 - absf(sin(a * 2.0)) * 30.0) * k
		ci.draw_circle(p.round(), 5.0, Pix.INK)
		ci.draw_circle(p.round(), 4.0, cols[i])
		px(ci, p + Vector2(-2, -2), Color.WHITE, 2)
	var dx := 200.0 + sin(st * 3.0) * 30.0
	var jump := absf(sin(st * 9.0)) * 10.0
	var dp := Vector2(dx, 300 - jump)
	ci.draw_rect(Rect2(dp, Vector2(14, 7)), Color("f4f0e8"))
	ci.draw_rect(Rect2(dp + Vector2(10, -5), Vector2(7, 7)), Color("f4f0e8"))
	px(ci, dp + Vector2(15, -3), Pix.INK)
	ci.draw_rect(Rect2(dp + Vector2(1, 7), Vector2(2, 3)), Color("d8d0c8"))
	ci.draw_rect(Rect2(dp + Vector2(10, 7), Vector2(2, 3)), Color("d8d0c8"))
	line(ci, dp + Vector2(0, 1), dp + Vector2(-5, -3 + sin(st * 20.0) * 2.0), Color("f4f0e8"), 2)


# Círculo mágico: dos anillos de runas girando en sentidos contrarios y un pentagrama
static func _mago(ci: CanvasItem, st: float, k: float) -> void:
	var col := Color("ff8ad8", 0.9 * k)
	var r1 := 130.0 * k
	var r2 := 112.0 * k
	ring(ci, C, r1, col, 1, 0.55)
	ring(ci, C, r2, Color(Pix.GOLD, 0.8 * k), 1, 0.55)
	for i in 24:
		var a := st * 0.8 + i * TAU / 24.0
		var p := C + Vector2(cos(a) * (r1 + r2) / 2.0, sin(a) * (r1 + r2) / 2.0 * 0.55)
		var g := i % 4
		match g:
			0: line(ci, p - Vector2(0, 3), p + Vector2(0, 3), Color(Pix.GOLD, k))
			1: line(ci, p - Vector2(3, 0), p + Vector2(3, 0), Color(Pix.GOLD, k))
			2: px(ci, p - Vector2(1, 1), Color(Pix.GOLD, k), 3)
			3:
				line(ci, p + Vector2(-2, -2), p + Vector2(2, 2), Color(Pix.GOLD, k))
				line(ci, p + Vector2(2, -2), p + Vector2(-2, 2), Color(Pix.GOLD, k))
	var pts: Array = []
	for i in 5:
		var a := -st * 0.6 - PI / 2.0 + i * TAU / 5.0
		pts.append(C + Vector2(cos(a) * r2, sin(a) * r2 * 0.55))
	for i in 5:
		line(ci, pts[i], pts[(i + 2) % 5], Color("ff8ad8", 0.7 * k))
	for i in 5:
		px(ci, pts[i] - Vector2(1, 1), Color.WHITE, 3)


# Columnas blanca y negra a los lados y el velo con granadas detrás
static func _papisa(ci: CanvasItem, st: float, k: float) -> void:
	var rise := (1.0 - k) * 200.0
	for side in [-1, 1]:
		var x: float = C.x + side * 150.0 - 14.0
		var col := Color("2a2a3a") if side < 0 else Color("e8e8f0")
		var y0 := 40.0 + rise
		ci.draw_rect(Rect2(x, y0, 28, 260), Pix.INK)
		ci.draw_rect(Rect2(x + 2, y0 + 2, 24, 256), col)
		ci.draw_rect(Rect2(x + 5, y0 + 2, 3, 256), col.lightened(0.25))
		ci.draw_rect(Rect2(x - 4, y0 - 6, 36, 10), col.darkened(0.2))
		Pix.draw_text_c(ci, x + 14, y0 + 30, "B" if side < 0 else "J", Color("ffd447") if side < 0 else Color("2a2a3a"), 2)
	for i in 30:
		var p := Vector2(C.x - 110 + (i % 6) * 44 + (int(i / 6.0) % 2) * 22, 60 + int(i / 6.0) * 46 + sin(st * 2.0 + i) * 3.0)
		ci.draw_circle(p, 4.0, Color("c0304a", 0.5 * k))
		px(ci, p + Vector2(-1, -2), Color("ff8a9a", 0.6 * k), 2)


# Enredaderas que crecen desde las esquinas de abajo con hojas y flores
static func _emperatriz(ci: CanvasItem, st: float, k: float) -> void:
	var grow := clampf(st / 1.2, 0.0, 1.0)
	for side in [-1.0, 1.0]:
		var prev := Vector2(C.x + side * 300.0, 340)
		var steps := int(40 * grow)
		for i in steps:
			var u := i / 40.0
			var p := Vector2(C.x + side * (300.0 - u * 190.0) + sin(u * 12.0 + st) * 14.0, 340 - u * 230.0)
			line(ci, prev, p, Color("2a7a3a"), 3)
			line(ci, prev, p, Color("5ab05a"), 1)
			if i % 4 == 2:
				var lp := p + Vector2(side * -8.0 * sin(u * 9.0), -3)
				ci.draw_circle(lp, 4.0, Color("4ab04a"))
				px(ci, lp + Vector2(-1, -2), Color("8af0a0"), 2)
			if i % 7 == 5:
				var fc: Color = [Color("ff8ab0"), Color("ffd447"), Color.WHITE][i % 3]
				for d in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
					px(ci, p + d - Vector2(1, 1), fc, 3)
				px(ci, p - Vector2(1, 1), Pix.GOLD, 2)
			prev = p


# Grietas que se abren en el suelo desde el golpe y un trono de piedra detrás
static func _emperador(ci: CanvasItem, st: float, k: float) -> void:
	var stone := Color("6a6a7a", 0.9 * k)
	ci.draw_rect(Rect2(C.x - 120, 30, 240, 260), Color(Pix.INK, 0.8 * k))
	ci.draw_rect(Rect2(C.x - 116, 34, 232, 252), stone)
	for y in range(40, 290, 18):
		ci.draw_rect(Rect2(C.x - 116, y, 232, 1), Color("4a4a5a", k))
		for x in range(-116, 116, 36):
			ci.draw_rect(Rect2(C.x + x + (18 if (y / 18) % 2 == 0 else 0), y, 1, 18), Color("4a4a5a", k))
	for side in [-1, 1]:
		ci.draw_circle(C + Vector2(side * 110, -120), 12.0, Color("d8c8a8", k))
		ci.draw_circle(C + Vector2(side * 110, -120), 6.0, Color("8a7a5a", k))
	var g := clampf((st - 0.35) / 0.5, 0.0, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 44
	for i in 7:
		var a := PI + i * PI / 6.0
		var p := C + Vector2(0, 110)
		for j in int(8 * g):
			var q := p + Vector2(cos(a) * 14.0 + rng.randf_range(-6, 6), sin(a) * 5.0 + rng.randf_range(-2, 2))
			line(ci, p, q, Color("1a1026"), 2)
			p = q


# Rosetón de vidriera girando lentamente detrás de la carta
static func _papa(ci: CanvasItem, st: float, k: float) -> void:
	var cols := [Color("c0302a"), Color("3a6ad8"), Color("ffd447"), Color("37a85a")]
	var r := 140.0 * k
	for i in 16:
		var a0 := st * 0.2 + i * TAU / 16.0
		var a1 := a0 + TAU / 16.0
		ci.draw_colored_polygon(PackedVector2Array([C, C + Vector2.from_angle(a0) * r, C + Vector2.from_angle(a1) * r]), Color(cols[i % 4], 0.35 * k))
		line(ci, C, C + Vector2.from_angle(a0) * r, Color(Pix.INK, 0.8 * k), 2)
	for rr in [r, r * 0.66, r * 0.33]:
		ring(ci, C, rr, Color(Pix.GOLD, 0.9 * k), 1)


# Cupido: una flecha con plumas cruza y dos corazones laten a los lados
static func _enamorados(ci: CanvasItem, st: float, k: float) -> void:
	for side in [-1, 1]:
		var beat := 1.0 + absf(sin(st * 7.0)) * 0.25
		var p := C + Vector2(side * 150, -20)
		var s := 6.0 * beat
		ci.draw_circle(p + Vector2(-s * 0.55, 0), s * 0.7, Color("ff4a6a", k))
		ci.draw_circle(p + Vector2(s * 0.55, 0), s * 0.7, Color("ff4a6a", k))
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-s * 1.2, s * 0.2), p + Vector2(s * 1.2, s * 0.2), p + Vector2(0, s * 1.6)]), Color("ff4a6a", k))
		px(ci, p + Vector2(-s * 0.7, -s * 0.3), Color("ffb0c0", k), 2)
	var u := fmod(st, 1.6) / 1.6
	var ax := lerpf(-40.0, 680.0, u)
	var ay := C.y + 30.0 - u * 60.0
	line(ci, Vector2(ax - 40, ay + 3), Vector2(ax, ay), Color("8a5a3a"), 2)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(ax, ay - 3), Vector2(ax + 8, ay), Vector2(ax, ay + 3)]), Color("c8d4e8"))
	for f in 3:
		line(ci, Vector2(ax - 40 + f * 3, ay + 3), Vector2(ax - 44 + f * 3, ay - 2), Color("ff8ab0"), 1)


# Líneas de velocidad continuas y ruedas con radios girando abajo
static func _carro(ci: CanvasItem, st: float, k: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var y := rng.randf_range(40, 320)
		var len := rng.randf_range(30, 120)
		var x := fmod(rng.randf_range(0, 700) - st * 900.0, 760.0)
		if x < 0:
			x += 760.0
		ci.draw_rect(Rect2(x - 60, y, len, 1), Color(1, 1, 1, 0.35 * k))
	for side in [-1, 1]:
		var wc := C + Vector2(side * 90, 118)
		ring(ci, wc, 20, Color("6a4a2a", k), 1)
		ring(ci, wc, 18, Color("8a6a3a", k), 1)
		for i in 6:
			var a := st * 12.0 + i * TAU / 6.0
			line(ci, wc, wc + Vector2.from_angle(a) * 18.0, Color("8a6a3a", k), 2)
		ci.draw_circle(wc, 4.0, Color(Pix.GOLD, k))


# Melena de león: púas naranjas alrededor que se erizan con cada rugido
static func _fuerza(ci: CanvasItem, st: float, k: float) -> void:
	var roar := absf(sin(st * 5.0))
	for i in 36:
		var a := i * TAU / 36.0 + sin(st * 3.0 + i) * 0.03
		var r0 := 110.0 * k
		var r1 := r0 + (24.0 + roar * 30.0 + (i % 3) * 8.0) * k
		var col: Color = [Color("ffb347"), Color("ff8a3a"), Color("c2501e")][i % 3]
		ci.draw_colored_polygon(PackedVector2Array([C + Vector2.from_angle(a - 0.06) * r0, C + Vector2.from_angle(a) * r1, C + Vector2.from_angle(a + 0.06) * r0]), Color(col, 0.85 * k))
	ring(ci, C, 108.0 * k, Color(Pix.GOLD, k), 1)
	for i in 2:
		var p := C + Vector2(-150 + i * 300, 100)
		Pix.draw_text_c(ci, p.x, p.y + sin(st * 10.0 + i) * 3.0, "GRR", Color("ffb347", roar * k), 2)


# Copos de nieve que caen dentro de la luz del farol y una montaña
static func _ermitano(ci: CanvasItem, st: float, k: float) -> void:
	ci.draw_colored_polygon(PackedVector2Array([Vector2(60, 330), Vector2(250, 180), Vector2(330, 230), Vector2(470, 150), Vector2(600, 330)]), Color("2a2a4a", 0.9 * k))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(230, 196), Vector2(250, 180), Vector2(272, 196), Vector2(250, 200)]), Color("e8f0ff", k))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(446, 168), Vector2(470, 150), Vector2(494, 168), Vector2(470, 172)]), Color("e8f0ff", k))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 60:
		var x := rng.randf_range(160, 480) + sin(st * 2.0 + i) * 8.0
		var y := fmod(rng.randf_range(0, 360) + st * 40.0, 360.0)
		px(ci, Vector2(x, y), Color(1, 1, 1, 0.8 * k), 1 + (i % 2))


# La Rueda de la Fortuna gigante: llanta, radios, símbolos alquímicos y bujes dorados
static func _rueda(ci: CanvasItem, st: float, k: float) -> void:
	var spin := st * (6.0 - minf(st, 1.6) * 3.0)
	var r := 140.0 * k
	ci.draw_circle(C, r + 6, Color(Pix.INK, 0.8 * k))
	ci.draw_circle(C, r + 4, Color("c9892a", 0.9 * k))
	ci.draw_circle(C, r - 4, Color("2a5aa8", 0.85 * k))
	ring(ci, C, r - 12, Color(Pix.GOLD, k), 1)
	for i in 8:
		var a := spin + i * TAU / 8.0
		line(ci, C + Vector2.from_angle(a) * 20.0, C + Vector2.from_angle(a) * (r - 6), Color(Pix.GOLD, k), 3)
		var sp := C + Vector2.from_angle(a + TAU / 16.0) * (r - 26)
		var glyph: String = ["T", "A", "R", "O", "+", "X", "O", "*"][i]
		Pix.draw_text_c(ci, sp.x, sp.y - 3, glyph, Color("fff0a0", k))
		ci.draw_circle(C + Vector2.from_angle(a) * (r + 4), 3.0, Color("fff0a0", k))
	ci.draw_circle(C, 18.0, Color(Pix.GOLD, k))
	ci.draw_circle(C, 8.0, Color("c9892a", k))
	# Indicador de arriba que hace tic
	var tick := sin(st * 20.0) * 0.2 * maxf(0.0, 1.6 - st)
	var tp := C + Vector2(0, -r - 14)
	ci.draw_colored_polygon(PackedVector2Array([tp + Vector2(-7, -6).rotated(tick), tp + Vector2(7, -6).rotated(tick), tp + Vector2(0, 8).rotated(tick)]), Color("ff4a5a", k))


# Balanza que oscila por encima de la carta y columnas moradas
static func _justicia(ci: CanvasItem, st: float, k: float) -> void:
	var tilt := sin(st * 6.0) * 0.3 * maxf(0.0, 1.0 - st * 0.5)
	var top := C + Vector2(0, -150)
	var g := Color(Pix.GOLD, k)
	line(ci, top, top + Vector2(0, 30), g, 3)
	var arm := Vector2(120, 0).rotated(tilt)
	line(ci, top + Vector2(0, 8) - arm, top + Vector2(0, 8) + arm, g, 3)
	for side in [-1, 1]:
		var end: Vector2 = top + Vector2(0, 8) + arm * side
		line(ci, end, end + Vector2(-18, 30), g, 1)
		line(ci, end, end + Vector2(18, 30), g, 1)
		ci.draw_colored_polygon(PackedVector2Array([end + Vector2(-22, 30), end + Vector2(22, 30), end + Vector2(14, 38), end + Vector2(-14, 38)]), g)
	ci.draw_circle(top, 5.0, Color("fff0a0", k))
	for side in [-1, 1]:
		ci.draw_rect(Rect2(C.x + side * 170 - 10, 50, 20, 240), Color("6a2a7a", 0.8 * k))
		ci.draw_rect(Rect2(C.x + side * 170 - 6, 50, 3, 240), Color("9a5aaa", 0.8 * k))


# La cuerda del Colgado desde arriba y hojas de árbol a los lados
static func _colgado(ci: CanvasItem, st: float, k: float) -> void:
	var sway := sin(st * 3.5) * 16.0
	for i in 20:
		var y := float(i) * 4.0
		px(ci, Vector2(C.x + sway * y / 80.0, 30 + y), Color("c8a878", k), 2 if i % 2 == 0 else 1)
	ci.draw_rect(Rect2(C.x - 170, 26, 340, 8), Color("6a4a2a", k))
	ci.draw_rect(Rect2(C.x - 170, 26, 340, 2), Color("9a7a4a", k))
	for side in [-1, 1]:
		ci.draw_rect(Rect2(C.x + side * 170 - 6, 26, 12, 280), Color("6a4a2a", k))
		for j in 6:
			var p := Vector2(C.x + side * 170, 50 + j * 40)
			ci.draw_circle(p + Vector2(side * 10, sin(st * 2.0 + j) * 2.0), 9.0, Color("4aa84a", 0.9 * k))


# La guadaña enorme que barre la pantalla y rosas negras
static func _muerte(ci: CanvasItem, st: float, k: float) -> void:
	var u := clampf((st - 0.3) / 0.35, 0.0, 1.0)
	var ang := lerpf(-2.4, 0.5, 1.0 - pow(1.0 - u, 3.0))
	var pivot := C + Vector2(150, 160)
	var tip := pivot + Vector2.from_angle(ang - PI / 2.0) * 330.0
	line(ci, pivot, tip, Color("6a4a3a", k), 4)
	var blade_dir := Vector2.from_angle(ang - PI / 2.0)
	var side := blade_dir.orthogonal()
	var pts := PackedVector2Array()
	for i in 12:
		var t := i / 11.0
		pts.append(tip + side * (-t * 110.0) + blade_dir * (sin(t * PI) * 26.0 - t * 30.0))
	for i in 11:
		var t := 1.0 - i / 10.0
		pts.append(tip + side * (-t * 110.0) + blade_dir * (sin(t * PI) * 10.0 - t * 30.0))
	ci.draw_colored_polygon(pts, Color("c8d0e0", k))
	for i in 11:
		px(ci, pts[i], Color.WHITE, 2)
	for i in 8:
		var p := Vector2(80 + i * 70, 316 + sin(i) * 6.0)
		ci.draw_circle(p, 5.0, Color("2a0a14", k))
		ci.draw_circle(p + Vector2(-1, -1), 2.0, Color("6a1a2a", k))
		line(ci, p, p + Vector2(0, 14), Color("1a3a1a", k), 1)


# Dos copas a los lados que se pasan un chorro de agua en arco
static func _templanza(ci: CanvasItem, st: float, k: float) -> void:
	var cups := [C + Vector2(-150, 20), C + Vector2(150, -10)]
	for p in cups:
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-14, -12), p + Vector2(14, -12), p + Vector2(6, 6), p + Vector2(-6, 6)]), Color(Pix.GOLD, k))
		ci.draw_rect(Rect2(p + Vector2(-2, 6), Vector2(4, 10)), Color(Pix.GOLD, k))
		ci.draw_rect(Rect2(p + Vector2(-9, 16), Vector2(18, 3)), Color(Pix.GOLD, k))
		ci.draw_rect(Rect2(p + Vector2(-14, -12), Vector2(28, 2)), Color("fff0a0", k))
	var from: Vector2 = cups[0] + Vector2(10, -12)
	var to: Vector2 = cups[1] + Vector2(-10, -12)
	var ctrl := (from + to) / 2.0 + Vector2(0, -130)
	for i in 40:
		var u := fmod(i / 40.0 + st * 0.8, 1.0)
		var a := from.lerp(ctrl, u)
		var b := ctrl.lerp(to, u)
		var p := a.lerp(b, u)
		px(ci, p + Vector2(sin(u * 30.0 + st * 8.0), 0), Color("8ad0ff", k), 3)
		px(ci, p, Color(1, 1, 1, 0.8 * k), 1)


# Cadenas desde las esquinas hasta la carta y lenguas de fuego abajo
static func _diablo(ci: CanvasItem, st: float, k: float) -> void:
	for corner in [Vector2(40, 340), Vector2(600, 340)]:
		var to := C + Vector2(signf(corner.x - C.x) * 40.0, 80)
		var n := 14
		for i in n:
			var p: Vector2 = corner.lerp(to, i / float(n)) + Vector2(0, sin(i * 0.9 + st * 4.0) * 4.0)
			var horiz := i % 2 == 0
			ci.draw_rect(Rect2(p - (Vector2(6, 3) if horiz else Vector2(3, 6)), Vector2(12, 6) if horiz else Vector2(6, 12)), Color("5a5a6a", k), false, 2.0)
	for i in 26:
		var x := 10.0 + i * 25.0
		var h := 50.0 + sin(st * 9.0 + i * 1.7) * 22.0 + (i % 3) * 10.0
		var base := 360.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 14, base), Vector2(x + 14, base), Vector2(x + sin(st * 6.0 + i) * 6.0, base - h * k)]), Color("ff5a1a", 0.85 * k))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 7, base), Vector2(x + 7, base), Vector2(x + sin(st * 6.0 + i) * 4.0, base - h * 0.6 * k)]), Color("ffd447", 0.9 * k))
	for side in [-1, 1]:
		var e := C + Vector2(side * 36, -60)
		ci.draw_circle(e + Vector2(side * 110, 0), 5.0, Color("ff2a1a", 0.6 + 0.4 * sin(st * 8.0)))


# Ladrillos que caen y grietas en la pantalla
static func _torre(ci: CanvasItem, st: float, k: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 16
	for i in 24:
		var x := rng.randf_range(60, 580)
		var t0 := rng.randf_range(0.0, 1.0)
		var y := -20.0 + maxf(0.0, st - t0) * maxf(0.0, st - t0) * 400.0
		if y > 380:
			continue
		var rot := (st - t0) * rng.randf_range(-6, 6)
		var p := Vector2(x, y)
		var pts := PackedVector2Array()
		for c in [Vector2(-6, -3), Vector2(6, -3), Vector2(6, 3), Vector2(-6, 3)]:
			pts.append(p + c.rotated(rot))
		ci.draw_colored_polygon(pts, Color("8a6a5a", k))
		line(ci, pts[0], pts[1], Color("b08a7a", k))
	if st > 0.3:
		var p := Vector2(470, 40)
		for i in 9:
			var q := p + Vector2(rng.randf_range(-24, 14), rng.randf_range(14, 30))
			line(ci, p, q, Color(1, 1, 1, 0.6 * k), 1)
			p = q


# Una gran estrella de ocho puntas detrás, con siete pequeñas alrededor que titilan
static func _estrella(ci: CanvasItem, st: float, k: float) -> void:
	var r := 130.0 * k
	var pts := PackedVector2Array()
	for i in 16:
		var a := st * 0.3 + i * TAU / 16.0
		pts.append(C + Vector2.from_angle(a) * (r if i % 2 == 0 else r * 0.42))
	ci.draw_colored_polygon(pts, Color("fff3c0", 0.3 * k))
	for i in 16:
		line(ci, pts[i], pts[(i + 1) % 16], Color(Pix.GOLD, 0.8 * k))
	for i in 7:
		var a := -PI / 2.0 + i * TAU / 7.0
		var p := C + Vector2(cos(a) * 190, sin(a) * 120)
		var tw := absf(sin(st * 5.0 + i))
		var s := 2.0 + tw * 5.0
		line(ci, p - Vector2(s, 0), p + Vector2(s, 0), Color("fff3c0", k))
		line(ci, p - Vector2(0, s), p + Vector2(0, s), Color("fff3c0", k))
		px(ci, p - Vector2(1, 1), Color.WHITE, 3)


# Dos torres a los lados, agua con reflejo y cráteres en la luna
static func _luna(ci: CanvasItem, st: float, k: float) -> void:
	for side in [-1, 1]:
		var x: float = C.x + side * 180.0 - 18.0
		ci.draw_rect(Rect2(x, 150, 36, 170), Color("2a2a5a", k))
		for j in 4:
			ci.draw_rect(Rect2(x + j * 10, 142, 6, 8), Color("2a2a5a", k))
		ci.draw_rect(Rect2(x + 14, 190, 8, 12), Color("ffd447", 0.8 * k))
	for y in range(300, 360, 4):
		var w := 200.0 + sin(st * 3.0 + y) * 40.0
		ci.draw_rect(Rect2(C.x - w / 2.0, y, w, 1), Color("9ab0ff", 0.3 * k))
	for c in [Vector2(-30, -60), Vector2(25, -30), Vector2(-10, 10), Vector2(40, -80)]:
		ci.draw_circle(C + c, 9.0, Color(0.6, 0.6, 0.8, 0.25 * k))


# Girasoles y un sol con cara detrás de los rayos
static func _sol(ci: CanvasItem, st: float, k: float) -> void:
	for i in 6:
		var x := 70.0 + i * 100.0
		var y := 300.0 + sin(st * 2.0 + i) * 3.0
		line(ci, Vector2(x, y), Vector2(x, 360), Color("2a7a3a", k), 3)
		for j in 10:
			var a := j * TAU / 10.0 + st
			ci.draw_circle(Vector2(x, y) + Vector2.from_angle(a) * 9.0, 4.0, Color("ffcf4a", k))
		ci.draw_circle(Vector2(x, y), 6.0, Color("6a3a1a", k))
	for side in [-1, 1]:
		var e := C + Vector2(side * 60, -70)
		ci.draw_rect(Rect2(e - Vector2(4, 1), Vector2(8, 3)), Color("8a4a1a", 0.6 * k))


# Alas de ángel enormes que se abren detrás de la carta, pluma a pluma
static func _juicio(ci: CanvasItem, st: float, k: float) -> void:
	var open := clampf(st / 0.8, 0.0, 1.0)
	for side in [-1.0, 1.0]:
		for row in 3:
			for i in 9:
				var u := i / 8.0
				var len := (150.0 - row * 34.0) * open
				var a: float = -PI / 2.0 + side * (0.4 + u * 1.5) + sin(st * 3.0) * 0.04 * side
				var base := C + Vector2(side * 30, -40 + row * 18)
				var tip := base + Vector2.from_angle(a) * len * (0.6 + u * 0.4)
				var col: Color = [Color("ffffff"), Color("e0e8ff"), Color("c0c8f0")][row]
				ci.draw_colored_polygon(PackedVector2Array([base, tip + Vector2.from_angle(a + side * PI / 2.0) * 6.0, tip, tip - Vector2.from_angle(a + side * PI / 2.0) * 6.0]), Color(col, 0.9 * k))
	# Trompeta dorada que asoma por arriba
	var tp := C + Vector2(70, -150)
	ci.draw_colored_polygon(PackedVector2Array([tp, tp + Vector2(40, -10), tp + Vector2(52, -22), tp + Vector2(54, 6), tp + Vector2(40, 2)]), Color(Pix.GOLD, k))


# Corona de laurel, los cuatro vientos en las esquinas y estrellas
static func _mundo(ci: CanvasItem, st: float, k: float) -> void:
	var r := 128.0 * k
	for i in 40:
		var a := i * TAU / 40.0 + st * 0.4
		var p := C + Vector2(cos(a) * r, sin(a) * r * 0.9)
		var d := Vector2.from_angle(a + PI / 2.0)
		ci.draw_colored_polygon(PackedVector2Array([p - d * 6.0, p + Vector2.from_angle(a) * 7.0, p + d * 6.0, p - Vector2.from_angle(a) * 3.0]), Color("37a85a", k))
		px(ci, p, Color("8af0a0", k), 2)
	for c in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var p := C + Vector2(c.x * 220, c.y * 110)
		ci.draw_circle(p, 14.0, Color("f0ecff", 0.8 * k))
		ci.draw_circle(p + Vector2(c.x * -8, -4), 9.0, Color("f0ecff", 0.8 * k))
		for j in 3:
			line(ci, p + Vector2(-c.x * 16, j * 4 - 4), p + Vector2(-c.x * (40 + sin(st * 6.0 + j) * 8.0), j * 6 - 6), Color(1, 1, 1, 0.6 * k))
