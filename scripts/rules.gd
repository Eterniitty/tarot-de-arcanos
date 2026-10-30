class_name Rules
extends RefCounted
## Reglas del tarot (variante francesa, 3 o 4 jugadores): el que gana la subasta juega solo contra los demás.
## Subasta: Pequeña ×1, Guardia ×2, Guardia sin perro ×4, Guardia contra el perro ×6.
## Se sigue el palo; sin él hay que fallar con triunfo y montar (superar el triunfo más alto) si se puede.
## El Loco (la Excusa) se juega cuando quieras, no gana nunca y vuelve a su equipo a cambio de medio punto.
## Puntos necesarios según las bazas mayores (1, 21, Loco) que gane el que toma: 0→56, 1→51, 2→41, 3→36.

const CONTRACTS := ["PASO", "PEQUEÑA", "GUARDIA", "GUARDIA SIN", "GUARDIA CONTRA"]
const MULT := [0, 1, 2, 4, 6]
const NEEDED := [112, 102, 82, 72]  # medios puntos

var n := 4
var dealer := 0
var hands: Array = []  # [p] -> Array[int]
var chien: Array = []
var phase := "bid"  # bid, discard, play, done, redeal
var bids: Array = []  # [p] -> -1 sin hablar, 0 paso, 1..4
var turn := 0
var contract := 0
var taker := -1
var trick: Array = []  # [[p, c], ...]
var leader := 0
var tricks_left := 0
var piles: Array = [[], []]  # 0 = el que toma, 1 = defensa
var excuse_debt := -1  # equipo que debe medio punto por la Excusa (-1 nada)
var last_trick: Array = []
var last_winner := -1
var petit_last := -1  # equipo que llevó el 1 a la última baza y la ganó (-1 nadie)
var played: Array = []  # todas las cartas jugadas en orden [[p, c]]
var discards: Array = []  # lo que aparta el que toma (solo lo conoce él)
var tricks_won := [0, 0]
var deal_seq: Array = []  # [[jugador o -1 = perro, carta]] en el orden del reparto (para la animación)


func deal(p_n: int, p_dealer: int, rng: RandomNumberGenerator) -> void:
	n = p_n
	dealer = p_dealer
	var d := Deck.shuffled(rng)
	var per := 18 if n == 4 else 24
	hands = []
	for p in n:
		hands.append([])
	chien = []
	# Reparto de tres en tres; seis veces, entre medias, una carta va al perro (nunca en la primera ni la última vuelta).
	var rounds := per * n / 3
	var slots: Array = range(1, rounds - 1)
	for i in range(slots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = slots[i]
		slots[i] = slots[j]
		slots[j] = t
	slots = slots.slice(0, 6)
	deal_seq = []
	var idx := 0
	var who := (dealer + 1) % n
	for r in rounds:
		for k in 3:
			hands[who].append(d[idx])
			deal_seq.append([who, d[idx]])
			idx += 1
		if r in slots:
			chien.append(d[idx])
			deal_seq.append([-1, d[idx]])
			idx += 1
		who = (who + 1) % n
	for p in n:
		hands[p] = Deck.sorted(hands[p])
	bids = []
	for p in n:
		bids.append(-1)
	phase = "bid"
	turn = (dealer + 1) % n
	contract = 0
	taker = -1
	trick = []
	piles = [[], []]
	excuse_debt = -1
	last_trick = []
	last_winner = -1
	petit_last = -1
	played = []
	discards = []
	tricks_won = [0, 0]
	tricks_left = per
	# Si alguien tiene el 1 de triunfo solo (sin más triunfos ni el Loco), se reparte otra vez ("petit sec").
	for p in n:
		var trumps: Array = hands[p].filter(func(c): return Deck.is_trump(c))
		if trumps == [1] and not (Deck.EXCUSE in hands[p]):
			phase = "redeal"


## Tutorial: reparto fijo (manos y perro dados) con su secuencia de reparto para la animación.
func set_fixed(p_hands: Array, p_chien: Array, p_dealer: int) -> void:
	dealer = p_dealer
	hands = []
	for h in p_hands:
		hands.append(Deck.sorted(h))
	chien = p_chien.duplicate()
	deal_seq = []
	var idx := []
	for p in n:
		idx.append(0)
	var ci := 0
	var who := (dealer + 1) % n
	var rounds: int = hands[0].size() * n / 3
	for rr in rounds:
		for k in 3:
			deal_seq.append([who, p_hands[who][idx[who]]])
			idx[who] += 1
		if rr % 4 == 2 and ci < chien.size():
			deal_seq.append([-1, chien[ci]])
			ci += 1
		who = (who + 1) % n
	phase = "bid"
	turn = (dealer + 1) % n


## Tutorial: cambia cartas entre manos y perro para que el jugador p tenga justo estas (y arregla el reparto).
func rig(p: int, wanted: Array) -> void:
	var spare: Array = hands[p].filter(func(c): return not (c in wanted))
	for c in wanted:
		if c in hands[p] or spare.is_empty():
			continue
		var give: int = spare.pop_back()
		var src: Array = chien
		for q in n:
			if c in hands[q]:
				src = hands[q]
		src[src.find(c)] = give
		hands[p][hands[p].find(give)] = c
		for d in deal_seq:
			if d[1] == c:
				d[1] = give
			elif d[1] == give:
				d[1] = c
	for q in n:
		hands[q] = Deck.sorted(hands[q])


func team(p: int) -> int:
	return 0 if p == taker else 1


func best_bid() -> int:
	var b := 0
	for x in bids:
		b = maxi(b, x)
	return b


func can_bid(b: int) -> bool:
	return b == 0 or b > best_bid()


## Devuelve true si la subasta ha terminado.
func bid(p: int, b: int) -> bool:
	if phase != "bid" or p != turn or not can_bid(b):
		return false
	bids[p] = b
	var k := 1
	while k <= n:
		var q := (p + k) % n
		if bids[q] == -1:
			turn = q
			return false
		k += 1
	contract = best_bid()
	if contract == 0:
		phase = "redeal"
		return true
	taker = bids.find(contract)
	match contract:
		1, 2:
			hands[taker].append_array(chien)
			hands[taker] = Deck.sorted(hands[taker])
			phase = "discard"
			turn = taker
		3:
			piles[0].append_array(chien)
			_start_play()
		4:
			piles[1].append_array(chien)
			_start_play()
	return true


func can_discard(c: int) -> bool:
	if Deck.is_oudler(c) or (Deck.suit(c) < 4 and Deck.value(c) == 14):
		return false
	if Deck.is_trump(c):
		# Solo si no queda nada más que apartar.
		var others: Array = hands[taker].filter(func(x): return not Deck.is_trump(x) and not Deck.is_oudler(x) and not (Deck.suit(x) < 4 and Deck.value(x) == 14))
		return others.size() < 6
	return true


func discard(cards: Array) -> bool:
	if phase != "discard" or cards.size() != 6:
		return false
	for c in cards:
		if not (c in hands[taker]) or not can_discard(c):
			return false
	for c in cards:
		hands[taker].erase(c)
	discards = cards.duplicate()
	piles[0].append_array(cards)
	_start_play()
	return true


func _start_play() -> void:
	phase = "play"
	leader = (dealer + 1) % n
	turn = leader
	trick = []


func led_suit() -> int:
	for e in trick:
		if e[1] != Deck.EXCUSE:
			return Deck.suit(e[1])
	return -1


func highest_trump_in_trick() -> int:
	var h := 0
	for e in trick:
		if Deck.is_trump(e[1]):
			h = maxi(h, e[1])
	return h


static func legal_for(hand: Array, trick_cards: Array) -> Array:
	var led := -1
	var high := 0
	for c in trick_cards:
		if led == -1 and c != Deck.EXCUSE:
			led = Deck.suit(c)
		if Deck.is_trump(c):
			high = maxi(high, c)
	if led == -1:
		return hand.duplicate()
	var out: Array = []
	var has_excuse: bool = Deck.EXCUSE in hand
	if led != Deck.TRUMP:
		for c in hand:
			if c != Deck.EXCUSE and Deck.suit(c) == led:
				out.append(c)
		if not out.is_empty():
			if has_excuse:
				out.append(Deck.EXCUSE)
			return out
	var trumps: Array = hand.filter(func(c): return Deck.is_trump(c))
	if not trumps.is_empty():
		var over: Array = trumps.filter(func(c): return c > high)
		out = over if not over.is_empty() else trumps
		if has_excuse:
			out.append(Deck.EXCUSE)
		return out
	return hand.duplicate()


func legal(p: int) -> Array:
	return legal_for(hands[p], trick.map(func(e): return e[1]))


static func trick_winner_idx(trick_cards: Array) -> int:
	var best := -1
	var led := -1
	for i in trick_cards.size():
		var c: int = trick_cards[i]
		if c == Deck.EXCUSE:
			continue
		if led == -1:
			led = Deck.suit(c)
			best = i
			continue
		var b: int = trick_cards[best]
		if Deck.is_trump(c):
			if not Deck.is_trump(b) or c > b:
				best = i
		elif not Deck.is_trump(b) and Deck.suit(c) == led and Deck.value(c) > Deck.value(b):
			best = i
	return best


## Juega una carta. Devuelve {} o, si se cierra la baza, {"winner": p, "cards": [...]}.
func play(p: int, c: int) -> Dictionary:
	if phase != "play" or p != turn or not (c in legal(p)):
		return {"error": true}
	hands[p].erase(c)
	trick.append([p, c])
	played.append([p, c])
	if trick.size() < n:
		turn = (p + 1) % n
		return {}
	var cards: Array = trick.map(func(e): return e[1])
	var wi := trick_winner_idx(cards)
	var winner: int = trick[wi][0]
	var wt := team(winner)
	tricks_left -= 1
	tricks_won[wt] += 1
	for e in trick:
		if e[1] == Deck.EXCUSE and tricks_left > 0:
			var et := team(e[0])
			piles[et].append(Deck.EXCUSE)
			if et != wt:
				excuse_debt = et
		else:
			piles[wt].append(e[1])
	if tricks_left == 0:
		for e in trick:
			if e[1] == 1 and team(e[0]) == wt:
				petit_last = wt
	last_trick = trick.duplicate()
	last_winner = winner
	trick = []
	leader = winner
	turn = winner
	if tricks_left == 0:
		_settle_excuse()
		phase = "done"
	return {"winner": winner, "cards": cards}


func _settle_excuse() -> void:
	if excuse_debt < 0:
		return
	var other := 1 - excuse_debt
	for c in piles[excuse_debt]:
		if Deck.half_points(c) == 1:
			piles[excuse_debt].erase(c)
			piles[other].append(c)
			return


func taker_half_points() -> int:
	var s := 0
	for c in piles[0]:
		s += Deck.half_points(c)
	return s


func taker_oudlers() -> int:
	return piles[0].filter(func(c): return Deck.is_oudler(c)).size()


## Resultado de la mano: puntos de cada jugador y el desglose para la pantalla final.
func score() -> Dictionary:
	var hp := taker_half_points()
	var ou := taker_oudlers()
	var need: int = NEEDED[ou]
	var diff := hp - need
	var won := diff >= 0
	var base := 25 + ceili(absi(diff) / 2.0)
	var petit := 0
	if petit_last >= 0:
		petit = 10 if petit_last == 0 else -10
	var m: int = MULT[contract]
	var unit := ((base if won else -base) + petit) * m
	var per: Array = []
	for p in n:
		per.append(unit * (n - 1) if p == taker else -unit)
	return {"half": hp, "oudlers": ou, "need": need, "diff": diff, "won": won, "base": base, "petit": petit,
		"mult": m, "unit": unit, "per": per, "taker": taker, "contract": contract}


func copy() -> Rules:
	var r := Rules.new()
	r.n = n
	r.dealer = dealer
	r.hands = hands.map(func(h): return h.duplicate())
	r.chien = chien.duplicate()
	r.phase = phase
	r.bids = bids.duplicate()
	r.turn = turn
	r.contract = contract
	r.taker = taker
	r.trick = trick.map(func(e): return e.duplicate())
	r.leader = leader
	r.tricks_left = tricks_left
	r.piles = [piles[0].duplicate(), piles[1].duplicate()]
	r.excuse_debt = excuse_debt
	r.petit_last = petit_last
	r.played = played.duplicate()
	r.discards = discards.duplicate()
	r.tricks_won = tricks_won.duplicate()
	return r
