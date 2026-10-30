class_name TarotHud
extends Node2D
## Interfaz de la mesa: placas de jugador con retrato, globos de la subasta, cartel de contrato, menú de subasta,
## ayudas de botones, textos que saltan, telón del sofá, puntuación con recuento animado, menús y panel de amigos.

var game: Node
var t := 0.0
var banner_text := ""
var banner_col := Pix.GOLD
var banner_t := -1.0
var banner_power := 0
var bubbles := {}  # seat -> {s, t, lvl}
var pops: Array = []  # {p, s, c, t, k}
var comics: Array = []  # {p, s, c, t, k, burst, rot}
var _pip_tex := {}
var hint_rect := Rect2()
var tut_open := false
var tut_lines: Array = []
var tut_t := 0.0
var tut_point := Vector2(-1, -1)
var tut_place := ""  # "", "top" o "bottom": dónde va el bocadillo
var flash_t := 0.0
var confetti_list: Array = []
var score_open := false
var score_t := 0.0
var score_ev := {}
var panel_open := false
var panel_kind := "join"
var panel_list: Array = []
var panel_sel := 0

const LEVEL_COLS := [Color("c8c0d8"), Color("7ab8ff"), Color("5ff0b0"), Color("ffd447"), Color("ff6a5a")]


func _process(delta: float) -> void:
	t += delta
	if banner_t >= 0.0:
		banner_t += delta
		if banner_t > 2.2:
			banner_t = -1.0
	for k in bubbles.keys():
		bubbles[k].t += delta
	for p in pops:
		p.t += delta
	pops = pops.filter(func(p): return p.t < 1.1)
	for c in comics:
		c.t += delta
	comics = comics.filter(func(c): return c.t < 1.25)
	flash_t = maxf(0.0, flash_t - delta)
	for c in confetti_list:
		c.v.y += 90.0 * delta
		c.v.x *= 0.99
		c.p += c.v * delta
		c.ph += delta * 8.0
	confetti_list = confetti_list.filter(func(c): return c.p.y < 380)
	if score_open:
		score_t += delta
	if tut_open:
		var before := int(tut_t * 45.0)
		tut_t += delta
		# El tecleo suena solo mientras quedan letras por escribir
		var total := 0
		for l in tut_lines:
			total += String(l).length()
		var now_c := int(tut_t * 45.0)
		if now_c != before and now_c % 3 == 0 and now_c < total:
			Sfx.play("tick", -16.0, 2.2)
	queue_redraw()


func banner(s: String, col: Color, power := 0) -> void:
	banner_text = s
	banner_col = col
	banner_t = 0.0
	banner_power = power


func bubble(seat: int, s: String, lvl: int) -> void:
	bubbles[seat] = {"s": s, "t": 0.0, "lvl": lvl}


func pop_text(p: Vector2, s: String, c: Color, k := 1) -> void:
	pops.append({"p": p, "s": s, "c": c, "t": 0.0, "k": k})


## Palabra de cómic: entra de golpe con rebote elástico, con estallido de rayos detrás, y se va encogiendo.
func comic(p: Vector2, txt: String, c: Color, k := 2.0, burst := true) -> void:
	comics.append({"p": p, "s": txt, "c": c, "t": 0.0, "k": k, "burst": burst, "rot": randf_range(-0.12, 0.12)})


func tut_show(lines: Array, point := Vector2(-1, -1), place := "") -> void:
	tut_point = point
	tut_place = place
	tut_lines = lines
	tut_t = 0.0
	tut_open = true
	Sfx.play("bounce", -6.0, 1.5)


## ✕: si el texto aún se está escribiendo, lo completa; si no, cierra el bocadillo.
func tut_next() -> void:
	var total := 0
	for l in tut_lines:
		total += String(l).length()
	if tut_t * 45.0 < total:
		tut_t = 999.0
	else:
		tut_open = false
		Sfx.play("select")


func flash(d: float) -> void:
	flash_t = d


func confetti(nn: int) -> void:
	var cols := [Color("ff6b7a"), Color("ffd447"), Color("7ab8ff"), Color("5ff0b0"), Color("ff8ad8"), Color.WHITE]
	for i in nn:
		confetti_list.append({"p": Vector2(randf_range(0, 640), randf_range(-60, -4)), "v": Vector2(randf_range(-40, 40), randf_range(20, 90)),
			"c": cols[i % cols.size()], "ph": randf() * 6.0})


func show_score(ev: Dictionary) -> void:
	score_ev = ev
	score_open = true
	score_t = 0.0


func open_join_panel() -> void:
	panel_kind = "join"
	refresh_panel()
	panel_open = true


func open_invite_panel() -> void:
	panel_kind = "invite"
	refresh_panel()
	panel_open = true


func refresh_panel() -> void:
	panel_list = Net.friends(panel_kind == "join")
	panel_sel = 0


# --- Dibujo ---

func _draw() -> void:
	match game.phase:
		"intro":
			TarotFront.intro(self, game.intro_t)
		"menu":
			match game.menu_page:
				"title":
					TarotFront.title(self, game, t)
				"play":
					TarotFront.p5_menu(self, game, t, "JUGAR", game.PLAY_DESC, game.PLAY_CARDS)
				"settings":
					TarotFront.p5_menu(self, game, t, "AJUSTES", game.SET_DESC, game.SET_CARDS)
				"games":
					TarotFront.p5_menu(self, game, t, "OTROS JUEGOS", game.GAMES_DESC, game.GAMES_CARDS)
				"look":
					TarotFront.p5_menu(self, game, t, "PERSONAJE", game.LOOK_DESC, [])
					TarotFront.look_preview(self, game, t)
		"lobby":
			_lobby()
		"guide":
			TarotGuide.draw(self, game.guide_page, game.guide_t, t)
		"casino":
			if game.casino:
				game.casino.draw_ui(self)
			for c in comics:
				_draw_comic(c)
		"table", "over":
			_table()
	if game.phase == "over":
		_over()
	for c in confetti_list:
		var w := 2.0 if int(c.ph) % 2 == 0 else 1.0
		draw_rect(Rect2(c.p.round(), Vector2(w, 2)), c.c)
	if flash_t > 0.0:
		draw_rect(Rect2(0, 0, 640, 360), Color(1, 1, 1, flash_t * 1.6))
	if game.msg_t > 0.0 and game.msg != "":
		var ww := Pix.text_width(game.msg) + 20
		_box(Rect2(320 - ww / 2.0, 328, ww, 16), Color("1e1236", 0.95), Pix.GOLD)
		Pix.draw_text_c(self, 320, 333, game.msg, Pix.CREAM)
	if panel_open:
		_panel()


## Caja de píxeles con esquinas recortadas.
func _box(r: Rect2, fill: Color, edge: Color) -> void:
	var o := r.grow(1)
	draw_rect(Rect2(o.position + Vector2(1, 0), o.size - Vector2(2, 0)), Pix.INK)
	draw_rect(Rect2(o.position + Vector2(0, 1), o.size - Vector2(0, 2)), Pix.INK)
	draw_rect(Rect2(r.position + Vector2(1, 0), r.size - Vector2(2, 0)), edge)
	draw_rect(Rect2(r.position + Vector2(0, 1), r.size - Vector2(0, 2)), edge)
	draw_rect(r.grow(-1), fill)


func _lobby() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.4))
	var quick: bool = game.mode == "online" and game.online_kind == "rapida"
	var gk: String = game.game_kind if game.mode == "online" else "tarot"
	var head := "PARTIDA RAPIDA" if quick else "SALA"
	if gk != "tarot":
		head += " · " + String(game.GAME_NAMES[gk])
	Pix.draw_text_c(self, 320, 20, head, Pix.GOLD, 4 if gk == "tarot" else 2)
	var sub := ""
	if game.mode == "sofa":
		sub = "PULSA ✕ EN TU MANDO PARA SENTARTE"
	elif quick:
		var dots := ".".repeat(int(t * 3.0) % 4)
		sub = ("EMPIEZA EN %d..." % ceili(game.quick_wait() - game.quick_count)) if game.quick_wait() > 0.0 else "BUSCANDO RIVALES" + dots
	else:
		sub = "ESPERANDO AMIGOS..." if Net.is_host() else "ESPERANDO AL ANFITRION..."
	Pix.draw_text_c(self, 320, 54, sub, Pix.CREAM)
	for i in game.n:
		var x: int = 320 - game.n * 70 + i * 140 + 10
		var r := Rect2(x, 76, 120, 108)
		var has: bool = i < game.players.size()
		_box(r, Color("1e1236", 0.94) if has else Color("120a24", 0.8), Pix.GOLD if has else Color("4a3a6a"))
		if has:
			var p: Dictionary = game.players[i]
			draw_set_transform(Vector2(x + 60, 112), 0.0, Vector2(3, 3))
			draw_texture(Pix.face(p), Vector2(-8, -6))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			Pix.draw_text_c(self, x + 60, 146, p.name, Pix.PLAYERS[p.pi].c1[0])
			Pix.draw_text_c(self, x + 60, 162, "MANDO" if p.kind == "human" and game.mode == "sofa" else ("IA" if p.kind == "ai" else ("ANFITRION" if p.kind == "human" else "ONLINE")), Color(Pix.CREAM, 0.6))
		else:
			Pix.draw_text_c(self, x + 60, 120, "LIBRE", Color(Pix.CREAM, 0.4))
			if gk == "tarot":
				Pix.draw_text_c(self, x + 60, 136, "(IA)", Color(Pix.CREAM, 0.3))
	# Opciones del anfitrión (o lo que ha elegido, para los demás)
	var rows: Array = game.lobby_rows()
	var rects: Array = []
	if rows.is_empty():
		if gk == "tarot":
			Pix.draw_text_c(self, 320, 204, "%d JUGADORES · PARTIDA DE %d MANOS · IA %s" % [game.n, game.n * game.rounds, game.level_name(game.ai.level)], Pix.CREAM)
		else:
			Pix.draw_text_c(self, 320, 204, "HASTA 4 JUGADORES CONTRA LA BANCA · CADA UNO CON SUS FICHAS", Pix.CREAM)
	for i in rows.size():
		var y := (198 + i * 24) if rows.size() <= 4 else (192 + i * 19)
		var sel: bool = i == game.lobby_sel
		var label: String = rows[i][1]
		var w := Pix.text_width(label)
		var rr := Rect2(320 - w / 2.0 - 24, y - 5, w + 48, 18)
		_box(rr, Color(Pix.PURPLE, 0.95) if sel else Color("1e1236", 0.9), Pix.GOLD if sel else Color("4a3a6a"))
		Pix.draw_text_c(self, 320, y, label, Pix.GOLD if sel else Color(Pix.CREAM, 0.8))
		rects.append(rr)
	game.lobby_rects = rects
	var hints := "✕ SENTARSE   ○ LEVANTARSE   OPTIONS EMPEZAR" if game.mode == "sofa" else ("✕ ELEGIR   ○ SALIR" if Net.is_host() else "○ SALIR")
	Pix.draw_text_c(self, 320, 306, hints, Pix.CREAM)


func _table() -> void:
	var g = game
	if g.show.active:
		# La cinemática de un Arcano ocupa la pantalla: solo sus textos de cómic por encima
		for c in comics:
			_draw_comic(c)
		return
	for p in g.n:
		if p < g.players.size():
			_plate(p)
	# Bocadillos de la subasta
	for seat in bubbles.keys():
		var b: Dictionary = bubbles[seat]
		if b.t > 2.4 and g.view_phase != "bid":
			continue
		if g.bids[seat] < 0 and g.taker != seat:
			continue
		var base: Vector2 = g._plate_center(seat) + Vector2(0, [-34, 26, 30, 26][g.slot(seat)])
		var pop := 1.0 + maxf(0.0, 0.3 - b.t) * 2.0
		var col: Color = LEVEL_COLS[b.lvl]
		var w := Pix.text_width(b.s) + 12
		var r := Rect2(base - Vector2(w / 2.0, 0) * pop, Vector2(w, 15) * pop)
		_box(r, Color("1e1236", 0.95), col)
		draw_rect(Rect2(base + Vector2(-2, -3), Vector2(4, 3)), col)
		Pix.draw_text_c(self, base.x, r.position.y + 4 * pop, b.s, col)
	# Cartel
	if banner_t >= 0.0:
		var a := clampf(banner_t / 0.12, 0.0, 1.0) * clampf((2.2 - banner_t) / 0.3, 0.0, 1.0)
		var sc := 2 if banner_power >= 2 or banner_text.length() < 18 else 1
		var w := Pix.text_width(banner_text, sc) + 40
		var y := 62 - 7 * sc
		var slide := (1.0 - clampf(banner_t / 0.18, 0.0, 1.0)) * 60.0
		draw_rect(Rect2(0, y - 6, 640, 14 * sc + 10), Color(Pix.INK, 0.6 * a))
		draw_rect(Rect2(320 - w / 2.0 - slide, y - 6, w, 1), Color(banner_col, a))
		draw_rect(Rect2(320 - w / 2.0 + slide, y + 14 * sc + 3, w, 1), Color(banner_col, a))
		Pix.draw_text_c(self, 320 + slide * 0.5, y, banner_text, Color(banner_col, a), sc, Color(Pix.INK, a), 1.0 if banner_power >= 3 else 0.0, t)
	# Textos que saltan
	for p in pops:
		var k := clampf(p.t / 1.1, 0.0, 1.0)
		var y: float = p.p.y - 18.0 * (1.0 - pow(1.0 - k, 3.0))
		var sc: int = p.k + (1 if p.t < 0.08 else 0)
		Pix.draw_text_c(self, p.p.x, y, p.s, Color(p.c, 1.0 - maxf(0.0, k - 0.7) / 0.3), sc)
	# Contrato en curso
	if g.taker >= 0 and g.contract > 0:
		var s := "%s · %s" % [g.players[g.taker].name, Rules.CONTRACTS[g.contract]]
		var need: float = Rules.NEEDED[clampi(g.taker_oudlers, 0, 3)] / 2.0
		var have: float = g.taker_half / 2.0
		var bw := maxi(Pix.text_width(s) + 14, 150)
		_box(Rect2(6, 6, bw, 26), Color("1e1236", 0.92), LEVEL_COLS[g.contract])
		Pix.draw_text(self, Vector2(13, 10), s, LEVEL_COLS[g.contract])
		var fw := bw - 60.0
		draw_rect(Rect2(12, 21, fw, 5), Color("120a24"))
		draw_rect(Rect2(12, 21, fw * clampf(have / 91.0, 0.0, 1.0), 5), Color("5ff0b0") if have >= need else Pix.GOLD)
		draw_rect(Rect2(12 + fw * need / 91.0, 19, 1, 9), Color.WHITE)
		Pix.draw_text(self, Vector2(16 + fw, 20), "%s/%s" % [_num(have), _num(need)], Color(Pix.CREAM, 0.8))
	Pix.draw_text(self, Vector2(6, 36 if g.taker >= 0 else 26), "MANO %d/%d" % [g.hand_no, g.hands_total], Color(Pix.CREAM, 0.55))
	# Palo que manda
	var led: int = g.led_suit_view()
	if led >= 0:
		var lc := TableFx.suit_color(led)
		var name: String = "TRIUNFO" if led == Deck.TRUMP else Minors.SUITS[led].name
		var lr := Rect2(270, 250, 100, 18) if false else Rect2(6, 48 if g.taker >= 0 else 38, Pix.text_width("MANDA " + name) + 30, 18)
		_box(lr, Color("1e1236", 0.92), lc)
		_draw_pip(led, lr.position + Vector2(10, 9))
		Pix.draw_text(self, lr.position + Vector2(21, 5), "MANDA " + name, lc)
	# Durante la cinemática de un Arcano no se pinta nada encima de ella
	var cine: bool = g.show.active
	if not cine:
		_trick_leader()
		_inspect()
	if g.view_phase == "bid" and g.turn_seat == g.me and g._is_local_human(g.me) and g.curtain < 0:
		_bid_menu()
	if not cine:
		_hints()
	for c in comics:
		_draw_comic(c)
	if g.curtain >= 0:
		_curtain()
	if score_open:
		_score()
	if tut_open:
		_tut_box()


func _plate(p: int) -> void:
	var g = game
	var pl: Dictionary = g.players[p]
	var pos: Vector2 = g.PLATE[g.slot(p)]
	var r := Rect2(pos, Vector2(96, 26))
	var turn: bool = g.turn_seat == p
	var col: Color = Pix.PLAYERS[pl.pi].c1[1]
	if turn:
		var pulse := 0.5 + 0.5 * sin(t * 8.0)
		for k in 2:
			draw_rect(r.grow(3 + k * 2), Color(Pix.GOLD, (0.35 - k * 0.15) * (0.5 + pulse * 0.5)), false, 1.0)
	_box(r, Color("1e1236", 0.92), Pix.GOLD if turn else col.darkened(0.2))
	draw_texture(Pix.face(pl), pos + Vector2(4, 7))
	Pix.draw_text(self, pos + Vector2(24, 5), String(pl.name).left(11), Pix.PLAYERS[pl.pi].c1[0])
	var sc: int = g.scores[p] if p < g.scores.size() else 0
	Pix.draw_text(self, pos + Vector2(24, 15), ("+" if sc > 0 else "") + str(sc), Color("5ff0b0") if sc > 0 else (Color("ff8a9a") if sc < 0 else Color(Pix.CREAM, 0.6)))
	if g.taker == p:
		_crown(pos + Vector2(84, 4))
	# Contador de cartas en la mano (con salto cuando cambia)
	var cnt: int = g.hand.size() if g.slot(p) == 0 else g.backs[p].size()
	if cnt > 0:
		var bx := pos + (Vector2(-30, 4) if g.slot(p) == 3 else Vector2(100, 4))
		draw_rect(Rect2(bx + Vector2(1, 1), Vector2(11, 15)), Color(0, 0, 0, 0.4))
		draw_rect(Rect2(bx, Vector2(11, 15)), Pix.INK)
		draw_rect(Rect2(bx + Vector2(1, 1), Vector2(9, 13)), Color("4a1f66"))
		draw_rect(Rect2(bx + Vector2(2, 2), Vector2(7, 11)), Color(Pix.GOLD, 0.5), false, 1.0)
		var ct := str(cnt)
		Pix.draw_text(self, bx + Vector2(14, 4), ct, Color("ff8a3a") if cnt == 1 else Pix.CREAM)
	if g.dealer == p:
		Pix.draw_text(self, pos + Vector2(84, 15), "D", Color(Pix.CREAM, 0.5))
	if turn and g.view_phase in ["play", "bid", "discard"]:
		var bob := roundf(sin(t * 7.0) * 2.0)
		var ax := pos.x + 48
		var ay := pos.y - 8 + bob if g.slot(p) != 2 else pos.y + 34 - bob
		for k in 4:
			var yy := ay + (k if g.slot(p) != 2 else -k)
			draw_rect(Rect2(ax - 3 + k, yy, 7 - k * 2, 1), Pix.GOLD)


func _draw_pip(s: int, center: Vector2) -> void:
	if s == Deck.TRUMP:
		for d in [Vector2(0, -3), Vector2(0, 3), Vector2(-3, 0), Vector2(3, 0)]:
			draw_rect(Rect2(center + d * 0.5 - Vector2(1, 1), Vector2(2, 2)), Color("b06aff"))
		draw_rect(Rect2(center - Vector2(1, 3), Vector2(2, 7)), Color("d8b0ff"))
		draw_rect(Rect2(center - Vector2(3, 1), Vector2(7, 2)), Color("d8b0ff"))
		return
	if not _pip_tex.has(s):
		_pip_tex[s] = Pix.tex(Minors.pip(s, 0))
	var tx: Texture2D = _pip_tex[s]
	draw_texture(tx, (center - tx.get_size() / 2.0).round())


## Nombre y valor de la carta elegida sobre ella; con □ (o Q) se ve en grande con su explicación.
func _inspect() -> void:
	var g = game
	if g.hand.is_empty() or g.curtain >= 0 or not g._is_local_human(g.me):
		return
	var c: int = g.hand[clampi(g.cursor, 0, g.hand.size() - 1)]
	var cn: CardNode = g.nodes.get(c)
	if cn == null or not is_instance_valid(cn):
		return
	var zoom: bool = g._my_pads().any(func(p): return p.held("zoom"))
	if g.turn_seat == g.me and g.view_phase in ["play", "discard"] and not zoom:
		var nm := Deck.name(c)
		var pts := _num(Deck.half_points(c) / 2.0)
		var line := "%s · %s PTS" % [nm, pts]
		var w := Pix.text_width(line) + 12
		var top := cn.position + Vector2(0, -66)
		top.x = clampf(top.x, w / 2.0 + 4, 636 - w / 2.0)
		top.y = minf(top.y, 228.0)  # nunca encima de mi placa ni de la mano
		_box(Rect2(top - Vector2(w / 2.0, 0), Vector2(w, 13)), Color("120a24", 0.95), Pix.CREAM)
		Pix.draw_text_c(self, top.x, top.y + 3, line, Pix.CREAM)
	if zoom:
		draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.6))
		draw_set_transform(Vector2(200, 170), 0.0, Vector2(2, 2))
		draw_rect(Rect2(-33, -51, 70, 108), Color(0, 0, 0, 0.4))
		draw_texture(Deck.texture(c), Vector2(-35, -54))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var x := 300.0
		Pix.draw_text(self, Vector2(x, 80), Deck.name(c), Pix.GOLD, 2)
		var info: Array = _card_info(c)
		for i in info.size():
			Pix.draw_text(self, Vector2(x, 110 + i * 14), info[i], Pix.CREAM)


func _card_info(c: int) -> Array:
	var out: Array = []
	out.append("VALE %s PUNTOS" % _num(Deck.half_points(c) / 2.0))
	if c == Deck.EXCUSE:
		out.append_array(["LA EXCUSA: LA PUEDES JUGAR SIEMPRE.", "NUNCA GANA, PERO VUELVE A TU MONTON.", "ES UNA DE LAS TRES CARTAS GRANDES."])
	elif Deck.is_trump(c):
		out.append("TRIUNFO NUMERO %d DE 21." % c)
		out.append("GANA A TODAS LAS CARTAS DE PALO")
		out.append("Y A LOS TRIUNFOS MAS BAJOS.")
		if c == 1:
			out.append_array(["EL PEQUEÑO: CARTA GRANDE, ¡PERO FRAGIL!", "SI LO GANAS EN LA ULTIMA BAZA: +10."])
		elif c == 21:
			out.append_array(["EL MUNDO: EL TRIUNFO MAS ALTO.", "NADIE PUEDE GANARLO."])
	else:
		var v := Deck.value(c)
		out.append("PALO DE %s, VALOR %d DE 14." % [Minors.SUITS[Deck.suit(c)].name, v])
		out.append("ORDEN: AS (BAJO) ... 10, SOTA, CABALLO, REINA, REY.")
		if v == 14:
			out.append("EL REY: NO SE PUEDE APARTAR AL PERRO.")
	out.append("")
	out.append("SUELTA □ PARA VOLVER")
	return out


## Corona saltarina sobre la carta que va ganando la baza.
func _trick_leader() -> void:
	var g = game
	# Solo cuentan las cartas que ya han aterrizado (la que vuela todavía no ha llegado)
	var landed: Array = g.trick_nodes.filter(func(e): return is_instance_valid(e[1]) and not e[1].flying)
	if landed.size() < 2:
		return
	var wi := Rules.trick_winner_idx(landed.map(func(e): return e[1].card))
	if wi < 0:
		return
	var cn: CardNode = landed[wi][1]
	# Abajo la etiqueta va debajo de la carta; arriba y a los lados, encima: así nunca tapa a la carta vecina
	var below: bool = g.slot(landed[wi][0]) == 0
	var top := cn.position + Vector2(0, (63.0 if below else -62.0) + roundf(sin(t * 6.0) * 2.0))
	_box(Rect2(top - Vector2(22, 8), Vector2(44, 12)), Color("2a1650", 0.95), Pix.GOLD)
	_crown(top + Vector2(-17, -5))
	Pix.draw_text(self, top + Vector2(-7, -5), "GANA", Pix.GOLD)


func _draw_comic(c: Dictionary) -> void:
	var tt: float = c.t
	var intro := clampf(tt / 0.09, 0.0, 1.0)
	var elastic := 1.0 + 0.45 * exp(-7.0 * tt) * sin(tt * 26.0)
	var out := clampf((1.25 - tt) / 0.25, 0.0, 1.0)
	var k: float = c.k * intro * elastic * (0.6 + 0.4 * out)
	var a := out
	var pos: Vector2 = c.p + Vector2(0, -tt * 10.0)
	var col: Color = c.c
	var w := Pix.text_width(c.s) + 10.0
	draw_set_transform(pos, c.rot, Vector2(k, k))
	if c.burst:
		var pts := PackedVector2Array()
		var spikes := 14
		for i in spikes * 2:
			var ang := i * PI / spikes + tt * 0.8
			var r := (w * 0.5 + 6.0) if i % 2 == 0 else (w * 0.5 - 2.0)
			pts.append(Vector2(cos(ang) * r, sin(ang) * r * 0.42))
		var outer := PackedVector2Array()
		for q in pts:
			outer.append(q * 1.12)
		draw_colored_polygon(outer, Color(Pix.INK, 0.9 * a))
		draw_colored_polygon(pts, Color(col.darkened(0.55), 0.95 * a))
	Pix.draw_text_c(self, 0, -3.5, c.s, Color(col.lightened(0.15), a), 1, Color(Pix.INK, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _crown(at: Vector2) -> void:
	for d in [Vector2(0, 0), Vector2(3, 1), Vector2(6, 0)]:
		draw_rect(Rect2(at + d, Vector2(1, 3)), Pix.GOLD)
	draw_rect(Rect2(at + Vector2(0, 3), Vector2(7, 3)), Pix.GOLD)
	draw_rect(Rect2(at + Vector2(3, 4), Vector2(1, 1)), Color("ff4a6a"))


func _bid_menu() -> void:
	var g = game
	var opts: Array = g._bid_options()
	var r := Rect2(220, 104, 200, 26 + opts.size() * 18)
	_box(r, Color("1e1236", 0.96), Pix.GOLD)
	Pix.draw_text_c(self, 320, r.position.y + 7, "¿CUANTO APUESTAS?", Pix.GOLD)
	for i in opts.size():
		var b: int = opts[i]
		var y := r.position.y + 24 + i * 18
		var sel: bool = i == g.bid_sel
		if sel:
			draw_rect(Rect2(r.position.x + 6, y - 4, r.size.x - 12, 15), Color(Pix.PURPLE, 0.95))
			Pix.draw_text(self, Vector2(r.position.x + 12 + roundf(sin(t * 8.0)), y), ">", Pix.GOLD)
		var lbl: String = Rules.CONTRACTS[b] + ("" if b == 0 else "  X%d" % Rules.MULT[b])
		Pix.draw_text_c(self, 320, y, lbl, LEVEL_COLS[b] if sel else Color(LEVEL_COLS[b], 0.7))
	# Fuerza de la mano (ayuda): una barra que se llena
	var v := TarotAI.hand_value(g.hand) if not g.hand.is_empty() else 0.0
	var bw := 180.0
	var bx := r.position.x + 10
	var by := r.end.y + 6
	_box(Rect2(bx, by, bw, 8), Color("120a24"), Color("4a3a6a"))
	var fill := clampf(v / 90.0, 0.0, 1.0) * (bw - 4)
	draw_rect(Rect2(bx + 2, by + 2, fill, 4), LEVEL_COLS[clampi(int(v / 18.0), 0, 4)])
	Pix.draw_text_c(self, 320, by + 12, "FUERZA DE TU MANO", Color(Pix.CREAM, 0.5))


## Una sola línea sobre la mano: qué te obligan a jugar y con qué botones (late para llamar la atención).
func _hints() -> void:
	var g = game
	hint_rect = Rect2()
	if g.turn_seat != g.me or not g._is_local_human(g.me) or g.curtain >= 0:
		return
	# Cada instrucción en su propia línea (lo que hay que hacer en dorado, los botones en crema)
	var lines: Array = []
	var klines: Array = []
	match g.view_phase:
		"bid":
			klines = ["ARRIBA/ABAJO: ELEGIR", "✕: APOSTAR"]
		"play":
			lines = _wrap(g.play_hint(), 24)
			klines = ["IZQ/DER O RATON: ELEGIR", "✕ O CLIC: JUGAR"]
		"discard":
			lines = ["APARTA 6 CARTAS", "(NI REYES NI TRIUNFOS)"]
			klines = ["✕ O CLIC: MARCAR (%d/6)" % g.picked.size(), "△ O CLIC AQUI: LISTO"]
		_:
			return
	var bob := roundf(sin(t * 4.0) * 1.5)
	var hh := 8 + (lines.size() + klines.size()) * 11
	var bw := 158.0
	for l in lines + klines:
		bw = maxf(bw, Pix.text_width(l) + 14.0)
	var r := Rect2(48, 134 + bob, bw, hh)
	hint_rect = r
	_box(r, Color("2a1650", 0.95), Pix.GOLD if not (g.view_phase == "discard" and g.picked.size() == 6) else Color("5ff0b0"))
	var y := r.position.y + 5
	for l in lines:
		Pix.draw_text(self, Vector2(r.position.x + 7, y), l, Pix.GOLD)
		y += 11
	for l in klines:
		Pix.draw_text(self, Vector2(r.position.x + 7, y), l, Pix.CREAM)
		y += 11


func _wrap(text: String, width: int) -> Array:
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


## Bocadillo del Loco: carta pequeña que se balancea a la izquierda y el texto escribiéndose a máquina.
func _tut_box() -> void:
	# Si la flecha señala algo de arriba, el bocadillo baja para dejar sitio a la flecha entera
	# Sitio del bocadillo según lo que señala la flecha: algo de arriba -> debajo de ello; una carta de la mesa
	# -> abajo del todo (tapando la mano, que en ese momento no se usa); la mano o nada -> arriba.
	var bh := 30.0 + tut_lines.size() * 14
	var by := 2.0
	if tut_point.y >= 0.0 and tut_point.y <= 60.0:
		by = tut_point.y + 52.0
	elif tut_point.y > 60.0 and tut_point.y < 240.0:
		by = 358.0 - bh
	if tut_place == "top":
		by = 2.0
	elif tut_place == "bottom" or score_open:
		by = 358.0 - bh
	var r := Rect2(40, by, 560, bh)
	var k := clampf(tut_t / 0.2, 0.0, 1.0)
	r.position.y -= (1.0 - k) * 30.0
	draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.25 * k))
	_box(r, Color("1e1236", 0.97), Pix.GOLD)
	var bob := roundf(sin(t * 3.0) * 2.0)
	draw_set_transform(r.position + Vector2(8, 14 + bob), 0.0, Vector2(3, 3))
	draw_texture(Pix.portrait(0), Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var shown := int(tut_t * 45.0)
	for i in tut_lines.size():
		var line: String = tut_lines[i]
		var part := line.left(clampi(shown, 0, line.length()))
		shown -= line.length()
		var col := Pix.GOLD if i == 0 else (Pix.CREAM if i < 3 else Color("9ad8ff"))
		Pix.draw_text(self, r.position + Vector2(64, 12 + i * 14), part, col)
	if shown >= 0 and int(t * 3.0) % 2 == 0:
		Pix.draw_text(self, r.end - Vector2(Pix.text_width("✕ VALE") + 10, 13), "✕ VALE", Pix.CREAM)
	# Flecha que salta señalando aquello de lo que habla, con un anillo que late
	if tut_point.x >= 0.0 and k >= 1.0:
		var tp := tut_point
		var below := tp.y > r.end.y
		var hop := roundf(sin(t * 7.0) * 4.0)
		var tip := tp + Vector2(0, (-18 if below else 18) + (hop if below else -hop))
		var dir := 1.0 if below else -1.0
		for k2 in 3:
			var rr := 14.0 + k2 * 6.0 + fmod(t * 20.0, 6.0)
			draw_arc(tp, rr, 0, TAU, 32, Color(Pix.GOLD, 0.5 - k2 * 0.15), 1.0)
		var pts := PackedVector2Array([tip, tip + Vector2(-9, -12 * dir), tip + Vector2(-3, -12 * dir), tip + Vector2(-3, -26 * dir), tip + Vector2(3, -26 * dir), tip + Vector2(3, -12 * dir), tip + Vector2(9, -12 * dir)])
		var outline := PackedVector2Array()
		for q in pts:
			outline.append(tip + (q - tip) * 1.25)
		draw_colored_polygon(outline, Pix.INK)
		draw_colored_polygon(pts, Pix.GOLD)


func _curtain() -> void:
	var g = game
	var p: Dictionary = g.players[g.curtain]
	draw_rect(Rect2(0, 250, 640, 110), Color(Pix.INK, 0.85))
	Pix.draw_text_c(self, 320, 270, "TURNO DE %s" % p.name, Pix.PLAYERS[p.pi].c1[0], 2)
	Pix.draw_text_c(self, 320, 296, "LOS DEMAS NO MIREIS · ✕ PARA VER TU MANO", Pix.CREAM)


func _score() -> void:
	var g = game
	var ev: Dictionary = score_ev
	var s: Dictionary = ev.s
	var k := clampf(score_t / 0.35, 0.0, 1.0)
	var r := Rect2(130, 40 + (1.0 - k) * 80, 380, 250)
	draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.55 * k))
	_box(r, Color("1e1236", 0.97), Pix.GOLD)
	var x0 := r.position.x
	var y0 := r.position.y
	var tk: Dictionary = g.players[s.taker]
	var won: bool = s.won
	Pix.draw_text_c(self, 320, y0 + 10, "%s %s" % [tk.name, "GANA" if won else "PIERDE"], Color("5ff0b0") if won else Color("ff8a9a"), 2)
	Pix.draw_text_c(self, 320, y0 + 30, "%s · X%d" % [Rules.CONTRACTS[s.contract], s.mult], LEVEL_COLS[s.contract])
	# Recuento: los puntos suben hasta el total
	var cnt := clampf((score_t - 0.4) / 1.0, 0.0, 1.0)
	var pts: float = s.half / 2.0 * cnt
	var need: float = s.need / 2.0
	var bar := Rect2(x0 + 20, y0 + 50, 340, 12)
	_box(bar, Color("120a24"), Color("4a3a6a"))
	var fill := clampf(pts / 91.0, 0.0, 1.0) * (bar.size.x - 4)
	draw_rect(Rect2(bar.position + Vector2(2, 2), Vector2(fill, 8)), Color("5ff0b0") if pts >= need else Color("ffd447"))
	var nx: float = bar.position.x + 2 + need / 91.0 * (bar.size.x - 4)
	draw_rect(Rect2(nx, bar.position.y - 3, 1, 18), Color.WHITE)
	Pix.draw_text(self, Vector2(x0 + 20, y0 + 68), "PUNTOS: %s DE %s" % [_num(snappedf(pts, 0.5)), _num(need)], Pix.CREAM)
	Pix.draw_text(self, Vector2(x0 + 20, y0 + 80), "BAZAS MAYORES: %d (1, 21 Y EL LOCO)" % s.oudlers, Color(Pix.CREAM, 0.7))
	var line := "%d + %s" % [25, "|%s| DE DIFERENCIA" % _num(absf(s.diff / 2.0))]
	if s.petit != 0:
		line += " %s 10 DEL PEQUEÑO" % ("+" if s.petit > 0 else "-")
	Pix.draw_text(self, Vector2(x0 + 20, y0 + 92), line + "  X%d" % s.mult, Color(Pix.CREAM, 0.7))
	# Las cartas ganadas por el que toma, en miniatura y de golpe
	var tc: Array = ev.get("taker_cards", [])
	var shown := int(clampf((score_t - 0.3) / 1.2, 0.0, 1.0) * tc.size())
	var specials: Array = tc.filter(func(c): return Deck.half_points(c) > 1)
	for i in mini(specials.size(), int(shown * specials.size() / maxf(1.0, tc.size())) + 1):
		var c: int = specials[i]
		var px := x0 + 22 + (i % 22) * 15
		var py := y0 + 106 + (i / 22) * 22
		draw_set_transform(Vector2(px, py), 0.0, Vector2(0.2, 0.2))
		draw_texture(Deck.texture(c), Vector2.ZERO)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Marcador de la partida
	var ty := y0 + 160
	Pix.draw_text(self, Vector2(x0 + 20, ty), "JUGADOR", Pix.GOLD)
	Pix.draw_text(self, Vector2(x0 + 200, ty), "ESTA MANO", Pix.GOLD)
	Pix.draw_text(self, Vector2(x0 + 300, ty), "TOTAL", Pix.GOLD)
	for i in g.players.size():
		var pl: Dictionary = g.players[i]
		var y: float = ty + 14 + i * 13
		var d: int = s.per[i]
		var tot: int = ev.totals[i]
		var shown_d := roundi(d * clampf((score_t - 1.2) / 0.6, 0.0, 1.0))
		draw_texture(Pix.face(pl), Vector2(x0 + 20, y - 3))
		Pix.draw_text(self, Vector2(x0 + 40, y), pl.name, Pix.PLAYERS[pl.pi].c1[0])
		Pix.draw_text(self, Vector2(x0 + 200, y), ("+" if shown_d > 0 else "") + str(shown_d), Color("5ff0b0") if d > 0 else Color("ff8a9a"))
		Pix.draw_text(self, Vector2(x0 + 300, y), str(tot), Pix.CREAM)
		if i in g.waiting_ok:
			Pix.draw_text(self, Vector2(x0 + 350, y), "...", Color(Pix.CREAM, 0.4 + 0.4 * sin(t * 6.0)))
	if not g.waiting_ok.is_empty():
		Pix.draw_text_c(self, 320, r.end.y - 14, "✕ SEGUIR", Pix.CREAM)


func _num(v: float) -> String:
	if absf(v - roundf(v)) < 0.01:
		return str(int(roundf(v)))
	return "%d,5" % int(floorf(v))


func _over() -> void:
	var g = game
	var tot: Array = g.last_score.get("totals", g.scores)
	var order: Array = range(g.players.size())
	order.sort_custom(func(a, b): return tot[a] > tot[b])
	draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.7))
	var wpl: Dictionary = g.players[order[0]]
	var tied: Array = order.filter(func(i): return tot[i] == tot[order[0]])
	var title := "¡GANA %s!" % wpl.name if tied.size() == 1 else "¡EMPATE EN CABEZA!"
	Pix.draw_text_c(self, 320, 40, title, Pix.GOLD, 3, Pix.INK, 2.0, t)
	for k in order.size():
		var i: int = order[k]
		var pl: Dictionary = g.players[i]
		var y := 110 + k * 30
		_box(Rect2(190, y - 6, 260, 24), Color("1e1236", 0.95), Pix.GOLD if k == 0 else Color("4a3a6a"))
		Pix.draw_text(self, Vector2(200, y + 2), "%d." % (k + 1), Pix.GOLD)
		draw_texture(Pix.face(pl), Vector2(218, y - 1))
		Pix.draw_text(self, Vector2(240, y + 2), pl.name, Pix.PLAYERS[pl.pi].c1[0])
		Pix.draw_text(self, Vector2(400, y + 2), str(tot[i]), Pix.CREAM)
	Pix.draw_text_c(self, 320, 320, "✕ OTRA PARTIDA   ○ MENU", Pix.CREAM)


func _panel() -> void:
	draw_rect(Rect2(0, 0, 640, 360), Color(Pix.INK, 0.7))
	var r := Rect2(170, 60, 300, 230)
	_box(r, Color("1e1236", 0.97), Pix.GOLD)
	Pix.draw_text_c(self, 320, r.position.y + 10, "SALAS DE AMIGOS" if panel_kind == "join" else "INVITAR A UN AMIGO", Pix.GOLD)
	if panel_list.is_empty():
		Pix.draw_text_c(self, 320, 160, "NO HAY NADIE" if panel_kind == "join" else "NO HAY AMIGOS CONECTADOS", Color(Pix.CREAM, 0.6))
		Pix.draw_text_c(self, 320, 176, "✕ ACTUALIZAR", Color(Pix.CREAM, 0.6))
	for i in mini(panel_list.size(), 10):
		var f: Dictionary = panel_list[i]
		var y := r.position.y + 32 + i * 18
		if i == panel_sel:
			draw_rect(Rect2(r.position.x + 6, y - 4, r.size.x - 12, 15), Color(Pix.PURPLE, 0.95))
		Pix.draw_text(self, Vector2(r.position.x + 16, y), f.name, Pix.GOLD if i == panel_sel else Pix.CREAM)
	Pix.draw_text_c(self, 320, r.end.y - 14, ("✕ UNIRSE" if panel_kind == "join" else "✕ INVITAR") + "   ○ CERRAR", Pix.CREAM)
