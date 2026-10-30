class_name Deck
extends RefCounted
## La baraja de tarot de 78 cartas. Ids: 0 = El Loco (la Excusa), 1..21 = triunfos (Arcanos Mayores I..XXI),
## 22..77 = Arcanos Menores (palo * 14 + valor - 1, valor 1..14). Todas las texturas se pintan por código.

const EXCUSE := 0
const TRUMP := 4  # "palo" de los triunfos
const N := 78

static var _cache := {}


static func is_trump(c: int) -> bool:
	return c >= 1 and c <= 21


static func suit(c: int) -> int:
	if c == EXCUSE:
		return -1
	if c <= 21:
		return TRUMP
	return (c - 22) / 14


static func value(c: int) -> int:
	if c <= 21:
		return c
	return (c - 22) % 14 + 1


static func minor(s: int, v: int) -> int:
	return 22 + s * 14 + v - 1


## Los tres "oudlers" (bazas mayores): el 1 de triunfo (Petit), el 21 y la Excusa.
static func is_oudler(c: int) -> bool:
	return c == EXCUSE or c == 1 or c == 21


## Puntos de la carta (×2 para trabajar con enteros: 91 puntos de la baraja = 182 medios puntos).
static func half_points(c: int) -> int:
	if is_oudler(c):
		return 9
	if c <= 21:
		return 1
	match value(c):
		14: return 9
		13: return 7
		12: return 5
		11: return 3
	return 1


static func name(c: int) -> String:
	if c <= 21:
		return Arcana.LIST[c].name
	return "%s DE %s" % [Minors.VALUE_NAMES[value(c)], Minors.SUITS[suit(c)].name]


## Orden de la mano: triunfos a la izquierda, luego palos alternando colores, y cada palo de mayor a menor.
static func sort_key(c: int) -> int:
	if c == EXCUSE:
		return 0
	if c <= 21:
		return 100 - c
	var order := [0, 1, 2, 3]  # bastos, copas, espadas, oros
	return 200 + order.find(suit(c)) * 20 + (15 - value(c))


static func sorted(hand: Array) -> Array:
	var h := hand.duplicate()
	h.sort_custom(func(a, b): return sort_key(a) < sort_key(b))
	return h


static func shuffled(rng: RandomNumberGenerator) -> Array:
	var d: Array = range(N)
	for i in range(N - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = d[i]
		d[i] = d[j]
		d[j] = t
	return d


# --- Texturas ---

static func texture(c: int) -> ImageTexture:
	var key := "c%d" % c
	if not _cache.has(key):
		_cache[key] = Pix.tex(image(c))
	return _cache[key]


static func back() -> ImageTexture:
	return Arcana.back()


static func image(c: int) -> Image:
	Arcana.ribbon_min_x = 19
	var i: Image
	if c <= 21:
		i = Arcana.front_image(c)
		if c == EXCUSE:
			Minors.corner_tag(i, "", [".ppp.", "p.p.p", "ppppp", ".p.p.", "....."], Color.BLACK)
		else:
			Minors.corner_tag(i, str(c), [".p.p.", "ppppp", ".ppp.", "ppppp", ".p.p."], Color("5a2a7a"))
		return i
	var s := suit(c)
	var v := value(c)
	i = Pix.img(Arcana.W, Arcana.H)
	Arcana._frame(i)
	Arcana._parchment(i)
	Arcana._filigree(i)
	Arcana._ribbon(i, Minors.VALUE_NAMES[v])
	Pix.rect(i, 7, 15, Arcana.AW + 2, Arcana.AH + 2, Pix.INK)
	var art := Pix.img(Arcana.AW, Arcana.AH)
	Minors.art(art, s, v)
	Paint.put(i, art, 8, 16)
	Arcana._scroll(i, Minors.SUITS[s].name)
	var label: String = str(v) if v <= 10 else ["S", "C", "D", "R"][v - 11]
	if v == 1:
		label = "A"
	Minors.corner_tag(i, label, Minors.MINI_PIPS[s], [Color("2a7a2a"), Color("b02a3a"), Color("2a4ab0"), Color("a8701a")][s])
	return i
