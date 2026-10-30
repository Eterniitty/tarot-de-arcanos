class_name ArcanaShow
extends Node2D
## Cinemática de cada Arcano Mayor al jugarlo: bandas de cine, la mesa se oscurece, la carta sube al centro a
## tamaño doble y su arcano «actúa» con un efecto propio (rayos, luna, llamas, rueda que gira, guadaña...), con su
## nombre y una frase. Luego la carta baja a su sitio en la baza. Se puede acelerar pulsando ✕ o ○.

const CENTER := Vector2(320, 158)
const FLAVOR := ["¡NADIE ME ATRAPA!", "TODO EMPIEZA AQUI", "EL SECRETO GUARDADO", "LA VIDA FLORECE", "LA LEY DEL REY",
	"LA VOZ DEL CIELO", "EL CORAZON ELIGE", "A TODA VELOCIDAD", "EL VALOR DOMA A LA FIERA", "UNA LUZ EN LA NOCHE",
	"GIRA LA SUERTE", "CADA COSA EN SU PESO", "TODO DEL REVES", "FIN Y PRINCIPIO", "EL JUSTO EQUILIBRIO",
	"LA TENTACION", "TODO SE DERRUMBA", "LA ESPERANZA", "EL MUNDO DE LOS SUEÑOS", "LA ALEGRIA", "EL DESPERTAR",
	"EL MUNDO ES TUYO"]

var game: Node
var fx: Fx
var t := 0.0
var active := false
var skip := false
# Escenario
var bars := 0.0
var dark := 0.0
var wash := Color(0, 0, 0, 0)
var rays := 0.0
var ray_cols: Array = [Pix.GOLD, Color.WHITE]
var ray_rot := 0.0
var ray_spin := 0.4
var disc := {}  # {p, r, c, kind: sun/moon/halo}
var spot := 0.0  # radio de la luz del farol (0 = sin farol)
var spot_p := CENTER
var orbit: Array = []  # texturas que giran alrededor de la carta
var orbit_r := 0.0
var title := ""
var sub := ""
var title_t := -1.0
var title_col := Pix.GOLD
var hearts: Array = []
var _pip_tex: Array = []
# Detalle común
var scene_id := -1
var scene_t := 0.0
var scene_k := 0.0
var card: CardNode
var aura := 0.0
var aura_col := Pix.GOLD
var motes: Array = []
var trail := false
var numeral := ""


func _ready() -> void:
	z_index = 950
	for s in 4:
		_pip_tex.append(Pix.tex(Minors.pip(s, 1)))


func _process(delta: float) -> void:
	t += delta
	ray_rot += delta * ray_spin
	scene_t += delta
	# Motas de luz que suben mientras dura la cinemática
	if active and randf() < 0.7:
		motes.append({"p": Vector2(randf_range(20, 620), 370), "v": Vector2(randf_range(-8, 8), -randf_range(30, 80)), "l": randf_range(2.0, 4.0), "c": aura_col.lerp(Color.WHITE, randf() * 0.5)})
	for m in motes:
		m.p += m.v * delta
		m.p.x += sin(t * 2.0 + m.p.y * 0.05) * 0.3
		m.l -= delta
	motes = motes.filter(func(m): return m.l > 0.0)
	# Estela de la carta al moverse rápido
	if trail and card and is_instance_valid(card):
		fx.ghost(card.spr.texture, card.spr.get_global_transform(), -card.spr.texture.get_size() / 2.0, Color(aura_col, 0.5), 0.16)
	if title_t >= 0.0:
		title_t += delta
	for h in hearts:
		h.p += h.v * delta
		h.l -= delta
	hearts = hearts.filter(func(h): return h.l > 0.0)
	if active and game:
		for p in game._my_pads() if game._is_local_human(game.me) else game.pads:
			if p.pressed("ok") or p.pressed("back"):
				skip = true
	queue_redraw()


func _w(d: float) -> void:
	await get_tree().create_timer(d * (0.2 if skip else 1.0)).timeout


func _tw() -> Tween:
	var tw := create_tween().set_parallel()
	if skip:
		tw.set_speed_scale(4.0)
	return tw


## Mueve la carta sin el muelle (para coreografías exactas).
func _move(cn: CardNode, pos: Vector2, rot: float, sc: float, d: float, trans := Tween.TRANS_BACK, ease := Tween.EASE_OUT) -> void:
	var tw := _tw()
	tw.tween_property(cn, "position", pos, d).set_trans(trans).set_ease(ease)
	tw.tween_property(cn, "rotation", rot, d).set_trans(trans).set_ease(ease)
	tw.tween_property(cn, "_cur_scale", sc, d).set_trans(trans).set_ease(ease)
	await tw.finished


func _fade(prop: String, to, d: float) -> void:
	var tw := _tw()
	tw.tween_property(self, prop, to, d)


func run(cn: CardNode, c: int, dest: Vector2, rot: float) -> void:
	active = true
	skip = false
	var old_fx_z := fx.z_index
	fx.z_index = 1100
	cn.flying = true
	cn.z_index = 1000
	var from_z := cn.z_index
	card = cn
	scene_id = c
	scene_k = 0.0
	numeral = Arcana.LIST[c].num
	aura_col = Arcana.LIST[c].bg[1].lerp(Color.WHITE, 0.3)
	if not cn.face_up:
		cn.flip(true, 0.18)
	# Entrada: bandas de cine, oscuridad y la carta sube al centro girando
	_fade("bars", 1.0, 0.25)
	_fade("dark", 0.72, 0.3)
	ray_cols = [Pix.GOLD, Color.WHITE]
	ray_spin = 0.4
	Sfx.play("swish", -2.0, 0.8)
	Sfx.play("charge", -10.0, 1.2)
	# Sube girando sobre sí misma (dos vueltas en 3D) con estela
	trail = true
	var spin_tw := _tw()
	spin_tw.tween_method(func(u: float): cn._flip_amt = cos(u * TAU * 2.0) if absf(cos(u * TAU * 2.0)) > 0.05 else 0.05, 0.0, 1.0, 0.5)
	await _move(cn, CENTER, 0.0, 2.0, 0.5, Tween.TRANS_EXPO)
	cn._flip_amt = 1.0
	trail = false
	cn.squash = Vector2(1.2, 0.85)
	Sfx.play("hit", -8.0, 0.7)
	Sfx.play("arcano", -3.0, 0.75 + c * 0.025)
	fx.ring(CENTER, 30, 170, 0.45, aura_col, 2)
	scene_t = 0.0
	_fade("scene_k", 1.0, 0.35)
	_fade("aura", 1.0, 0.3)
	title = "%s · %s" % [Arcana.LIST[c].num, Arcana.LIST[c].name]
	sub = FLAVOR[c]
	title_t = 0.0
	title_col = Arcana.LIST[c].bg[1].lerp(Color.WHITE, 0.45)
	cn.shine()
	await _act(cn, c)
	# Salida: todo se recoge y la carta baja a su sitio de la baza
	title_t = -1.0
	_fade("scene_k", 0.0, 0.25)
	_fade("aura", 0.0, 0.2)
	_fade("rays", 0.0, 0.25)
	_fade("dark", 0.0, 0.3)
	_fade("bars", 0.0, 0.3)
	_fade("wash", Color(wash, 0.0), 0.3)
	_fade("spot", 0.0, 0.3)
	_fade("orbit_r", 0.0, 0.25)
	disc = {}
	trail = true
	await _move(cn, dest, rot, 1.0, 0.3, Tween.TRANS_QUAD, Tween.EASE_IN)
	trail = false
	fx.ring(dest, 16, 70, 0.35, aura_col, 2)
	for k in 12:
		var a := k * TAU / 12.0
		fx.streak(dest + Vector2.from_angle(a) * 44.0, dest + Vector2.from_angle(a) * 74.0, 0.16, aura_col, 1)
	Sfx.play("land", 0.0, 0.8)
	cn.target_pos = dest
	cn.target_rot = rot
	cn.target_scale = 1.0
	cn.vel = Vector2.ZERO
	cn.flying = false
	cn.squash = Vector2(1.25, 0.8)
	cn.z_index = from_z
	scene_id = -1
	card = null
	orbit.clear()
	fx.z_index = old_fx_z
	active = false


func _rays_on(cols: Array, spin: float, amount := 1.0) -> void:
	ray_cols = cols
	ray_spin = spin
	_fade("rays", amount, 0.3)


# --- Cada arcano ---

func _act(cn: CardNode, c: int) -> void:
	var at := CENTER
	match c:
		0:  # El Loco: rebota como una pelota por toda la mesa
			wash = Color("ffd447", 0.0)
			_fade("wash", Color("ffd447", 0.12), 0.3)
			var pts := [Vector2(180, 120), Vector2(470, 110), Vector2(250, 220), Vector2(420, 200), CENTER]
			for k in pts.size():
				Sfx.play("bounce", -2.0, 1.2 + k * 0.12)
				await _move(cn, pts[k], (k % 2 * 2 - 1) * 0.4, 2.0 - k * 0.1, 0.22, Tween.TRANS_QUAD)
				cn.squash = Vector2(1.3, 0.75)
				fx.burst(pts[k], 16, Color.WHITE, 60, 180, 0.6, 140, 2, Vector2.UP, 1.2, 2.0, [Color("ff6b7a"), Color("ffd447"), Color("7ab8ff"), Color("5ff0b0")])
			await _move(cn, CENTER, 0.0, 2.0, 0.2)
			game.hud.comic(at + Vector2(0, -120), "¡JA, JA!", Pix.GOLD, 2.2, true)
			await _w(0.6)
		1:  # El Mago: los cuatro palos giran alrededor y se funden en la carta
			_rays_on([Color("c0408a"), Color("ffd447")], 0.8, 0.7)
			orbit = _pip_tex.duplicate()
			_fade("orbit_r", 92.0, 0.4)
			Sfx.play("teleport", -4.0)
			for k in 3:
				fx.converge(at, 24, 110, 0.4, [Color("ff8ad8"), Pix.GOLD, Color.WHITE], 80.0)
				await _w(0.28)
			_fade("orbit_r", 0.0, 0.3)
			await _w(0.3)
			Sfx.play("reveal", -2.0, 1.2)
			fx.ring(at, 10, 140, 0.5, Color("ff8ad8"), 3)
			_lemniscate(at + Vector2(0, -130))
			await _w(0.5)
		2:  # La Papisa: sale la luna, cae un velo de estrellas azules
			_fade("wash", Color("3a6ad8", 0.25), 0.4)
			disc = {"p": at + Vector2(0, -10), "r": 0.0, "c": Color("f4f0ff"), "kind": "moon"}
			var tw := _tw()
			tw.tween_method(func(r): disc.r = r, 0.0, 90.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			Sfx.play("ding", -4.0, 0.7)
			for k in 18:
				fx.star(Vector2(randf_range(60, 580), randf_range(40, 280)), Color("9ad8ff"), 0.7, randi_range(2, 4))
				if k % 6 == 0:
					Sfx.play("ding", -10.0, 1.2 + k * 0.03)
				await _w(0.06)
			await _w(0.3)
		3:  # La Emperatriz: estalla una primavera de pétalos en espiral
			_fade("wash", Color("37a85a", 0.2), 0.4)
			_rays_on([Color("8af0a0"), Color("ffe0a0")], 0.5, 0.6)
			var petals := [Color("ff8ab0"), Color("ffd447"), Color("8af0a0"), Color.WHITE]
			for k in 6:
				var a := k * TAU / 6.0 + t
				fx.burst(at + Vector2.from_angle(a) * 30.0, 18, Color.WHITE, 60, 170, 1.2, 40, 2, Vector2.from_angle(a), 0.6, 1.2, petals)
				Sfx.play("jump2", -8.0, 0.9 + k * 0.08)
				cn.squash = Vector2(1.06, 0.95)
				await _w(0.14)
			await _w(0.4)
		4:  # El Emperador: cae con todo su peso y la mesa se agrieta
			await _move(cn, at + Vector2(0, -120), 0.0, 2.3, 0.25, Tween.TRANS_QUAD)
			await _move(cn, at, 0.0, 2.0, 0.12, Tween.TRANS_EXPO, Tween.EASE_IN)
			Sfx.play("boom")
			Sfx.play("crumble", -2.0)
			game.shake = 10.0
			game.hud.flash(0.25)
			cn.squash = Vector2(1.35, 0.7)
			fx.ring(at + Vector2(0, 100), 6, 180, 0.6, Color("c0503a"), 3)
			for k in 26:
				fx.burst(at + Vector2(randf_range(-70, 70), 100), 1, Color("8a8a9a"), 60, 220, 1.0, 500, 2, Vector2.UP, 0.8)
			_rays_on([Color("c0302a"), Color("ffd08a")], 0.2, 0.7)
			await _w(0.8)
		5:  # El Papa: tres campanadas de luz desde arriba
			_rays_on([Pix.GOLD, Color("fff3c0")], 0.15, 0.8)
			for k in 3:
				Sfx.play("ding", -2.0, 0.6 + k * 0.12)
				Sfx.play("heart", -6.0, 0.7)
				fx.ring(at, 20, 150 + k * 20, 0.6, Pix.GOLD, 3)
				fx.column(at.x, 0.4)
				cn.squash = Vector2(1.08, 1.08)
				await _w(0.36)
			await _w(0.2)
		6:  # Los Enamorados: corazones que suben y una flecha que cruza
			_fade("wash", Color("ff8ab0", 0.22), 0.4)
			for k in 22:
				hearts.append({"p": Vector2(randf_range(80, 560), 370), "v": Vector2(randf_range(-20, 20), randf_range(-160, -90)), "l": 2.2, "s": randi_range(1, 2)})
			Sfx.play("heart", -2.0, 1.3)
			await _w(0.5)
			fx.streak(Vector2(-20, at.y + 20), Vector2(660, at.y - 30), 0.35, Color.WHITE, 2)
			Sfx.play("dash", -2.0, 1.4)
			await _w(0.18)
			fx.burst(at, 40, Color("ff4a6a"), 80, 240, 0.8, 60, 2, Vector2.ZERO, PI, 2.0, [Color("ff4a6a"), Color("ff8ab0"), Color.WHITE])
			Sfx.play("heart", 0.0, 1.6)
			game.hud.comic(at + Vector2(0, -122), "¡AMOR!", Color("ff4a6a"), 2.4, true)
			await _w(0.6)
		7:  # El Carro: cruza la mesa a toda velocidad dejando estelas
			for side in [-1.0, 1.0]:
				Sfx.play("dash", -2.0, 1.0 + side * 0.1)
				await _move(cn, at + Vector2(side * 230, 0), side * 0.15, 1.8, 0.16, Tween.TRANS_QUAD, Tween.EASE_IN)
				for k in 12:
					var y := at.y + randf_range(-90, 90)
					fx.streak(Vector2(320 - side * 300, y), Vector2(320 + side * 300, y), 0.25, Color(1, 1, 1, 0.7), 1)
				await _move(cn, at, 0.0, 2.0, 0.2)
				fx.burst(at + Vector2(0, 100), 20, Color("c8b088"), 60, 160, 0.6, 200, 2, Vector2(-side, -0.5), 0.6)
			game.shake = 4.0
			await _w(0.4)
		8:  # La Fuerza: rugido que hace temblar todo
			_fade("wash", Color("ff8a3a", 0.18), 0.3)
			for k in 3:
				Sfx.play("hit_big", -4.0, 0.6 + k * 0.1)
				cn.squash = Vector2(1.25, 0.82) if k % 2 == 0 else Vector2(0.85, 1.2)
				fx.ring(at, 30, 170, 0.45, Color("ffb347"), 4 - k)
				game.shake = 6.0
				await _w(0.3)
			game.hud.comic(at + Vector2(0, -122), "¡GRRR!", Color("ffb347"), 2.4, true)
			await _w(0.5)
		9:  # El Ermitaño: todo se apaga salvo la luz de su farol, que se balancea
			_fade("dark", 0.0, 0.2)
			_fade("spot", 120.0, 0.4)
			Sfx.play("reveal", -10.0, 0.5)
			for k in 30:
				spot_p = at + Vector2(sin(k * 0.25) * 26.0, cos(k * 0.5) * 6.0)
				if k % 10 == 0:
					fx.star(at + Vector2(randf_range(-40, 40), randf_range(-60, 60)), Color("ffd88a"), 0.6, 3)
				await _w(0.04)
			await _w(0.2)
			spot_p = at
		10:  # La Rueda: gira como la rueda de la fortuna y se para con un tic
			_rays_on([Color("2a5aa8"), Color("7fd0c0")], 2.5, 0.7)
			var spins := 14
			for k in spins:
				var d := 0.03 + k * k * 0.0016
				await _move(cn, at, cn.rotation + TAU / 6.0, 2.0, d, Tween.TRANS_LINEAR)
				Sfx.play("tick", -2.0, 1.6 - k * 0.04)
				fx.sparks(at + Vector2.from_angle(cn.rotation) * 90.0, 2, Vector2.from_angle(cn.rotation + PI / 2.0), 0.4, 80, 160, 0.3, [Pix.GOLD, Color.WHITE])
			await _move(cn, at, 0.0, 2.0, 0.25)
			Sfx.play("ding", 0.0, 1.0)
			ray_spin = 0.3
			await _w(0.3)
		11:  # La Justicia: la balanza se equilibra y cae la espada
			for k in 5:
				var a := (0.28 if k % 2 == 0 else -0.28) * (1.0 - k * 0.2)
				Sfx.play("tick", -4.0, 0.8 + k * 0.1)
				await _move(cn, at, a, 2.0, 0.16, Tween.TRANS_SINE)
			await _move(cn, at, 0.0, 2.0, 0.12)
			Sfx.play("swing", 0.0, 0.8)
			fx.streak(at + Vector2(0, -170), at + Vector2(0, 170), 0.3, Color.WHITE, 3)
			fx.slash(at, 120, -PI / 2.0 - 0.2, PI / 2.0 + 0.2, 0.3, Pix.GOLD, 4)
			game.hud.flash(0.15)
			await _w(0.5)
		12:  # El Colgado: se da la vuelta y se balancea colgado
			_fade("wash", Color("4aa8a0", 0.18), 0.3)
			Sfx.play("swish", -2.0, 0.7)
			await _move(cn, at, PI, 2.0, 0.35, Tween.TRANS_BACK)
			for k in 4:
				await _move(cn, at + Vector2(sin(k * 1.6) * 16.0, 0), PI + (0.2 if k % 2 == 0 else -0.2) * (1.0 - k * 0.2), 2.0, 0.22, Tween.TRANS_SINE)
			Sfx.play("swish", -2.0, 1.1)
			await _move(cn, at, TAU, 2.0, 0.3, Tween.TRANS_BACK)
			cn.rotation = 0.0
		13:  # La Muerte: la mesa se tiñe de rojo, guadañazo y ceniza
			_fade("dark", 0.88, 0.2)
			_fade("wash", Color("5a0a1a", 0.35), 0.3)
			Sfx.play("thunder", -4.0, 0.6)
			await _w(0.35)
			Sfx.play("swing", 0.0, 0.6)
			fx.slash(at + Vector2(60, -40), 210, -PI * 0.95, 0.15, 0.45, Color("ff4a5a"), 5)
			game.shake = 7.0
			game.hud.flash(0.12)
			for k in 40:
				fx.puff(Vector2(randf_range(40, 600), randf_range(-20, 40)), Vector2(randf_range(-10, 10), randf_range(40, 90)), 1, 2, 2.0, Color(0.8, 0.8, 0.85, 0.6))
			await _w(0.7)
		14:  # La Templanza: chorros de agua que pasan de una copa a otra
			_fade("wash", Color("8ad0ff", 0.18), 0.3)
			var waters := [Color("8ad0ff"), Color("c8f0ff"), Color.WHITE]
			for k in 10:
				var from := at + Vector2(-150 if k % 2 == 0 else 150, -60)
				fx.burst(from, 12, Color("8ad0ff"), 120, 170, 0.8, 220, 2, (at - from).normalized() + Vector2(0, -0.6), 0.2, 0.4, waters)
				if k % 2 == 0:
					Sfx.play("orb", -8.0, 0.6 + k * 0.03)
				await _w(0.11)
			await _w(0.4)
		15:  # El Diablo: llamas desde abajo, rojo y sacudidas
			_fade("dark", 0.9, 0.2)
			_fade("wash", Color("ff3a1a", 0.22), 0.3)
			for k in 4:
				game.shake = 5.0
				cn.squash = Vector2(1.12, 0.9)
				Sfx.play("thunder", -6.0, 0.7 + k * 0.05)
				for j in 14:
					fx.puff(Vector2(randf_range(40, 600), 370), Vector2(randf_range(-15, 15), -randf_range(120, 220)), 4, 14, 0.9, Color(1.0, randf_range(0.3, 0.6), 0.1, 0.85))
				await _w(0.28)
			game.hud.comic(at + Vector2(0, -122), "¡TENTACION!", Color("ff5a3a"), 2.0, true)
			await _w(0.4)
		16:  # La Torre: rayos que caen sobre la carta y escombros
			_fade("dark", 0.85, 0.15)
			for k in 3:
				var x := at.x + randf_range(-60, 60)
				fx.bolt(x, at.y - 30)
				Sfx.play("thunder", -2.0, 0.9 + k * 0.1)
				game.hud.flash(0.18)
				game.shake = 8.0
				cn.squash = Vector2(0.85, 1.15)
				for j in 10:
					fx.burst(Vector2(x, at.y - 60), 1, Color("8a7a9a"), 80, 200, 0.9, 420, 2, Vector2.UP, 1.0)
				await _w(0.3)
			Sfx.play("crumble")
			await _w(0.4)
		17:  # La Estrella: lluvia de estrellas que caen hacia la carta
			_fade("wash", Color("0a1440", 0.35), 0.3)
			for k in 30:
				var p := Vector2(randf_range(40, 600), randf_range(-10, 60))
				fx.streak(p, p.lerp(at, 0.85), 0.35, Color("fff3c0"), 1)
				fx.star(p.lerp(at, 0.85), Color("fff3c0"), 0.5, 3)
				if k % 5 == 0:
					Sfx.play("ding", -10.0, 1.4 + k * 0.02)
				await _w(0.035)
			fx.burst(at, 40, Pix.GOLD, 60, 200, 0.8, 40, 2)
			await _w(0.4)
		18:  # La Luna: noche azul, luna enorme detrás y ondas como en el agua
			_fade("dark", 0.88, 0.25)
			_fade("wash", Color("1a2a6a", 0.3), 0.3)
			disc = {"p": at + Vector2(0, -20), "r": 0.0, "c": Color("e8e0ff"), "kind": "moon"}
			var tw := _tw()
			tw.tween_method(func(r): disc.r = r, 0.0, 110.0, 0.7).set_trans(Tween.TRANS_SINE)
			Sfx.play("warn", -6.0, 0.5)
			for k in 4:
				fx.ring(at + Vector2(0, 110), 6, 140, 0.8, Color("9ab0ff"), 1)
				await _w(0.25)
			await _w(0.3)
		19:  # El Sol: rayos enormes girando y un fogonazo cálido
			disc = {"p": at, "r": 0.0, "c": Color("ffcf4a"), "kind": "sun"}
			var tw := _tw()
			tw.tween_method(func(r): disc.r = r, 0.0, 125.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_rays_on([Color("ffcf4a"), Color("ff8a3a")], 1.2, 1.0)
			_fade("wash", Color("ffcf4a", 0.2), 0.3)
			Sfx.play("reveal", 0.0, 0.9)
			await _w(0.4)
			game.hud.flash(0.3)
			fx.sparks(at, 40, Vector2.UP, PI, 140, 360, 0.7, [Pix.GOLD, Color.WHITE, Color("ff8a3a")])
			await _w(0.6)
		20:  # El Juicio: trompeta, la carta se eleva entre anillos de luz
			_rays_on([Color("e0e8ff"), Pix.GOLD], 0.5, 0.8)
			Sfx.play("go", 0.0, 0.7)
			await _move(cn, at + Vector2(0, 30), 0.0, 1.7, 0.15)
			var tw := _tw()
			tw.tween_property(cn, "position", at + Vector2(0, -12), 0.6).set_trans(Tween.TRANS_SINE)
			tw.tween_property(cn, "_cur_scale", 2.1, 0.6).set_trans(Tween.TRANS_SINE)
			for k in 4:
				fx.ring(at, 10, 160, 0.6, Pix.GOLD if k % 2 == 0 else Color.WHITE, 2)
				fx.column(at.x + randf_range(-40, 40), 0.3)
				await _w(0.16)
			game.hud.flash(0.3)
			await _w(0.4)
		21:  # El Mundo: corona de laurel que gira y explosión dorada enorme
			_rays_on([Color("6a3a9a"), Pix.GOLD], 0.9, 1.0)
			disc = {"p": at, "r": 0.0, "c": Color("37c25a"), "kind": "halo"}
			var tw := _tw()
			tw.tween_method(func(r): disc.r = r, 0.0, 118.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			orbit = _pip_tex.duplicate()
			_fade("orbit_r", 132.0, 0.5)
			Sfx.play("charge", -2.0, 0.9)
			await _w(0.7)
			Sfx.play("boom")
			Sfx.play("win", -4.0)
			game.shake = 10.0
			game.hud.flash(0.4)
			for k in 3:
				fx.ring(at, 10 + k * 6, 200 + k * 40, 0.6 + k * 0.1, [Pix.GOLD, Color.WHITE, Color("b06aff")][k], 3)
			fx.sparks(at, 60, Vector2.UP, PI, 150, 420, 0.8, [Pix.GOLD, Color.WHITE, Color("ffe8a0")])
			game.hud.confetti(60)
			await _w(0.8)
		_:
			await _w(0.8)


func _lemniscate(c: Vector2) -> void:
	for k in 40:
		var a := k * TAU / 40.0
		var d := 1.0 + sin(a) * sin(a)
		var p := c + Vector2(cos(a) / d, sin(a) * cos(a) / d) * 40.0
		fx.star(p, Pix.GOLD, 0.6, 1)


# --- Dibujo del escenario (debajo de la carta) ---

func _draw() -> void:
	if dark <= 0.001 and bars <= 0.001 and wash.a <= 0.001 and rays <= 0.001 and spot <= 0.0 and disc.is_empty() and hearts.is_empty() and motes.is_empty():
		return
	if wash.a > 0.0:
		draw_rect(Rect2(-10, -10, 660, 380), wash)
	if dark > 0.0:
		draw_rect(Rect2(-10, -10, 660, 380), Color(0.03, 0.01, 0.07, dark))
	if spot > 0.0:
		# Todo a oscuras menos el círculo del farol (con borde tramado)
		for k in 40:
			var r := spot + k * 9.0
			draw_arc(spot_p, r, 0, TAU, 64, Color(0.02, 0.0, 0.05, minf(0.95, 0.4 + k * 0.08)), 10.0)
		draw_circle(spot_p, spot, Color(1.0, 0.85, 0.5, 0.08))
	if rays > 0.0:
		var n := 16
		for i in n:
			var a := ray_rot + i * TAU / n
			var w := 0.09
			var col: Color = ray_cols[i % ray_cols.size()]
			draw_colored_polygon(PackedVector2Array([CENTER, CENTER + Vector2.from_angle(a - w) * 520.0, CENTER + Vector2.from_angle(a + w) * 520.0]), Color(col, 0.22 * rays))
	if not disc.is_empty() and disc.r > 0.5:
		var p: Vector2 = disc.p
		var r: float = disc.r
		var col: Color = disc.c
		match disc.kind:
			"moon":
				for k in 4:
					draw_circle(p, r + 10 + k * 8, Color(col, 0.05))
				draw_circle(p, r, Color(col, 0.85))
				draw_circle(p + Vector2(r * 0.35, -r * 0.2), r * 0.92, Color(0.05, 0.05, 0.18, 0.9))
			"sun":
				for k in 5:
					draw_circle(p, r + k * 10, Color(col, 0.08))
				draw_circle(p, r, Color(col, 0.7))
				draw_circle(p, r * 0.8, Color(col.lightened(0.3), 0.6))
			"halo":
				for k in 3:
					draw_arc(p, r + k * 4, 0, TAU, 72, Color(col, 0.8 - k * 0.2), 4.0)
				for k in 24:
					var a := k * TAU / 24.0 + t * 0.5
					draw_circle(p + Vector2.from_angle(a) * (r + 4), 4.0, Color("5ff07a"))
	# Número romano gigante, muy tenue, al fondo
	if scene_k > 0.0 and numeral != "":
		Pix.draw_text_c(self, CENTER.x, CENTER.y - 40, numeral, Color(aura_col, 0.12 * scene_k), 12, Color(0, 0, 0, 0))
	ArcanaScenes.draw(self, scene_id, scene_t, scene_k)
	for m in motes:
		draw_rect(Rect2(m.p.round(), Vector2.ONE * (2.0 if m.l > 2.5 else 1.0)), Color(m.c, clampf(m.l / 1.5, 0.0, 1.0) * 0.8))
	# Aura que late alrededor de la carta (marco de luz por capas)
	if aura > 0.01 and card and is_instance_valid(card):
		var cp := card.position
		var sc: float = card._cur_scale
		var hw := 35.0 * sc
		var hh := 54.0 * sc
		var pulse := 0.6 + 0.4 * sin(t * 6.0)
		for k in 6:
			var g := 3.0 + k * 4.0 + pulse * 3.0
			draw_rect(Rect2(cp - Vector2(hw + g, hh + g), Vector2((hw + g) * 2.0, (hh + g) * 2.0)), Color(aura_col, aura * (0.28 - k * 0.04)), false, 3.0)
		# Chispas que recorren el borde de la carta
		for k in 6:
			var u := fmod(t * 0.5 + k / 6.0, 1.0)
			var per := u * 4.0
			var q: Vector2
			if per < 1.0:
				q = cp + Vector2(lerpf(-hw, hw, per), -hh)
			elif per < 2.0:
				q = cp + Vector2(hw, lerpf(-hh, hh, per - 1.0))
			elif per < 3.0:
				q = cp + Vector2(lerpf(hw, -hw, per - 2.0), hh)
			else:
				q = cp + Vector2(-hw, lerpf(hh, -hh, per - 3.0))
			draw_rect(Rect2(q - Vector2(2, 2), Vector2(4, 4)), Color(Color.WHITE, aura))
			draw_rect(Rect2(q - Vector2(4, 0), Vector2(8, 1)), Color(aura_col, aura))
			draw_rect(Rect2(q - Vector2(0, 4), Vector2(1, 8)), Color(aura_col, aura))
	for h in hearts:
		var a: float = clampf(h.l / 0.6, 0.0, 1.0)
		var s: int = h.s
		var q: Vector2 = h.p.round()
		for d in [Vector2(-1, 0), Vector2(1, 0)]:
			draw_rect(Rect2(q + d * 2 * s - Vector2(1, 1) * s, Vector2(2, 2) * s), Color("ff4a6a", a))
		draw_rect(Rect2(q + Vector2(-3, 0) * s, Vector2(6, 2) * s), Color("ff4a6a", a))
		draw_rect(Rect2(q + Vector2(-2, 2) * s, Vector2(4, 1) * s), Color("ff4a6a", a))
		draw_rect(Rect2(q + Vector2(-1, 3) * s, Vector2(2, 1) * s), Color("ff4a6a", a))
	if orbit_r > 1.0:
		for i in orbit.size():
			var a := t * 2.2 + i * TAU / orbit.size()
			var tx: Texture2D = orbit[i]
			draw_texture(tx, (CENTER + Vector2(cos(a) * orbit_r, sin(a) * orbit_r * 0.75) - tx.get_size() / 2.0).round())
	# Bandas de cine
	if bars > 0.0:
		var h := 34.0 * bars
		draw_rect(Rect2(-10, -10, 660, h + 10), Color.BLACK)
		draw_rect(Rect2(-10, 360 - h, 660, h + 10), Color.BLACK)
	# Nombre y frase (en las bandas de abajo)
	if title_t >= 0.0:
		# El nombre cae letra a letra con rebote; la frase se escribe a máquina arriba
		var w := Pix.text_width(title, 2)
		var x := 320.0 - w / 2.0
		var nt := Pix.norm(title)
		for i in nt.length():
			var lt := title_t - i * 0.035
			if lt <= 0.0:
				break
			var drop := 0.0 if lt > 0.2 else (1.0 - lt / 0.2) * -26.0
			var bounce := sin(clampf(lt, 0.0, 0.4) * 25.0) * maxf(0.0, 0.4 - lt) * 6.0
			var col := Color.WHITE if lt < 0.08 else title_col
			Pix.draw_text(self, Vector2(x, 326 + drop - absf(bounce)), nt[i], col, 2)
			x += 6 * 2 if nt[i] != " " else 12
		var shown := int(clampf((title_t - 0.3) * 40.0, 0.0, sub.length()))
		Pix.draw_text(self, Vector2(320 - Pix.text_width(sub) / 2.0, 12), sub.left(shown), Pix.CREAM)
