class_name TarotGuide
extends RefCounted
## «Cómo se juega»: siete páginas con cartas de verdad y pequeñas demostraciones animadas que se repiten.

const PAGES := 7


static func draw(ci: CanvasItem, page: int, gt: float, t: float) -> void:
	ci.draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.55))
	var r := Rect2(40, 20, 560, 310)
	_box(ci, r, Color("1e1236", 0.96), Pix.GOLD)
	match page:
		0: _p_goal(ci, gt, t)
		1: _p_cards(ci, gt, t)
		2: _p_trick(ci, gt, t)
		3: _p_trump(ci, gt, t)
		4: _p_fool(ci, gt, t)
		5: _p_bid(ci, gt, t)
		6: _p_points(ci, gt, t)
	# Puntos de página y botones
	for i in PAGES:
		var c := Pix.GOLD if i == page else Color("4a3a6a")
		ci.draw_rect(Rect2(320 - PAGES * 6 + i * 12, 312, 6 if i == page else 4, 4), c)
	Pix.draw_text_c(ci, 320, 340, "IZQ/DER PASAR PAGINA   ✕ SIGUIENTE   ○ VOLVER", Pix.CREAM)


static func _box(ci: CanvasItem, r: Rect2, fill: Color, edge: Color) -> void:
	var o := r.grow(1)
	ci.draw_rect(Rect2(o.position + Vector2(1, 0), o.size - Vector2(2, 0)), Pix.INK)
	ci.draw_rect(Rect2(o.position + Vector2(0, 1), o.size - Vector2(0, 2)), Pix.INK)
	ci.draw_rect(Rect2(r.position + Vector2(1, 0), r.size - Vector2(2, 0)), edge)
	ci.draw_rect(Rect2(r.position + Vector2(0, 1), r.size - Vector2(0, 2)), edge)
	ci.draw_rect(r.grow(-1), fill)


static func _title(ci: CanvasItem, s: String, t: float) -> void:
	Pix.draw_text_c(ci, 320, 32, s, Pix.GOLD, 2, Pix.INK, 1.0, t)


static func _lines(ci: CanvasItem, y: float, lines: Array, col := Pix.CREAM) -> void:
	for i in lines.size():
		Pix.draw_text_c(ci, 320, y + i * 12, lines[i], col)


## Carta en (pos) con escala y giro; `pop` hace que entre con rebote.
static func _card(ci: CanvasItem, c: int, pos: Vector2, sc: float, rot := 0.0, glow := 0.0) -> void:
	ci.draw_set_transform(pos, rot, Vector2(sc, sc))
	ci.draw_rect(Rect2(-33, -51, 70, 108), Color(0, 0, 0, 0.35))
	if glow > 0.0:
		for k in 3:
			ci.draw_rect(Rect2(-36 - k * 2, -55 - k * 2, 72 + k * 4, 110 + k * 4), Color(Pix.GOLD, glow * (0.4 - k * 0.12)), false, 2.0)
	ci.draw_texture(Deck.texture(c) if c >= 0 else Deck.back(), Vector2(-35, -54))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _ease_back(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	var c1 := 1.70158
	return 1.0 + (c1 + 1.0) * pow(x - 1.0, 3.0) + c1 * pow(x - 1.0, 2.0)


static func _p_goal(ci: CanvasItem, gt: float, t: float) -> void:
	_title(ci, "EL OBJETIVO", t)
	_lines(ci, 62, ["EN CADA MANO UN JUGADOR APUESTA Y JUEGA SOLO CONTRA LOS DEMAS.",
		"SI CONSIGUE LOS PUNTOS QUE NECESITA, GANA Y LOS DEMAS LE PAGAN.",
		"SI NO LLEGA, PAGA EL A TODOS. LOS DEMAS JUEGAN JUNTOS PARA HUNDIRLE."])
	# El que apuesta (dorado) contra tres
	var cx := 320.0
	for i in 4:
		var ang := -PI / 2.0 + i * TAU / 4.0 + PI
		var p := Vector2(cx, 200) + Vector2(cos(ang) * 120, sin(ang) * 56)
		var taker := i == 0
		var bob := sin(t * 3.0 + i) * 2.0
		ci.draw_set_transform(p + Vector2(0, bob), 0.0, Vector2(3, 3))
		ci.draw_texture(Pix.portrait(i), Vector2(-8, -6))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Pix.draw_text_c(ci, p.x, p.y + 22, "EL QUE APUESTA" if taker else "DEFENSA", Pix.GOLD if taker else Color("7ab8ff"))
	var k := fmod(gt, 2.0) / 2.0
	Pix.draw_text_c(ci, cx, 192, "CONTRA", Color("ff8a9a"), 2 if k < 0.5 else 1)


static func _p_cards(ci: CanvasItem, gt: float, t: float) -> void:
	_title(ci, "LAS 78 CARTAS", t)
	_lines(ci, 58, ["CUATRO PALOS: BASTOS, COPAS, ESPADAS Y OROS (DEL AS AL REY).",
		"21 TRIUNFOS (LOS ARCANOS MAYORES): GANAN A CUALQUIER CARTA DE PALO.",
		"Y EL LOCO, QUE ES ESPECIAL. EL TRIUNFO MAS ALTO GANA."])
	var row := [Deck.minor(0, 14), Deck.minor(1, 13), Deck.minor(2, 12), Deck.minor(3, 1), 1, 15, 21, 0]
	for i in row.size():
		var appear := _ease_back((gt - i * 0.12) / 0.4)
		var x := 80.0 + i * 68.0
		_card(ci, row[i], Vector2(x, 210 + (1.0 - appear) * 60.0), 1.0 if appear >= 0.99 else maxf(0.01, appear), 0.0)
	Pix.draw_text_c(ci, 182, 272, "PALOS", Color(Pix.CREAM, 0.7))
	Pix.draw_text_c(ci, 454, 272, "TRIUNFOS", Color("d8b0ff"))
	Pix.draw_text_c(ci, 556, 272, "LOCO", Pix.GOLD)


## Una baza animada: cuatro cartas entran por turnos y la ganadora brilla.
static func _demo_trick(ci: CanvasItem, cards: Array, gt: float, winner: int, label: String) -> void:
	var cycle := fmod(gt, 5.0)
	var spots := [Vector2(320, 240), Vector2(236, 192), Vector2(320, 150), Vector2(404, 192)]
	var from := [Vector2(320, 400), Vector2(-40, 206), Vector2(320, -60), Vector2(680, 206)]
	for i in cards.size():
		var k := clampf((cycle - i * 0.7) / 0.35, 0.0, 1.0)
		if k <= 0.0:
			continue
		var e := _ease_back(k)
		var p: Vector2 = from[i].lerp(spots[i], e)
		var glow := 1.0 if cycle > 3.2 and i == winner else 0.0
		_card(ci, cards[i], p, 1.0 if k >= 1.0 else 1.0 + (1.0 - k) * 0.5, 0.0, glow)
	if cycle > 3.2:
		var w: Vector2 = spots[winner]
		Pix.draw_text_c(ci, w.x + 62, w.y - 4 + roundf(sin(gt * 6.0) * 2.0), label, Pix.GOLD)


static func _p_trick(ci: CanvasItem, gt: float, t: float) -> void:
	_title(ci, "LA BAZA", t)
	_lines(ci, 58, ["SALE UNO Y LOS DEMAS TIENEN QUE JUGAR DEL MISMO PALO (SERVIR).",
		"GANA LA CARTA MAS ALTA DE ESE PALO Y SE LLEVA LAS CUATRO.",
		"EL QUE GANA SALE EN LA SIGUIENTE."])
	_demo_trick(ci, [Deck.minor(1, 7), Deck.minor(1, 13), Deck.minor(1, 2), Deck.minor(1, 10)], gt, 1, "GANA LA REINA")


static func _p_trump(ci: CanvasItem, gt: float, t: float) -> void:
	_title(ci, "FALLAR Y MONTAR", t)
	_lines(ci, 58, ["SI NO TIENES DEL PALO, ESTAS OBLIGADO A JUGAR UN TRIUNFO (FALLAR).",
		"SI YA HAY UN TRIUNFO, TIENES QUE PONER UNO MAS ALTO SI PUEDES (MONTAR).",
		"SOLO SI NO TIENES TRIUNFOS PUEDES TIRAR LO QUE QUIERAS."])
	_demo_trick(ci, [Deck.minor(2, 14), 6, Deck.minor(2, 3), 12], gt, 3, "GANA EL XII")


static func _p_fool(ci: CanvasItem, gt: float, t: float) -> void:
	_title(ci, "EL LOCO", t)
	_lines(ci, 58, ["EL LOCO SE PUEDE JUGAR EN CUALQUIER MOMENTO, TE TOQUE LO QUE TE TOQUE.",
		"NUNCA GANA LA BAZA, PERO VUELVE A TU MONTON: TE SALVA UNA CARTA BUENA.",
		"EL 1, EL 21 Y EL LOCO SON LAS TRES CARTAS MAS VALIOSAS."])
	var k := fmod(gt, 3.0)
	var spin := k * TAU * 0.5 if k < 1.0 else 0.0
	var bounce := absf(sin(k * 4.0)) * maxf(0.0, 1.5 - k) * 18.0
	_card(ci, 0, Vector2(320, 206 - bounce), 1.0, spin)
	_card(ci, 1, Vector2(190, 206), 1.0, 0.0)
	_card(ci, 21, Vector2(450, 206), 1.0, 0.0)
	Pix.draw_text_c(ci, 190, 272, "EL 1", Color("ffb0ff"))
	Pix.draw_text_c(ci, 450, 272, "EL 21", Pix.GOLD)


static func _p_bid(ci: CanvasItem, gt: float, t: float) -> void:
	_title(ci, "LA APUESTA Y EL PERRO", t)
	_lines(ci, 58, ["AL REPARTIR QUEDAN 6 CARTAS APARTE: EL PERRO. CADA UNO APUESTA O PASA.",
		"PEQUEÑA Y GUARDIA: COGES EL PERRO Y APARTAS 6 (NI REYES NI TRIUNFOS).",
		"GUARDIA SIN: EL PERRO ES TUYO SIN VERLO. GUARDIA CONTRA: ES DE LOS OTROS."])
	var names := ["PEQUEÑA X1", "GUARDIA X2", "GUARDIA SIN X4", "GUARDIA CONTRA X6"]
	for i in 4:
		var k := _ease_back((gt - i * 0.25) / 0.35)
		var y := 120.0 + i * 24.0
		var w := 170.0
		_box(ci, Rect2(80 + (1.0 - k) * -200.0, y, w, 18), Color("120a24"), TarotHud.LEVEL_COLS[i + 1])
		Pix.draw_text(ci, Vector2(92 + (1.0 - k) * -200.0, y + 6), names[i], TarotHud.LEVEL_COLS[i + 1])
	for i in 6:
		var k := clampf((fmod(gt, 4.0) - 1.0 - i * 0.12) / 0.2, 0.0, 1.0)
		var face := k >= 1.0
		var x := 330.0 + i * 40.0
		_card(ci, [Deck.minor(0, 5), 14, Deck.minor(3, 11), Deck.minor(1, 3), 9, Deck.minor(2, 8)][i] if face else -1, Vector2(x, 186), 1.0, 0.0)
	Pix.draw_text_c(ci, 430, 248, "EL PERRO", Pix.GOLD)
	Pix.draw_text_c(ci, 320, 270, "MULTIPLICA LO QUE GANAS... Y LO QUE PIERDES", Color("ff8a9a"))


static func _p_points(ci: CanvasItem, gt: float, t: float) -> void:
	_title(ci, "LOS PUNTOS", t)
	var row := [[Deck.minor(3, 14), "4,5"], [Deck.minor(3, 13), "3,5"], [Deck.minor(3, 12), "2,5"], [Deck.minor(3, 11), "1,5"], [21, "4,5"], [Deck.minor(3, 5), "0,5"]]
	for i in row.size():
		var x := 100.0 + i * 88.0
		var k := _ease_back((gt - i * 0.1) / 0.35)
		_card(ci, row[i][0], Vector2(x, 118), 1.0 if k >= 0.99 else maxf(0.01, k), 0.0)
		Pix.draw_text_c(ci, x, 178, row[i][1], Pix.GOLD, 2)
	_lines(ci, 198, ["REY 4,5 · REINA 3,5 · CABALLO 2,5 · SOTA 1,5 · EL 1, EL 21 Y EL LOCO 4,5 · RESTO 0,5",
		"PUNTOS QUE NECESITA EL QUE APUESTA, SEGUN CUANTAS DE LAS TRES GRANDES GANE:"])
	var need := [["NINGUNA", "56"], ["UNA", "51"], ["DOS", "41"], ["LAS TRES", "36"]]
	for i in 4:
		var x := 130.0 + i * 128.0
		_box(ci, Rect2(x - 52, 226, 104, 36), Color("120a24"), Pix.GOLD)
		Pix.draw_text_c(ci, x, 232, need[i][0], Pix.CREAM)
		Pix.draw_text_c(ci, x, 244, need[i][1], Pix.GOLD, 2)
	Pix.draw_text_c(ci, 320, 274, "BONUS: GANAR LA ULTIMA BAZA CON EL 1 VALE 10 MAS", Color("ffb0ff"))
