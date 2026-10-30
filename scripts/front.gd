class_name TarotFront
## Lo que se ve antes de jugar: la intro del estudio WAS. (las letras entran una a una y una máquina las encaja),
## la portada (JUGAR / AJUSTES / SALIR, con Discord y opinión abajo a la derecha) y los menús de JUGAR y
## AJUSTES con aire de Persona 5: rojo, negro, cortes en diagonal y la opción elegida en una placa que salta.

const STUDIO := "WAS."
const RED := Color("e0233c")
const RED_D := Color("8c0f22")
const BLACK := Color("0e0a12")
const BLURPLE := Color("5865f2")
const METAL := Color("e8dcc0")
const METAL_HI := Color("fbefd5")
const METAL_SH := Color("a8916c")
const STEEL := Color("4a4458")
const STEEL_HI := Color("8a84a0")

## Letras gordas del logo, 7x7 celdas.
const BIG := {
	"W": ["##...##", "##...##", "##...##", "##.#.##", "##.#.##", "#######", ".##.##."],
	"A": [".#####.", "##...##", "##...##", "#######", "##...##", "##...##", "##...##"],
	"F": ["#######", "##.....", "##.....", "#####..", "##.....", "##.....", "##....."],
	"S": [".######", "##.....", "##.....", ".#####.", ".....##", ".....##", "######."],
	"U": ["##...##", "##...##", "##...##", "##...##", "##...##", "##...##", ".#####."],
}
const CELL := 10
const INTRO_LEN := 4.1
## [instante, sonido] de la intro
const INTRO_SFX := [[0.12, "servo"], [0.6, "clunk"], [1.05, "clunk"], [1.5, "clunk"], [1.62, "servo"], [1.9, "clank"], [1.98, "clunk"], [2.3, "rivet"], [2.55, "ding"]]
const SLAM := 1.9
const DOT_T := 2.3

const ICON_DISCORD := [
	"...##....##...",
	"..##########..",
	".############.",
	".############.",
	"###..####..###",
	"###..####..###",
	"##############",
	"##############",
	".####....####.",
	"..##......##..",
]
const ICON_FEEDBACK := [
	".############.",
	"##############",
	"######..######",
	"######..######",
	"######..######",
	"##############",
	"######..######",
	".############.",
	"...###........",
	"..##..........",
	".#............",
]


# --- Intro del estudio ---

static func _letters() -> String:
	return STUDIO.replace(".", "")


static func _on(g: Array, x: int, y: int) -> bool:
	return y >= 0 and y < g.size() and x >= 0 and x < String(g[y]).length() and String(g[y])[x] == "#"


## Instante en que entra la letra i y desde dónde viene (izquierda, arriba, derecha...).
static func _letter_in(i: int) -> float:
	return 0.35 + 0.45 * i


static func intro(ci: CanvasItem, t: float) -> void:
	ci.draw_rect(Rect2(0, 0, 640, 360), BLACK)
	var letters := _letters()
	var nl := letters.length()
	var lw := 7 * CELL
	var gap := 8
	var has_dot := STUDIO.ends_with(".")
	var total := nl * lw + (nl - 1) * gap + (gap + 2 * CELL if has_dot else 0)
	var x0 := 320 - total / 2
	var y0 := 130
	# Temblor en cada golpe de la máquina
	var sh := 0.0
	for e in [[0.6, 1.5], [1.05, 1.5], [1.5, 1.5], [SLAM, 5.0], [DOT_T, 2.0]]:
		var d: float = t - e[0]
		if d >= 0.0 and d < 0.25:
			sh = maxf(sh, e[1] * (1.0 - d / 0.25))
	ci.draw_set_transform(Vector2(roundf(sin(t * 90.0) * sh), roundf(cos(t * 71.0) * sh * 0.6)), 0.0, Vector2.ONE)
	# Raíl por el que corren las letras, con marcas que se desplazan como una cinta
	var rail_y := y0 + lw + 8
	var rk := clampf((t - 0.05) / 0.3, 0.0, 1.0) * (1.0 - clampf((t - 2.6) / 0.4, 0.0, 1.0))
	if rk > 0.0:
		var rw := 380.0 * rk
		ci.draw_rect(Rect2(320 - rw / 2.0, rail_y, rw, 4), STEEL)
		ci.draw_rect(Rect2(320 - rw / 2.0, rail_y, rw, 1), STEEL_HI)
		var run := fmod(t * 160.0, 12.0) if t < SLAM else 0.0
		var x := 320 - rw / 2.0 + run
		while x < 320 + rw / 2.0:
			ci.draw_rect(Rect2(roundf(x), rail_y + 5, 2, 3), Color(STEEL, 0.8))
			x += 12.0
	# Posición de cada letra: entra hasta su sitio separada y luego el golpe las junta
	var spread_k := clampf((t - 1.75) / (SLAM - 1.75), 0.0, 1.0)
	spread_k *= spread_k
	var pos: Array = []
	for i in nl:
		var fx := float(x0 + i * (lw + gap))
		var spread := (i - (nl - 1) / 2.0) * 26.0 * (1.0 - spread_k)
		var dest := Vector2(fx + spread, y0)
		var k := clampf((t - _letter_in(i)) / 0.25, 0.0, 1.0)
		k *= k  # acelera hasta el tope, como una pieza empujada
		var from := dest
		match i % 3:
			0:
				from = Vector2(-lw - 30, y0)
			1:
				from = Vector2(dest.x, -lw - 30)
			2:
				from = Vector2(670, y0)
		pos.append(from.lerp(dest, k).round() if t >= _letter_in(i) else Vector2(-999, -999))
	# Pistones que empujan las letras de los extremos para encajarlas
	if t > 1.6 and t < 2.2 and nl > 1:
		var reach := clampf((t - 1.6) / 0.15, 0.0, 1.0) * (1.0 - clampf((t - 1.98) / 0.2, 0.0, 1.0))
		var py := y0 + lw / 2 - 5
		var lt: float = lerpf(0.0, pos[0].x - 2.0, reach)
		_rod(ci, Rect2(0, py, lt, 10), true)
		var rt: float = lerpf(640.0, pos[nl - 1].x + lw + 2.0, reach)
		_rod(ci, Rect2(rt, py, 640.0 - rt, 10), false)
	# Brillo que cruza el logo cuando ya está montado
	var shine := -999.0
	if t > 2.5 and t < 2.95:
		shine = lerpf(x0 - 60.0, x0 + total + 60.0, (t - 2.5) / 0.45)
	for i in nl:
		if pos[i].x > -900:
			_big(ci, letters[i], pos[i], shine)
	# Grapas de acero que unen las letras justo después del golpe
	if t > SLAM:
		var gk := clampf((t - SLAM - 0.04) / 0.08, 0.0, 1.0)
		for i in nl - 1:
			var gx := x0 + (i + 1) * (lw + gap) - gap / 2.0
			var gl: Array = BIG.get(letters[i], BIG["A"])
			var gr: Array = BIG.get(letters[i + 1], BIG["A"])
			for cands in [[1, 2, 0], [5, 6, 4]]:
				# La grapa va en una fila donde las dos letras tienen chapa en el borde
				var row := -1
				for c in cands:
					if _on(gl, 6, c) and _on(gr, 0, c):
						row = c
						break
				if row < 0:
					continue
				var w := (gap + 12.0) * gk
				var r := Rect2(roundf(gx - w / 2.0), y0 + row * CELL + 2, roundf(w), 6)
				if w > 0.5:
					ci.draw_rect(r.grow(1), Pix.INK)
					ci.draw_rect(r, STEEL)
					ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 1)), STEEL_HI)
					if gk >= 1.0:
						ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(2, 2)), STEEL_HI)
						ci.draw_rect(Rect2(r.end - Vector2(4, 4), Vector2(2, 2)), STEEL_HI)
	# El punto cae como un remache
	if has_dot and t >= DOT_T - 0.18:
		var dk := clampf((t - (DOT_T - 0.18)) / 0.18, 0.0, 1.0)
		dk *= dk
		var dx := x0 + nl * (lw + gap)
		var dy := lerpf(-40.0, y0 + 5 * CELL, dk)
		_dot(ci, Vector2(dx, roundf(dy)), shine)
	# Chispas del encaje entre letras y del remache
	var seams: Array = []
	for i in nl - 1:
		seams.append([Vector2(x0 + (i + 1) * (lw + gap) - gap / 2.0, y0 + lw / 2.0), SLAM])
	if has_dot:
		seams.append([Vector2(x0 + nl * (lw + gap) + CELL, y0 + 7 * CELL), DOT_T])
	for s in seams:
		var d: float = t - s[1]
		if d < 0.0 or d > 0.6:
			continue
		for j in 14:
			var h := fposmod(sin(j * 12.9898 + s[0].x) * 43758.5453, 1.0)
			var h2 := fposmod(sin(j * 78.233 + s[0].y) * 12543.13, 1.0)
			var a := -PI / 2.0 + (h - 0.5) * 2.6
			var v := Vector2(cos(a), sin(a)) * (90.0 + h2 * 140.0)
			var p: Vector2 = s[0] + v * d + Vector2(0, 260.0 * d * d)
			var c := Pix.GOLD.lerp(Color("ff7a2a"), d / 0.6)
			ci.draw_rect(Rect2(p.round(), Vector2(2, 2)), Color(c, 1.0 - d / 0.6))
	# Vapor bajo cada letra al frenar en seco
	for i in nl:
		var d := t - (_letter_in(i) + 0.25)
		if d > 0.0 and d < 0.5 and pos[i].x > -900:
			for side in [-1, 1]:
				var c := Vector2(pos[i].x + lw / 2.0 + side * (lw / 2.0 + d * 30.0), rail_y - 2 - d * 10.0)
				ci.draw_circle(c, 3.0 + d * 12.0, Color(METAL_HI, 0.35 * (1.0 - d / 0.5)))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if t > 2.75:
		Pix.draw_text_c(ci, 320, y0 + lw + 26, "PRESENTA", Color(METAL, clampf((t - 2.75) / 0.4, 0.0, 1.0) * 0.7))
	if t > 3.5:
		ci.draw_rect(Rect2(0, 0, 640, 360), Color(BLACK, clampf((t - 3.5) / 0.5, 0.0, 1.0)))


static func _rod(ci: CanvasItem, r: Rect2, left: bool) -> void:
	if r.size.x <= 0.0:
		return
	ci.draw_rect(r, STEEL)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), STEEL_HI)
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 2), Vector2(r.size.x, 2)), Pix.INK)
	# Cabeza del pistón
	var hx := r.end.x - 6 if left else r.position.x
	ci.draw_rect(Rect2(hx, r.position.y - 7, 6, 24), STEEL)
	ci.draw_rect(Rect2(hx, r.position.y - 7, 6, 2), STEEL_HI)
	ci.draw_rect(Rect2(hx + (4 if left else 0), r.position.y - 7, 2, 24), Pix.INK)


## Letra de chapa: contorno de tinta, sombra, bisel por celdas, juntas de panel y remaches.
static func _big(ci: CanvasItem, ch: String, pos: Vector2, shine: float) -> void:
	var g: Array = BIG.get(ch, BIG["A"])
	for gy in 7:
		for gx in 7:
			if _on(g, gx, gy):
				ci.draw_rect(Rect2(pos + Vector2(gx, gy) * CELL + Vector2(5, 6), Vector2(CELL, CELL)), Color(0, 0, 0, 0.55))
	for gy in 7:
		for gx in 7:
			if _on(g, gx, gy):
				ci.draw_rect(Rect2(pos + Vector2(gx, gy) * CELL, Vector2(CELL, CELL)).grow(2), Pix.INK)
	for gy in 7:
		for gx in 7:
			if not _on(g, gx, gy):
				continue
			var r := Rect2(pos + Vector2(gx, gy) * CELL, Vector2(CELL, CELL))
			var lit := absf(r.position.x + gy * CELL * 0.6 - shine) < 9.0
			ci.draw_rect(r, METAL_HI if lit else METAL)
			if not _on(g, gx, gy - 1):
				ci.draw_rect(Rect2(r.position, Vector2(CELL, 2)), METAL_HI)
			if not _on(g, gx - 1, gy):
				ci.draw_rect(Rect2(r.position, Vector2(1, CELL)), METAL_HI)
			if not _on(g, gx, gy + 1):
				ci.draw_rect(Rect2(r.position + Vector2(0, CELL - 3), Vector2(CELL, 3)), METAL_SH)
			if not _on(g, gx + 1, gy):
				ci.draw_rect(Rect2(r.position + Vector2(CELL - 2, 0), Vector2(2, CELL)), METAL_SH)
			if gx % 2 == 1 and _on(g, gx + 1, gy):
				ci.draw_rect(Rect2(r.position + Vector2(CELL - 1, 2), Vector2(1, CELL - 4)), Color(METAL_SH, 0.7))
			if gy % 3 == 2 and _on(g, gx, gy + 1):
				ci.draw_rect(Rect2(r.position + Vector2(2, CELL - 1), Vector2(CELL - 4, 1)), Color(METAL_SH, 0.7))
			if (gx * 3 + gy * 5) % 7 == 0:
				ci.draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(2, 2)), METAL_SH)


static func _dot(ci: CanvasItem, p: Vector2, shine: float) -> void:
	var r := Rect2(p, Vector2(CELL * 2, CELL * 2))
	ci.draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.55))
	ci.draw_rect(r.grow(2), Pix.INK)
	ci.draw_rect(r, Pix.GOLD.lightened(0.3) if absf(p.x - shine) < 12.0 else Pix.GOLD)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Pix.GOLD.lightened(0.4))
	ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y - 3), Vector2(r.size.x, 3)), Pix.GOLD_D)
	ci.draw_rect(Rect2(r.end.x - 2, r.position.y, 2, r.size.y), Pix.GOLD_D)
	ci.draw_rect(Rect2(r.position + Vector2(8, 8), Vector2(4, 4)), Pix.GOLD_D)


# --- Portada ---

static func title(ci: CanvasItem, g: Node, t: float) -> void:
	var mt: float = g.menu_t
	var open := 1.0 - pow(1.0 - clampf(mt / 0.7, 0.0, 1.0), 3.0)
	var cards := [21, 0, 1, Deck.minor(3, 1), Deck.minor(1, 14)]
	for k in cards.size():
		var tex: Texture2D = Deck.texture(cards[k])
		var a := ((k - 2) * 0.22 + sin(t * 1.2 + k) * 0.03) * open
		var p := Vector2(320 + (k - 2) * 46 * open, 150 + absf(k - 2) * 8 * open + sin(t * 2.0 + k) * 2.0)
		ci.draw_set_transform(p, a, Vector2.ONE)
		ci.draw_rect(Rect2(-33, -51, 70, 108), Color(0, 0, 0, 0.35))
		ci.draw_texture(tex, Vector2(-35, -54))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ci.draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.45))
	# Título: cae de arriba con rebote
	var tk := clampf(mt / 0.55, 0.0, 1.0)
	var bounce := 1.0 + 2.70158 * pow(tk - 1.0, 3) + 1.70158 * pow(tk - 1.0, 2)
	Pix.draw_text_c(ci, 320, roundf(lerpf(-60.0, 22.0, bounce)), "TAROT", Pix.GOLD, 6, Pix.INK, 2.0, t)
	Pix.draw_text_c(ci, 320, roundf(lerpf(-20.0, 70.0, bounce)), "DE ARCANOS", Pix.CREAM, 2)
	# Opciones
	var rects: Array = []
	var items: Array = g.menu_items
	for i in 3:
		var ik := 1.0 - pow(1.0 - clampf((mt - 0.25 - i * 0.08) / 0.3, 0.0, 1.0), 3.0)
		var y := roundf(232 + i * 30 + (1.0 - ik) * 60.0)
		var label: String = items[i][1]
		var sel: bool = g.menu_sel == i
		var w := Pix.text_width(label, 2)
		if sel:
			var pl := Rect2(320 - w / 2.0 - 30, y - 6, w + 60, 26)
			ci.draw_colored_polygon(PackedVector2Array([pl.position + Vector2(8, 0), Vector2(pl.end.x, pl.position.y),
				pl.end - Vector2(8, 0), Vector2(pl.position.x, pl.end.y)]), Color(Pix.PURPLE, 0.95))
			var bob := roundf(sin(t * 8.0) * 2.0)
			Pix.draw_text(ci, Vector2(320 - w / 2.0 - 20 + bob, y + 3), ">", Pix.GOLD)
			Pix.draw_text(ci, Vector2(320 + w / 2.0 + 14 - bob, y + 3), "<", Pix.GOLD)
		Pix.draw_text_c(ci, 320, y, label, Pix.GOLD if sel else Color(Pix.CREAM, 0.8), 2)
		rects.append(Rect2(320 - w / 2.0 - 30, y - 6, w + 60, 26))
	# Discord y opinión abajo a la derecha
	var ib := [Rect2(578, 326, 24, 24), Rect2(608, 326, 24, 24)]
	for k in 2:
		var r: Rect2 = ib[k]
		var sel: bool = g.menu_sel == 3 + k
		var lift := -2.0 if sel else 0.0
		r.position.y += lift
		ci.draw_rect(r.grow(1), Pix.INK)
		ci.draw_rect(r, Pix.GOLD if sel else Color("2a1c40"))
		ci.draw_rect(r.grow(-2), Color("1e1236"))
		if k == 0:
			_icon(ci, ICON_DISCORD, r.get_center() - Vector2(7, 5), BLURPLE)
		else:
			_icon(ci, ICON_FEEDBACK, r.get_center() - Vector2(7, 6), Pix.GOLD)
		rects.append(r)
		if sel:
			var tip: String = "SERVIDOR DE DISCORD" if k == 0 else "ENVIAR OPINION"
			Pix.draw_text(ci, Vector2(632 - Pix.text_width(tip), 312), tip, Pix.CREAM)
	g.menu_rects = rects
	Pix.draw_text(ci, Vector2(10, 342), "✕ ELEGIR", Color(Pix.CREAM, 0.7))


static func _icon(ci: CanvasItem, rows: Array, at: Vector2, col: Color) -> void:
	at = at.round()
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				ci.draw_rect(Rect2(at + Vector2(x, y), Vector2.ONE), col)


# --- Menús de JUGAR y AJUSTES (estilo Persona 5) ---

static func _slant(ci: CanvasItem, r: Rect2, col: Color, sl := 10.0) -> void:
	ci.draw_colored_polygon(PackedVector2Array([r.position + Vector2(sl, 0), Vector2(r.end.x, r.position.y),
		r.end - Vector2(sl, 0), Vector2(r.position.x, r.end.y)]), col)


## items: [[id, texto]]; descs: textos de abajo; cards: carta de cada opción.
static func p5_menu(ci: CanvasItem, g: Node, t: float, header: String, descs: Array, cards: Array) -> void:
	var mt: float = g.menu_t
	var items: Array = g.menu_items
	var sel_i: int = g.menu_sel
	ci.draw_rect(Rect2(0, 0, 640, 360), BLACK)
	# Rayos que giran detrás de la carta
	var c0 := Vector2(500, 160)
	for i in 18:
		if i % 2 == 1:
			continue
		var a := i * TAU / 18.0 + t * 0.12
		ci.draw_colored_polygon(PackedVector2Array([c0, c0 + Vector2(cos(a), sin(a)) * 700.0, c0 + Vector2(cos(a + 0.2), sin(a + 0.2)) * 700.0]), Color(RED_D, 0.45))
	# Losa roja en diagonal con semitono
	var slab := PackedVector2Array([Vector2(0, 0), Vector2(320, 0), Vector2(230, 360), Vector2(0, 360)])
	ci.draw_colored_polygon(slab, RED)
	for y in range(4, 360, 8):
		var edge := 320.0 - y * 90.0 / 360.0
		for x in range(4, int(edge) - 4, 8):
			var s := 1 + int(x / 110.0)
			ci.draw_rect(Rect2(x - s / 2, y - s / 2, s, s), RED_D)
	ci.draw_line(Vector2(320, 0), Vector2(230, 360), Pix.INK, 3.0)
	# Cabecera
	var hw := Pix.text_width(header, 4)
	_slant(ci, Rect2(10, 10, hw + 46, 42), Pix.INK, 12)
	_slant(ci, Rect2(16, 14, hw + 34, 34), Pix.CREAM, 10)
	Pix.draw_text(ci, Vector2(34, 18), header, BLACK, 4, Color(0, 0, 0, 0))
	# Opciones en escalera
	var rects: Array = []
	for i in items.size():
		var k := 1.0 - pow(1.0 - clampf((mt - 0.06 * i) / 0.22, 0.0, 1.0), 3.0)
		var x := roundf(26 + i * 10 - (1.0 - k) * 340.0)
		var y := (72 + i * (38 if items.size() <= 6 else 35)) if items.size() <= 7 else 62 + i * 30
		var sel := i == sel_i
		var label: String = items[i][1]
		var w := Pix.text_width(label, 2)
		if sel:
			var jit := Vector2(roundf(sin(t * 13.0)), roundf(cos(t * 11.0)))
			var pr := Rect2(x - 6 + jit.x, y - 2 + jit.y, w + 50, 32)
			_slant(ci, Rect2(pr.position + Vector2(7, 5), pr.size), Pix.INK, 12)
			_slant(ci, pr.grow(2), Pix.INK, 12)
			_slant(ci, pr, Pix.CREAM, 12)
			Pix.draw_text(ci, Vector2(x + 18 + jit.x, y + 8 + jit.y), label, BLACK, 2, Color(0, 0, 0, 0))
			# Flecha que entra y sale
			var ax := x - 16 + roundf(sin(t * 9.0) * 3.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(ax - 8, y + 4), Vector2(ax + 6, y + 14), Vector2(ax - 8, y + 24)]), Pix.INK)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(ax - 6, y + 8), Vector2(ax + 2, y + 14), Vector2(ax - 6, y + 20)]), Pix.CREAM)
		else:
			_slant(ci, Rect2(x, y + 3, w + 30, 24), BLACK, 8)
			Pix.draw_text(ci, Vector2(x + 14, y + 8), label, Color(Pix.CREAM, 0.75), 2)
		rects.append(Rect2(x - 6, y - 2, w + 56, 32))
	g.menu_rects = rects
	# Carta de la opción elegida: gira al cambiar y se balancea
	if sel_i < cards.size() and cards[sel_i] >= 0:
		var st: float = g.sel_t
		var pk := clampf(st / 0.25, 0.0, 1.0)
		var sx := absf(cos((1.0 - pk) * PI * 0.5 * 2.0)) if pk < 1.0 else 1.0
		var rot := -0.1 + sin(t * 1.3) * 0.03
		var cp := Vector2(486, 150 + sin(t * 1.7) * 3.0)
		ci.draw_set_transform(cp + Vector2(12, 10), rot, Vector2(2.0 * maxf(sx, 0.05), 2.0))
		ci.draw_rect(Rect2(-35, -54, 70, 108), Pix.INK)
		ci.draw_set_transform(cp, rot, Vector2(2.0 * maxf(sx, 0.05), 2.0))
		ci.draw_rect(Rect2(-37, -56, 74, 112), RED)
		ci.draw_texture(Deck.texture(cards[sel_i]), Vector2(-35, -54))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Descripción abajo a la derecha
	if sel_i < descs.size():
		var lines := wrap_lines(descs[sel_i], 46)
		var bh := 14 + lines.size() * 11
		_slant(ci, Rect2(296, 346 - bh, 336, bh), Pix.INK, 12)
		_slant(ci, Rect2(300, 349 - bh, 326, bh - 6), BLACK, 10)
		for li in lines.size():
			Pix.draw_text(ci, Vector2(318, 353 - bh + li * 11), lines[li], Pix.CREAM)
	Pix.draw_text(ci, Vector2(12, 344), "✕ ELEGIR   ○ VOLVER", Pix.CREAM)
	# Corte de entrada: una cuchillada negra cruza la pantalla
	if mt < 0.3:
		var wk := mt / 0.3
		var cx := lerpf(-200.0, 900.0, wk)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx, 0), Vector2(cx + 700, 0), Vector2(cx + 560, 360), Vector2(cx - 140, 360)]), Pix.INK)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx - 30, 0), Vector2(cx, 0), Vector2(cx - 140, 360), Vector2(cx - 170, 360)]), RED)


## Pantalla de personaje: el bufón grande sobre un pedestal, que respira, parpadea y salta al cambiar algo.
static func look_preview(ci: CanvasItem, g: Node, t: float) -> void:
	var lk: Dictionary = g.cfg.look
	var st: float = g.sel_t
	var hop := -absf(sin(minf(st, 0.35) / 0.35 * PI)) * 14.0 if st < 0.35 else 0.0
	var pose := "idle0"
	if fmod(t, 3.2) > 3.05:
		pose = "blink"
	elif int(t * 1.6) % 2 == 1:
		pose = "idle1"
	var c := Vector2(480, 168)
	# Pedestal
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-70, 52), c + Vector2(70, 52), c + Vector2(56, 70), c + Vector2(-56, 70)]), Pix.INK)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-66, 50), c + Vector2(66, 50), c + Vector2(54, 64), c + Vector2(-54, 64)]), RED)
	ci.draw_rect(Rect2(c + Vector2(-60, 50), Vector2(120, 2)), Color("ff6a7a"))
	var sh := 1.0 - minf(1.0, -hop / 20.0)
	ci.draw_rect(Rect2(c + Vector2(-30 * sh, 47), Vector2(60 * sh, 4)), Color(0, 0, 0, 0.45))
	# Muñeco a escala entera
	var tex := Pix.doll(lk, pose)
	ci.draw_texture_rect(tex, Rect2((c + Vector2(-54, -82 + hop)).round(), Vector2(108, 132)), false)
	# Retrato tal como se verá en la mesa
	var pr := Rect2(560, 64, 54, 46)
	_slant(ci, pr.grow(3), Pix.INK, 6)
	_slant(ci, pr, Pix.CREAM, 6)
	ci.draw_texture_rect(Pix.portrait_look(lk), Rect2(pr.position + Vector2(9, 5), Vector2(36, 28)), false)
	Pix.draw_text_c(ci, pr.get_center().x, pr.end.y - 10, "MESA", BLACK, 1, Color(0, 0, 0, 0))
	var nm: String = g.my_name()
	Pix.draw_text_c(ci, c.x, c.y + 76, nm, Pix.PLAYERS[int(lk.color) % Pix.PLAYERS.size()].c1[0], 2)


static func wrap_lines(text: String, width: int) -> Array:
	var out: Array = []
	var cur := ""
	for w in text.split(" ", false):
		if cur == "":
			cur = w
		elif (cur + " " + w).length() <= width:
			cur += " " + w
		else:
			out.append(cur)
			cur = w
	if cur != "":
		out.append(cur)
	return out
