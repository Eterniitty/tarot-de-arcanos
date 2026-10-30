class_name Arcana
extends RefCounted
## Los Arcanos Mayores que cambian las reglas de cada ronda y el arte pixel de sus cartas (70x108).
## Cada ilustración (54x70) es una escena pintada por capas con Paint: fondo, planos lejanos, sujeto con
## contorno y biselado, y detalles (hierba, vetas, gotas, destellos).

const W := 70
const H := 108
const AW := 54
const AH := 70

const LIST := [
	{"id": "loco", "num": "0", "name": "EL LOCO", "desc": "SALTOS SIN LIMITE", "bg": [Color("7fd0ff"), Color("ffe9a8")]},
	{"id": "mago", "num": "I", "name": "EL MAGO", "desc": "TUS GOLPES LANZAN ORBES", "bg": [Color("3b1f6e"), Color("c0408a")]},
	{"id": "sacerdotisa", "num": "II", "name": "LA PAPISA", "desc": "ESCUDO QUE PARA UN GOLPE", "bg": [Color("1a2a5a"), Color("6a8ad0")]},
	{"id": "emperatriz", "num": "III", "name": "EMPERATRIZ", "desc": "LA HIERBA CURA", "bg": [Color("37a85a"), Color("ffe0a0")]},
	{"id": "emperador", "num": "IV", "name": "EMPERADOR", "desc": "PESAIS MAS, VOLAIS MENOS", "bg": [Color("c0503a"), Color("ffd08a")]},
	{"id": "hierofante", "num": "V", "name": "EL PAPA", "desc": "GOLPEAR TE CURA", "bg": [Color("6a2a2a"), Color("d08a4a")]},
	{"id": "enamorados", "num": "VI", "name": "AMANTES", "desc": "LOS RIVALES SE ATRAEN", "bg": [Color("ff8ab0"), Color("ffe0c0")]},
	{"id": "carro", "num": "VII", "name": "EL CARRO", "desc": "VELOCIDAD DE CARRO", "bg": [Color("2a6aa8"), Color("a8d8ff")]},
	{"id": "fuerza", "num": "VIII", "name": "LA FUERZA", "desc": "EMPUJONES DOBLES", "bg": [Color("ffb347"), Color("ff6b3d")]},
	{"id": "ermitano", "num": "IX", "name": "ERMITAÑO", "desc": "TODO VA MAS LENTO", "bg": [Color("0a0a2a"), Color("ffd88a")]},
	{"id": "rueda", "num": "X", "name": "LA RUEDA", "desc": "CAMBIO DE SITIO CADA 6 S", "bg": [Color("2a5aa8"), Color("7fd0c0")]},
	{"id": "justicia", "num": "XI", "name": "JUSTICIA", "desc": "RECIBES LA MITAD DE LO QUE DAS", "bg": [Color("4a1a5a"), Color("c0508a")]},
	{"id": "colgado", "num": "XII", "name": "EL COLGADO", "desc": "GRAVEDAD AL REVES", "bg": [Color("4aa8a0"), Color("cfe8a0")]},
	{"id": "muerte", "num": "XIII", "name": "LA MUERTE", "desc": "UN GOLPE, UN KO", "bg": [Color("120a1e"), Color("5a1a3a")]},
	{"id": "templanza", "num": "XIV", "name": "TEMPLANZA", "desc": "EL DAÑO SE REPARTE", "bg": [Color("8ad0ff"), Color("ff8a6a")]},
	{"id": "diablo", "num": "XV", "name": "EL DIABLO", "desc": "DAÑO DOBLE, SIN ESQUIVA", "bg": [Color("0a0208"), Color("ff3a2a")]},
	{"id": "torre", "num": "XVI", "name": "LA TORRE", "desc": "RAYOS Y SUELO QUE CAE", "bg": [Color("1a1030"), Color("5a2a4a")]},
	{"id": "estrella", "num": "XVII", "name": "ESTRELLA", "desc": "CAEN ESTRELLAS QUE CURAN", "bg": [Color("0a1440"), Color("fff3c0")]},
	{"id": "luna", "num": "XVIII", "name": "LA LUNA", "desc": "OSCURIDAD TOTAL", "bg": [Color("0e1a40"), Color("3a3a8a")]},
	{"id": "sol", "num": "XIX", "name": "EL SOL", "desc": "TODO VA MAS RAPIDO", "bg": [Color("ffcf4a"), Color("ff8a3a")]},
	{"id": "juicio", "num": "XX", "name": "EL JUICIO", "desc": "SEGUNDA VIDA PARA TODOS", "bg": [Color("5a8ad0"), Color("e0e8ff")]},
	{"id": "mundo", "num": "XXI", "name": "EL MUNDO", "desc": "LOS BORDES SE CONECTAN", "bg": [Color("1a3a6a"), Color("6a3a9a")]},
]

const GOLD_L := Color("fff0a0")
const RIBBON := Color("5a2a7a")

# --- El bufón de las cartas (24x36), por partes como el del juego. Y/y/g = oro claro/medio/oscuro, W = sombra del cuello.
const J_HEAD := [
	".......aaa....ccc.......",
	".....aAAaab..dcCCcc.....",
	"...aAAaab......dcCCcc...",
	"..aAab..........dcCc....",
	".aab..............dcc...",
	".ab....AAaabdccC.....dc.",
	"gyg...AAAaabdcccC....gyg",
	"yYy..AAAAaabdccccC...yYy",
	".g..AAAAaaabdcccccC...g.",
	"....Yyyyyyyyyyyyyyg.....",
	"....gyyyyyyyyyyyyyg.....",
	".....ssssssssssssss.....",
	".....Sssssssssssssss....",
	".....Sssswessswesss.....",
	".....Sssswessswessss....",
	".....SSssssssssssssss...",
	".....SSsrrsssssrrss.....",
	".....SSSssseeeeess......",
	"......SSSssssssss.......",
]
const J_TORSO := [
	"....wwWwwWwwWwwWww......",
	"...wWwwWwwWwwWwwWw......",
	"....aaaAaabdccCccd......",
	"....aAAAaabdcCCCcd......",
	"....aaAaabbddcCccd......",
	"....aaaaabbddcccdd......",
	"....baaabbbdddccdd......",
	"....gyyyyyYYyyyyyg......",
	"....bbabbaddcddcdd......",
	"....bb.bb.dd.dd.d.......",
]
const J_STAND := [
	".......cd...ab..........",
	".......cd...ab..........",
	".......cd...ab..........",
	".......cd...ab..........",
	"......kkk..kkk..........",
	".....kkkk..kkkky........",
	"....ykkk...kkk..........",
]
const J_WALK := [
	"......cd.....ab.........",
	".....cd.......ab........",
	"....cd.........ab.......",
	"...cd...........ab......",
	"..kkk...........kkk.....",
	".kkkk...........kkkky...",
	"ykkk....................",
]
const J_JUMP := [
	".......cd...ab..........",
	"......cd.....ab.........",
	"....kkkk......ab........",
	"...ykkk.......kkk.......",
	"..............kkkky.....",
	"........................",
	"........................",
]
const J_ARMS_DOWN := [21, [
	"...a..............c.....",
	"..aa..............cc....",
	"..ab..............cd....",
	"..ab..............cd....",
	"..ss..............ss....",
	"...s..............s.....",
]]
const J_ARMS_UP := [12, [
	".ss..................ss.",
	".ss..................ss.",
	".aa..................cc.",
	".ab..................cd.",
	"..ab................cd..",
	"..ab................cd..",
	"...ab..............cd...",
	"...ab..............cd...",
	"....a..............c....",
]]
const J_ARMS_HOLD := [21, [
	"...a..............ccc...",
	"..aa...............cccs.",
	"..ab.................ss.",
	"..ab....................",
	"..ss....................",
	"...s....................",
]]

const DOG := ["........ww.", ".......wwwe", "w.....wwwwk", ".wwwwwwwW..", "..wwwwwwW..", "..W.....W..", ".W.......W."]
const HOWL := ["......k..", ".....kkk.", ".....kkkk", "....kkk..", "...kkkk..", "..kkkkk..", "kkkkkkk..", ".k.k.kk.."]
const FALLER := [".aa..", ".ss..", "aaaaa", ".aa..", ".a.a.", "a...a"]
const CRAB := ["r.....r", "rr.r.rr", ".rrrrr.", "..r.r.."]

static var _cache := {}
static var ribbon_min_x := 0  # el Tarot deja sitio a la izquierda para el índice de esquina


static func index_of(id: String) -> int:
	for i in LIST.size():
		if LIST[i].id == id:
			return i
	return -1


static func back() -> ImageTexture:
	if not _cache.has("back"):
		_cache.back = Pix.tex(back_image())
	return _cache.back


static func front(idx: int) -> ImageTexture:
	var key := "f%d" % idx
	if not _cache.has(key):
		_cache[key] = Pix.tex(front_image(idx))
	return _cache[key]


# --- Marco ---

static func _frame(i: Image) -> void:
	Pix.rect(i, 0, 0, W, H, Pix.INK)
	Pix.rect(i, 1, 1, W - 2, H - 2, GOLD_L)
	Pix.rect(i, 2, 2, W - 4, H - 4, Pix.GOLD)
	Pix.rect(i, 3, 3, W - 6, H - 6, Pix.INK)
	for c in [Vector2i(0, 0), Vector2i(W - 1, 0), Vector2i(0, H - 1), Vector2i(W - 1, H - 1)]:
		i.set_pixel(c.x, c.y, Color(0, 0, 0, 0))
	for c in [Vector2i(1, 1), Vector2i(W - 2, 1), Vector2i(1, H - 2), Vector2i(W - 2, H - 2)]:
		i.set_pixel(c.x, c.y, Pix.INK)
	# Brillo de la moldura dorada
	for x in range(4, W - 4, 7):
		Pix.px(i, x, 1, Color.WHITE)
	for y in range(5, H - 4, 9):
		Pix.px(i, 1, y, Color.WHITE)


static func _parchment(i: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for y in range(4, H - 4):
		for x in range(4, W - 4):
			var c := Color("f4e4c1")
			var r := rng.randf()
			if r < 0.06:
				c = Color("e6d0a4")
			elif r < 0.09:
				c = Color("fbf1da")
			var edge := mini(mini(x - 4, W - 5 - x), mini(y - 4, H - 5 - y))
			if edge < 3 and (x + y + edge) % 2 == 0:
				c = c.lerp(Color("c9a46a"), 0.45 - edge * 0.12)
			i.set_pixel(x, y, c)


const FILIGREE := ["ggg..", "g..y.", "g.y..", ".y...", "....."]


static func _filigree(i: Image) -> void:
	var f := Pix.img(5, 5)
	Pix.stamp(f, FILIGREE, {"g": Color("a8702a"), "y": Pix.GOLD}, 0, 0)
	Paint.put(i, f, 5, 5)
	var fx := f.duplicate()
	fx.flip_x()
	Paint.put(i, fx, W - 10, 5)
	var fy := f.duplicate()
	fy.flip_y()
	Paint.put(i, fy, 5, H - 10)
	var fxy := fx.duplicate()
	fxy.flip_y()
	Paint.put(i, fxy, W - 10, H - 10)


static func _ribbon(i: Image, num: String) -> void:
	var wide := Pix.text_width(num) > 36  # CABALLO: cinta más justa y sin puntas, para no pisar el índice
	var tw := Pix.text_width(num) + (4 if wide else 10)
	var x0 := maxi((W - tw) / 2, ribbon_min_x)
	if x0 + tw > W - 5:
		tw = W - 5 - x0
		wide = true
	var shifted := x0 != (W - tw) / 2
	for side in ([] if wide else ([1] if shifted else [-1, 1])):
		var ex := x0 - 4 if side < 0 else x0 + tw
		Pix.rect(i, ex, 7, 4, 7, Color("3a1a52"))
		Pix.px(i, ex if side < 0 else ex + 3, 10, Color("f4e4c1"))
	Pix.rect(i, x0, 5, tw, 10, Pix.INK)
	Pix.rect(i, x0 + 1, 6, tw - 2, 8, RIBBON)
	Pix.rect(i, x0 + 1, 6, tw - 2, 1, Color("8a4aaa"))
	Pix.stamp_text(i, x0 + (2 if wide else 5), 7, num, GOLD_L)


static func _scroll(i: Image, nm: String) -> void:
	Pix.rect(i, 4, 88, W - 8, 14, Pix.INK)
	Pix.rect(i, 5, 89, W - 10, 12, Color("fbefd5"))
	Pix.rect(i, 5, 89, W - 10, 1, Color.WHITE)
	Pix.rect(i, 5, 100, W - 10, 1, Color("d9bf8c"))
	for x in [5, W - 6]:
		Pix.rect(i, x, 90, 1, 10, Color("c9a060"))
	Pix.stamp_text(i, (W - Pix.text_width(nm, 1, 3)) / 2, 92, nm, Pix.PURPLE, 3)


static func front_image(idx: int) -> Image:
	var a: Dictionary = LIST[idx]
	var i := Pix.img(W, H)
	_frame(i)
	_parchment(i)
	_filigree(i)
	_ribbon(i, a.num)
	Pix.rect(i, 7, 15, AW + 2, AH + 2, Pix.INK)
	var art := Pix.img(AW, AH)
	_art(art, a.id)
	Paint.put(i, art, 8, 16)
	_scroll(i, a.name)
	return i


static func back_image() -> Image:
	var i := Pix.img(W, H)
	_frame(i)
	Pix.dither_v(i, 4, 4, W - 8, H - 8, Color("24124a"), Color("4a1f66"), 6)
	for y in range(4, H - 4):
		for x in range(4, W - 4):
			if (x + y) % 12 == 0 or (x - y + 240) % 12 == 0:
				Paint.blendpx(i, x, y, Color("8a5ab0", 0.35))
	Paint.speckle(i, Rect2i(4, 4, W - 8, H - 8), Color("d8c8ff", 0.8), 0.02, 9)
	for k in 2:
		var o := 6 + k * 2
		var c: Color = Color("a8702a") if k == 0 else Pix.GOLD
		Pix.rect(i, o, o, W - o * 2, 1, c)
		Pix.rect(i, o, H - o - 1, W - o * 2, 1, c)
		Pix.rect(i, o, o, 1, H - o * 2, c)
		Pix.rect(i, W - o - 1, o, 1, H - o * 2, c)
	var cx := W / 2.0
	var cy := H / 2.0
	Paint.glow(i, cx, cy, 28, Pix.GOLD, 0.4)
	for k in 16:
		var ang := k * TAU / 16.0
		var r1 := 24.0 if k % 2 == 0 else 18.0
		Paint.thick_line(i, Vector2(cx, cy) + Vector2.from_angle(ang) * 12.0, Vector2(cx, cy) + Vector2.from_angle(ang) * r1, 1, Pix.GOLD if k % 2 == 0 else Color("c9892a"))
	Paint.sphere(i, cx, cy, 12, Paint.ramp(Pix.GOLD), 1.0, false)
	# Ojo que todo lo ve
	for x in range(-8, 9):
		var hh := roundi(4.5 * (1.0 - pow(x / 8.5, 2.0)))
		for y in range(-hh, hh + 1):
			Pix.px(i, roundi(cx) + x, roundi(cy) + y, Color("fbf6e8") if absi(y) < hh else Pix.INK)
	Paint.sphere(i, cx, cy, 3.6, Paint.ramp(Color("7a3ab0")), 1.0, false)
	Pix.disc(i, cx, cy, 1.6, Pix.INK)
	Pix.px(i, roundi(cx) + 1, roundi(cy) - 2, Color.WHITE)
	# Luna arriba y estrella abajo
	for y in range(14, 26):
		for x in range(28, 43):
			var d1 := Vector2(x + 0.5 - cx, y + 0.5 - 20.0).length()
			var d2 := Vector2(x + 0.5 - cx - 3.0, y + 0.5 - 18.0).length()
			if d1 <= 5.5 and d2 > 4.5:
				Pix.px(i, x, y, Color("e8e0ff") if d1 < 4.6 else Color("9a8ac0"))
	Paint.sparkle(i, roundi(cx), H - 20, Pix.GOLD, true)
	for c in [Vector2i(11, 12), Vector2i(W - 12, 12), Vector2i(11, H - 13), Vector2i(W - 12, H - 13)]:
		Paint.sparkle(i, c.x, c.y, Pix.GOLD)
	return i


# --- El bufón ---

## Segundo color del arlequín en las cartas: contrasta con la piel (en el juego es crema, aquí se perdería).
const J_SECOND := [Color("3a4aa8"), Color("e8b84a"), Color("8a4ab8"), Color("2a9a9a")]


static func jester(pi: int, legs: Array, arms: Array, flip_v := false) -> Image:
	var pal := Pix.palette(pi)
	var c2 := Paint.ramp(J_SECOND[pi])
	pal["C"] = c2[3]
	pal["c"] = c2[2]
	pal["d"] = c2[1]
	pal["Y"] = GOLD_L
	pal["g"] = Color("c9892a")
	pal["W"] = Color("d8ccf0")
	var im := Pix.img(26, 38)
	Pix.stamp(im, legs, pal, 1, 30)
	Pix.stamp(im, J_TORSO, pal, 1, 20)
	Pix.stamp(im, J_HEAD, pal, 1, 1)
	Pix.stamp(im, arms[1], pal, 1, 1 + int(arms[0]))
	# Rombos de arlequín sobre el traje
	for y in range(23, 27):
		for x in range(6, 18):
			if (x + y * 2) % 6 == 0 and im.get_pixel(x, y).a > 0.0:
				im.set_pixel(x, y, im.get_pixel(x, y).lightened(0.25))
	if flip_v:
		im.flip_y()
	Paint.outline_in(im)
	return im


static func _sprite(rows: Array, pal: Dictionary, outline := true) -> Image:
	var im := Pix.img(rows[0].length() + 2, rows.size() + 2)
	Pix.stamp(im, rows, pal, 1, 1)
	if outline:
		Paint.outline_in(im)
	return im


# --- Ilustraciones (lienzo 54x70) ---

static func _art(a: Image, id: String) -> void:
	match id:
		"loco": _loco(a)
		"mago": _mago(a)
		"fuerza": _fuerza(a)
		"rueda": _rueda(a)
		"colgado": _colgado(a)
		"muerte": _muerte(a)
		"torre": _torre(a)
		"luna": _luna(a)
		"sol": _sol(a)
		"mundo": _mundo(a)
		_: ArcanaExtra.art(a, id)


static func _flowers(a: Image, y0: int, y1: int, n: int, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var cols := [Color("ff6b7a"), Color("ffd447"), Color.WHITE, Color("b48aff")]
	for k in n:
		var x := rng.randi_range(1, AW - 2)
		var y := rng.randi_range(y0, y1)
		if a.get_pixel(x, y).a == 0.0:
			continue
		Pix.px(a, x, y + 1, Color("2a7a4a"))
		Pix.px(a, x, y, cols[k % cols.size()])
		if k % 3 == 0:
			Pix.px(a, x - 1, y, Color(cols[k % cols.size()], 0.7))
			Pix.px(a, x + 1, y, Color(cols[k % cols.size()], 0.7))


static func _loco(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("6fc3ff"), Color("ffe0a0"), 7)
	Paint.glow(a, 10, 10, 15, Color("fff3a0"), 0.6)
	for k in 12:
		var ang := k * TAU / 12.0
		Paint.thick_line(a, Vector2(10, 10) + Vector2.from_angle(ang) * 8.0, Vector2(10, 10) + Vector2.from_angle(ang) * (12.0 if k % 2 else 10.0), 1, Color("fff8c0"))
	Paint.sphere(a, 10, 10, 6, Paint.ramp(Color("ffd447")))
	# Pájaros lejanos
	for b in [Vector2i(36, 7), Vector2i(42, 11), Vector2i(48, 5)]:
		Pix.px(a, b.x - 1, b.y - 1, Color("5a4a8a"))
		Pix.px(a, b.x, b.y, Color("5a4a8a"))
		Pix.px(a, b.x + 1, b.y - 1, Color("5a4a8a"))
	# Montañas con nieve
	var mt := Paint.layer(AW, AH)
	Paint.poly(mt, PackedVector2Array([Vector2(0, 44), Vector2(9, 31), Vector2(16, 38), Vector2(27, 23), Vector2(39, 39), Vector2(54, 29), Vector2(54, 56), Vector2(0, 56)]), Color("a99ad6"))
	Paint.bevel(mt, Color("c8bce8"), Color("8a7ab8"))
	for p in [Vector2(9, 31), Vector2(27, 23), Vector2(54, 29)]:
		Paint.poly(mt, PackedVector2Array([p, p + Vector2(-4, 5), p + Vector2(-1, 4), p + Vector2(1, 6), p + Vector2(4, 4)]), Color("f4f0ff"))
	Paint.put(a, mt, 0, 0)
	# Nubes del valle
	var cl := Paint.layer(AW, AH)
	Paint.cloud(cl, 47, 60, 14, Paint.ramp(Color("eae4ff")))
	Paint.cloud(cl, 50, 67, 10, Paint.ramp(Color("eae4ff")))
	Paint.outline_in(cl, Color("8a7ab8"))
	Paint.put(a, cl, 0, 0)
	# Acantilado con hierba
	var cf := Paint.layer(AW, AH)
	var rock := Paint.ramp(Color("8a6a9a"))
	Paint.poly(cf, PackedVector2Array([Vector2(0, 52), Vector2(14, 50), Vector2(28, 51), Vector2(37, 53), Vector2(40, 58), Vector2(38, 70), Vector2(0, 70)]), rock[2])
	for y in AH:
		for x in AW:
			if cf.get_pixel(x, y).a > 0.0 and (x * 3 + y * 5) % 11 == 0:
				cf.set_pixel(x, y, rock[1])
	Paint.bevel(cf, rock[3], rock[0])
	var grass := Paint.ramp(Color("5fd26a"))
	for x in 40:
		for y in range(48, 60):
			if cf.get_pixel(x, y).a > 0.0:
				for k in 3:
					Pix.px(cf, x, y + k, grass[4 - k])
				if (x * 7) % 5 == 0:
					Pix.px(cf, x, y - 1, grass[3])
				break
	Paint.outline_in(cf)
	Paint.put(a, cf, 0, 0)
	_flowers(a, 51, 56, 10, 3)
	# Perro saltando y bufón con su hatillo
	Paint.put(a, _sprite(DOG, {"w": Color.WHITE, "W": Color("c8c0e0"), "e": Pix.INK, "k": Pix.INK}), 1, 40)
	Paint.put(a, jester(0, J_WALK, J_ARMS_HOLD), 8, 14)
	var bl := Paint.layer(AW, AH)
	Paint.thick_line(bl, Vector2(31, 37), Vector2(45, 23), 1, Color("8a5524"))
	Paint.sphere(bl, 45, 21, 4.5, Paint.ramp(Color("c0563a")))
	Pix.px(bl, 45, 17, Color("ffd447"))
	Paint.outline_in(bl)
	Paint.put(a, bl, 0, 0)
	Pix.px(a, 30, 36, Color("ffffff"))  # rosa blanca en la mano


static func _mago(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("2a1660"), Color("b0408a"), 7)
	Paint.speckle(a, Rect2i(0, 0, AW, 44), Color("ffd8ff", 0.7), 0.025, 11)
	# Arco de rosas y hojas
	var vine := Paint.layer(AW, AH)
	var leaf := Paint.ramp(Color("37c25a"))
	for x in AW:
		var y := roundi(4.0 + sin(x * 0.45) * 1.5)
		Pix.px(vine, x, y, leaf[1])
		if x % 4 == 0:
			Pix.px(vine, x, y + 1, leaf[3])
			Pix.px(vine, x + 1, y + 2, leaf[2])
	for x in range(5, AW, 10):
		Paint.sphere(vine, x, 4, 2.6, Paint.ramp(Color("e8384f")), 1.0, false)
		Pix.px(vine, x, 4, Color("ffb0b8"))
	Paint.outline_in(vine)
	Paint.put(a, vine, 0, 0)
	# Infinito sobre la cabeza
	Paint.glow(a, 27, 10, 9, Pix.GOLD, 0.45)
	Paint.lemniscate(a, 27, 10, 7, Pix.GOLD, Color("a8702a"))
	Paint.put(a, jester(1, J_STAND, J_ARMS_UP), 14, 15)
	# Varita alzada con estrella
	Paint.glow(a, 46, 10, 8, Color("fff3a0"), 0.6)
	Paint.thick_line(a, Vector2(38, 28), Vector2(46, 11), 1, Color.WHITE)
	Paint.thick_line(a, Vector2(39, 28), Vector2(47, 11), 1, Color("c9c0f0"))
	Paint.sparkle(a, 46, 10, Pix.GOLD, true)
	# Mesa de madera con los cuatro objetos
	var tb := Paint.layer(AW, AH)
	var wood := Paint.ramp(Color("a86a34"))
	Pix.rect(tb, 2, 47, 50, 4, wood[3])
	Pix.rect(tb, 2, 47, 50, 1, wood[4])
	Pix.rect(tb, 4, 51, 46, 19, wood[1])
	for y in range(52, 70, 3):
		for x in range(5, 49):
			if (x * 5 + y) % 13 < 4:
				Pix.px(tb, x, y, wood[0])
	Pix.rect(tb, 4, 51, 46, 1, wood[0])
	Pix.rect(tb, 24, 56, 6, 5, Color("e8b84a"))
	Pix.px(tb, 26, 58, wood[0])
	Paint.outline_in(tb)
	Paint.put(a, tb, 0, 0)
	var obj := Paint.layer(AW, AH)
	var gold := Paint.ramp(Pix.GOLD)
	Paint.poly(obj, PackedVector2Array([Vector2(7, 39), Vector2(14, 39), Vector2(12, 43), Vector2(11, 44), Vector2(12, 47), Vector2(9, 47), Vector2(10, 44), Vector2(9, 43)]), gold[2])
	Paint.bevel(obj, gold[4], gold[0])
	Paint.sphere(obj, 22, 44, 3.5, gold)
	Pix.px(obj, 22, 44, Color("a8702a"))
	Pix.px(obj, 21, 43, Color("a8702a"))
	Pix.px(obj, 23, 43, Color("a8702a"))
	Paint.thick_line(obj, Vector2(32, 45), Vector2(46, 45), 1, Color("e0e0f0"))
	Pix.px(obj, 47, 45, Color("e0e0f0"))
	Pix.rect(obj, 31, 43, 1, 5, gold[1])
	Pix.rect(obj, 28, 45, 3, 1, Color("6a3a2a"))
	Paint.outline_in(obj)
	Paint.put(a, obj, 0, 0)
	for p in [Vector2i(6, 20), Vector2i(48, 34), Vector2i(10, 30), Vector2i(41, 18)]:
		Paint.sparkle(a, p.x, p.y, Color("ff8ad8"))


static func _fuerza(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("ffe08a"), Color("ff9a5a"), 7)
	var mt := Paint.layer(AW, AH)
	Paint.poly(mt, PackedVector2Array([Vector2(0, 50), Vector2(12, 36), Vector2(22, 46), Vector2(34, 34), Vector2(54, 48), Vector2(54, 60), Vector2(0, 60)]), Color("7a8ad8"))
	Paint.bevel(mt, Color("a8b8f0"), Color("5a6ab8"))
	Paint.put(a, mt, 0, 0)
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 57, 2.0, 0.2, 1.0, Paint.ramp(Color("6ad06a")), 5)
	Paint.put(a, g, 0, 0)
	_flowers(a, 58, 68, 14, 8)
	# León tumbado: cuerpo, melena en mechones sombreados, cara, hocico
	var ln := Paint.layer(AW, AH)
	var fur := Paint.ramp(Color("e8a84a"))
	Paint.sphere(ln, 46, 58, 10, fur, 0.55, false)
	Paint.sphere(ln, 30, 63, 4, fur, 0.6, false)
	for k in 14:
		var ang := k * TAU / 14.0
		Paint.sphere(ln, 39 + cos(ang) * 10.0, 45 + sin(ang) * 10.0, 4.6, Paint.ramp(Color("c2501e")), 1.0, false)
	Paint.sphere(ln, 39, 45, 9, Paint.ramp(Color("d0702a")), 1.0, false)
	Paint.sphere(ln, 38, 46, 7, Paint.ramp(Color("ffc061")), 1.0, false)
	Paint.sphere(ln, 37, 49, 3.6, Paint.ramp(Color("ffe8b0")), 0.75, false)
	for p in [Vector2i(34, 43), Vector2i(40, 43)]:
		Pix.rect(ln, p.x, p.y, 2, 2, Pix.INK)
		Pix.px(ln, p.x, p.y, Color.WHITE)
	Pix.rect(ln, 36, 47, 3, 2, Color("6a2a2a"))
	Pix.px(ln, 37, 49, Color("6a2a2a"))
	Pix.px(ln, 35, 51, Color("8a3a2a"))
	Pix.px(ln, 39, 51, Color("8a3a2a"))
	for x in [27, 29, 31]:
		Pix.px(ln, x, 66, fur[0])
	Paint.outline_in(ln)
	Paint.put(a, ln, 0, 0)
	Paint.glow(a, 13, 14, 8, Color.WHITE, 0.4)
	Paint.lemniscate(a, 13, 14, 6, Color.WHITE, Color("c9a060"))
	Paint.put(a, jester(2, J_STAND, J_ARMS_HOLD), 0, 20)
	# Guirnalda de flores sobre el traje
	for p in [Vector2i(6, 41), Vector2i(10, 42), Vector2i(14, 42), Vector2i(18, 41)]:
		Pix.px(a, p.x, p.y, Color("ff6b7a"))
		Pix.px(a, p.x + 1, p.y, Color("37c25a"))


static func _rueda(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("2a5aa8"), Color("9ad8f0"), 7)
	Paint.speckle(a, Rect2i(0, 0, AW, AH), Color(1, 1, 1, 0.6), 0.02, 21)
	var cl := Paint.layer(AW, AH)
	var cr := Paint.ramp(Color("eef0ff"))
	for c in [Vector2(7, 9), Vector2(47, 9), Vector2(7, 65), Vector2(47, 65)]:
		Paint.cloud(cl, c.x, c.y, 13, cr)
	Paint.outline_in(cl, Color("3a5a9a"))
	Paint.put(a, cl, 0, 0)
	for c in [Vector2i(7, 5), Vector2i(47, 5), Vector2i(7, 61), Vector2i(47, 61)]:
		Paint.sparkle(a, c.x, c.y, Pix.GOLD)
	# Serpiente que baja por la izquierda: cuerpo grueso con rombos, cabeza con ojo y lengua
	var sn := Paint.layer(AW, AH)
	var sk := Paint.ramp(Color("d8c03a"))
	for y in range(15, 58):
		var x := 8.0 + sin(y * 0.3) * 3.0
		for dx in 3:
			var col: Color = sk[3] if dx == 0 else (sk[2] if dx == 1 else sk[1])
			if (y + dx) % 4 == 0:
				col = Color("8a5a1a")
			Pix.px(sn, roundi(x) + dx, y, col)
	Paint.sphere(sn, 10, 59, 3.2, sk, 0.8, false)
	Pix.px(sn, 11, 58, Pix.INK)
	Pix.px(sn, 12, 58, Color("ff3a4a"))
	Pix.px(sn, 13, 61, Color("ff3a4a"))
	Pix.px(sn, 14, 62, Color("ff3a4a"))
	Paint.outline_in(sn)
	Paint.put(a, sn, 0, 0)
	# La rueda: aro de oro, ruedo naranja, radios, runas y cubo
	var wh := Paint.layer(AW, AH)
	var c := Vector2(29, 37)
	Paint.sphere(wh, c.x, c.y, 19, Paint.ramp(Pix.GOLD), 1.0, false)
	var inner := Paint.ramp(Color("2a2a7a"))
	for y in AH:
		for x in AW:
			var d := Vector2(x + 0.5 - c.x, y + 0.5 - c.y).length()
			if d < 14.5:
				var lit := Vector2(x + 0.5 - c.x, y + 0.5 - c.y).normalized().dot(Vector2(0.6, 0.7))
				wh.set_pixel(x, y, inner[2] if d < 13.5 else (inner[0] if lit < 0 else inner[3]))
	for k in 8:
		var ang := k * TAU / 8.0 + 0.2
		Paint.thick_line(wh, c + Vector2.from_angle(ang) * 4.0, c + Vector2.from_angle(ang) * 13.5, 1, Pix.GOLD if k % 2 == 0 else Color("c9892a"))
		Pix.px(wh, roundi(c.x + cos(ang + 0.39) * 16.5), roundi(c.y + sin(ang + 0.39) * 16.5), Color("6a3a1a"))
		Pix.px(wh, roundi(c.x + cos(ang + 0.39) * 16.5) + 1, roundi(c.y + sin(ang + 0.39) * 16.5), Color("6a3a1a"))
	# Símbolos alquímicos entre los radios: agua, fuego, sal y mercurio
	var sym := Color("fbefd5")
	var q := [c + Vector2(-7, -7), c + Vector2(7, -7), c + Vector2(-7, 7), c + Vector2(7, 7)]
	Pix.line(wh, roundi(q[0].x) - 2, roundi(q[0].y) - 1, roundi(q[0].x), roundi(q[0].y) + 2, sym)
	Pix.line(wh, roundi(q[0].x) + 2, roundi(q[0].y) - 1, roundi(q[0].x), roundi(q[0].y) + 2, sym)
	Pix.line(wh, roundi(q[0].x) - 2, roundi(q[0].y) - 1, roundi(q[0].x) + 2, roundi(q[0].y) - 1, sym)
	Pix.line(wh, roundi(q[1].x) - 2, roundi(q[1].y) + 1, roundi(q[1].x), roundi(q[1].y) - 2, sym)
	Pix.line(wh, roundi(q[1].x) + 2, roundi(q[1].y) + 1, roundi(q[1].x), roundi(q[1].y) - 2, sym)
	Pix.line(wh, roundi(q[1].x) - 2, roundi(q[1].y) + 1, roundi(q[1].x) + 2, roundi(q[1].y) + 1, sym)
	Pix.ring(wh, q[2].x, q[2].y, 2.5, 1, sym)
	Pix.line(wh, roundi(q[2].x) - 2, roundi(q[2].y), roundi(q[2].x) + 2, roundi(q[2].y), sym)
	Pix.ring(wh, q[3].x, q[3].y - 1, 2.0, 1, sym)
	Pix.line(wh, roundi(q[3].x), roundi(q[3].y) + 1, roundi(q[3].x), roundi(q[3].y) + 3, sym)
	Pix.line(wh, roundi(q[3].x) - 1, roundi(q[3].y) + 2, roundi(q[3].x) + 1, roundi(q[3].y) + 2, sym)
	Paint.sphere(wh, c.x, c.y, 4.2, Paint.ramp(Pix.GOLD))
	Pix.px(wh, roundi(c.x), roundi(c.y), Pix.INK)
	Paint.outline_in(wh)
	Paint.put(a, wh, 0, 0)
	Paint.glow(a, c.x, 12, 6, Color.WHITE, 0.5)
	Paint.sparkle(a, roundi(c.x), 13, Pix.GOLD, true)


static func _colgado(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("3a8a9a"), Color("d8f0b0"), 7)
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 63, 1.0, 0.3, 0.0, Paint.ramp(Color("5fc26a")), 6)
	Paint.put(a, g, 0, 0)
	_flowers(a, 64, 68, 8, 12)
	# Árbol vivo en forma de T con corteza y hojas
	var tr := Paint.layer(AW, AH)
	var bark := Paint.ramp(Color("8a5a2a"))
	Pix.rect(tr, 4, 7, 6, 63, bark[2])
	Pix.rect(tr, 44, 7, 6, 63, bark[2])
	Pix.rect(tr, 4, 6, 46, 5, bark[2])
	for y in range(7, 70):
		for x in [5, 8, 45, 48]:
			if (y + x) % 5 < 3:
				Pix.px(tr, x, y, bark[1])
	for x in range(6, 48, 3):
		Pix.px(tr, x, 8, bark[1])
	Paint.bevel(tr, bark[4], bark[0])
	var leaf := Paint.ramp(Color("37c25a"))
	var seed_k := 0
	for p in [Vector2(6, 5), Vector2(17, 4), Vector2(30, 4), Vector2(44, 5), Vector2(49, 17), Vector2(5, 22), Vector2(49, 36), Vector2(4, 44)]:
		seed_k += 1
		Paint.foliage(tr, p.x, p.y, 5.0 if seed_k % 3 else 6.5, leaf, seed_k * 7)
	Paint.outline_in(tr)
	Paint.put(a, tr, 0, 0)
	Paint.thick_line(a, Vector2(27, 11), Vector2(27, 15), 1, Color("f4e4c1"))
	Paint.glow(a, 27, 46, 13, Pix.GOLD, 0.65)
	Pix.ring(a, 27, 46, 10.5, 1, Pix.GOLD)
	Paint.put(a, jester(3, J_STAND, J_ARMS_DOWN, true), 14, 13)
	for p in [Vector2i(17, 54), Vector2i(37, 54), Vector2i(27, 59)]:
		Paint.sparkle(a, p.x, p.y, GOLD_L)


static func _muerte(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("160a26"), Color("7a1a3a"), 7)
	Paint.speckle(a, Rect2i(0, 0, AW, 30), Color(1, 0.9, 1, 0.6), 0.02, 13)
	Paint.glow(a, 27, 50, 22, Color("ff8a3a"), 0.45)
	for k in 13:
		var ang := PI + PI * (k + 0.5) / 13.0
		var tip := Vector2(27, 51) + Vector2.from_angle(ang) * 60.0
		Paint.poly(a, PackedVector2Array([Vector2(27, 51), tip, Vector2(27, 51) + Vector2.from_angle(ang + 0.07) * 60.0]), Color(1, 0.6, 0.3, 0.16))
	Paint.sphere(a, 27, 51, 8, Paint.ramp(Color("ff9a4a")), 1.0, false)
	# Dos torres al horizonte y suelo
	var tw := Paint.layer(AW, AH)
	var st := Paint.ramp(Color("4a3a5a"))
	for x0 in [6, 41]:
		Pix.rect(tw, x0, 38, 7, 14, st[2])
		for k in 4:
			Pix.rect(tw, x0 + k * 2, 36, 1, 2, st[2])
		Pix.px(tw, x0 + 3, 42, Color("ffd447"))
	Pix.rect(tw, 0, 51, AW, 19, Color("2a1424"))
	Paint.bevel(tw, st[3], st[0])
	Paint.outline_in(tw)
	Paint.put(a, tw, 0, 0)
	Paint.speckle(a, Rect2i(0, 52, AW, 18), Color("5a2a4a", 0.6), 0.12, 2)
	# Guadaña detrás de la figura
	var sc := Paint.layer(AW, AH)
	var metal := Paint.ramp(Color("b8b8d8"))
	Paint.thick_line(sc, Vector2(43, 9), Vector2(37, 69), 2, Color("6a4a2a"))
	Paint.thick_line(sc, Vector2(43, 9), Vector2(37, 69), 1, Color("8a6a3a"))
	Paint.bezier(sc, Vector2(44, 9), Vector2(34, -2), Vector2(15, 11), 2, metal[2])
	Paint.bezier(sc, Vector2(44, 8), Vector2(34, -3), Vector2(16, 10), 1, metal[4])
	Paint.outline_in(sc)
	Paint.put(a, sc, 0, 0)
	# Figura encapuchada: capa con pliegues, borde iluminado a contraluz, bajo deshilachado, cordón y manga
	var dt := Paint.layer(AW, AH)
	var cloak := Paint.ramp(Color("3a2456"))
	var hem := PackedVector2Array([Vector2(27, 11), Vector2(35, 16), Vector2(39, 36), Vector2(46, 66)])
	for k in 8:
		hem.append(Vector2(45 - k * 5, 69 if k % 2 == 0 else 65))
	hem.append_array(PackedVector2Array([Vector2(8, 66), Vector2(15, 36), Vector2(19, 16)]))
	Paint.poly(dt, hem, cloak[2])
	for x in [18, 22, 27, 32, 36]:
		for y in range(33, 68):
			var xx: int = x + (y - 33) * (x - 27) / 40
			if dt.get_pixel(xx, y).a > 0.0:
				Pix.px(dt, xx, y, cloak[1])
				if y % 2 == 0:
					Pix.px(dt, xx + 1, y, cloak[3])
	Paint.bevel(dt, cloak[4], cloak[0])
	Pix.rect(dt, 18, 38, 19, 1, Color("a8702a"))
	Pix.rect(dt, 26, 39, 2, 6, Color("a8702a"))
	Paint.poly(dt, PackedVector2Array([Vector2(33, 22), Vector2(40, 31), Vector2(38, 36), Vector2(31, 30)]), cloak[1])
	Paint.ellipse(dt, 27, 24, 7, 8, cloak[0])
	Paint.ellipse(dt, 27, 25, 6, 7, Color("120818"))
	Paint.sphere(dt, 27, 24, 5.6, Paint.ramp(Color("f2ead8")), 1.0, false)
	Pix.rect(dt, 24, 27, 7, 4, Color("e0d6bc"))
	for p in [Vector2i(23, 23), Vector2i(28, 23)]:
		Pix.rect(dt, p.x, p.y, 3, 3, Pix.INK)
		Pix.px(dt, p.x + 1, p.y + 1, Color("ff3a4a"))
	Pix.px(dt, 26, 26, Pix.INK)
	Pix.px(dt, 27, 26, Pix.INK)
	for x in range(24, 31):
		Pix.px(dt, x, 29, Color("b8a890") if x % 2 else Pix.INK)
	for p in [Vector2i(38, 33), Vector2i(40, 33), Vector2i(39, 35), Vector2i(41, 35)]:
		Pix.px(dt, p.x, p.y, Color("e8e0c8"))
	Paint.outline_in(dt)
	Paint.put(a, dt, 0, 0)
	for p in [Vector2(24, 24), Vector2(29, 24)]:
		Paint.glow(a, p.x, p.y, 2.5, Color("ff3a4a"), 0.35)
	# Rosa blanca caída
	var rs := Paint.layer(AW, AH)
	Paint.sphere(rs, 9, 64, 2.6, Paint.ramp(Color("f4f0ff")), 1.0, false)
	Pix.px(rs, 11, 66, Color("37c25a"))
	Pix.px(rs, 12, 67, Color("37c25a"))
	Paint.outline_in(rs)
	Paint.put(a, rs, 0, 0)


static func _torre(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("0e0a24"), Color("4a2a5a"), 7)
	# Lluvia
	for k in 40:
		var x := (k * 37) % AW
		var y := (k * 53) % AH
		Paint.blendpx(a, x, y, Color(0.6, 0.7, 1.0, 0.5))
		Paint.blendpx(a, x - 1, y + 1, Color(0.6, 0.7, 1.0, 0.3))
	# Rayo con halo
	Paint.glow(a, 40, 8, 16, Color("9ad8ff"), 0.4)
	var bolt := [Vector2(53, 0), Vector2(46, 5), Vector2(49, 7), Vector2(40, 12), Vector2(42, 13), Vector2(33, 16)]
	for k in bolt.size() - 1:
		Paint.thick_line(a, bolt[k], bolt[k + 1], 2, Color("9ad8ff"))
	for k in bolt.size() - 1:
		Paint.thick_line(a, bolt[k], bolt[k + 1], 1, Color.WHITE)
	# Roca
	var rk := Paint.layer(AW, AH)
	var rock := Paint.ramp(Color("5a4a6a"))
	Paint.poly(rk, PackedVector2Array([Vector2(2, 70), Vector2(8, 60), Vector2(18, 55), Vector2(37, 55), Vector2(46, 61), Vector2(52, 70)]), rock[2])
	for p in [Vector2i(14, 62), Vector2i(30, 60), Vector2i(40, 66)]:
		Pix.px(rk, p.x, p.y, rock[0])
		Pix.px(rk, p.x + 1, p.y + 1, rock[0])
		Pix.px(rk, p.x + 2, p.y + 1, rock[0])
	Paint.bevel(rk, rock[4], rock[0])
	Paint.outline_in(rk)
	Paint.put(a, rk, 0, 0)
	# Torre de piedra con ladrillos, almenas, ventanas en llamas
	var tw := Paint.layer(AW, AH)
	var stone := Paint.ramp(Color("8a8aa8"))
	Pix.rect(tw, 19, 18, 17, 38, stone[2])
	for k in 5:
		Pix.rect(tw, 18 + k * 4, 14, 3, 4, stone[2])
	Pix.rect(tw, 18, 17, 19, 2, stone[3])
	for y in range(20, 56, 4):
		for x in range(19, 36):
			Pix.px(tw, x, y, stone[1])
		for x in range(19 + (2 if (y / 4) % 2 else 0), 36, 5):
			for yy in range(y, y + 4):
				Pix.px(tw, x, yy, stone[1])
	Paint.bevel(tw, stone[4], stone[0])
	for y in range(18, 56):
		Pix.px(tw, 34, y, stone[0])
	for w in [Vector2i(22, 24), Vector2i(29, 33), Vector2i(22, 43)]:
		Pix.rect(tw, w.x, w.y, 4, 5, Pix.INK)
		Pix.rect(tw, w.x + 1, w.y + 1, 2, 4, Color("ff8a2a"))
		Pix.px(tw, w.x + 1, w.y + 2, Pix.GOLD)
	Paint.outline_in(tw)
	Paint.put(a, tw, 0, 0)
	for w in [Vector2(24, 27), Vector2(31, 36), Vector2(24, 46)]:
		Paint.glow(a, w.x, w.y, 6, Color("ff8a2a"), 0.5)
	# Llamas en la cima
	var fl := Paint.layer(AW, AH)
	for p in [Vector3(24, 11, 3.5), Vector3(28, 9, 4.5), Vector3(32, 11, 3.2), Vector3(28, 6, 2.6)]:
		Paint.sphere(fl, p.x, p.y, p.z, Paint.ramp(Color("ff6a2a")), 1.0, false)
	Paint.sphere(fl, 28, 10, 2.5, Paint.ramp(Pix.GOLD), 1.0, false)
	Paint.put(a, fl, 0, 0)
	Paint.glow(a, 28, 10, 10, Color("ffb04a"), 0.4)
	# Corona que sale volando
	var cr := Paint.layer(AW, AH)
	var gold := Paint.ramp(Pix.GOLD)
	Pix.rect(cr, 8, 9, 7, 3, gold[2])
	for k in 3:
		Pix.rect(cr, 8 + k * 3, 6 + k % 2, 1, 3, gold[3])
	Pix.px(cr, 11, 10, Color("ff3a4a"))
	Paint.outline_in(cr)
	Paint.put(a, cr, 0, 0)
	# Gente cayendo y chispas
	Paint.put(a, _sprite(FALLER, {"a": Color("e8384f"), "s": Pix.SKIN}), 7, 28)
	var f2 := _sprite(FALLER, {"a": Color("3b8bea"), "s": Pix.SKIN})
	f2.flip_y()
	Paint.put(a, f2, 41, 36)
	for p in [Vector2i(14, 20), Vector2i(40, 26), Vector2i(10, 46), Vector2i(45, 48), Vector2i(16, 38)]:
		Pix.px(a, p.x, p.y, Pix.GOLD)
		Pix.px(a, p.x, p.y + 1, Color("ff8a2a"))


static func _luna(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("0a1440"), Color("3a3a8a"), 7)
	Paint.speckle(a, Rect2i(0, 0, AW, 40), Color(1, 1, 0.9, 0.8), 0.03, 17)
	Paint.glow(a, 27, 16, 19, Color("fff2c4"), 0.4)
	# Luna llena con la fase en sombra y cara dormida
	var mn := Paint.layer(AW, AH)
	Paint.sphere(mn, 27, 16, 11, Paint.ramp(Color("fff2c4")), 1.0, false)
	for y in AH:
		for x in AW:
			if mn.get_pixel(x, y).a > 0.0 and Vector2(x + 0.5 - 33.0, y + 0.5 - 13.0).length() < 10.0:
				mn.set_pixel(x, y, mn.get_pixel(x, y).darkened(0.35))
	for p in [Vector2i(21, 14), Vector2i(24, 20), Vector2i(30, 21)]:
		Pix.px(mn, p.x, p.y, Color("d8c890"))
		Pix.px(mn, p.x + 1, p.y, Color("e8d8a0"))
	Pix.rect(mn, 21, 16, 3, 1, Color("8a7a5a"))
	Pix.px(mn, 22, 19, Color("8a7a5a"))
	Paint.outline_in(mn, Color("1a1a4a"))
	Paint.put(a, mn, 0, 0)
	for p in [Vector2i(16, 31), Vector2i(22, 34), Vector2i(31, 33), Vector2i(37, 30)]:
		Pix.px(a, p.x, p.y, Pix.GOLD)
		Pix.px(a, p.x, p.y + 1, Color("ffb04a"))
	# Montañas, torres, camino, charca
	var mt := Paint.layer(AW, AH)
	Paint.poly(mt, PackedVector2Array([Vector2(0, 46), Vector2(14, 38), Vector2(27, 44), Vector2(40, 37), Vector2(54, 45), Vector2(54, 56), Vector2(0, 56)]), Color("2a2a6a"))
	Paint.put(a, mt, 0, 0)
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 52, 1.0, 0.25, 0.5, Paint.ramp(Color("2a5a4a")), 7)
	Paint.put(a, g, 0, 0)
	var tw := Paint.layer(AW, AH)
	var st := Paint.ramp(Color("6a6a9a"))
	for x0 in [0, 46]:
		Pix.rect(tw, x0, 28, 8, 28, st[2])
		for k in 3:
			Pix.rect(tw, x0 + k * 3, 25, 2, 3, st[2])
		Pix.rect(tw, x0 + 3, 34, 2, 3, Color("ffd447"))
	Paint.bevel(tw, st[4], st[0])
	Paint.outline_in(tw)
	Paint.put(a, tw, 0, 0)
	var pth := Paint.layer(AW, AH)
	var sand := Paint.ramp(Color("c8a870"))
	for y in range(50, 70):
		var t := (y - 50) / 20.0
		var cx := 27.0 + sin(t * 5.0) * 4.0 * (1.0 - t)
		var hw := 1.0 + t * 6.0
		for x in range(roundi(cx - hw), roundi(cx + hw) + 1):
			Pix.px(pth, x, y, sand[3] if (x + y) % 3 == 0 else sand[2])
	Paint.put(a, pth, 0, 0)
	var pool := Paint.layer(AW, AH)
	var water := Paint.ramp(Color("2a6ab0"))
	Paint.ellipse(pool, 27, 66, 15, 4, water[2])
	Pix.rect(pool, 18, 65, 6, 1, water[4])
	Pix.rect(pool, 30, 67, 5, 1, water[3])
	Paint.outline_in(pool, Color("1a2a4a"))
	Paint.put(a, pool, 0, 0)
	Paint.put(a, _sprite(CRAB, {"r": Color("ff5a4a")}), 23, 62)
	Paint.put(a, _sprite(HOWL, {"k": Color("e8d8b0")}), 9, 44)
	var wolf := _sprite(HOWL, {"k": Color("9a9ab8")})
	wolf.flip_x()
	Paint.put(a, wolf, 35, 44)


static func _sol(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("5ab8ff"), Color("ffe9a0"), 7)
	Paint.glow(a, 27, 14, 22, Color("fff3a0"), 0.55)
	for k in 16:
		var ang := k * TAU / 16.0
		var p0 := Vector2(27, 14) + Vector2.from_angle(ang) * 10.0
		if k % 2 == 0:
			Paint.thick_line(a, p0, Vector2(27, 14) + Vector2.from_angle(ang) * 19.0, 2, Pix.GOLD)
		else:
			for s in 7:
				var p := Vector2(27, 14) + Vector2.from_angle(ang + sin(s * 1.2) * 0.06) * (10.0 + s * 1.2)
				Pix.px(a, roundi(p.x), roundi(p.y), Color("ff9a3a"))
	var sn := Paint.layer(AW, AH)
	Paint.sphere(sn, 27, 14, 9, Paint.ramp(Pix.GOLD), 1.0, false)
	for p in [Vector2i(23, 12), Vector2i(29, 12)]:
		Pix.px(sn, p.x, p.y, Color("a8501e"))
		Pix.px(sn, p.x + 1, p.y + 1, Color("a8501e"))
		Pix.px(sn, p.x + 2, p.y, Color("a8501e"))
	for x in range(24, 31):
		Pix.px(sn, x, 17 + (1 if x > 25 and x < 29 else 0), Color("a8501e"))
	Pix.rect(sn, 21, 15, 2, 1, Color("ff8a6a"))
	Pix.rect(sn, 32, 15, 2, 1, Color("ff8a6a"))
	Paint.outline_in(sn, Color("c9892a"))
	Paint.put(a, sn, 0, 0)
	# Girasoles tras el muro
	var fl := Paint.layer(AW, AH)
	for fx: int in [6, 18, 36, 48]:
		var hy := 38 + (fx % 3)
		Pix.rect(fl, fx, hy, 1, 10, Color("2a8a4a"))
		Pix.px(fl, fx + 1, hy + 5, Color("37c25a"))
		Pix.px(fl, fx + 2, hy + 4, Color("37c25a"))
		for k in 8:
			var ang := k * TAU / 8.0
			Paint.sphere(fl, fx + cos(ang) * 3.2, hy + sin(ang) * 3.2, 1.8, Paint.ramp(Color("ffd447")), 1.0, false)
		Paint.sphere(fl, fx, hy, 2.4, Paint.ramp(Color("8a4a1a")), 1.0, false)
	Paint.outline_in(fl)
	Paint.put(a, fl, 0, 0)
	# Muro de ladrillo y hierba
	var wl := Paint.layer(AW, AH)
	var brick := Paint.ramp(Color("d0804a"))
	Pix.rect(wl, 0, 46, AW, 11, brick[2])
	for y in range(46, 57, 3):
		Pix.rect(wl, 0, y, AW, 1, brick[0])
		for x in range((y / 3 % 2) * 3, AW, 6):
			Pix.rect(wl, x, y, 1, 3, brick[0])
	Pix.rect(wl, 0, 45, AW, 1, brick[4])
	Paint.outline_in(wl)
	Paint.put(a, wl, 0, 0)
	var g := Paint.layer(AW, AH)
	Paint.hills(g, 58, 1.0, 0.4, 0.0, Paint.ramp(Color("6ad06a")), 9)
	Paint.put(a, g, 0, 0)
	_flowers(a, 59, 68, 10, 4)
	Paint.put(a, jester(0, J_JUMP, J_ARMS_UP), 14, 26)
	# Estandarte rojo ondeando
	var bn := Paint.layer(AW, AH)
	Paint.thick_line(bn, Vector2(38, 40), Vector2(45, 25), 1, Color("8a5524"))
	var red := Paint.ramp(Color("e8384f"))
	for k in 9:
		var y0 := 25 + roundi(sin(k * 0.8) * 1.5)
		Pix.rect(bn, 45 + k, y0 + k / 4, 1, 7 - k / 3, red[2] if k % 3 else red[3])
	Paint.outline_in(bn)
	Paint.put(a, bn, 0, 0)


static func _mundo(a: Image) -> void:
	Pix.dither_v(a, 0, 0, AW, AH, Color("101a4a"), Color("5a2a8a"), 7)
	Paint.speckle(a, Rect2i(0, 0, AW, AH), Color(1, 1, 1, 0.8), 0.03, 31)
	var cl := Paint.layer(AW, AH)
	var cr := Paint.ramp(Color("d8d0ff"))
	for c in [Vector2(6, 7), Vector2(48, 7), Vector2(6, 66), Vector2(48, 66)]:
		Paint.cloud(cl, c.x, c.y, 10, cr)
	Paint.outline_in(cl, Color("2a1a5a"))
	Paint.put(a, cl, 0, 0)
	# Guirnalda de laurel con hojas en dos tonos y lazos rojos
	var wr := Paint.layer(AW, AH)
	var leaf := Paint.ramp(Color("37c25a"))
	var c := Vector2(27, 36)
	for k in 64:
		var ang := k * TAU / 64.0
		var p := c + Vector2(cos(ang) * 20.0, sin(ang) * 28.0)
		var lit := Vector2(cos(ang), sin(ang)).dot(Vector2(-0.6, -0.7))
		var col: Color = leaf[3] if lit > 0.2 else (leaf[2] if lit > -0.3 else leaf[1])
		Pix.rect(wr, roundi(p.x) - 1, roundi(p.y) - 1, 3, 3, col)
		if k % 2 == 0:
			var o := Vector2(cos(ang), sin(ang)) * 2.5
			Pix.px(wr, roundi(p.x + o.x), roundi(p.y + o.y), leaf[4] if lit > 0 else leaf[2])
	var red := Paint.ramp(Color("e8384f"))
	for by in [8, 64]:
		Paint.sphere(wr, 27, by, 2.2, red, 1.0, false)
		Pix.rect(wr, 22, by - 2, 4, 3, red[2])
		Pix.rect(wr, 29, by - 2, 4, 3, red[2])
		Pix.px(wr, 23, by - 2, red[4])
		Pix.px(wr, 30, by - 2, red[4])
	Paint.outline_in(wr)
	Paint.put(a, wr, 0, 0)
	Paint.glow(a, 27, 36, 15, Color("b48aff"), 0.35)
	Paint.put(a, jester(1, J_JUMP, J_ARMS_UP), 14, 17)
	# Fajín violeta y varitas en las manos
	Paint.thick_line(a, Vector2(20, 41), Vector2(33, 46), 1, Color("b48aff"))
	for p in [Vector2i(16, 13), Vector2i(38, 13)]:
		Paint.sparkle(a, p.x, p.y, Pix.GOLD)
