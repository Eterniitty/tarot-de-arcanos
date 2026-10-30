class_name Pix
extends RefCounted
## Arte pixel generado por código: paleta, contornos, el bufón de cada jugador y una fuente 5x7.

const INK := Color("1a1026")
const GOLD := Color("ffd447")
const GOLD_D := Color("c9892a")
const CREAM := Color("fbefd5")
const PURPLE := Color("3a2456")
const SKIN := Color("ffd9b8")
const SKIN_D := Color("e8a985")
const WHITE := Color("ffffff")
const SHOE := Color("2a2140")
const BLUSH := Color("ff9a9a")

## Colores de cada jugador: traje principal y segundo color del arlequín, [claro, medio, oscuro].
const PLAYERS := [
	{"name": "ROJO", "c1": [Color("ff8a7a"), Color("e8384f"), Color("9e1f45")], "c2": [Color("fff3e0"), Color("f2c9a0"), Color("b8806a")]},
	{"name": "AZUL", "c1": [Color("8ae2ff"), Color("3b8bea"), Color("27479e")], "c2": [Color("f4f0ff"), Color("c9c0f0"), Color("8a7cc0")]},
	{"name": "VERDE", "c1": [Color("a6f58a"), Color("37c25a"), Color("1c7a4a")], "c2": [Color("fffbe0"), Color("f0e09a"), Color("b0a050")]},
	{"name": "NARANJA", "c1": [Color("ffd27a"), Color("ff8b2b"), Color("c2501e")], "c2": [Color("f6eaff"), Color("d6b8f0"), Color("9a70c0")]},
	{"name": "MORADO", "c1": [Color("d8a6ff"), Color("9b4fe0"), Color("5a2a9e")], "c2": [Color("fff3e0"), Color("f2c9a0"), Color("b8806a")]},
	{"name": "ROSA", "c1": [Color("ffb8e0"), Color("f05fb0"), Color("a62a76")], "c2": [Color("f4f0ff"), Color("c9c0f0"), Color("8a7cc0")]},
	{"name": "TURQUESA", "c1": [Color("9ff5e8"), Color("2cc4b0"), Color("15786e")], "c2": [Color("fffbe0"), Color("f0e09a"), Color("b0a050")]},
	{"name": "NOCHE", "c1": [Color("8a8ab0"), Color("4a4a72"), Color("26263e")], "c2": [Color("fff3e0"), Color("f2c9a0"), Color("b8806a")]},
]

# --- Personaje a medida: el bufón con traje, detalles, gorro, piel, ojos y cara elegidos ---

const SECONDS := [
	{"name": "CREMA", "c": [Color("fff3e0"), Color("f2c9a0"), Color("b8806a")]},
	{"name": "LILA", "c": [Color("f4f0ff"), Color("c9c0f0"), Color("8a7cc0")]},
	{"name": "ORO", "c": [Color("fff4b0"), Color("f0cf5a"), Color("b08a30")]},
	{"name": "MENTA", "c": [Color("e0ffe8"), Color("9ae0b0"), Color("4a9a6a")]},
	{"name": "CIELO", "c": [Color("e4f4ff"), Color("9ccaf0"), Color("4a7ab0")]},
	{"name": "CARBON", "c": [Color("8a8098"), Color("54486a"), Color("2c2440")]},
]
const SKINS := [
	{"name": "CLARA", "c": [Color("ffd9b8"), Color("e8a985")]},
	{"name": "MIEL", "c": [Color("f1c27d"), Color("c98e4c")]},
	{"name": "CANELA", "c": [Color("c68642"), Color("9a6232")]},
	{"name": "CACAO", "c": [Color("8d5524"), Color("6a3c18")]},
	{"name": "LUNA", "c": [Color("dccfff"), Color("a898d8")]},
	{"name": "DUENDE", "c": [Color("b8f0c8"), Color("80c098")]},
]
## Gorros: filas 0..6 de la cabeza (16 de ancho). A/a/b traje, C/c/d detalles, y oro, r gema, h pelo.
const HATS := [
	{"name": "BUFON", "rows": ["................", "..ab........dC..", "..aab......dCC..", "...aab....dcC...", "...Aaab..dccC...", "....AaabdcCC....", "....yyyyyyyy...."]},
	{"name": "TRES PUNTAS", "rows": [".ab....yy....dC.", ".aab..aabb..dCC.", "..aab.aabb.dcC..", "..AaabaabbdccC..", "...AaabaabcCC...", "....Aaaabccc....", "....yyyyyyyy...."]},
	{"name": "CORONA", "rows": ["................", "................", "....y..yy..y....", "....yy.yy.yy....", "....yyyyyyyy....", "....yryyyyry....", "....yyyyyyyy...."]},
	{"name": "MAGO", "rows": ["..........ab....", ".........aab....", "........aayb....", ".......aaaab....", "......Aaaaaab...", "..AAAaaaaaaaabb.", "....CCCCcccc...."]},
	{"name": "CAPUCHA", "rows": ["................", "................", ".....aaaaaa.....", "....aAaaaaaab...", "...aAaaaaaaaab..", "...aaaaaaaaaab..", "...aCCCCccccdb.."]},
	{"name": "SIN GORRO", "rows": ["................", "................", "................", "................", ".....hhhhhh.....", "....hhhhhhhh....", "....hhhhhhhh...."]},
	{"name": "CHISTERA", "rows": ["................", ".....bbbbbb.....", ".....baaaab.....", ".....baaaab.....", ".....bCCCCb.....", ".....baaaab.....", "...bbbbbbbbbb..."]},
]
const EYES := ["NORMALES", "DORMIDOS", "GAFAS", "PARCHE", "ESTRELLAS"]
const EXTRAS := ["COLORETE", "BIGOTE", "BARBA", "PECAS", "NADA"]
const LOOK_DEFAULT := {"color": 0, "c2": 0, "hat": 0, "skin": 0, "eyes": 0, "extra": 0}


static func look_palette(look: Dictionary) -> Dictionary:
	var c1: Array = PLAYERS[int(look.get("color", 0)) % PLAYERS.size()].c1
	var c2: Array = SECONDS[int(look.get("c2", 0)) % SECONDS.size()].c
	var sk: Array = SKINS[int(look.get("skin", 0)) % SKINS.size()].c
	return {"A": c1[0], "a": c1[1], "b": c1[2], "C": c2[0], "c": c2[1], "d": c2[2], "y": GOLD,
		"s": sk[0], "S": sk[1], "e": INK, "w": CREAM, "k": SHOE, "r": BLUSH, "h": c2[2], "g": Color("7ab8ff")}


## Las 12 filas de la cabeza: gorro + cara con los ojos y el detalle elegidos.
static func head_rows(look: Dictionary) -> Array:
	var rows: Array = Array(HATS[int(look.get("hat", 0)) % HATS.size()].rows).duplicate()
	var face := ["....ssssssss....", "....ssssssss....", "....ssssssss....", "....ssssssss....", "....SSssssss...."]
	match int(look.get("eyes", 0)) % EYES.size():
		0:
			face[2] = "....sssssese...."
		1:
			face[2] = "....sssssSsS...."
		2:
			face[1] = "....ssssseeeee.."
			face[2] = "....sssssegeg..."
		3:
			face[1] = "....eeeeeeeess.."
			face[2] = "....sssssseee..."
		4:
			face[1] = "....ssssssysy..."
			face[2] = "....sssssyyyy..."
	match int(look.get("extra", 0)) % EXTRAS.size():
		0:
			face[3] = "....ssssssrs...."
		1:
			face[3] = "....sssshhhhh..."
		2:
			face[3] = "....shhhhhhhh..."
			face[4] = "....hhhhhhhh...."
		3:
			face[3] = "....ssssrsrs...."
	# La capucha baja por los lados de la cara
	if HATS[int(look.get("hat", 0)) % HATS.size()].name == "CAPUCHA":
		for i in 4:
			var r: String = face[i]
			face[i] = "...a" + r.substr(4, 8) + "b..."
	rows.append_array(face)
	return rows


static func portrait_look(look: Dictionary) -> ImageTexture:
	var key := "pl" + str(look)
	if not _cache.has(key):
		var im := img(16, 12)
		stamp(im, head_rows(look), look_palette(look), 0, 0)
		_cache[key] = tex(outline(im))
	return _cache[key]


## El bufón entero (de pie) con el aspecto elegido, para la pantalla de personaje.
static func doll(look: Dictionary, pose := "idle0") -> ImageTexture:
	var key := "dl%s%s" % [pose, str(look)]
	if not _cache.has(key):
		var def: Array = POSES[pose]
		var pal := look_palette(look)
		var im := img(16, 20)
		stamp(im, _part(def[3]), pal, 0, 17)
		stamp(im, head_rows(look), pal, 0, def[1])
		stamp(im, _part(def[2]), pal, 0, 12 + int(def[4]))
		_cache[key] = tex(outline(im))
	return _cache[key]


## Retrato de un jugador: el suyo a medida si lo tiene, si no el del color de su asiento.
static func face(p: Dictionary) -> ImageTexture:
	var lk = p.get("look", {})
	if lk is Dictionary and not lk.is_empty():
		return portrait_look(lk)
	return portrait(int(p.get("pi", 0)))

# El bufón (16x20 antes del contorno): cabeza con gorro de dos puntas, torso y piernas por separado
# para combinar poses. A/a/b = color 1 (claro/medio/oscuro), C/c/d = color 2, y = oro, s/S = piel.
const HEAD := [
	"................",
	"..ab........dC..",
	"..aab......dCC..",
	"...aab....dcC...",
	"...Aaab..dccC...",
	"....AaabdcCC....",
	"....yyyyyyyy....",
	"....ssssssss....",
	"....ssssssss....",
	"....sssssese....",
	"....ssssssrs....",
	"....SSssssss....",
]
const HEAD_BLINK := [
	"................",
	"..ab........dC..",
	"..aab......dCC..",
	"...aab....dcC...",
	"...Aaab..dccC...",
	"....AaabdcCC....",
	"....yyyyyyyy....",
	"....ssssssss....",
	"....ssssssss....",
	"....sssssSsS....",
	"....ssssssrs....",
	"....SSssssss....",
]
const HEAD_HURT := [
	"................",
	"..ab........dC..",
	"..aab......dCC..",
	"...aab....dcC...",
	"...Aaab..dccC...",
	"....AaabdcCC....",
	"....yyyyyyyy....",
	"....ssssssss....",
	"....sssseses....",
	"....ssssSsSs....",
	"....sssssees....",
	"....SSssssss....",
]
const T_IDLE := [
	"...wwwwwwwwww...",
	"...aaaaccccc....",
	"..saAaacCcccs...",
	"...aaaaccccc....",
	"....yyyyyyy.....",
]
const T_ATTACK := [
	"...wwwwwwwwww...",
	"...aaaaccccccss.",
	"...aAaacCccc....",
	"...aaaaccccc....",
	"....yyyyyyy.....",
]
const T_JUMP := [
	"..swwwwwwwwwws..",
	"...aaaaccccc....",
	"...aAaacCccc....",
	"...aaaaccccc....",
	"....yyyyyyy.....",
]
const T_RUN_A := [
	"...wwwwwwwwww...",
	"...aaaaccccc.s..",
	"..saAaacCccc....",
	"...aaaaccccc....",
	"....yyyyyyy.....",
]
const T_RUN_B := [
	"...wwwwwwwwww...",
	"...aaaaccccc....",
	"...aAaacCcccs...",
	"..saaaaccccc....",
	"....yyyyyyy.....",
]
const T_WIND := [
	"...wwwwwwwwww...",
	"..saaaaccccc....",
	".s.aAaacCccc....",
	"...aaaaccccc....",
	"....yyyyyyy.....",
]
const T_FOLLOW := [
	"...wwwwwwwwww...",
	"...aaaaccccc....",
	"...aAaacCcccc...",
	"...aaaacccccss..",
	"....yyyyyyy.....",
]
const T_APEX := [
	"...wwwwwwwwww...",
	".ssaaaaccccccss.",
	"...aAaacCccc....",
	"...aaaaccccc....",
	"....yyyyyyy.....",
]
const L_PUSH1 := ["....dd....bb....", "...dd......bb...", "..kkk.....kkk..."]
const L_PUSH2 := ["....bb....dd....", "...bb......dd...", "..kkk.....kkk..."]
const L_LAND := ["................", "...dd.....bb....", "..kkk.....kkk..."]
const L_KICK := ["...dd.....bb....", "....dd...bb.....", ".....kk.kk......"]
const L_IDLE := ["....dd...bb.....", "....dd...bb.....", "...kkk...kkk...."]
const L_RUN1 := ["...dd.....bb....", "..dd.......bb...", ".kkk.......kkk.."]
const L_RUN2 := [".....ddbb.......", ".....dd.bb......", "....kkk..kk....."]
const L_RUN3 := ["...bb.....dd....", "..bb.......dd...", ".kkk.......kkk.."]
const L_RUN4 := [".....bbdd.......", "......bb.dd.....", ".....kk..kkk...."]
const L_JUMP := ["....ddd.bbb.....", "...kkk...kkk....", "................"]
const L_FALL := ["...dd.....bb....", "..dd.......bb...", "..kk.......kk..."]

## Pose: [cabeza, bajada de cabeza, torso, piernas, bajada del torso].
const POSES := {
	"idle0": ["HEAD", 0, "T_IDLE", "L_IDLE", 0],
	"idle1": ["HEAD", 1, "T_IDLE", "L_IDLE", 0],
	"idle2": ["HEAD", 1, "T_IDLE", "L_IDLE", 1],
	"blink": ["HEAD_BLINK", 0, "T_IDLE", "L_IDLE", 0],
	"run0": ["HEAD", 0, "T_RUN_A", "L_RUN1", 0],
	"run1": ["HEAD", 1, "T_RUN_A", "L_PUSH1", 0],
	"run2": ["HEAD", 1, "T_IDLE", "L_RUN2", 0],
	"run3": ["HEAD", 0, "T_RUN_B", "L_RUN2", 0],
	"run4": ["HEAD", 0, "T_RUN_B", "L_RUN3", 0],
	"run5": ["HEAD", 1, "T_RUN_B", "L_PUSH2", 0],
	"run6": ["HEAD", 1, "T_IDLE", "L_RUN4", 0],
	"run7": ["HEAD", 0, "T_RUN_A", "L_RUN4", 0],
	"jump": ["HEAD", 0, "T_JUMP", "L_JUMP", 0],
	"apex": ["HEAD", 0, "T_APEX", "L_IDLE", 0],
	"fall": ["HEAD", 0, "T_JUMP", "L_FALL", 0],
	"fall2": ["HEAD", 0, "T_APEX", "L_FALL", 0],
	"land": ["HEAD", 2, "T_IDLE", "L_LAND", 1],
	"atk_wind": ["HEAD", 0, "T_WIND", "L_IDLE", 0],
	"atk": ["HEAD", 0, "T_ATTACK", "L_RUN1", 0],
	"atk_follow": ["HEAD", 0, "T_FOLLOW", "L_RUN1", 0],
	"atk_up_wind": ["HEAD", 2, "T_IDLE", "L_LAND", 1],
	"atk_up": ["HEAD", 0, "T_JUMP", "L_IDLE", 0],
	"atk_down": ["HEAD", 0, "T_JUMP", "L_KICK", 0],
	"dash": ["HEAD", 0, "T_ATTACK", "L_RUN1", 0],
	"dash2": ["HEAD", 0, "T_ATTACK", "L_PUSH1", 0],
	"hurt": ["HEAD_HURT", 0, "T_JUMP", "L_FALL", 0],
	"hurt2": ["HEAD_HURT", 0, "T_APEX", "L_JUMP", 0],
}

const GLYPHS := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#"],
	"Ñ": [".##.#", "#..#.", "#...#", "##..#", "#.#.#", "#..##", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"V": ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "#.#.#", ".#.#."],
	"X": ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
	"1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
	"5": ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."],
	"6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
	"7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
	"8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
	"9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
	"!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."],
	"¡": ["..#..", ".....", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"?": [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."],
	"¿": ["..#..", ".....", "..#..", ".#...", "#....", "#...#", ".###."],
	".": [".....", ".....", ".....", ".....", ".....", ".....", "..#.."],
	",": [".....", ".....", ".....", ".....", ".....", "..#..", ".#..."],
	":": [".....", "..#..", ".....", ".....", ".....", "..#..", "....."],
	"-": [".....", ".....", ".....", ".###.", ".....", ".....", "....."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", "....."],
	"%": ["##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##"],
	"/": ["....#", "....#", "...#.", "..#..", ".#...", "#....", "#...."],
	"(": ["...#.", "..#..", ".#...", ".#...", ".#...", "..#..", "...#."],
	")": [".#...", "..#..", "...#.", "...#.", "...#.", "..#..", ".#..."],
	"·": [".....", ".....", ".....", "..#..", ".....", ".....", "....."],
	">": [".#...", "..#..", "...#.", "....#", "...#.", "..#..", ".#..."],
	"<": ["...#.", "..#..", ".#...", "#....", ".#...", "..#..", "...#."],
	"✕": [".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "....."],
	"○": [".....", ".###.", "#...#", "#...#", "#...#", ".###.", "....."],
	"□": [".....", "#####", "#...#", "#...#", "#...#", "#####", "....."],
	"△": [".....", "..#..", ".#.#.", ".#.#.", "#...#", "#####", "....."],
}
## Los símbolos del mando salen siempre con su color de PlayStation.
const BUTTON_COLORS := {"✕": Color("7ab8ff"), "○": Color("ff6b7a"), "□": Color("ff8ad8"), "△": Color("5ff0b0")}
const ACCENTS := {"Á": "A", "É": "E", "Í": "I", "Ó": "O", "Ú": "U", "Ü": "U", "À": "A", "È": "E", "Ì": "I", "Ò": "O", "Ù": "U",
	"Â": "A", "Ê": "E", "Î": "I", "Ô": "O", "Û": "U", "Ä": "A", "Ë": "E", "Ï": "I", "Ö": "O", "Ã": "A", "Õ": "O", "Ç": "C", "_": "-"}

static var _cache := {}


static func img(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


static func tex(i: Image) -> ImageTexture:
	return ImageTexture.create_from_image(i)


static func px(i: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < i.get_width() and y < i.get_height():
		i.set_pixel(x, y, c)


static func rect(i: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, i.get_width(), i.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		i.fill_rect(r, c)


static func disc(i: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(floori(cy - r) - 1, ceili(cy + r) + 1):
		for x in range(floori(cx - r) - 1, ceili(cx + r) + 1):
			var dx := x + 0.5 - cx
			var dy := y + 0.5 - cy
			if dx * dx + dy * dy <= r * r:
				px(i, x, y, c)


static func ring(i: Image, cx: float, cy: float, r: float, w: float, c: Color) -> void:
	for y in range(floori(cy - r) - 1, ceili(cy + r) + 1):
		for x in range(floori(cx - r) - 1, ceili(cx + r) + 1):
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if d <= r and d > r - w:
				px(i, x, y, c)


static func line(i: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	while true:
		px(i, x0, y0, c)
		if x0 == x1 and y0 == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy


## Degradado vertical con tramado a cuadros entre bandas (aspecto de 16 bits).
static func dither_v(i: Image, x: int, y: int, w: int, h: int, top: Color, bot: Color, bands := 6) -> void:
	for yy in h:
		for xx in w:
			var f := float(yy) / maxf(1.0, h - 1.0)
			f += (0.5 / bands) * (1.0 if (xx + yy) % 2 == 0 else -1.0)
			var q := clampf(floorf(f * bands) / (bands - 1.0), 0.0, 1.0)
			px(i, x + xx, y + yy, top.lerp(bot, q))


static func stamp(i: Image, rows: Array, pal: Dictionary, ox: int, oy: int) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch != "." and pal.has(ch):
				px(i, ox + x, oy + y, pal[ch])


## Copia la imagen con un contorno de 1 px (4 vecinos) en tinta.
static func outline(src: Image, c := INK) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := img(w + 2, h + 2)
	out.blit_rect(src, Rect2i(0, 0, w, h), Vector2i(1, 1))
	for y in h + 2:
		for x in w + 2:
			if out.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var sx: int = x - 1 + d.x
				var sy: int = y - 1 + d.y
				if sx >= 0 and sy >= 0 and sx < w and sy < h and src.get_pixel(sx, sy).a > 0.0:
					out.set_pixel(x, y, c)
					break
	return out


static func palette(pi: int) -> Dictionary:
	var p: Dictionary = PLAYERS[pi]
	var c1: Array = p.c1
	var c2: Array = p.c2
	return {"A": c1[0], "a": c1[1], "b": c1[2], "C": c2[0], "c": c2[1], "d": c2[2], "y": GOLD,
		"s": SKIN, "S": SKIN_D, "e": INK, "w": WHITE, "k": SHOE, "r": BLUSH}


## Imagen de una pose del bufón (18x22 con contorno).
static func fighter_image(pi: int, pose: String) -> Image:
	var def: Array = POSES[pose]
	var pal := palette(pi)
	var im := img(16, 20)
	stamp(im, _part(def[3]), pal, 0, 17)
	stamp(im, _part(def[0]), pal, 0, def[1])
	stamp(im, _part(def[2]), pal, 0, 12 + int(def[4]))
	return outline(im)


static func _part(n: String) -> Array:
	match n:
		"HEAD": return HEAD
		"HEAD_BLINK": return HEAD_BLINK
		"HEAD_HURT": return HEAD_HURT
		"T_IDLE": return T_IDLE
		"T_ATTACK": return T_ATTACK
		"T_JUMP": return T_JUMP
		"T_RUN_A": return T_RUN_A
		"T_RUN_B": return T_RUN_B
		"T_WIND": return T_WIND
		"T_FOLLOW": return T_FOLLOW
		"T_APEX": return T_APEX
		"L_PUSH1": return L_PUSH1
		"L_PUSH2": return L_PUSH2
		"L_LAND": return L_LAND
		"L_KICK": return L_KICK
		"L_IDLE": return L_IDLE
		"L_RUN1": return L_RUN1
		"L_RUN2": return L_RUN2
		"L_RUN3": return L_RUN3
		"L_RUN4": return L_RUN4
		"L_JUMP": return L_JUMP
	return L_FALL


static func fighter_frames(pi: int) -> Dictionary:
	var key := "f%d" % pi
	if not _cache.has(key):
		var d := {}
		for pose in POSES:
			d[pose] = tex(fighter_image(pi, pose))
		_cache[key] = d
	return _cache[key]


static func portrait(pi: int) -> ImageTexture:
	var key := "p%d" % pi
	if not _cache.has(key):
		var im := img(16, 12)
		stamp(im, HEAD, palette(pi), 0, 0)
		_cache[key] = tex(outline(im))
	return _cache[key]


# --- Texto ---

## Sin mando conectado, los símbolos de botón se escriben como teclas.
static var kb_prompts := false
const KEY_NAMES := {"✕": "ESPACIO", "○": "ESC", "△": "TAB", "□": "Q", "OPTIONS": "INTRO", "CREATE": "ESC"}


static func norm(s: String) -> String:
	s = s.to_upper()
	if kb_prompts:
		for k in KEY_NAMES:
			s = s.replace(k, KEY_NAMES[k])
	for k in ACCENTS:
		s = s.replace(k, ACCENTS[k])
	return s


## Nombre de Steam escrito solo con letras que tiene la fuente (los símbolos raros se quitan).
static func safe_name(s: String, fallback := "AMIGO", max_len := 12) -> String:
	var n := norm(s)
	var out := ""
	for ch in n:
		if GLYPHS.has(ch) and not BUTTON_COLORS.has(ch):
			out += ch
		elif ch == " " and not out.ends_with(" ") and out != "":
			out += " "
	out = out.strip_edges().left(max_len).strip_edges()
	return out if out.length() >= 2 else fallback


static func text_width(s: String, scale := 1, space := 6) -> int:
	var t := norm(s)
	var n := t.length()
	var spaces := t.count(" ")
	return maxi(0, (n - spaces) * 6 + spaces * space - 1) * scale


## Dibuja texto pixel con contorno de tinta. wave > 0 hace ondular las letras.
static func draw_text(ci: CanvasItem, pos: Vector2, text: String, col: Color, scale := 1, outline_col := INK, wave := 0.0, t := 0.0) -> void:
	var s := norm(text)
	pos = pos.round()
	for pass_i in 2:
		var x := pos.x
		for i in s.length():
			var ch := s[i]
			var oy := 0.0
			if wave > 0.0:
				oy = roundf(sin(t * 6.0 + i * 0.7) * wave)
			if GLYPHS.has(ch):
				var g: Array = GLYPHS[ch]
				var c: Color = BUTTON_COLORS.get(ch, col)
				for gy in 7:
					var row: String = g[gy]
					for gx in 5:
						if row[gx] != "#":
							continue
						var r := Rect2(x + gx * scale, pos.y + oy + gy * scale, scale, scale)
						if pass_i == 0:
							if outline_col.a > 0.0:
								ci.draw_rect(r.grow(scale), outline_col)
								ci.draw_rect(Rect2(r.position + Vector2(0, scale * 2), r.size), outline_col)
						else:
							ci.draw_rect(r, Color(c, col.a))
			x += 6 * scale


static func draw_text_c(ci: CanvasItem, center_x: float, y: float, text: String, col: Color, scale := 1, outline_col := INK, wave := 0.0, t := 0.0) -> void:
	draw_text(ci, Vector2(roundf(center_x - text_width(text, scale) / 2.0), y), text, col, scale, outline_col, wave, t)


## Texto pixel dentro de una imagen (para las cartas).
static func stamp_text(i: Image, x: int, y: int, text: String, col: Color, space := 6) -> void:
	var s := norm(text)
	var cx := x
	for k in s.length():
		var ch := s[k]
		if GLYPHS.has(ch):
			var g: Array = GLYPHS[ch]
			for gy in 7:
				var row: String = g[gy]
				for gx in 5:
					if row[gx] == "#":
						px(i, cx + gx, y + gy, col)
		cx += space if ch == " " else 6
