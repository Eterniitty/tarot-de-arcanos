class_name TarotCasino
extends Node2D
## Juegos clásicos de libre uso con las cartas menores del tarot, contra la banca y apostando fichas:
##  · BLACKJACK (veintiuno): As 1 u 11, figuras (sota, caballo, dama, rey) 10. La banca se planta con 17.
##    Blackjack (21 con dos cartas) paga 3 a 2; doblar con las dos primeras cartas.
##  · SIETE Y MEDIA: solo As-7 y figuras; las figuras valen medio punto. Pasarse de 7,5 pierde.
##    La banca pide hasta tener 6 o más y gana los empates. Siete y media justo paga doble.
## Online se sientan hasta 4 contra la misma banca. El anfitrión lleva la mesa (baraja, turnos y pagos)
## y manda cada suceso a todos con `_send`; cada jugador solo elige su apuesta y sus jugadas (`_send_act`).
## En solitario es lo mismo sin red, con un único asiento.

const DECK_POS := Vector2(586, 150)
const ME_Y := 252.0
const MULTI_Y := 262.0
const BANK_Y := 96.0
const BETS := [5, 10, 20, 50, 100]
const BANK_LOOK := {"color": 7, "c2": 2, "hat": 6, "skin": 1, "eyes": 0, "extra": 1}
const RED := Color("ff6a5a")
const GREEN := Color("5ff0b0")

signal acted(seat: int, id: String)

var game: Node
var kind := "bj"  # bj o 7m
## bet: eligiendo apuesta · ready: apostado, esperando a los demás · deal · player: mi turno ·
## wait: turno de otro · bank · result
var state := "bet"
var seats: Array = []  # {name, pi, look, peer, chips, bet, ready, gone, res, delta}
var me_seat := 0
var hands: Array = []  # por asiento: [CardNode]
var bank: Array = []
var turn := -1
var bet_i := 1
var actions: Array = []  # [id, texto] en mi turno
var act_sel := 0
var act_rects: Array = []
var result_text := ""
var result_col := Pix.GOLD
var t := 0.0
var shown_chips := 0.0
var rng := RandomNumberGenerator.new()
var _sess := 0
var _auto_t := 0.0
# Solo en el anfitrión
var shoe: Array = []
var h_cards: Array = []  # por asiento: [int]
var b_cards: Array = []
var _round := false  # hay una mano en juego (las apuestas nuevas esperan a la siguiente)


func setup(g: Node, k: String) -> void:
	game = g
	kind = k
	rng.randomize()
	seats = []
	for p in game.players:
		var pd: Dictionary = p
		var mine_p: bool = (pd.kind == "human") if Net.is_host() else (pd.kind == "remote" and int(pd.peer) == multiplayer.get_unique_id())
		var ch: int = int(game.cfg.get("fichas", 100)) if mine_p else int(pd.get("fichas", 100))
		seats.append({"name": pd.name, "pi": pd.pi, "look": pd.get("look", {}), "peer": pd.peer, "chips": ch,
			"bet": 0, "ready": false, "gone": false, "res": 99, "delta": 0})
		if mine_p:
			me_seat = seats.size() - 1
	hands = []
	for i in seats.size():
		hands.append([])
	shown_chips = chips()
	if is_host():
		_new_shoe()
		_send({"t": "seats", "seats": seats})


func is_host() -> bool:
	return Net.is_host()


func multi() -> bool:
	return seats.size() > 1


func chips() -> int:
	return int(seats[me_seat].chips) if me_seat < seats.size() else 0


func title() -> String:
	return "BLACKJACK" if kind == "bj" else "SIETE Y MEDIA"


func _new_shoe() -> void:
	shoe = []
	for s in 4:
		for v in range(1, 15):
			if kind == "7m" and v >= 8 and v <= 10:
				continue  # la siete y media se juega sin 8, 9 ni 10
			shoe.append(Deck.minor(s, v))
	for i in range(shoe.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = shoe[i]
		shoe[i] = shoe[j]
		shoe[j] = tmp


# --- Valores ---

static func card_value(k: String, c: int) -> float:
	var v := Deck.value(c)
	if k == "bj":
		return 10.0 if v >= 10 else float(v)
	return 0.5 if v >= 11 else float(v)


## Total de una lista de cartas (números); las tapadas (-1) no cuentan.
static func score(k: String, cards: Array) -> float:
	var s := 0.0
	var aces := 0
	for c in cards:
		if int(c) < 0:
			continue
		s += card_value(k, int(c))
		if k == "bj" and Deck.value(int(c)) == 1:
			aces += 1
	if k == "bj" and aces > 0 and s + 10.0 <= 21.0:
		s += 10.0  # un As vale 11 si no te pasas
	return s


## Total de una mano en la mesa (solo las cartas boca arriba).
func total(hand_nodes: Array) -> float:
	var cs := []
	for cn in hand_nodes:
		cs.append(cn.card if cn.face_up else -1)
	return score(kind, cs)


func limit() -> float:
	return 21.0 if kind == "bj" else 7.5


func _fmt(v: float) -> String:
	return ("%d" % int(v)) if is_equal_approx(v, roundf(v)) else ("%d,5" % int(v))


func _natural(cards: Array) -> bool:
	return kind == "bj" and cards.size() == 2 and is_equal_approx(score(kind, cards), 21.0)


# --- Red: el anfitrión manda sucesos, los jugadores mandan jugadas ---

func _send(ev: Dictionary) -> void:
	apply(ev)
	game.casino_broadcast(ev)


func _send_act(id: String, data = null) -> void:
	if is_host():
		remote_act(1, id, data, me_seat)
	else:
		game.casino_send_act(id, data)


## Jugada que llega al anfitrión (de la red o de su propio mando).
func remote_act(peer: int, id: String, data, seat := -1) -> void:
	if seat < 0:
		for i in seats.size():
			if int(seats[i].peer) == peer and i != me_seat:
				seat = i
	if seat < 0 or seat >= seats.size() or seats[seat].gone:
		return
	match id:
		"bet":
			var sd: Dictionary = seats[seat]
			if sd.ready or _round or not (data is int or data is float):
				return
			if int(sd.chips) < BETS[0]:
				sd.chips = 100
				_send({"t": "comic", "seat": seat, "s": "LA CASA TE PRESTA 100", "col": "gold", "sfx": "win"})
			var b: int = BETS[0]
			for v in BETS:
				if int(v) <= int(data) and int(v) <= int(sd.chips):
					b = int(v)
			sd.bet = b
			sd.chips = int(sd.chips) - b
			sd.ready = true
			_send({"t": "seats", "seats": seats})
			_maybe_start()
		"hit", "stand", "double":
			acted.emit(seat, id)


## Alguien se ha ido de la sala: su asiento se queda vacío y, si le tocaba, se planta.
func peer_left(peer: int) -> void:
	for i in seats.size():
		if int(seats[i].peer) == peer and i != me_seat and not seats[i].gone:
			seats[i].gone = true
			game._toast("%s SE HA IDO" % seats[i].name)
			_send({"t": "seats", "seats": seats})
			acted.emit(i, "stand")
	_maybe_start()


func _maybe_start() -> void:
	if _round:
		return
	for sd in seats:
		if not sd.gone and not sd.ready:
			return
	_host_round()


## Aplica un suceso en esta pantalla (en todas, también la del anfitrión).
func apply(ev: Dictionary) -> void:
	match String(ev.get("t", "")):
		"seats":
			seats = ev.seats
			game.cfg.fichas = chips()
		"clear":
			_clear()
			for sd in seats:
				sd.res = 99
			state = "deal"
			act_sel = 0
		"shuffle":
			Sfx.play("shuffle")
		"give":
			_give(int(ev.who), int(ev.card))
		"reveal":
			for cn in bank:
				if not cn.face_up:
					cn.card = int(ev.card)
					Sfx.play("flip")
					cn.flip(true)
					break
		"turn":
			turn = int(ev.seat)
			if turn == me_seat:
				state = "player"
				actions = ev.acts
				act_sel = clampi(act_sel, 0, actions.size() - 1)
				if multi():
					Sfx.play("ding", -6.0)
			else:
				state = "wait"
		"comic":
			var who := int(ev.seat)
			var at := Vector2(320, BANK_Y + 70) if who < 0 else (Vector2(320, ME_Y - 70) if not multi() else Vector2(seat_x(who), MULTI_Y - 96))
			var col: Color = {"gold": Pix.GOLD, "red": RED, "green": GREEN}.get(String(ev.col), Pix.CREAM)
			game.hud.comic(at, String(ev.s), col, 2.0 if multi() else 2.4)
			if ev.has("sfx"):
				Sfx.play(String(ev.sfx))
			if String(ev.get("sfx", "")) == "ko" and who == me_seat:
				game.shake = 4.0
		"bank":
			turn = -1
			state = "bank"
		"result":
			turn = -1
			seats = ev.seats
			_show_result()


func _show_result() -> void:
	var sd: Dictionary = seats[me_seat]
	var r := int(sd.res)
	var d := int(sd.delta)
	match r:
		2:
			result_text = "¡BLACKJACK! +%d" % d
			result_col = Pix.GOLD
		1:
			result_text = ("¡SIETE Y MEDIA! +%d" if kind == "7m" and is_equal_approx(total(hands[me_seat]), 7.5) else "¡GANAS! +%d") % d
			result_col = GREEN
		0:
			result_text = "EMPATE"
			result_col = Pix.CREAM
		99:
			result_text = "NO JUGASTE ESTA MANO"
			result_col = Pix.CREAM
		_:
			result_text = "PIERDES %d" % -d
			result_col = RED
	if r == 1 or r == 2:
		Sfx.play("win")
		game.hud.confetti(60 if r == 2 else 30)
		for cn in hands[me_seat]:
			cn.glow = 1.0
			cn.glow_col = Pix.GOLD
	elif r < 0:
		Sfx.play("warn")
	for i in seats.size():
		if int(seats[i].res) == -1:
			for cn in hands[i]:
				cn.dim = 0.5
	game.cfg.fichas = chips()
	game._save_cfg()
	state = "result"


# --- La mano (anfitrión) ---

func _host_round() -> void:
	_round = true
	_sess += 1
	var s := _sess
	_send({"t": "clear"})
	h_cards = []
	for i in seats.size():
		h_cards.append([])
	b_cards = []
	if shoe.size() < 10 + 6 * seats.size():
		_new_shoe()
		_send({"t": "shuffle"})
		await _wait(0.5)
	var live := _live()
	for i in live:
		await _host_give(i, true)
	if kind == "bj":
		await _host_give(-1, true)
		for i in live:
			await _host_give(i, true)
		await _host_give(-1, false)
	for i in live:
		if s != _sess:
			return
		if _natural(h_cards[i]):
			_send({"t": "comic", "seat": i, "s": "¡BLACKJACK!", "col": "gold", "sfx": "ding"})
			await _wait(0.6)
			continue
		await _host_turn(i)
	if s != _sess:
		return
	await _host_bank()
	if s != _sess:
		return
	_host_pay()


func _live() -> Array:
	var out := []
	for i in seats.size():
		if not seats[i].gone and seats[i].ready:
			out.append(i)
	return out


## Reparte una carta a un asiento (o a la banca con -1). La tapada de la banca viaja como -1.
func _host_give(who: int, up: bool) -> void:
	if shoe.is_empty():
		_new_shoe()
		_send({"t": "shuffle"})
	var c: int = shoe.pop_back()
	if who < 0:
		b_cards.append(c)
	else:
		h_cards[who].append(c)
	_send({"t": "give", "who": who, "card": c if up else -1})
	await _wait(0.5 if up else 0.34)


func _host_turn(i: int) -> void:
	var s := _sess
	var bust := "¡TE PASAS!" if not multi() else "¡SE PASA!"
	while s == _sess and not seats[i].gone:
		var acts := [["hit", "PEDIR"], ["stand", "PLANTARSE"]]
		if kind == "bj" and h_cards[i].size() == 2 and int(seats[i].chips) >= int(seats[i].bet):
			acts.append(["double", "DOBLAR"])
		_send({"t": "turn", "seat": i, "acts": acts})
		var id := await _wait_act(i)
		if s != _sess:
			return
		match id:
			"hit":
				await _host_give(i, true)
				var v := score(kind, h_cards[i])
				if v > limit():
					_send({"t": "comic", "seat": i, "s": bust, "col": "red", "sfx": "ko"})
					await _wait(0.8)
					return
				if is_equal_approx(v, limit()):
					return
			"double":
				if kind != "bj" or h_cards[i].size() != 2 or int(seats[i].chips) < int(seats[i].bet):
					continue
				seats[i].chips = int(seats[i].chips) - int(seats[i].bet)
				seats[i].bet = int(seats[i].bet) * 2
				_send({"t": "seats", "seats": seats})
				_send({"t": "comic", "seat": i, "s": "¡DOBLO!", "col": "gold", "sfx": "count"})
				await _host_give(i, true)
				if score(kind, h_cards[i]) > limit():
					_send({"t": "comic", "seat": i, "s": bust, "col": "red", "sfx": "ko"})
					await _wait(0.8)
				return
			_:
				_send({"t": "turn", "seat": -1, "acts": []})
				return


func _wait_act(i: int) -> String:
	var id := ""
	while id == "":
		var r: Array = await acted
		if int(r[0]) == i:
			id = String(r[1])
	return id


func _host_bank() -> void:
	var s := _sess
	_send({"t": "bank"})
	await _wait(0.35)
	if kind == "bj":
		_send({"t": "reveal", "card": b_cards[-1]})
		await _wait(0.3)
	# Contra quién juega la banca: los que no se han pasado ni tienen blackjack
	var standing := []
	for i in _live():
		if score(kind, h_cards[i]) <= limit() and not _natural(h_cards[i]):
			standing.append(i)
	var stop := 17.0 if kind == "bj" else 6.0
	while s == _sess and not standing.is_empty():
		var b := score(kind, b_cards)
		var need := b < stop
		if kind == "7m" and not need and b < 7.5:
			# En la siete y media la banca sigue pidiendo si va perdiendo contra todos
			need = standing.all(func(i): return score(kind, h_cards[i]) > b)
		if not need:
			break
		await _wait(0.45)
		await _host_give(-1, true)
	if s != _sess:
		return
	await _wait(0.4)
	if score(kind, b_cards) > limit() and not standing.is_empty():
		_send({"t": "comic", "seat": -1, "s": "¡LA BANCA SE PASA!", "col": "gold"})


func _host_pay() -> void:
	var b := score(kind, b_cards)
	for i in seats.size():
		var sd: Dictionary = seats[i]
		if sd.gone or not sd.ready:
			sd.res = 99
			sd.delta = 0
			sd.ready = false
			continue
		var me := score(kind, h_cards[i])
		var bet := int(sd.bet)
		var r := -1
		if me > limit():
			r = -1
		elif _natural(h_cards[i]) and not _natural(b_cards):
			r = 2
		elif b > limit():
			r = 1
		elif me > b and not (kind == "7m" and is_equal_approx(me, b)):
			r = 1
		elif is_equal_approx(me, b) and kind == "bj":
			r = 0
		var back := 0
		match r:
			2:
				back = bet + int(bet * 1.5)  # 3 a 2
			1:
				back = bet + bet * (2 if kind == "7m" and is_equal_approx(me, 7.5) else 1)
			0:
				back = bet
		sd.chips = int(sd.chips) + back
		sd.res = r
		sd.delta = back - bet
		sd.ready = false
	_round = false
	_send({"t": "result", "seats": seats})


# --- Bucle (esta pantalla) ---

func step(_delta: float) -> void:
	t += _delta
	shown_chips = move_toward(shown_chips, chips(), maxf(1.0, absf(chips() - shown_chips)) * _delta * 4.0)
	if game.auto_play:
		_auto(_delta)
	match state:
		"bet":
			if game._any("left"):
				bet_i = maxi(0, bet_i - 1)
				Sfx.play("tick")
			if game._any("right"):
				bet_i = mini(BETS.size() - 1, bet_i + 1)
				Sfx.play("tick")
			if game._any("ok"):
				_place_bet()
			elif game._any("back"):
				game._leave_casino()
		"player":
			if game._any("left"):
				act_sel = (act_sel + actions.size() - 1) % actions.size()
				Sfx.play("tick")
			if game._any("right"):
				act_sel = (act_sel + 1) % actions.size()
				Sfx.play("tick")
			if game._any("ok"):
				_act(String(actions[act_sel][0]))
		"result":
			if game._any("ok"):
				_next_hand()
			elif game._any("back"):
				game._leave_casino()
		_:
			if multi() and game._any("back"):
				game._leave_casino()


## Pruebas: esta pantalla juega sola (pide hasta 16 en el blackjack y hasta 5 en la siete y media).
func _auto(delta: float) -> void:
	_auto_t += delta
	if _auto_t < 0.6:
		return
	match state:
		"bet":
			_auto_t = 0.0
			_place_bet()
		"player":
			_auto_t = 0.0
			_act("hit" if total(hands[me_seat]) < (16.0 if kind == "bj" else 5.0) else "stand")


func _place_bet() -> void:
	Sfx.play("count", -4.0)
	state = "ready"
	_send_act("bet", BETS[bet_i])


func _act(id: String) -> void:
	state = "wait"
	_send_act(id)


func _next_hand() -> void:
	_clear()
	state = "bet"
	Sfx.play("select")


func mouse(mp: Vector2, click: bool, moved: bool) -> void:
	if state == "player":
		for i in act_rects.size():
			if act_rects[i].has_point(mp):
				if moved and act_sel != i:
					act_sel = i
					Sfx.play("tick", -8.0)
				if click:
					act_sel = i
					Pad.mouse_ok = true
	elif state == "bet":
		for i in act_rects.size():
			if act_rects[i].has_point(mp) and click:
				bet_i = i
				Sfx.play("tick")
		if click and _deal_rect().has_point(mp):
			Pad.mouse_ok = true
	elif state == "result":
		Pad.mouse_ok = click


# --- Cartas en la mesa ---

func _give(who: int, c: int) -> void:
	var hand_nodes: Array = bank if who < 0 else hands[who]
	var cn := CardNode.new()
	cn.setup(c, false)
	cn.position = DECK_POS
	cn.target_pos = DECK_POS
	cn.z_index = 10 + hand_nodes.size()
	add_child(cn)
	hand_nodes.append(cn)
	_layout(hand_nodes, who)
	Sfx.play("swish", -4.0)
	var dest: Vector2 = cn.target_pos
	cn.fly_to(dest, cn.target_rot, 1.0, 0.32, -50.0, 1.0)
	await _wait(0.2)
	if c >= 0 and is_instance_valid(cn):
		Sfx.play("flip", -2.0)
		await cn.flip(true, 0.14)
	await _wait(0.14)
	Sfx.play("land", -6.0)


func seat_x(i: int) -> float:
	if not multi():
		return 300.0
	return 320.0 + (i - (seats.size() - 1) / 2.0) * 150.0


func _layout(hand_nodes: Array, who: int) -> void:
	var y := BANK_Y if who < 0 else (ME_Y if not multi() else MULTI_Y)
	var cx := 300.0 if who < 0 else seat_x(who)
	var st := minf(46.0, 300.0 / maxf(1, hand_nodes.size()))
	if who >= 0 and multi():
		st = minf(22.0, 80.0 / maxf(1, hand_nodes.size() - 1))
	for i in hand_nodes.size():
		var cn: CardNode = hand_nodes[i]
		cn.target_pos = Vector2(cx + (i - (hand_nodes.size() - 1) / 2.0) * st, y)
		cn.target_rot = (i - (hand_nodes.size() - 1) / 2.0) * 0.04
		cn.z_index = 10 + i


func _clear() -> void:
	var all := bank.duplicate()
	for h in hands:
		all.append_array(h)
	for cn in all:
		var c: CardNode = cn
		if not is_instance_valid(c):
			continue
		c.fly_to(DECK_POS + Vector2(80, -200), 0.6, 0.8, 0.3, 30.0)
		get_tree().create_timer(0.35).timeout.connect(c.queue_free)
	if not all.is_empty():
		Sfx.play("swish")
	bank = []
	for i in hands.size():
		hands[i] = []


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


# --- Dibujo (lo llama la interfaz) ---

func _deal_rect() -> Rect2:
	return Rect2(240, 300, 160, 24) if not multi() else Rect2(240, 230, 160, 24)


func draw_ui(ci: CanvasItem) -> void:
	# Mazo
	for k in 5:
		ci.draw_texture(Deck.back(), DECK_POS - Vector2(35, 54) + Vector2(k, -k))
	Pix.draw_text(ci, Vector2(12, 10), title(), Pix.GOLD, 2)
	var rule := "LLEGA A 21 SIN PASARTE · LA BANCA SE PLANTA CON 17" if kind == "bj" else "LLEGA A 7 Y MEDIA SIN PASARTE · LAS FIGURAS VALEN MEDIO PUNTO"
	Pix.draw_text(ci, Vector2(12, 30), rule, Color(Pix.CREAM, 0.7))
	# Fichas
	_chip_stack(ci, Vector2(30, 330), int(shown_chips))
	Pix.draw_text(ci, Vector2(52, 324), "%d FICHAS" % int(roundf(shown_chips)), Pix.GOLD)
	# Banca y jugadores
	_seat(ci, Vector2(64, BANK_Y - 30), Pix.portrait_look(BANK_LOOK), "LA BANCA", bank)
	if not multi():
		var sd: Dictionary = seats[me_seat]
		_seat(ci, Vector2(64, ME_Y - 30), Pix.face(sd), String(sd.name), hands[me_seat])
	else:
		for i in seats.size():
			_seat_multi(ci, i)
	act_rects = []
	var mid := 160 if not multi() else 152  # línea de avisos entre la banca y los jugadores
	match state:
		"bet":
			var y0 := 150 if not multi() else 124
			Pix.draw_text_c(ci, 320, y0, "¿CUANTO APUESTAS?", Pix.CREAM, 2)
			for i in BETS.size():
				var r := Rect2(176 + i * 60, y0 + 24, 52, 40)
				var sel := i == bet_i
				var ok: bool = BETS[i] <= maxi(chips(), BETS[0])
				game.hud._box(r, Color(Pix.PURPLE, 0.95) if sel else Color("1e1236", 0.9), Pix.GOLD if sel else Color("4a3a6a"))
				_chip(ci, r.position + Vector2(26, 14 - (2 if sel else 0) + roundf(sin(t * 6.0) * 1.5) * (1 if sel else 0)), i)
				Pix.draw_text_c(ci, r.get_center().x, r.end.y - 12, str(BETS[i]), (Pix.GOLD if sel else Pix.CREAM) if ok else Color(Pix.CREAM, 0.3))
				act_rects.append(r)
			var dr := _deal_rect()
			game.hud._box(dr, Color(Pix.PURPLE, 0.95), Pix.GOLD)
			Pix.draw_text_c(ci, 320, dr.position.y + 8, "✕ REPARTIR" if not multi() else "✕ APOSTAR", Pix.GOLD)
			Pix.draw_text(ci, Vector2(500, 344), "○ SALIR", Color(Pix.CREAM, 0.7))
		"ready":
			if multi():
				var dots := ".".repeat(int(t * 3.0) % 4)
				Pix.draw_text_c(ci, 320, 140, "ESPERANDO A LOS DEMAS" + dots, Pix.CREAM, 2)
				Pix.draw_text(ci, Vector2(500, 344), "○ SALIR", Color(Pix.CREAM, 0.7))
		"player":
			var x := 320 - actions.size() * 52
			var by := 312 if not multi() else 330
			for i in actions.size():
				var r := Rect2(x + i * 104, by, 96, 22)
				var sel := i == act_sel
				game.hud._box(r, Color(Pix.PURPLE, 0.95) if sel else Color("1e1236", 0.9), Pix.GOLD if sel else Color("4a3a6a"))
				Pix.draw_text_c(ci, r.get_center().x, r.position.y + 7, actions[i][1], Pix.GOLD if sel else Pix.CREAM)
				act_rects.append(r)
			if multi():
				Pix.draw_text_c(ci, 320, mid, "¡TU TURNO!", Pix.GOLD)
		"wait":
			if multi() and turn >= 0 and turn < seats.size():
				Pix.draw_text_c(ci, 320, mid, "TURNO DE %s" % seats[turn].name, Pix.CREAM)
		"bank":
			if multi():
				Pix.draw_text_c(ci, 320, mid, "JUEGA LA BANCA", Pix.CREAM)
		"result":
			# Online va más pequeño, en el hueco entre la banca y los asientos
			var sc := 3 if not multi() else 2
			var w := Pix.text_width(result_text, sc) + 40
			var ry := 160 if not multi() else 151
			game.hud._box(Rect2(320 - w / 2.0, ry, w, 12 * sc + 4), Color("1e1236", 0.96), result_col)
			Pix.draw_text_c(ci, 320, ry + 2 + 2 * sc, result_text, result_col, sc)
			Pix.draw_text_c(ci, 320, 314 if not multi() else 340, "✕ OTRA MANO   ○ SALIR", Pix.CREAM)
	if not multi() and state not in ["bet", "ready"]:
		Pix.draw_text(ci, Vector2(52, 340), "APUESTA %d" % int(seats[me_seat].bet), Color(Pix.GOLD, 0.8))


func _seat(ci: CanvasItem, at: Vector2, face_tex: Texture2D, nm: String, hand_nodes: Array) -> void:
	ci.draw_texture_rect(face_tex, Rect2(at - Vector2(27, 21), Vector2(54, 42)), false)
	Pix.draw_text_c(ci, at.x, at.y + 26, nm, Pix.CREAM)
	if not hand_nodes.is_empty():
		_total_box(ci, Vector2(at.x, at.y + 40), hand_nodes, 2)


func _total_box(ci: CanvasItem, top_c: Vector2, hand_nodes: Array, sc: int) -> void:
	var v := total(hand_nodes)
	var hidden := hand_nodes.any(func(cn): return not cn.face_up)
	var txt := _fmt(v) + ("+?" if hidden else "")
	var col := RED if v > limit() else (Pix.GOLD if is_equal_approx(v, limit()) else Pix.CREAM)
	var w := Pix.text_width(txt, sc) + 8 * sc
	game.hud._box(Rect2(top_c.x - w / 2.0, top_c.y, w, 7 * sc + 8), Color("1e1236", 0.95), col)
	Pix.draw_text_c(ci, top_c.x, top_c.y + 4 + (1 if sc == 2 else 0), txt, col, sc)


## Un asiento de la mesa online: cara, nombre, apuesta (o lo que ha ganado) y el total de sus cartas.
func _seat_multi(ci: CanvasItem, i: int) -> void:
	var sd: Dictionary = seats[i]
	var x := seat_x(i)
	var y := 178.0
	var mine := i == me_seat
	var alpha := 0.35 if sd.gone else 1.0
	if turn == i:
		var ay := y - 10 + roundf(sin(t * 8.0) * 2.0)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, ay), Vector2(x + 6, ay), Vector2(x, ay + 6)]), Pix.GOLD)
	game.hud._box(Rect2(x - 68, y, 136, 26), Color("1e1236", 0.9 * alpha), Pix.GOLD if mine or turn == i else Color("4a3a6a", alpha))
	ci.draw_texture_rect(Pix.face(sd), Rect2(x - 64, y + 1, 32, 24), false, Color(1, 1, 1, alpha))
	var col: Color = Pix.PLAYERS[int(sd.pi) % Pix.PLAYERS.size()].c1[0]
	Pix.draw_text(ci, Vector2(x - 28, y + 4), String(sd.name) + (" (TU)" if mine else ""), Color(col, alpha))
	var line := ""
	var lcol := Color(Pix.GOLD, 0.85 * alpha)
	if sd.gone:
		line = "SE HA IDO"
	elif int(sd.res) != 99 and not sd.ready:
		var d := int(sd.delta)
		line = ("+%d" % d) if d > 0 else ("EMPATE" if d == 0 else "%d" % d)
		lcol = GREEN if d > 0 else (Pix.CREAM if d == 0 else RED)
	elif sd.ready:
		line = "APUESTA %d" % int(sd.bet)
	else:
		line = "APOSTANDO..." if state in ["bet", "ready", "result"] else "MIRANDO"
	Pix.draw_text(ci, Vector2(x - 28, y + 15), line, lcol)
	if not hands[i].is_empty():
		_total_box(ci, Vector2(x + 50, y + 5), hands[i], 1)


const CHIP_COLS := [Color("e8e0d0"), Color("e8384f"), Color("3b8bea"), Color("37c25a"), Color("1a1026")]


func _chip(ci: CanvasItem, c: Vector2, i: int) -> void:
	var col: Color = CHIP_COLS[i % CHIP_COLS.size()]
	ci.draw_circle(c + Vector2(0, 2), 9.0, Pix.INK)
	ci.draw_circle(c, 9.0, Pix.INK)
	ci.draw_circle(c, 8.0, col)
	for k in 6:
		var a := k * TAU / 6.0 + t * 0.5
		ci.draw_rect(Rect2((c + Vector2(cos(a), sin(a)) * 6.0 - Vector2(1, 1)).round(), Vector2(2, 2)), Pix.CREAM if i != 0 else Color("b8806a"))
	ci.draw_circle(c, 4.0, col.darkened(0.25))


func _chip_stack(ci: CanvasItem, at: Vector2, n_chips: int) -> void:
	var n_st := clampi(n_chips / 25, 1, 8)
	for k in n_st:
		_chip(ci, at + Vector2(0, -k * 3), (k + 1) % 4)
