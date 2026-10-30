class_name TarotAI
extends RefCounted
## IA del tarot. Subasta y descarte por valoración de la mano; en el juego, Monte Carlo con determinización:
## reparte al azar las cartas que no ve (respetando los fallos que ya ha mostrado cada rival), juega el resto de
## la mano con una política rápida para cada carta legal y elige la que da mejor resultado medio a su equipo.
## La subasta y la política rápida están entrenadas con manos jugadas entre IAs (tools/train_ai.gd).

## Niveles: muestras de Monte Carlo (0 = solo la política rápida), probabilidad de despiste y subasta.
const LEVELS := [
	{"name": "FACIL", "samples": 0, "blunder": 0.3, "bid": "naive"},
	{"name": "NORMAL", "samples": 0, "blunder": 0.05, "bid": "trained"},
	{"name": "DIFICIL", "samples": 20, "blunder": 0.0, "bid": "trained"},
	{"name": "EXPERTO", "samples": 40, "blunder": 0.0, "bid": "trained", "infer": true},
]

static var bid_w: Array = TarotAIParams.BID_W
var samples := 28
var level := 2
var blunder := 0.0
var infer := false  # deducir las manos rivales a partir de la subasta (Experto)
var prm: Dictionary = TarotAIParams.PLAY.duplicate()
var rng := RandomNumberGenerator.new()


func _init(seed_v := 0) -> void:
	if seed_v != 0:
		rng.seed = seed_v
	else:
		rng.randomize()


func set_level(l: int) -> void:
	level = clampi(l, 0, LEVELS.size() - 1)
	samples = LEVELS[level].samples
	blunder = LEVELS[level].blunder
	infer = LEVELS[level].get("infer", false)


## Carta para la partida según el nivel.
func decide_card(r: Rules, p: int) -> int:
	if samples > 0:
		return choose_card(r, p)
	var legal := r.legal(p)
	if blunder > 0.0 and rng.randf() < blunder:
		return legal[rng.randi() % legal.size()]
	return quick(r, p)


# --- Subasta ---

## Rasgos de una mano para el modelo de la subasta (los recuentos van normalizados a 18 cartas).
static func bid_features(hand: Array) -> Array:
	var k := 18.0 / hand.size()
	var nt := 0
	var big := 0
	var mid := 0
	var per := [0, 0, 0, 0]
	var heads := [0, 0, 0, 0]  # sotas, caballos, reinas, reyes
	for c in hand:
		if Deck.is_trump(c):
			nt += 1
			if c >= 16:
				big += 1
			elif c >= 11:
				mid += 1
		elif c > 21:
			per[Deck.suit(c)] += 1
			var v := Deck.value(c)
			if v >= 11:
				heads[v - 11] += 1
	var voids := 0
	var singles := 0
	var long := 0
	for s in 4:
		if per[s] == 0:
			voids += 1
		elif per[s] == 1:
			singles += 1
		long += maxi(0, per[s] - 4)
	var has1 := 1.0 if 1 in hand else 0.0
	var bare1 := has1 if nt <= 4 else 0.0
	return [1.0, 1.0 if 21 in hand else 0.0, 1.0 if Deck.EXCUSE in hand else 0.0, has1, bare1,
		nt * k, big * k, mid * k, heads[3] * k, heads[2] * k, heads[1] * k, heads[0] * k,
		voids, singles, long * k, (nt * k) * voids, maxf(0.0, nt * k - 7.0)]


## Margen esperado (por multiplicador) si esta mano toma con un tipo de contrato: 0 = con perro, 1 = sin, 2 = contra.
static func predict(hand: Array, ctype: int) -> float:
	var w: Array = bid_w[ctype]
	if w.is_empty():
		return hand_value(hand) - 45.0
	var f := bid_features(hand)
	var v := 0.0
	for i in mini(f.size(), w.size()):
		v += f[i] * w[i]
	return v


## Resultado para el que toma, sin multiplicar: ±(25 + diferencia) ± pequeño al final.
static func outcome(w: Rules) -> float:
	var sc := w.score()
	return float(sc.unit) / maxf(1.0, sc.mult)


static func hand_value(hand: Array) -> float:
	var v := 0.0
	var trumps: Array = hand.filter(func(c): return Deck.is_trump(c))
	var nt := trumps.size()
	if 21 in hand:
		v += 10.0
	if Deck.EXCUSE in hand:
		v += 8.0
	if 1 in hand:
		v += 2.0 + minf(nt - 1, 6) * 1.2
	for c in trumps:
		v += 2.0 + (1.5 if c >= 16 else 0.0)
	var per_suit := [0, 0, 0, 0]
	for c in hand:
		if c <= 21:
			continue
		var s := Deck.suit(c)
		per_suit[s] += 1
		match Deck.value(c):
			14: v += 6.0
			13: v += 3.0
			12: v += 2.0
			11: v += 1.0
	for s in 4:
		if per_suit[s] >= 5:
			v += (per_suit[s] - 4) * 2.5
		if per_suit[s] == 0:
			v += 4.0 if nt >= 5 else 2.0
		elif per_suit[s] == 1:
			v += 2.0 if nt >= 5 else 0.5
	return v * 18.0 / hand.size()


func choose_bid(r: Rules, p: int) -> int:
	var hand: Array = r.hands[p]
	var want := 0
	if LEVELS[level].bid == "trained":
		if predict(hand, 2) > prm.t4:
			want = 4
		elif predict(hand, 1) > prm.t3:
			want = 3
		else:
			var pc := predict(hand, 0)
			if pc > prm.t2:
				want = 2
			elif pc > prm.t1:
				want = 1
		if want > 0 and r.can_bid(want):
			return want
		return 0
	var v := hand_value(hand) + rng.randf_range(-8.0, 8.0)
	if v >= 78.0:
		want = 4
	elif v >= 65.0:
		want = 3
	elif v >= 50.0:
		want = 2
	elif v >= 37.0:
		want = 1
	if want > 0 and r.can_bid(want):
		return want
	return 0


# --- Descarte: vaciar palos cortos, sin tocar reyes ni triunfos ---

func choose_discard(r: Rules) -> Array:
	var hand: Array = r.hands[r.taker]
	var cand: Array = hand.filter(func(c): return r.can_discard(c) and not Deck.is_trump(c))
	if cand.size() < 6:
		cand = hand.filter(func(c): return r.can_discard(c))
	var count := [0, 0, 0, 0]
	for c in hand:
		if c > 21:
			count[Deck.suit(c)] += 1
	cand.sort_custom(func(a, b):
		var sa := Deck.suit(a)
		var sb := Deck.suit(b)
		var ka: float = (count[sa] if sa < 4 else 99) * 10.0 + Deck.half_points(a) * 3.0
		var kb: float = (count[sb] if sb < 4 else 99) * 10.0 + Deck.half_points(b) * 3.0
		return ka < kb)
	return cand.slice(0, 6)


# --- Juego ---

## Lo que cada jugador ha demostrado no tener: [p] -> {suit: true}, con 4 = triunfos.
static func voids_from(r: Rules) -> Array:
	var v: Array = []
	for p in r.n:
		v.append({})
	var t: Array = []
	for e in r.played:
		t.append(e)
		var cards: Array = t.map(func(x): return x[1])
		var led := -1
		var high := 0
		for i in cards.size() - 1:
			var c: int = cards[i]
			if led == -1 and c != Deck.EXCUSE:
				led = Deck.suit(c)
			if Deck.is_trump(c):
				high = maxi(high, c)
		var c: int = e[1]
		var p: int = e[0]
		if led != -1 and c != Deck.EXCUSE:
			var s := Deck.suit(c)
			if s != led:
				v[p][led] = true
				if s != Deck.TRUMP:
					v[p][Deck.TRUMP] = true
		if t.size() == r.n:
			t = []
	return v


func choose_card(r: Rules, p: int) -> int:
	var legal := r.legal(p)
	if legal.size() == 1:
		return legal[0]
	var unseen := _unseen(r, p)
	var voids := voids_from(r)
	var totals := {}
	for c in legal:
		totals[c] = 0.0
	for s in samples:
		var world := _sample_inferred(r, p, unseen, voids) if infer else _sample(r, p, unseen, voids)
		if world == null:
			continue
		for c in legal:
			var w: Rules = world.copy()
			w.play(p, c)
			_rollout(w)
			totals[c] += outcome(w) * (1.0 if p == w.taker else -1.0)
	var best: int = legal[0]
	for c in legal:
		if totals[c] > totals[best]:
			best = c
	return best


## Cartas que p no puede ver: las de los demás (y el perro/descarte si no es suyo).
func _unseen(r: Rules, p: int) -> Array:
	var seen := {}
	for c in r.hands[p]:
		seen[c] = true
	for e in r.played:
		seen[e[1]] = true
	for e in r.trick:
		seen[e[1]] = true
	if p == r.taker:
		for c in r.discards:
			seen[c] = true
	if r.contract <= 2 and p != r.taker:
		pass  # el perro se enseñó, pero el que toma pudo apartar parte de él: sigue sin saberse dónde está
	if r.contract == 3 and p == r.taker:
		pass
	var out: Array = []
	for c in Deck.N:
		if not seen.has(c):
			out.append(c)
	return out


## Como _sample, pero se queda con el reparto más creíble según la subasta: quien tomó debía tener mano para
## su contrato y quien pasó, no. Se mide con el mismo modelo con el que apuesta la IA.
func _sample_inferred(r: Rules, p: int, unseen: Array, voids: Array) -> Rules:
	var best: Rules = null
	var best_score := -INF
	for attempt in 6:
		var w := _sample(r, p, unseen, voids)
		var sc := 0.0
		for q in r.n:
			if q == p or r.bids[q] < 0:
				continue
			var orig: Array = w.hands[q].duplicate()
			for e in r.played:
				if e[0] == q:
					orig.append(e[1])
			for e in r.trick:
				if e[0] == q:
					orig.append(e[1])
			if orig.is_empty():
				continue
			var b: int = r.bids[q]
			var ct := 0 if b <= 2 else (1 if b == 3 else 2)
			var v := predict(orig, ct)
			var th: float = [prm.t1, prm.t1, prm.t2, prm.t3, prm.t4][b]
			# Cuanto más lejos de lo que su apuesta (o su paso) hace pensar, menos creíble
			sc -= maxf(0.0, th - v) if b > 0 else maxf(0.0, v - prm.t1)
		if sc > best_score:
			best_score = sc
			best = w
		if sc >= 0.0:
			break
	return best


## Reparte las cartas no vistas entre los rivales respetando cuántas tiene cada uno y sus fallos.
func _sample(r: Rules, p: int, unseen: Array, voids: Array) -> Rules:
	var w := r.copy()
	var need := {}
	for q in r.n:
		if q != p:
			need[q] = r.hands[q].size()
			w.hands[q] = []
	var hidden_pile := 0  # cartas apartadas que nadie tiene en la mano
	if p != r.taker and r.contract <= 2:
		hidden_pile = 6
	elif r.contract >= 3:
		hidden_pile = 6
	# Cartas del perro que el que toma no pudo apartar (reyes, triunfos, Loco, 1, 21) siguen en su mano o jugadas
	var forced: Array = []
	if p != r.taker and r.contract <= 2:
		for c in r.chien:
			if c in unseen and (Deck.is_trump(c) or Deck.is_oudler(c) or (Deck.suit(c) < 4 and Deck.value(c) == 14)):
				forced.append(c)
	for attempt in 6:
		var pool := unseen.duplicate()
		for c in forced:
			pool.erase(c)
		_shuffle(pool)
		var ok := true
		var hands := {}
		for q in need:
			hands[q] = []
		if forced.size() > 0:
			if forced.size() > need[r.taker]:
				ok = false
			else:
				hands[r.taker].append_array(forced)
		# Primero los más restringidos
		var order: Array = need.keys()
		order.sort_custom(func(a, b): return voids[a].size() > voids[b].size())
		var rest: Array = []
		for c in pool:
			rest.append(c)
		var pile_left := hidden_pile
		for c in rest:
			var s := Deck.suit(c)
			var placed := false
			for q in order:
				if hands[q].size() < need[q] and not voids[q].has(s if s >= 0 else -9):
					hands[q].append(c)
					placed = true
					break
			if not placed:
				if pile_left > 0:
					pile_left -= 1
				else:
					ok = false
					break
		if ok:
			for q in need:
				if hands[q].size() != need[q]:
					ok = false
		if ok:
			for q in need:
				w.hands[q] = hands[q]
			return w
	# Si no cuadra, reparto sin restricciones
	var pool2 := unseen.duplicate()
	_shuffle(pool2)
	var i := 0
	for q in need:
		w.hands[q] = pool2.slice(i, i + need[q])
		i += need[q]
	return w


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


func _rollout(w: Rules) -> void:
	var guard := 0
	while w.phase == "play" and guard < 200:
		guard += 1
		var q := w.turn
		w.play(q, quick(w, q))


## Política rápida (para las simulaciones y como reserva).
func quick(r: Rules, p: int) -> int:
	var legal := r.legal(p)
	if legal.size() == 1:
		return legal[0]
	var my_team := r.team(p)
	if r.trick.is_empty():
		return _lead(r, p, legal)
	var cards: Array = r.trick.map(func(e): return e[1])
	var wi := Rules.trick_winner_idx(cards)
	var last := r.trick.size() == r.n - 1
	var winning_team := r.team(r.trick[wi][0]) if wi >= 0 else -1
	var beat: Array = []
	for c in legal:
		if c == Deck.EXCUSE:
			continue
		var t2 := cards.duplicate()
		t2.append(c)
		if Rules.trick_winner_idx(t2) == t2.size() - 1:
			beat.append(c)
	if winning_team == my_team:
		# El compañero gana: cargar puntos si es seguro, si no, lo más bajo
		var strong: bool = last or (wi >= 0 and Deck.is_trump(cards[wi]) and cards[wi] >= prm.partner_strong)
		if strong:
			return _max_by(legal.filter(func(c): return c != Deck.EXCUSE and c != 1 and not (c == 21)), func(c): return Deck.half_points(c) * 10 - (c if Deck.is_trump(c) else 0), legal)
		return _cheapest(legal)
	if not beat.is_empty():
		var safe: Array = beat
		if not last:
			safe = beat.filter(func(c): return c != 1)
			if safe.is_empty():
				safe = beat
		return _min_by(safe, func(c): return (c if Deck.is_trump(c) else Deck.value(c)) + (100 if c == 21 and not last else 0), safe)
	# No se puede ganar: soltar lo que menos vale; la Excusa salva una carta buena
	if Deck.EXCUSE in legal and r.tricks_left > 1:
		var others: Array = legal.filter(func(c): return c != Deck.EXCUSE)
		var cheapest := _cheapest(others)
		if Deck.half_points(cheapest) >= prm.excuse_pts or cheapest == 1 or r.tricks_left <= 2:
			return Deck.EXCUSE
	return _cheapest(legal.filter(func(c): return c != Deck.EXCUSE) if legal.size() > 1 else legal)


func _lead(r: Rules, p: int, legal: Array) -> int:
	var hand: Array = r.hands[p]
	var trumps: Array = hand.filter(func(c): return Deck.is_trump(c))
	if p == r.taker and trumps.size() >= prm.lead_trumps:
		var high: Array = trumps.filter(func(c): return c >= prm.lead_trump_min)
		if not high.is_empty():
			return high.max()
	if prm.king_lead == 1:
		for c in hand:
			if c > 21 and Deck.value(c) == 14:
				return c
	var per := {}
	for c in hand:
		if c > 21:
			per[Deck.suit(c)] = per.get(Deck.suit(c), 0) + 1
	if not per.is_empty():
		var best_s: int = per.keys()[0]
		var want_long: bool = (prm.taker_long == 1) if p == r.taker else (prm.def_long == 1)
		for s in per:
			if (per[s] > per[best_s]) == want_long:
				best_s = s
		var cs: Array = hand.filter(func(c): return c > 21 and Deck.suit(c) == best_s)
		return _min_by(cs, func(c): return Deck.value(c), cs)
	return _cheapest(legal)


static func _cheapest(cards: Array) -> int:
	return _min_by(cards, func(c): return Deck.half_points(c) * 30 + (c if Deck.is_trump(c) else Deck.value(c)) + (500 if c == 1 or c == 21 else 0) + (300 if c == Deck.EXCUSE else 0), cards)


static func _min_by(cards: Array, f: Callable, fallback: Array) -> int:
	if cards.is_empty():
		cards = fallback
	var best: int = cards[0]
	var bv: float = f.call(best)
	for c in cards:
		var v: float = f.call(c)
		if v < bv:
			best = c
			bv = v
	return best


static func _max_by(cards: Array, f: Callable, fallback: Array) -> int:
	if cards.is_empty():
		cards = fallback
	var best: int = cards[0]
	var bv: float = f.call(best)
	for c in cards:
		var v: float = f.call(c)
		if v > bv:
			best = c
			bv = v
	return best
