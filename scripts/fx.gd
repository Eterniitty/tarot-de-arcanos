class_name Fx
extends Node2D
## Partículas pixel, anillos, estelas, tajos, rayos y avisos. Todo se dibuja en cuadrados de 1 px para no romper el pixel art.

var speed := 1.0
var parts: Array = []
var rings: Array = []
var ghosts: Array = []
var slashes: Array = []
var lines: Array = []
var bolts: Array = []
var columns: Array = []
var orbs: Array = []  # lo rellena la simulación: [{p, c}]
var stars: Array = []
var puffs: Array = []
var texts: Array = []
var pickups: Array = []  # posiciones de las estrellas de La Estrella
var ovals: Array = []  # ondas de choque ovaladas
var echo: Array = []  # segundo destello retrasado en golpes fuertes


func burst(pos: Vector2, n: int, col: Color, vmin: float, vmax: float, life: float, grav := 200.0, size := 1, dir := Vector2.ZERO, spread := PI, drag := 2.0, cols: Array = []) -> void:
	for i in n:
		var a := randf() * TAU if dir == Vector2.ZERO else dir.angle() + randf_range(-spread, spread)
		var c: Color = col if cols.is_empty() else cols[randi() % cols.size()]
		parts.append({"p": pos, "v": Vector2.from_angle(a) * randf_range(vmin, vmax), "l": life * randf_range(0.6, 1.0),
			"m": life, "c": c, "s": size, "g": grav, "d": drag})


func ring(pos: Vector2, r0: float, r1: float, life: float, col: Color, width := 2) -> void:
	rings.append({"p": pos, "r0": r0, "r1": r1, "l": life, "m": life, "c": col, "w": width})


func ghost(tex: Texture2D, xf: Transform2D, off: Vector2, col: Color, life := 0.22) -> void:
	ghosts.append({"t": tex, "x": xf, "o": off, "c": col, "l": life, "m": life})


## Tajo en arco que se dibuja barriendo de a0 a a1 (radianes).
func slash(center: Vector2, r: float, a0: float, a1: float, life: float, col: Color, thick := 3) -> void:
	slashes.append({"p": center, "r": r, "a0": a0, "a1": a1, "l": life, "m": life, "c": col, "w": thick})


## Chispa con estela: se dibuja como una línea orientada según su velocidad.
func sparks(pos: Vector2, n: int, dir: Vector2, spread: float, vmin: float, vmax: float, life: float, cols: Array) -> void:
	for i in n:
		var a := dir.angle() + randf_range(-spread, spread)
		parts.append({"p": pos, "v": Vector2.from_angle(a) * randf_range(vmin, vmax), "l": life * randf_range(0.6, 1.0),
			"m": life, "c": cols[randi() % cols.size()], "s": 1, "g": 140.0, "d": 4.0, "streak": true})


func streak(a: Vector2, b: Vector2, life: float, col: Color, width := 1.0) -> void:
	lines.append({"a": a, "b": b, "l": life, "m": life, "c": col, "w": width})


## Golpe: destello en cruz alargado según la dirección, onda de choque ovalada, chispas con estela y polvo.
func impact(pos: Vector2, dir: Vector2, col: Color, power: float) -> void:
	var big := clampf(power / 600.0, 0.0, 1.5)
	var n := dir.normalized() if dir.length() > 0.01 else Vector2.RIGHT
	var side := n.orthogonal()
	var long := 10.0 + 14.0 * big
	streak(pos - n * 4.0, pos + n * long, 0.09 + big * 0.05, Color.WHITE, 3)
	streak(pos + n * 2.0, pos - n * long * 0.6, 0.08 + big * 0.04, Color.WHITE, 2)
	streak(pos - side * (5.0 + 3.0 * big), pos + side * (5.0 + 3.0 * big), 0.07 + big * 0.04, Color.WHITE, 2)
	for k in 6:
		var a := n.angle() + randf_range(-0.9, 0.9)
		streak(pos + Vector2.from_angle(a) * 4.0, pos + Vector2.from_angle(a) * randf_range(10, 20) * (1.0 + big), 0.1, Color(col.lightened(0.5)), 1)
	ovals.append({"p": pos, "n": n, "r1": 10.0 + 18.0 * big, "l": 0.22 + 0.08 * big, "m": 0.22 + 0.08 * big, "c": Color.WHITE})
	ovals.append({"p": pos, "n": n, "r1": 6.0 + 12.0 * big, "l": 0.18, "m": 0.18, "c": col.lightened(0.3)})
	var hot := [Color.WHITE, col.lightened(0.5), col]
	if big > 0.7:
		hot.append_array([Color("ffd447"), Color("ff8a3a")])
	sparks(pos, int(10 + 16 * big), n, 0.6, 120, 300 + 220 * big, 0.35, hot)
	burst(pos, 6, Color.WHITE, 40, 160, 0.25, 0, 1)
	star(pos, Color.WHITE, 0.16 + 0.06 * big, 3 + int(big * 2))
	puff(pos, -n * 30.0, 2, 6 + 6 * big, 0.3, Color(1, 1, 1, 0.3))
	if big > 0.9:
		echo.append({"p": pos + n * 8.0, "t": 0.06, "c": col})


func bolt(x: float, y_to: float) -> void:
	var pts := PackedVector2Array()
	var y := -10.0
	var cx := x
	while y < y_to:
		pts.append(Vector2(cx, y))
		y += randf_range(8, 16)
		cx = x + randf_range(-7, 7)
	pts.append(Vector2(x, y_to))
	bolts.append({"pts": pts, "l": 0.28, "m": 0.28})


## Destello en cruz que crece y se apaga.
func star(pos: Vector2, col: Color, life := 0.45, size := 3) -> void:
	stars.append({"p": pos, "c": col, "l": life, "m": life, "s": size})


## Nube redonda que se hincha y se desvanece (humo, polvo).
func puff(pos: Vector2, vel: Vector2, r0: float, r1: float, life: float, col: Color) -> void:
	puffs.append({"p": pos, "v": vel, "r0": r0, "r1": r1, "l": life, "m": life, "c": col})


## Partículas que vienen desde un círculo hacia el centro (para «cargar» algo).
func converge(center: Vector2, n: int, radius: float, life: float, cols: Array, swirl := 0.0) -> void:
	for i in n:
		var a := randf() * TAU
		var p := center + Vector2.from_angle(a) * radius * randf_range(0.7, 1.3)
		var v := (center - p) / life + Vector2.from_angle(a + PI / 2.0) * swirl
		parts.append({"p": p, "v": v, "l": life * randf_range(0.7, 1.0), "m": life, "c": cols[randi() % cols.size()],
			"s": 1 + randi() % 2, "g": 0.0, "d": 0.0})


func text(pos: Vector2, s: String, col: Color, life := 0.6, scale := 1) -> void:
	texts.append({"p": pos, "s": s, "c": col, "l": life, "m": life, "k": scale})


static func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - x, 3.0)


func column(x: float, life: float) -> void:
	columns.append({"x": x, "l": life, "m": life})


func clear() -> void:
	for a in [parts, rings, ghosts, slashes, lines, bolts, columns, stars, puffs, texts, pickups, ovals, echo]:
		a.clear()


func _process(delta: float) -> void:
	var dt := delta * speed
	for p in parts:
		p.v.y += p.g * dt
		p.v *= maxf(0.0, 1.0 - p.d * dt)
		p.p += p.v * dt
		p.l -= dt
	parts = parts.filter(func(p): return p.l > 0.0)
	for e in puffs:
		e.p += e.v * dt
		e.v *= maxf(0.0, 1.0 - 2.5 * dt)
	for e in texts:
		e.p.y -= 22.0 * dt
	for e in echo:
		e.t -= dt
		if e.t <= 0.0:
			star(e.p, Color.WHITE, 0.14, 4)
			ring(e.p, 3, 22, 0.2, e.c, 1)
	echo = echo.filter(func(e): return e.t > 0.0)
	for sl in slashes:
		var k: float = 1.0 - sl.l / sl.m
		if k < 0.5 and randf() < 0.6:
			var head: float = lerpf(sl.a0, sl.a1, minf(1.0, _ease(k * 2.2)))
			var hp: Vector2 = sl.p + Vector2.from_angle(head) * sl.r
			parts.append({"p": hp, "v": Vector2.from_angle(head + PI / 2.0 * signf(sl.a1 - sl.a0)) * randf_range(40, 110),
				"l": 0.18, "m": 0.18, "c": Color.WHITE if randf() < 0.5 else sl.c, "s": 1, "g": 0.0, "d": 5.0, "streak": true})
	for arr in [rings, ghosts, slashes, lines, bolts, columns, stars, puffs, texts, ovals]:
		for e in arr:
			e.l -= dt
	rings = rings.filter(func(e): return e.l > 0.0)
	ghosts = ghosts.filter(func(e): return e.l > 0.0)
	slashes = slashes.filter(func(e): return e.l > 0.0)
	lines = lines.filter(func(e): return e.l > 0.0)
	bolts = bolts.filter(func(e): return e.l > 0.0)
	columns = columns.filter(func(e): return e.l > 0.0)
	stars = stars.filter(func(e): return e.l > 0.0)
	puffs = puffs.filter(func(e): return e.l > 0.0)
	texts = texts.filter(func(e): return e.l > 0.0)
	ovals = ovals.filter(func(e): return e.l > 0.0)
	queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for c in columns:
		var a := 0.12 + 0.12 * absf(sin(t * 18.0))
		draw_rect(Rect2(roundf(c.x) - 7, 0, 14, 216), Color(1, 0.85, 0.3, a))
		for y in range(0, 216, 6):
			draw_rect(Rect2(roundf(c.x) - 7, y, 1, 3), Color(1, 0.9, 0.4, 0.6))
			draw_rect(Rect2(roundf(c.x) + 6, y, 1, 3), Color(1, 0.9, 0.4, 0.6))
	for pf in puffs:
		var k: float = 1.0 - pf.l / pf.m
		var r: float = lerpf(pf.r0, pf.r1, 1.0 - pow(1.0 - k, 2.0))
		var c: Color = pf.c
		draw_circle(pf.p.round(), r, Color(c, c.a * (1.0 - k)))
		draw_circle((pf.p + Vector2(-r * 0.3, -r * 0.3)).round(), r * 0.45, Color(c.lightened(0.25), c.a * (1.0 - k) * 0.8))
	for g in ghosts:
		var k: float = g.l / g.m
		draw_set_transform_matrix(g.x)
		draw_texture(g.t, g.o, Color(g.c, 0.55 * k))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	for sl in slashes:
		var k: float = 1.0 - sl.l / sl.m
		var head: float = lerpf(sl.a0, sl.a1, minf(1.0, _ease(k * 2.2)))
		var tail: float = lerpf(sl.a0, sl.a1, clampf(_ease(k * 2.2) - 0.55 - k * 0.4, 0.0, 1.0))
		var w: float = sl.w
		var n := 22
		for j in n + 1:
			var u := float(j) / n
			var a := lerpf(tail, head, u)
			var thick := maxf(1.0, w * sin(u * PI * 0.92 + 0.08) * (1.0 - k * 0.6))
			for rr in range(0, int(thick) + 1):
				var r: float = sl.r - rr
				var pp: Vector2 = (sl.p + Vector2.from_angle(a) * r).round()
				var c: Color = Color.WHITE
				if rr == 0:
					c = Color(sl.c.lightened(0.5))
				elif rr >= int(thick):
					c = sl.c
				if u < 0.25 and (int(pp.x) + int(pp.y)) % 2 == 0:
					continue
				draw_rect(Rect2(pp, Vector2.ONE), c)
	for ov in ovals:
		var k: float = 1.0 - ov.l / ov.m
		var r: float = lerpf(2.0, ov.r1, 1.0 - pow(1.0 - k, 2.0))
		var nn: Vector2 = ov.n
		var steps := maxi(14, int(r * 5.0))
		for j in steps:
			var a := j * TAU / steps
			var q := nn * cos(a) * r * 0.45 + nn.orthogonal() * sin(a) * r
			draw_rect(Rect2((ov.p + q).round(), Vector2.ONE * (2.0 if k < 0.5 else 1.0)), Color(ov.c, 1.0 - k * 0.5))
	for l in lines:
		var k: float = l.l / l.m
		draw_line(l.a.round(), l.a.lerp(l.b, k).round(), l.c, l.w)
	for r in rings:
		var k: float = 1.0 - r.l / r.m
		var rad: float = lerpf(r.r0, r.r1, 1.0 - pow(1.0 - k, 2.0))
		var steps := maxi(12, int(rad * 5.0))
		for j in steps:
			var pp: Vector2 = (r.p + Vector2.from_angle(j * TAU / steps) * rad).round()
			draw_rect(Rect2(pp, Vector2.ONE * (r.w if k < 0.6 else 1)), r.c)
	for b in bolts:
		var pts: PackedVector2Array = b.pts
		for j in pts.size() - 1:
			draw_line(pts[j], pts[j + 1], Color("9ad8ff"), 4.0)
		for j in pts.size() - 1:
			draw_line(pts[j], pts[j + 1], Color.WHITE, 2.0)
	for q in pickups:
		var p: Vector2 = q.round()
		var pulse := 1.0 + 0.5 * sin(t * 8.0 + p.x)
		draw_circle(p, 6.0 + pulse, Color(1, 0.95, 0.6, 0.25))
		for k in 5:
			var ang := -PI / 2.0 + k * TAU / 5.0
			draw_line(p, (p + Vector2.from_angle(ang) * 5.0).round(), Pix.GOLD, 2.0)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Color.WHITE)
	for o in orbs:
		var p: Vector2 = o.p.round()
		var pulse := 1.0 if int(t * 20.0) % 2 == 0 else 0.0
		draw_circle(p, 4.0 + pulse, Color(o.c, 0.5))
		draw_circle(p, 3.0, o.c)
		draw_circle(p, 1.5, Color.WHITE)
	for st in stars:
		var k: float = st.l / st.m
		var arm := roundf(st.s * sin(k * PI) * 2.0)
		var p: Vector2 = st.p.round()
		var c: Color = st.c
		draw_rect(Rect2(p - Vector2(arm, 0), Vector2(arm * 2 + 1, 1)), c)
		draw_rect(Rect2(p - Vector2(0, arm), Vector2(1, arm * 2 + 1)), c)
		if arm >= 3:
			var d := roundf(arm * 0.45)
			for q in [Vector2(d, d), Vector2(-d, d), Vector2(d, -d), Vector2(-d, -d)]:
				draw_rect(Rect2(p + q, Vector2.ONE), Color(c, 0.7))
		draw_rect(Rect2(p - Vector2.ONE, Vector2(3, 3)) if arm >= 2 else Rect2(p, Vector2.ONE), Color.WHITE)
	for tx in texts:
		var k: float = tx.l / tx.m
		var a := 1.0 if k > 0.3 else k / 0.3
		var sc: int = tx.k + (1 if k > 0.85 else 0)
		Pix.draw_text_c(self, tx.p.x, tx.p.y, tx.s, Color(tx.c, a), sc, Color(Pix.INK, a))
	for p in parts:
		if p.has("streak"):
			var tail_p: Vector2 = p.p - p.v * 0.035
			draw_line(tail_p.round(), p.p.round(), p.c, 1.0)
			continue
		var k: float = p.l / p.m
		var s: float = maxf(1.0, ceilf(p.s * minf(1.0, k * 1.6)))
		draw_rect(Rect2(p.p.round(), Vector2(s, s)), p.c)
