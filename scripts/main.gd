extends Node2D
## Tarot de Arcanos: juego de bazas con las 78 cartas. Un anfitrión manda (reglas, IA y turnos) y reparte a cada
## pantalla solo lo que puede ver; cada pantalla anima los sucesos en orden con su cola. Modos: un jugador contra
## tres IAs, en el sofá (varios mandos, cada uno ve su mano cuando le toca) y online por Steam (o LAN para pruebas).

signal action_done(seat: int, kind: String, data)

const W := 640
const H := 360
const SEAT_NAMES_AI := ["MAGO", "PAPISA", "ERMITAÑO", "SIBILA"]
## Enlaces de los iconos de la portada (vacíos hasta que existan)
const DISCORD_URL := ""
const FEEDBACK_URL := ""
const CFG_PATH := "user://ajustes.cfg"

var fx: Fx
var hud: TarotHud
var table: Node2D
var bg: Sprite2D
var table_fx: TableFx
var show: ArcanaShow
var arcana_anim := true  # cinemática de los Arcanos Mayores

# Partida
var mode := "solo"  # solo, sofa, online
var n := 4
var players: Array = []  # {name, kind: human/ai/remote, peer, dev, pi}
var me := 0  # asiento que ve esta pantalla
var hands_total := 4
var rounds := 2  # vueltas de reparto: cada jugador reparte `rounds` veces (como en las partidas de antes)
var hand_no := 0
var scores := [0, 0, 0, 0]
var rules: Rules  # solo en el anfitrión
var rng := RandomNumberGenerator.new()
var ai: TarotAI
var phase := "intro"  # intro, menu, lobby, guide, table, over
var intro_t := 0.0
var menu_page := "title"  # title (JUGAR/AJUSTES/SALIR), play, settings
var menu_t := 0.0  # tiempo desde que se abrió la página (animaciones de entrada)
var sel_t := 0.0  # tiempo desde el último cambio de opción
var _last_sel := -1
var menu_rects: Array = []  # zonas de cada opción, las rellena el dibujo (para el ratón)
var lobby_sel := 0
var lobby_rects: Array = []
var online_kind := ""  # "sala" (con amigos) o "rapida" (gente al azar)
var game_kind := "tarot"  # a qué se juega en la sala: tarot, bj (blackjack) o 7m (siete y media)
var quick_count := 0.0
var cfg := {"nivel": 1, "n": 4, "rounds": 2, "cine": true, "vol": 8, "full": true, "look": Pix.LOOK_DEFAULT.duplicate(), "name": "", "fichas": 100}
var casino: TarotCasino  # Blackjack / Siete y media
var name_edit := false  # escribiendo el nombre en la pantalla de personaje
var name_guard := 0.0  # tras escribir, un respiro para que el Intro no vuelva a abrir la edición
var session := 0

# Vista (lo que se ve en esta pantalla)
var hand: Array = []  # mis cartas
var nodes := {}  # carta -> CardNode (las mías, las de la baza, el perro descubierto)
var backs: Array = [[], [], [], []]  # por asiento: dorsos de los rivales
var chien_nodes: Array = []
var trick_nodes: Array = []  # [[seat, CardNode]]
var pile_nodes: Array = [[], [], [], []]
var counts := [0, 0, 0, 0]
var bids := [-1, -1, -1, -1]
var contract := 0
var taker := -1
var turn_seat := -1
var dealer := 0
var tricks_won := [0, 0, 0, 0]
var last_score := {}
var view_phase := ""  # bid, discard, play, wait, score
var cursor := 0
var bid_sel := 0
var legal: Array = []
var picked: Array = []  # descarte elegido
var curtain := -1  # sofá: asiento que debe coger el mando (mano tapada)
var sofa_shown := false  # sofá: la mano del asiento `me` está a la vista
var waiting_ok: Array = []  # asientos que aún no han pulsado ✕ en la puntuación
var taker_half := 0  # medios puntos que lleva el que toma en sus bazas (a la vista de todos)
var taker_oudlers := 0
var guide_page := 0
var tutorial := false
var tut_seen := {}
var tut_fast := false  # tutorial: el resto de la mano se juega solo y rápido
var trick_no := 0
var last_win_reason := ""  # tutorial: por qué ganó la última baza
var guide_t := 0.0

# Cola de sucesos
var _queue: Array = []
var _busy := false

# Entrada
var pads: Array = []  # Pad
var menu_sel := 0
var menu_items: Array = []
var msg := ""
var msg_t := 0.0
var shake := 0.0
var capture_dir := ""
var _m_prev := false
var _m_last := Vector2(-99, -99)
var _ai_thread: Thread
var auto_play := false  # pruebas: el jugador de esta pantalla juega solo
var auto_wait := 0.0
var force_bid := -1  # pruebas: apuesta que hace el jugador automático
var test_contract := -1  # pruebas: la primera IA que habla apuesta esto (0 = todos pasan en la primera mano)


func _ready() -> void:
	rng.randomize()
	ai = TarotAI.new()
	bg = Sprite2D.new()
	bg.texture = Pix.tex(TableArt.felt(W, H))
	bg.centered = false
	add_child(bg)
	table_fx = TableFx.new()
	table_fx.game = self
	add_child(table_fx)
	table = Node2D.new()
	add_child(table)
	fx = Fx.new()
	fx.z_index = 600
	add_child(fx)
	show = ArcanaShow.new()
	show.game = self
	show.fx = fx
	add_child(show)
	var hl := CanvasLayer.new()
	add_child(hl)
	hud = TarotHud.new()
	hud.game = self
	hl.add_child(hud)
	pads.append(Pad.new("kb"))
	for d in Input.get_connected_joypads():
		pads.append(Pad.new("joy%d" % d))
	Input.joy_connection_changed.connect(_on_joy)
	Net.peer_joined.connect(_on_peer_joined)
	Net.peer_left.connect(_on_peer_left)
	Net.connected.connect(_on_net_connected)
	Net.failed.connect(func(m): _toast(m); _go_menu())
	Net.steam_join_requested.connect(func(id): Net.join_steam(id); _toast("ENTRANDO EN LA SALA..."))
	var args := OS.get_cmdline_user_args()
	var ci := args.find("--capturas")
	if ci >= 0 and ci + 1 < args.size():
		capture_dir = args[ci + 1]
		DirAccess.make_dir_recursive_absolute(capture_dir)
		_apply_cfg()
		phase = "menu"
		_build_menu()
		_capture_run.call_deferred(args)
	else:
		_load_cfg()
		_build_menu()
		if cfg.full and not "--ventana" in args:
			get_window().mode = Window.MODE_FULLSCREEN


func _on_joy(d: int, on: bool) -> void:
	if on:
		pads.append(Pad.new("joy%d" % d))
	else:
		pads = pads.filter(func(p): return p.dev != "joy%d" % d)


func _toast(s: String, t := 2.5) -> void:
	msg = s
	msg_t = t


# --- Menú ---

const PLAY_DESC := ["TU CONTRA TRES RIVALES CONTROLADOS POR LA IA.",
	"PARTIDA RAPIDA CON GENTE DE TODO EL MUNDO. SI FALTA ALGUIEN, SE SIENTA LA IA.",
	"TU PROPIA SALA: ELIGE EL JUEGO (TAROT, BLACKJACK O SIETE Y MEDIA) E INVITA A TUS AMIGOS POR STEAM.",
	"VARIOS MANDOS EN LA MISMA PANTALLA. CADA UNO MIRA SU MANO CUANDO LE TOCA.",
	"UNA MANO GUIADA PASO A PASO: CADA CARTA EXPLICADA.",
	"LAS REGLAS CON DIBUJOS, PAGINA A PAGINA.",
	"JUEGOS CLASICOS CON LAS MISMAS CARTAS CONTRA LA BANCA: BLACKJACK Y SIETE Y MEDIA.",
	"VISTE A TU BUFON: TRAJE, GORRO, CARA Y NOMBRE. ASI TE VERAN LOS DEMAS EN LA MESA."]
const PLAY_CARDS := [1, 21, 17, 6, 0, 5, 10, 2]
const GAMES_DESC := ["EL VEINTIUNO DE TODA LA VIDA CONTRA LA BANCA. FIGURAS 10, AS 1 U 11. BLACKJACK PAGA 3 A 2.",
	"EL CLASICO ESPAÑOL: DEL AS AL 7 Y LAS FIGURAS A MEDIO PUNTO. SIETE Y MEDIA JUSTO PAGA DOBLE.",
	"BLACKJACK CON GENTE DE TODO EL MUNDO: HASTA 4 EN LA MESA CONTRA LA MISMA BANCA.",
	"SIETE Y MEDIA CON GENTE DE TODO EL MUNDO. PARA JUGAR CON AMIGOS: CREAR SALA Y ELIGE EL JUEGO."]
const GAMES_CARDS := [77, 42, 76, 41]
const GAME_NAMES := {"tarot": "TAROT", "bj": "BLACKJACK", "7m": "SIETE Y MEDIA"}
const LOOK_DESC := ["EL COLOR DE TU TRAJE. TAMBIEN ES TU COLOR EN LA MESA.", "EL SEGUNDO COLOR DEL ARLEQUIN.",
	"BUFON, TRES PUNTAS, CORONA, MAGO, CAPUCHA, CHISTERA... O A CABEZA DESCUBIERTA.", "EL TONO DE PIEL.",
	"COMO MIRA TU PERSONAJE.", "UN DETALLE PARA LA CARA.", "PULSA ✕ Y ESCRIBE TU NOMBRE CON EL TECLADO. VACIO = TU NOMBRE DE STEAM.",
	"UNA COMBINACION AL AZAR.", "GUARDAR Y VOLVER."]
const SET_DESC := ["FACIL SE DESPISTA. NORMAL JUEGA CON CABEZA. DIFICIL Y EXPERTO SIMULAN CIENTOS DE JUGADAS ANTES DE CADA CARTA.",
	"CUANTOS SE SIENTAN A LA MESA EN UN JUGADOR, EN EL SOFA Y EN TUS SALAS.",
	"CADA JUGADOR REPARTE ESTAS VECES. MAS MANOS = LA SUERTE DE UNA MANO PESA MENOS.",
	"LA ANIMACION ESPECIAL AL JUGAR UN ARCANO MAYOR.",
	"VOLUMEN DE TODOS LOS SONIDOS.",
	"JUGAR A PANTALLA COMPLETA O EN VENTANA.",
	"GUARDAR Y VOLVER A LA PORTADA."]
const SET_CARDS := [9, 4, 10, 19, 17, 18, 0]


func _build_menu() -> void:
	match menu_page:
		"title":
			menu_items = [["play", "JUGAR"], ["settings", "AJUSTES"], ["quit", "SALIR"], ["discord", "DISCORD"], ["feedback", "OPINION"]]
		"play":
			menu_items = [["solo", "UN JUGADOR"], ["quick", "ONLINE"], ["host", "CREAR SALA"], ["sofa", "EN EL SOFA"], ["tuto", "TUTORIAL"], ["guide", "COMO SE JUEGA"], ["games", "OTROS JUEGOS"], ["look", "MI PERSONAJE"]]
		"games":
			menu_items = [["bj", "BLACKJACK"], ["7m", "SIETE Y MEDIA"], ["bjq", "BLACKJACK ONLINE"], ["7mq", "SIETE Y MEDIA ONLINE"]]
		"look":
			var lk: Dictionary = cfg.look
			var nm := my_name() + ("_" if name_edit and int(menu_t * 3.0) % 2 == 0 else (" " if name_edit else ""))
			menu_items = [["color", "TRAJE  < %s >" % Pix.PLAYERS[lk.color].name], ["c2", "DETALLES  < %s >" % Pix.SECONDS[lk.c2].name],
				["hat", "GORRO  < %s >" % Pix.HATS[lk.hat].name], ["skin", "PIEL  < %s >" % Pix.SKINS[lk.skin].name],
				["eyes", "OJOS  < %s >" % Pix.EYES[lk.eyes]], ["extra", "CARA  < %s >" % Pix.EXTRAS[lk.extra]],
				["name", "NOMBRE: " + nm], ["random", "AL AZAR"], ["back", "LISTO"]]
		"settings":
			menu_items = [["nivel", "DIFICULTAD  < %s >" % level_name(int(cfg.nivel))], ["n", "JUGADORES  < %d >" % cfg.n], ["vueltas", "PARTIDA  < %d MANOS >" % (int(cfg.n) * int(cfg.rounds))],
				["cine", "CINE DE ARCANOS  < %s >" % ("SI" if cfg.cine else "NO")], ["vol", "VOLUMEN  < %d >" % cfg.vol],
				["full", "PANTALLA COMPLETA  < %s >" % ("SI" if cfg.full else "NO")], ["back", "VOLVER"]]
	menu_sel = clampi(menu_sel, 0, menu_items.size() - 1)


func level_name(l: int) -> String:
	return ["FÁCIL", "NORMAL", "DIFÍCIL", "EXPERTO"][clampi(l, 0, 3)]


func _set_page(p: String) -> void:
	if menu_page in ["settings", "look"] and p != menu_page:
		_save_cfg()
	name_edit = false
	menu_page = p
	menu_sel = 0
	menu_t = 0.0
	_build_menu()
	Sfx.play("swish", -4.0)


func _go_menu() -> void:
	session += 1
	tutorial = false
	tut_fast = false
	Engine.time_scale = 1.0
	hud.tut_open = false
	if Net.online():
		Net.close()
	online_kind = ""
	if casino:
		casino.queue_free()
		casino = null
	phase = "menu"
	_clear_table()
	players.clear()
	hud.panel_open = false
	_apply_cfg()
	if menu_page == "title":
		menu_page = "play"
	menu_t = 0.0
	_build_menu()


# --- Ajustes (se guardan en user://ajustes.cfg) ---

func _load_cfg() -> void:
	var c := ConfigFile.new()
	if c.load(CFG_PATH) == OK:
		for k in cfg.keys():
			cfg[k] = c.get_value("ajustes", k, cfg[k])
	_apply_cfg()


func _save_cfg() -> void:
	if capture_dir != "":
		return
	var c := ConfigFile.new()
	for k in cfg.keys():
		c.set_value("ajustes", k, cfg[k])
	c.save(CFG_PATH)


func _apply_cfg() -> void:
	n = int(cfg.n)
	rounds = int(cfg.rounds)
	arcana_anim = bool(cfg.cine)
	ai.set_level(int(cfg.nivel))
	var v := int(cfg.vol)
	AudioServer.set_bus_mute(0, v <= 0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 1) / 10.0))


func _setting_step(id: String, d: int) -> void:
	match id:
		"nivel":
			cfg.nivel = wrapi(int(cfg.nivel) + d, 0, TarotAI.LEVELS.size())
		"n":
			cfg.n = 3 if int(cfg.n) == 4 else 4
		"vueltas":
			cfg.rounds = wrapi(int(cfg.rounds) - 1 + d, 0, 3) + 1
		"cine":
			cfg.cine = not cfg.cine
		"vol":
			cfg.vol = wrapi(int(cfg.vol) + d, 0, 11)
		"full":
			cfg.full = not cfg.full
			if capture_dir == "":
				get_window().mode = Window.MODE_FULLSCREEN if cfg.full else Window.MODE_WINDOWED
	_apply_cfg()
	_build_menu()
	Sfx.play("tick")


func _process(delta: float) -> void:
	Pix.kb_prompts = Input.get_connected_joypads().is_empty()
	_mouse()
	for p in pads:
		p.poll(delta)
	msg_t -= delta
	shake = maxf(0.0, shake - delta * 30.0)
	table.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake if shake > 0.1 else Vector2.ZERO
	menu_t += delta
	sel_t += delta
	if menu_sel != _last_sel:
		_last_sel = menu_sel
		sel_t = 0.0
	match phase:
		"intro":
			var before := intro_t
			intro_t += delta
			for e in TarotFront.INTRO_SFX:
				if before < e[0] and intro_t >= e[0]:
					Sfx.play(e[1])
			if intro_t >= TarotFront.INTRO_LEN or _any("ok") or _any("back") or _any("start"):
				phase = "menu"
				_set_page("title")
		"menu":
			_menu_input()
		"casino":
			if casino:
				casino.step(delta)
		"lobby":
			_lobby_input()
			# Partida rápida: con la mesa llena, empieza sola a los 3 segundos
			if mode == "online" and online_kind == "rapida" and Net.is_host() and quick_wait() > 0.0:
				quick_count += delta
				if quick_count > quick_wait():
					quick_count = 0.0
					_lobby_pick("start", 1)
			else:
				quick_count = 0.0
		"guide":
			guide_t += delta
			if _any("right") or _any("ok"):
				if guide_page < TarotGuide.PAGES - 1:
					guide_page += 1
					guide_t = 0.0
					Sfx.play("flip", -4.0)
				elif _any("ok"):
					phase = "menu"
			if _any("left") and guide_page > 0:
				guide_page -= 1
				guide_t = 0.0
				Sfx.play("flip", -4.0)
			if _any("back"):
				phase = "menu"
		"table":
			_table_input()
		"over":
			for p in pads:
				if p.pressed("ok"):
					Sfx.play("select")
					if Net.online() and Net.is_host():
						_host_restart()
					elif not Net.online():
						_go_menu()
				if p.pressed("back"):
					_go_menu()
	_layout()


## Ratón: pasar por encima elige (carta, opción del menú o de la apuesta) y el clic izquierdo confirma.
## Clic derecho mantenido = lupa. En el descarte, clic en el cartel de abajo = apartar.
func _mouse() -> void:
	var mp := get_global_mouse_position()
	var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var click := down and not _m_prev
	_m_prev = down
	var moved := mp.distance_to(_m_last) > 0.5
	_m_last = mp
	Pad.mouse_ok = false
	Pad.mouse_alt = false
	Pad.mouse_zoom = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	match phase:
		"intro":
			Pad.mouse_ok = click
		"casino":
			if casino:
				casino.mouse(mp, click, moved)
		"menu":
			if hud.panel_open:
				Pad.mouse_ok = click
				return
			for i in menu_rects.size():
				if menu_rects[i].has_point(mp):
					if moved and menu_sel != i:
						menu_sel = i
						Sfx.play("tick", -8.0)
					if click:
						menu_sel = i
						Pad.mouse_ok = true
		"lobby":
			if hud.panel_open or mode == "sofa":
				Pad.mouse_ok = click
				return
			for i in lobby_rects.size():
				if lobby_rects[i].has_point(mp):
					if moved and lobby_sel != i:
						lobby_sel = i
						Sfx.play("tick", -8.0)
					if click:
						lobby_sel = i
						Pad.mouse_ok = true
		"guide", "over":
			Pad.mouse_ok = click
		"table":
			if hud.tut_open or hud.score_open or curtain >= 0:
				Pad.mouse_ok = click
				return
			if turn_seat != me or not _is_local_human(me):
				return
			if view_phase == "bid":
				var opts := _bid_options()
				for i in opts.size():
					var r := Rect2(226, 124 + i * 18, 188, 15)
					if r.has_point(mp):
						if moved and bid_sel != i:
							bid_sel = i
							Sfx.play("tick", -8.0)
						if click:
							bid_sel = i
							Pad.mouse_ok = true
			elif view_phase in ["play", "discard"]:
				if hud.hint_rect.has_point(mp) and view_phase == "discard":
					Pad.mouse_alt = click
					return
				var hit := _card_under(mp)
				if hit >= 0:
					if moved and cursor != hit:
						cursor = hit
						Sfx.play("tick", -10.0, 1.3)
					if click:
						cursor = hit
						Pad.mouse_ok = true


## Índice en mi mano de la carta bajo el ratón (la de encima si se solapan).
func _card_under(mp: Vector2) -> int:
	var best := -1
	var best_z := -9999
	for i in hand.size():
		var cn: CardNode = nodes.get(hand[i])
		if cn == null or not is_instance_valid(cn):
			continue
		var l := cn.to_local(mp)
		if absf(l.x) <= 35.0 and absf(l.y) <= 54.0 and cn.z_index > best_z:
			best = i
			best_z = cn.z_index
	return best


func _any(k: String) -> bool:
	for p in pads:
		if p.pressed(k):
			return true
	return false


## Partida rápida: segundos de cuenta atrás antes de empezar solos (0 = aún no se puede).
func quick_wait() -> float:
	if players.size() >= n:
		return 3.0
	if game_kind != "tarot" and players.size() >= 2:
		return 8.0
	return 0.0


func _menu_input() -> void:
	if hud.panel_open:
		_panel_input()
		return
	if name_edit or name_guard > 0.0:
		name_guard -= get_process_delta_time()
		_build_menu()  # cursor que parpadea
		return
	var cnt := menu_items.size()
	if _any("up"):
		menu_sel = (menu_sel + cnt - 1) % cnt
		Sfx.play("tick")
	if _any("down"):
		menu_sel = (menu_sel + 1) % cnt
		Sfx.play("tick")
	var id: String = menu_items[menu_sel][0]
	if menu_page == "title" and menu_sel >= 3 and (_any("left") or _any("right")):
		menu_sel = 7 - menu_sel  # entre los dos iconos de abajo
		Sfx.play("tick")
	if menu_page == "settings" and id != "back":
		if _any("left"):
			_setting_step(id, -1)
		if _any("right"):
			_setting_step(id, 1)
	if menu_page == "look" and id in Pix.LOOK_DEFAULT:
		if _any("left"):
			_look_step(id, -1)
		if _any("right"):
			_look_step(id, 1)
	if _any("ok"):
		if menu_page == "settings":
			if id == "back":
				_set_page("title")
			else:
				_setting_step(id, 1)
			return
		if menu_page == "look":
			match id:
				"back":
					_set_page("play")
				"name":
					name_edit = true
					Sfx.play("select")
				"random":
					for k in Pix.LOOK_DEFAULT:
						cfg.look[k] = randi() % _look_size(k)
					Sfx.play("teleport", -4.0)
					sel_t = 0.0
					_build_menu()
				_:
					_look_step(id, 1)
			return
		Sfx.play("select")
		_menu_pick(id)
	elif _any("back") and menu_page != "title":
		_set_page("play" if menu_page in ["look", "games"] else "title")


func _start_casino(k: String) -> void:
	phase = "casino"
	if casino:
		casino.queue_free()
	casino = TarotCasino.new()
	table.add_child(casino)
	casino.setup(self, k)


func _leave_casino() -> void:
	_save_cfg()
	if casino:
		casino.queue_free()
		casino = null
	if Net.online():
		_go_menu()
	phase = "menu"
	menu_page = "games"
	menu_sel = 0
	menu_t = 0.0
	_build_menu()


## Mesa de casino online: el anfitrión sienta a todos (sin IA) y empieza.
func _start_casino_online() -> void:
	session += 1
	Net.lock()
	_net_casino_start.rpc(players, game_kind)
	_start_casino(game_kind)


@rpc("authority", "call_remote", "reliable")
func _net_casino_start(list: Array, k: String) -> void:
	session += 1
	players = list
	game_kind = k
	_clear_table()
	_start_casino(k)


func casino_broadcast(ev: Dictionary) -> void:
	if Net.online() and Net.is_host():
		_net_casino_ev.rpc(ev)


@rpc("authority", "call_remote", "reliable")
func _net_casino_ev(ev: Dictionary) -> void:
	if casino and phase == "casino":
		casino.apply(ev)


func casino_send_act(id: String, data) -> void:
	_net_casino_act.rpc_id(1, id, data)


@rpc("any_peer", "call_remote", "reliable")
func _net_casino_act(id: String, data) -> void:
	if Net.is_host() and casino and phase == "casino":
		casino.remote_act(multiplayer.get_remote_sender_id(), id, data)


func _look_size(k: String) -> int:
	match k:
		"color":
			return Pix.PLAYERS.size()
		"c2":
			return Pix.SECONDS.size()
		"hat":
			return Pix.HATS.size()
		"skin":
			return Pix.SKINS.size()
		"eyes":
			return Pix.EYES.size()
	return Pix.EXTRAS.size()


func _look_step(k: String, d: int) -> void:
	cfg.look[k] = wrapi(int(cfg.look[k]) + d, 0, _look_size(k))
	sel_t = 0.0
	Sfx.play("tick")
	_build_menu()


## Escribir el nombre: letras de la fuente, borrar, Intro o Esc para terminar.
func _input(event: InputEvent) -> void:
	if not name_edit or not (event is InputEventKey) or not event.pressed:
		return
	var k := event as InputEventKey
	var nm: String = cfg.name
	if k.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]:
		name_edit = false
		name_guard = 0.25
		cfg.name = Pix.safe_name(nm, "", 10) if nm.strip_edges().length() >= 2 else ""
		Sfx.play("select")
	elif k.keycode == KEY_BACKSPACE:
		cfg.name = nm.left(nm.length() - 1)
		Sfx.play("tick", -6.0)
	elif k.unicode > 0 and nm.length() < 10:
		var ch := Pix.norm(String.chr(k.unicode))
		if ch == " " or (Pix.GLYPHS.has(ch) and not Pix.BUTTON_COLORS.has(ch)):
			cfg.name = nm + ch
			Sfx.play("tick", -6.0, 1.3)
	_build_menu()
	get_viewport().set_input_as_handled()


func _menu_pick(id: String) -> void:
	var lan := not Net.steam_ok or "--lan" in OS.get_cmdline_user_args()
	match id:
		"look":
			_set_page("look")
		"games":
			_set_page("games")
		"bj", "7m":
			mode = "solo"
			players = [_me_player()]
			_start_casino(id)
		"bjq", "7mq":
			game_kind = id.left(2)
			_quick_search()
		"play":
			_set_page("play")
		"settings":
			_set_page("settings")
		"discord", "feedback":
			var url: String = DISCORD_URL if id == "discord" else FEEDBACK_URL
			if url == "":
				_toast("ENLACE AUN NO DISPONIBLE")
			else:
				OS.shell_open(url)
		"tuto":
			mode = "solo"
			tutorial = true
			tut_fast = false
			trick_no = 0
			tut_seen = {}
			players = [_me_player()]
			_fill_ai()
			_start_match()
		"guide":
			phase = "guide"
			guide_page = 0
			guide_t = 0.0
		"solo":
			mode = "solo"
			players = [_me_player()]
			_fill_ai()
			_start_match()
		"sofa":
			mode = "sofa"
			players = []
			phase = "lobby"
		"host":
			game_kind = "tarot"
			online_kind = "sala"
			if not lan:
				if Net.steam_offline():
					_toast("STEAM ESTA SIN CONEXION")
					return
				Net.host_steam(false)
				_toast("CREANDO SALA DE STEAM...")
			elif Net.host_lan():
				_on_net_connected()
		"quick":
			game_kind = "tarot"
			_quick_search()
		"join":
			if not lan:
				hud.open_join_panel()
			else:
				Net.join_lan("127.0.0.1")
				_toast("CONECTANDO...")
		"quit":
			get_tree().quit()


## Partida rápida del juego elegido (game_kind): busca una sala pública de ese juego o abre una.
func _quick_search() -> void:
	online_kind = "rapida"
	Net.partida = game_kind
	if "--lan" in OS.get_cmdline_user_args():
		if Net.quick_lan():
			_on_net_connected()
		else:
			_toast("BUSCANDO PARTIDA...")
	elif not Net.steam_ok:
		_toast("EL ONLINE NECESITA STEAM ABIERTO")
	elif Net.steam_offline():
		_toast("STEAM ESTA SIN CONEXION")
	else:
		Net.quick_steam()
		_toast("BUSCANDO PARTIDA...")


func _panel_input() -> void:
	var list: Array = hud.panel_list
	if _any("back"):
		hud.panel_open = false
		return
	if list.is_empty():
		if _any("ok"):
			hud.refresh_panel()
		return
	if _any("up"):
		hud.panel_sel = (hud.panel_sel + list.size() - 1) % list.size()
	if _any("down"):
		hud.panel_sel = (hud.panel_sel + 1) % list.size()
	if _any("ok"):
		var f: Dictionary = list[hud.panel_sel]
		if hud.panel_kind == "join":
			Net.join_steam(int(f.lobby))
			hud.panel_open = false
			_toast("ENTRANDO EN LA SALA DE %s..." % f.name)
		else:
			# Solo se invita cuando el jugador lo pide pulsando ✕ sobre un amigo.
			Net.invite(int(f.id))
			_toast("INVITACION ENVIADA A %s" % f.name)
			Sfx.play("join")


## Mi jugador: nombre (el elegido o el de Steam) y el muñeco a medida.
func _me_player() -> Dictionary:
	var lk: Dictionary = cfg.look
	return {"name": my_name(), "kind": "human", "peer": 1, "dev": "", "pi": int(lk.get("color", 0)) % Pix.PLAYERS.size(), "look": lk.duplicate()}


func my_name() -> String:
	return String(cfg.name) if String(cfg.name) != "" else Net.my_name


## Aspecto que llega por la red: solo números dentro de cada lista.
func _clean_look(lk) -> Dictionary:
	var out := Pix.LOOK_DEFAULT.duplicate()
	if lk is Dictionary:
		var sizes := {"color": Pix.PLAYERS.size(), "c2": Pix.SECONDS.size(), "hat": Pix.HATS.size(), "skin": Pix.SKINS.size(), "eyes": Pix.EYES.size(), "extra": Pix.EXTRAS.size()}
		for k in sizes:
			out[k] = clampi(int(lk.get(k, 0)) if (lk.get(k, 0) is int or lk.get(k, 0) is float) else 0, 0, sizes[k] - 1)
	return out


func _fill_ai() -> void:
	var used := players.map(func(p): return p.pi)
	var k := 0
	while players.size() < n:
		var pi := 0
		while pi in used:
			pi += 1
		used.append(pi)
		players.append({"name": SEAT_NAMES_AI[k % 4], "kind": "ai", "peer": 1, "dev": "", "pi": pi})
		k += 1


# --- Sala (sofá y online) ---

func _lobby_input() -> void:
	if hud.panel_open:
		_panel_input()
		return
	if mode == "sofa":
		for p in pads:
			var joined := players.filter(func(q): return q.dev == p.dev)
			if p.pressed("ok") and joined.is_empty() and players.size() < n:
				players.append({"name": "JUGADOR %d" % (players.size() + 1), "kind": "human", "peer": 1, "dev": p.dev, "pi": players.size()})
				Sfx.play("join")
			elif p.pressed("back"):
				if not joined.is_empty():
					players.erase(joined[0])
					Sfx.play("leave")
				else:
					_go_menu()
					return
			elif p.pressed("start") and not players.is_empty():
				_fill_ai()
				_start_match()
				return
	else:
		if _any("back"):
			_go_menu()
			return
		if not Net.is_host():
			return
		var rows := lobby_rows()
		if rows.is_empty():
			return
		lobby_sel = clampi(lobby_sel, 0, rows.size() - 1)
		if _any("up"):
			lobby_sel = (lobby_sel + rows.size() - 1) % rows.size()
			Sfx.play("tick")
		if _any("down"):
			lobby_sel = (lobby_sel + 1) % rows.size()
			Sfx.play("tick")
		var id: String = rows[lobby_sel][0]
		if id in ["nivel", "n", "vueltas", "juego"]:
			if _any("left"):
				_lobby_pick(id, -1)
			if _any("right"):
				_lobby_pick(id, 1)
		if _any("ok"):
			_lobby_pick(id, 1)
		if _any("alt") and Net.mode == "steam" and online_kind == "sala":
			hud.open_invite_panel()
		for p in pads:
			if p.dev != "kb" and p.pressed("start"):
				_lobby_pick("start", 1)


## Opciones del anfitrión en la sala online: [id, texto].
func lobby_rows() -> Array:
	if mode != "online" or not Net.is_host():
		return []
	if online_kind == "rapida":
		return [["start", "EMPEZAR YA (LOS HUECOS LOS OCUPA LA IA)" if game_kind == "tarot" else "EMPEZAR YA"]]
	var r := [["juego", "JUEGO  < %s >" % GAME_NAMES[game_kind]]]
	if game_kind == "tarot":
		r.append_array([["nivel", "IA  < %s >" % level_name(ai.level)], ["n", "JUGADORES  < %d >" % n], ["vueltas", "PARTIDA  < %d MANOS >" % (n * rounds)]])
	if Net.mode == "steam":
		r.append(["invite", "INVITAR POR STEAM"])
	r.append(["start", "EMPEZAR PARTIDA"])
	return r


func _lobby_pick(id: String, d: int) -> void:
	match id:
		"juego":
			var ks := GAME_NAMES.keys()
			game_kind = ks[wrapi(ks.find(game_kind) + d, 0, ks.size())]
			if game_kind != "tarot":
				n = 4  # en el casino caben 4 contra la banca
			lobby_sel = 0
			Sfx.play("tick")
		"n":
			var nn := 3 if n == 4 else 4
			if players.size() > nn:
				_toast("HAY DEMASIADA GENTE PARA %d" % nn)
				Sfx.play("warn")
				return
			n = nn
			Sfx.play("tick")
		"vueltas":
			rounds = wrapi(rounds - 1 + d, 0, 3) + 1
			Sfx.play("tick")
		"nivel":
			ai.set_level(wrapi(ai.level + d, 0, TarotAI.LEVELS.size()))
			Sfx.play("tick")
		"invite":
			Sfx.play("select")
			hud.open_invite_panel()
			return
		"start":
			Sfx.play("select")
			if game_kind != "tarot":
				_start_casino_online()
				return
			_fill_ai()
			_sync_players()
			_start_match()
			return
	_sync_players()


func _on_net_connected() -> void:
	mode = "online"
	phase = "lobby"
	lobby_sel = 0
	if Net.is_host():
		players = [_me_player()]
		if online_kind == "rapida":
			n = 4
			rounds = 2
			_sync_players()
			_toast("BUSCANDO RIVALES...")
		else:
			online_kind = "sala"
			_toast("SALA CREADA")
	else:
		_net_hello.rpc_id(1, my_name(), cfg.look, int(cfg.fichas))


func _on_peer_joined(_id: int) -> void:
	pass


func _on_peer_left(id: int) -> void:
	if not Net.is_host():
		return
	if phase == "casino" and casino:
		casino.peer_left(id)
		return
	if phase == "lobby":
		players = players.filter(func(q): return not (q.kind == "remote" and q.peer == id))
		_sync_players()
		return
	for i in players.size():
		var p: Dictionary = players[i]
		if p.kind == "remote" and p.peer == id:
			p.kind = "ai"
			_toast("%s SE HA IDO: LE SUSTITUYE LA IA" % p.name)
			p.name = p.name.left(7) + " IA"
			# Si la partida le estaba esperando, despertarla para que decida la IA
			action_done.emit(i, "wake", null)
	_sync_players()


@rpc("any_peer", "call_remote", "reliable")
func _net_hello(nm: String, lk, fichas := 100) -> void:
	if not Net.is_host() or phase != "lobby" or players.size() >= n:
		return
	var id := multiplayer.get_remote_sender_id()
	var look := _clean_look(lk)
	# Su color si está libre; si no, el primero que quede
	var used := players.map(func(q): return q.pi)
	var pi: int = look.color
	while pi in used:
		pi = (pi + 1) % Pix.PLAYERS.size()
	players.append({"name": Pix.safe_name(nm, "AMIGO", 10), "kind": "remote", "peer": id, "dev": "", "pi": pi, "look": look,
		"fichas": clampi(int(fichas), 0, 1000000)})
	Sfx.play("join")
	_sync_players()


func _sync_players() -> void:
	if Net.online() and Net.is_host():
		_net_players.rpc(players, n, rounds, online_kind, ai.level, game_kind)


@rpc("authority", "call_remote", "reliable")
func _net_players(list: Array, p_n: int, p_rounds: int, p_kind: String, p_level: int, p_game := "tarot") -> void:
	ai.set_level(p_level)
	game_kind = p_game if GAME_NAMES.has(p_game) else "tarot"
	players = list
	n = p_n
	rounds = p_rounds
	online_kind = p_kind
	for i in players.size():
		if players[i].peer == multiplayer.get_unique_id() and players[i].kind == "remote":
			me = i
	if phase == "menu":
		phase = "lobby"


# --- Partida (anfitrión) ---

func _start_match() -> void:
	session += 1
	phase = "table"
	scores = []
	for p in n:
		scores.append(0)
	hand_no = 0
	hands_total = 1 if "--una-mano" in OS.get_cmdline_user_args() or tutorial else n * rounds
	me = 0
	for i in players.size():
		if players[i].kind == "human":
			me = i
			break
	_clear_table()
	if Net.online() and Net.is_host():
		Net.lock()
		_net_start.rpc(players, n)
	_host_match(session)


func _host_restart() -> void:
	_start_match()


@rpc("authority", "call_remote", "reliable")
func _net_start(list: Array, p_n: int) -> void:
	session += 1
	players = list
	n = p_n
	for i in players.size():
		if players[i].peer == multiplayer.get_unique_id() and players[i].kind == "remote":
			me = i
	phase = "table"
	_clear_table()
	scores = []
	for p in n:
		scores.append(0)


func _host_match(sess: int) -> void:
	for h in hands_total:
		if sess != session:
			return
		hand_no = h + 1
		var dlr := h % n if not tutorial else TarotTutorial.DEALER
		while true:
			rules = Rules.new()
			rules.deal(n, dlr, rng)
			if tutorial:
				rules.set_fixed(TarotTutorial.hands(), TarotTutorial.chien(), TarotTutorial.DEALER)
			if rules.phase == "redeal":
				continue
			_emit({"t": "deal", "dealer": dlr, "hand_no": hand_no, "of": hands_total})
			await _drain()
			while rules.phase == "bid":
				var p := rules.turn
				_emit({"t": "bid_turn", "p": p, "best": rules.best_bid()})
				var b_any = await _ask(p, "bid", sess)
				if sess != session:
					return
				var b := int(b_any)
				if not rules.can_bid(b):
					b = 0
				rules.bid(p, b)
				_emit({"t": "bid", "p": p, "b": b})
				await _drain()
			if rules.phase != "redeal":
				break
			_emit({"t": "redeal"})
			await _drain()
			dlr = (dlr + 1) % n
		_emit({"t": "contract", "taker": rules.taker, "c": rules.contract})
		await _drain()
		if rules.contract <= 2:
			_emit({"t": "chien_show", "cards": rules.chien.duplicate()})
			await _drain()
			_emit({"t": "take_chien"})
			await _drain()
			_emit({"t": "discard_turn", "p": rules.taker})
			var cards_any = await _ask(rules.taker, "discard", sess)
			if sess != session:
				return
			var cards: Array = cards_any if cards_any is Array else []
			if not rules.discard(cards):
				rules.discard(ai.choose_discard(rules))
			_emit({"t": "discarded", "p": rules.taker, "cards": rules.discards.duplicate()})
			await _drain()
		else:
			_emit({"t": "chien_away", "to": rules.taker if rules.contract == 3 else -1})
			await _drain()
		while rules.phase == "play":
			var p := rules.turn
			_emit({"t": "turn", "p": p})
			var c_any = await _ask(p, "play", sess)
			if sess != session:
				return
			var c := int(c_any)
			if not (c in rules.legal(p)):
				c = ai.quick(rules, p)
			var led := rules.led_suit()
			var high := rules.highest_trump_in_trick()
			var res := rules.play(p, c)
			_emit({"t": "play", "p": p, "c": c, "led": led, "high": high})
			await _drain()
			if res.has("winner"):
				_emit({"t": "trick", "w": res.winner, "last": rules.phase == "done", "petit": rules.petit_last})
				await _drain()
		var sc := rules.score()
		for p in n:
			scores[p] += sc.per[p]
		_emit({"t": "score", "s": sc, "totals": scores.duplicate(), "hand_no": hand_no, "of": hands_total,
			"taker_cards": rules.piles[0].duplicate()})
		await _drain()
		await _wait_all_ok(sess)
	if sess == session:
		_emit({"t": "over", "totals": scores.duplicate()})


## Espera la decisión de un asiento: IA (en un hilo, con un respiro para que se vea), humano local o remoto.
func _ask(p: int, kind: String, sess: int):
	var pl: Dictionary = players[p]
	if pl.kind == "ai":
		var t0 := Time.get_ticks_msec()
		var result
		match kind:
			"bid":
				result = 0 if tutorial else ai.choose_bid(rules, p)
				if test_contract >= 0:
					result = test_contract if rules.best_bid() == 0 and test_contract > 0 else 0
					if test_contract == 0 and rules.bids.count(-1) <= 1:
						test_contract = -1  # tras el reparto en blanco, la siguiente mano es normal
			"discard":
				result = TarotTutorial.discard() if tutorial else ai.choose_discard(rules)
			"play" when tutorial and TarotTutorial.scripted_card(_trick_no(), p) >= 0:
				result = TarotTutorial.scripted_card(_trick_no(), p)
			"play" when ai.samples == 0:
				result = ai.decide_card(rules, p)
			"play":
				var snap := rules.copy()
				var brain := TarotAI.new()
				brain.set_level(ai.level)
				_ai_thread = Thread.new()
				_ai_thread.start(func(): return brain.decide_card(snap, p))
				while _ai_thread.is_alive():
					await get_tree().process_frame
				result = _ai_thread.wait_to_finish()
		var min_ms := 650 if kind != "play" else 420 + rng.randi_range(0, 380)
		if tutorial and tut_fast:
			min_ms = 60
		while Time.get_ticks_msec() - t0 < min_ms:
			await get_tree().process_frame
		return result
	while true:
		var r: Array = await action_done
		if sess != session:
			return null
		if r[0] == p and r[1] == kind:
			return r[2]
		if players[p].kind == "ai":
			return await _ask(p, kind, sess)


## Número de baza en curso (0 = la primera), en el anfitrión.
func _trick_no() -> int:
	return (18 if n == 4 else 24) - rules.tricks_left


func _wait_all_ok(sess: int) -> void:
	waiting_ok = []
	for i in players.size():
		if players[i].kind in ["human", "remote"]:
			waiting_ok.append(i)
	var t0 := Time.get_ticks_msec()
	while not waiting_ok.is_empty() and sess == session:
		var r: Array = await action_done
		if r[1] == "ok" or players[r[0]].kind == "ai":
			waiting_ok.erase(r[0])
			_emit({"t": "ok", "p": r[0]})


## Acción de un jugador de esta pantalla: el anfitrión la usa directamente, el cliente se la manda.
func _act(seat: int, kind: String, data) -> void:
	if mode == "sofa" and kind in ["bid", "discard", "play"] and _sofa_humans() > 1:
		_sofa_hide()
	if not Net.online() or Net.is_host():
		action_done.emit(seat, kind, data)
	else:
		_net_act.rpc_id(1, kind, data)


@rpc("any_peer", "call_remote", "reliable")
func _net_act(kind: String, data) -> void:
	if not Net.is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	for i in players.size():
		if players[i].kind == "remote" and players[i].peer == id:
			action_done.emit(i, kind, data)


# --- Sucesos: el anfitrión reparte a cada uno su versión ---

func _emit(ev: Dictionary) -> void:
	if Net.online():
		for i in players.size():
			var pl: Dictionary = players[i]
			if pl.kind == "remote":
				_net_ev.rpc_id(pl.peer, _view_ev(ev, i))
	var local_seat := me
	if mode == "sofa":
		local_seat = -2  # el sofá ve según quién tenga el mando
	var lev := _view_ev(ev, local_seat)
	lev["_s"] = session  # para descartar sucesos de una partida anterior
	_queue.append(lev)
	if not _busy:
		_pump()


@rpc("authority", "call_remote", "reliable")
func _net_ev(ev: Dictionary) -> void:
	_queue.append(ev)
	if not _busy:
		_pump()


## Versión del suceso para el asiento `seat` (-2 = sofá: lo calcula la pantalla al mostrarlo).
func _view_ev(ev: Dictionary, seat: int) -> Dictionary:
	var e := ev.duplicate(true)
	match ev.t:
		"deal":
			var seq: Array = []
			for d in rules.deal_seq:
				seq.append([d[0], d[1] if seat == -2 or d[0] == seat else -1])
			e.seq = seq
		"take_chien":
			e.taker = rules.taker
			e.cards = rules.chien.duplicate()
		"discarded":
			if seat != -2 and seat != ev.p:
				e.cards = [-1, -1, -1, -1, -1, -1]
		"turn":
			if seat == -2 or seat == ev.p:
				e.legal = rules.legal(ev.p)
				if tutorial and players[ev.p].kind == "human":
					var sc := TarotTutorial.scripted_card(_trick_no(), ev.p)
					if sc >= 0:
						e.legal = [sc]
			e.trick_no = _trick_no()
		"discard_turn":
			if seat == -2 or seat == ev.p:
				e.allowed = rules.hands[ev.p].filter(func(c): return rules.can_discard(c))
				if tutorial:
					e.allowed = TarotTutorial.discard()
	return e


func _drain() -> void:
	while _busy or not _queue.is_empty():
		await get_tree().process_frame


func _pump() -> void:
	_busy = true
	while not _queue.is_empty():
		var ev: Dictionary = _queue.pop_front()
		if ev.has("_s") and ev._s != session:
			continue
		await _apply(ev)
	_busy = false


# --- Vista ---

func _clear_table() -> void:
	hud.score_open = false
	# La mesa vieja se esconde y se borra un poco después: así una animación que aún corra no toca nada borrado.
	var old := table
	old.visible = false
	old.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().create_timer(6.0).timeout.connect(old.queue_free)
	table = Node2D.new()
	add_child(table)
	move_child(table, old.get_index() + 1)
	nodes.clear()
	backs = [[], [], [], []]
	chien_nodes.clear()
	trick_nodes.clear()
	pile_nodes = [[], [], [], []]
	hand.clear()
	counts = [0, 0, 0, 0]
	bids = [-1, -1, -1, -1]
	contract = 0
	taker = -1
	turn_seat = -1
	tricks_won = [0, 0, 0, 0]
	view_phase = ""
	legal = []
	picked = []
	curtain = -1
	fx.clear()


## Posición en pantalla de cada asiento: 0 abajo (yo), 1 izquierda, 2 arriba, 3 derecha (con 3 jugadores: abajo, izquierda, derecha).
func slot(p: int) -> int:
	var v := (p - me + n) % n
	if n == 3 and v == 2:
		return 3
	return v


## Mano del tutorial: fuerte (el 21, el Loco, el 1 y muchos triunfos) para que se pueda ganar aprendiendo.
const TUTORIAL_HAND := [21, 0, 1, 19, 17, 15, 12, 8, 5, 35, 34, 25, 49, 42, 37, 77, 58, 52]

## Las cartas posadas van a escala 1 y rectas: el pixel art solo se lee nítido sin escalar ni girar.
const TRICK_SPOT := [Vector2(320, 214), Vector2(246, 166), Vector2(320, 110), Vector2(394, 166)]
const PILE_SPOT := [Vector2(604, 236), Vector2(130, 76), Vector2(214, 30), Vector2(540, 64)]
const PLATE := [Vector2(8, 244), Vector2(48, 98), Vector2(408, 6), Vector2(496, 98)]


func hand_spot(k: int, count: int) -> Vector2:
	var stride := minf(34.0, 530.0 / maxf(1.0, count - 1))
	return Vector2(320.0 - stride * (count - 1) / 2.0 + stride * k, 326.0)


func back_spot(s: int, k: int, count: int) -> Array:
	var st := 7.0
	var off := (k - (count - 1) / 2.0) * st
	match s:
		1: return [Vector2(14, 176 + off), PI / 2.0]
		2: return [Vector2(320 + off, 4), PI]
		3: return [Vector2(626, 176 - off), -PI / 2.0]
	return [Vector2(320, 400), 0.0]


func _layout() -> void:
	# Mi mano en abanico (la carta del cursor sube)
	var k := hand.size()
	for i in k:
		var c: int = hand[i]
		var cn: CardNode = nodes.get(c)
		if cn == null or cn.flying:
			continue
		var p := hand_spot(i, k)
		var arc := (i - (k - 1) / 2.0) / maxf(1.0, k)
		p.y += absf(arc) * absf(arc) * 40.0
		var sel := i == cursor and view_phase in ["play", "discard"] and turn_seat == me and curtain < 0
		var chosen := c in picked
		var my_play := view_phase == "play" and turn_seat == me and curtain < 0 and _is_local_human(me)
		if my_play and not sel:
			if c in legal:
				p.y -= 7.0 + sin(Time.get_ticks_msec() / 1000.0 * 6.0 + i * 0.55) * 2.0
			else:
				p.y += 12.0
		if sel:
			p.y -= 24.0
		if chosen:
			p.y -= 14.0
		cn.target_pos = p
		cn.target_rot = 0.0 if sel else arc * 0.35
		cn.target_scale = 1.0
		cn.lift = 1.0 if sel else (0.4 if chosen else 0.0)
		cn.z_index = i + (100 if sel else 0)
		var playable := view_phase != "play" or turn_seat != me or c in legal
		if view_phase == "discard" and turn_seat == me:
			playable = c in legal
		cn.dim = lerpf(cn.dim, 0.0 if playable else 1.0, 0.2)
		cn.glow = lerpf(cn.glow, 1.0 if chosen else 0.0, 0.2)
		cn.glow_col = Color("ff6a7a")
	for p in n:
		var s := slot(p)
		if s == 0:
			continue
		var list: Array = backs[p]
		for i in list.size():
			var cn: CardNode = list[i]
			if cn.flying:
				continue
			var sp := back_spot(s, i, list.size())
			cn.target_pos = sp[0]
			cn.target_rot = sp[1]
			cn.target_scale = 0.5
			cn.z_index = i


## Palo que manda en la baza que se está jugando (-1 si aún no hay; 4 = triunfo).
func led_suit_view() -> int:
	for e in trick_nodes:
		var c: int = e[1].card
		if c != Deck.EXCUSE and c >= 0:
			return Deck.suit(c)
	return -1


## Índice en trick_nodes de la carta que va ganando ahora mismo.
func trick_leader_idx() -> int:
	return Rules.trick_winner_idx(trick_nodes.map(func(e): return e[1].card))


## Ayuda para mi turno: qué me obligan a jugar.
func play_hint() -> String:
	if tutorial and legal.size() == 1:
		return "JUEGA %s, COMO TE EXPLICA EL LOCO" % _short(legal[0])
	var led := led_suit_view()
	if trick_nodes.is_empty():
		return "SALES TU: JUEGA LA CARTA QUE QUIERAS"
	if led == -1:
		return "SOLO HAY EL LOCO: JUEGA LO QUE QUIERAS"
	var has_led := hand.any(func(c): return c != Deck.EXCUSE and Deck.suit(c) == led)
	var high := 0
	for e in trick_nodes:
		if Deck.is_trump(e[1].card):
			high = maxi(high, e[1].card)
	var trumps: Array = hand.filter(func(c): return Deck.is_trump(c))
	if led == Deck.TRUMP:
		if trumps.is_empty():
			return "NO TIENES TRIUNFOS: DESCARTA LO QUE QUIERAS"
		return "SIRVE TRIUNFO MAS ALTO QUE EL %d" % high if trumps.any(func(c): return c > high) else "SIRVE TRIUNFO (NO PUEDES MONTAR)"
	if has_led:
		return "SIRVE %s" % Minors.SUITS[led].name
	if trumps.is_empty():
		return "NO TIENES %s NI TRIUNFOS: DESCARTA" % Minors.SUITS[led].name
	if high > 0:
		return "NO TIENES %s: MONTA AL %d SI PUEDES" % [Minors.SUITS[led].name, high]
	return "NO TIENES %s: FALLA CON UN TRIUNFO" % Minors.SUITS[led].name


func _new_card(c: int, up: bool, pos: Vector2) -> CardNode:
	var cn := CardNode.new()
	cn.setup(c, up)
	cn.position = pos
	cn.target_pos = pos
	table.add_child(cn)
	return cn


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


## Aplica un suceso con su animación. Termina cuando la animación ha terminado.
func _apply(ev: Dictionary) -> void:
	match ev.t:
		"deal":
			await _ev_deal(ev)
			if ev.get("_s", session) != session:
				return
			await _tut("hola", ["¡HOLA! SOY EL LOCO. VAMOS A JUGAR UNA MANO JUNTOS, PASO A PASO.", "LA IDEA ES SENCILLA: EN CADA RONDA (SE LLAMA BAZA) CADA JUGADOR", "PONE UNA CARTA EN EL CENTRO, Y LA MAS FUERTE SE LLEVA LAS CUATRO."], Vector2(320, 166))
			await _tut("leer", ["ESTA ES TU MANO. A LA IZQUIERDA, LOS TRIUNFOS (LAS CARTAS MAS", "FUERTES, CON NUMERO DEL 1 AL 21). A LA DERECHA, LOS CUATRO PALOS:", "BASTOS, COPAS, ESPADAS Y OROS. MANTEN □ O CLIC DERECHO PARA AMPLIAR."] + _ex_leer(), Vector2(320, 284))
		"bid_turn":
			turn_seat = ev.p
			view_phase = "bid"
			await _maybe_curtain(ev.p)
			if _is_local_human(ev.p):
				bid_sel = 0
				Sfx.play("ding", -6.0)
				await _tut("apuesta", ["ANTES DE JUGAR SE APUESTA. QUIEN APUESTA JUEGA SOLO CONTRA LOS OTROS TRES", "Y TIENE QUE JUNTAR PUNTOS CON LAS CARTAS QUE GANE. TU MANO ES FUERTE:", "TIENES 7 TRIUNFOS (CON EL 21 Y EL 1) Y TRES REYES. CON UNA MANO ASI SE APUESTA.", "ELIGE PEQUEÑA, LA APUESTA BASICA, Y PULSA ✕."], Vector2(320, 120))
		"bid":
			bids[ev.p] = ev.b
			hud.bubble(ev.p, Rules.CONTRACTS[ev.b], ev.b)
			Sfx.play("select" if ev.b == 0 else "charge", -4.0 if ev.b == 0 else -8.0, 1.0 + ev.b * 0.12)
			if ev.b >= 3:
				shake = 4.0 + ev.b
				fx.ring(_plate_center(ev.p), 6, 80, 0.5, Color("ff6a3a"), 2)
			turn_seat = -1
			await _wait(0.55 if ev.b == 0 else 0.9)
		"redeal":
			hud.banner("TODOS PASAN · SE REPARTE OTRA VEZ", Pix.CREAM)
			await _collect_all()
		"contract":
			taker = ev.taker
			contract = ev.c
			for p in n:
				if p != taker:
					bids[p] = -1
			hud.banner("%s SE LA JUEGA" % players[taker].name, Pix.CREAM)
			hud.comic(Vector2(320, 170), Rules.CONTRACTS[contract], TarotHud.LEVEL_COLS[contract], 2.0 + contract * 0.35, true)
			taker_half = 0
			taker_oudlers = 0
			Sfx.play("reveal")
			Sfx.play("boom", -10.0 + contract * 2.0)
			fx.converge(_plate_center(taker), 30, 120, 0.5, [Pix.GOLD, Color.WHITE], 50.0)
			await _wait(0.5)
			fx.ring(_plate_center(taker), 4, 110, 0.6, Pix.GOLD, 3)
			shake = 3.0 * contract
			await _wait(0.9)
			if taker == me:
				await _tut("contrato", ["¡AHORA ERES TU CONTRA LOS TRES! AQUI ARRIBA VES LOS PUNTOS", "QUE LLEVAS Y LOS QUE NECESITAS (LA RAYA BLANCA) PARA GANAR.", "LOS REYES, REINAS, EL 1, EL 21 Y YO SOMOS LAS CARTAS QUE MAS VALEN."], Vector2(80, 28))
		"chien_show":
			await _ev_chien_show(ev.cards)
			await _tut("perro", ["ESTAS 6 CARTAS DEL CENTRO SON EL PERRO: UN REGALO PARA QUIEN APUESTA.", "MIRA QUE BIEN: VIENE EL TRIUNFO 20 Y LA REINA DE COPAS (3,5 PUNTOS).", "AHORA SE VAN A TU MANO."], Vector2(320, 166))
		"take_chien":
			await _ev_take_chien(ev)
		"chien_away":
			await _ev_chien_away(ev.to)
		"discard_turn":
			turn_seat = ev.p
			view_phase = "discard"
			picked = []
			legal = ev.get("allowed", [])
			cursor = 0
			await _maybe_curtain(ev.p)
			if _is_local_human(ev.p):
				hud.banner("APARTA 6 CARTAS", Pix.CREAM)
				await _tut("aparta", ["AHORA TIENES 24 CARTAS: DEBES APARTAR 6 BOCA ABAJO (AL FINAL CUENTAN PARA TI).", "VAMOS A APARTAR TUS 4 ESPADAS (5, 8, 3 Y 6), EL 2 DE BASTOS Y EL 3 DE COPAS.", "¿POR QUE? VALEN MUY POCO, Y SIN ESPADAS, CUANDO ALGUIEN SALGA CON ESPADAS", "PODRAS GANAR CON UN TRIUNFO. MARCA LAS 6 QUE BRILLAN CON ✕ Y PULSA △."], Vector2(320, 284))
		"discarded":
			await _ev_discarded(ev)
		"turn":
			trick_no = ev.get("trick_no", trick_no)
			turn_seat = ev.p
			view_phase = "play"
			legal = ev.get("legal", [])
			await _maybe_curtain(ev.p)
			if _is_local_human(ev.p):
				if not legal.is_empty() and not (hand[clampi(cursor, 0, hand.size() - 1)] in legal):
					cursor = hand.find(legal[0])
				Sfx.play("tick", -4.0, 1.4)
				if tutorial and not legal.is_empty():
					cursor = hand.find(legal[0])
					var cn0: CardNode = nodes.get(legal[0])
					await _tut("t%d" % trick_no, TarotTutorial.MSG.get("t%d" % trick_no, []), cn0.target_pos + Vector2(0, -70) if cn0 else Vector2(-1, -1), "top")
		"play":
			await _ev_play(ev)
			if tutorial:
				var k := "o%d_%d" % [trick_no, ev.p]
				if TarotTutorial.MSG.has(k):
					await _tut(k, TarotTutorial.MSG[k], TRICK_SPOT[slot(ev.p)] + Vector2(0, 46), "bottom")
		"trick":
			await _ev_trick(ev)
			if tutorial:
				var k := "a%d" % trick_no
				if TarotTutorial.MSG.has(k):
					await _tut(k, TarotTutorial.MSG[k], Vector2(80, 28) if ev.w == me else Vector2(-1, -1))
				trick_no += 1
				if trick_no >= TarotTutorial.script().size() and not tut_fast:
					tut_fast = true
					arcana_anim = false
					Engine.time_scale = 3.0
					for pl in players:
						if pl.kind == "human":
							pl.kind = "ai"
		"score":
			await _ev_score(ev)
			if tutorial:
				Engine.time_scale = 1.0
				arcana_anim = bool(cfg.cine)
			await _tut("puntos", _tut_score_lines(ev.s), Vector2(-1, -1))
		"ok":
			waiting_ok.erase(ev.p)
		"over":
			last_score["totals"] = ev.totals
			hud.score_open = false
			phase = "over"
			view_phase = "over"
			Sfx.play("win")
			hud.confetti(160)


## Tutorial: el Loco dice algo (una vez por clave) y la partida espera a que pulses ✕.
func _tut(key: String, lines: Array, point := Vector2(-1, -1), place := "") -> void:
	if not tutorial or tut_seen.has(key):
		return
	tut_seen[key] = true
	hud.tut_show(lines, point, place)
	while hud.tut_open:
		await get_tree().process_frame


# --- Tutorial: ejemplos con las cartas que tienes ahora mismo ---

func _short(c: int) -> String:
	if c == Deck.EXCUSE:
		return "EL LOCO"
	if Deck.is_trump(c):
		return "EL TRIUNFO %d" % c
	return Deck.name(c)


func _ex_leer() -> Array:
	var trumps: Array = hand.filter(func(c): return Deck.is_trump(c))
	var top := 0
	for c in trumps:
		top = maxi(top, c)
	return ["POR EJEMPLO: TIENES %d TRIUNFOS, Y EL MAS FUERTE ES %s." % [trumps.size(), _short(top)]]


func _ex_sale() -> Array:
	var kings: Array = hand.filter(func(c): return c > 21 and Deck.value(c) == 14)
	if not kings.is_empty():
		var k: int = kings[0]
		var sn: String = Minors.SUITS[Deck.suit(k)].name
		return ["TIENES %s: SI SALES CON EL, TODOS DEBEN ECHAR %s Y NADIE" % [Deck.name(k), sn], "LO SUPERA, SALVO QUIEN NO TENGA %s Y FALLE CON UN TRIUNFO." % sn]
	return ["NO TIENES REYES: SAL CON UNA CARTA BAJA PARA NO REGALAR PUNTOS."]


## Qué carta va ganando ahora y cuáles de las mías le ganarían.
func _beaters() -> Array:
	var cards: Array = trick_nodes.map(func(e): return e[1].card)
	var out: Array = []
	for c in legal:
		if c == Deck.EXCUSE:
			continue
		var t2 := cards.duplicate()
		t2.append(c)
		if Rules.trick_winner_idx(t2) == t2.size() - 1:
			out.append(c)
	return out


func _ex_sirve(led: int) -> Array:
	var wi := trick_leader_idx()
	if wi < 0:
		return []
	var best: int = trick_nodes[wi][1].card
	var win := _beaters()
	var lose: Array = legal.filter(func(c): return c != Deck.EXCUSE and not (c in win))
	var line := "AHORA VA GANANDO %s." % _short(best)
	if not win.is_empty() and not lose.is_empty():
		return [line, "CON %s LE GANARIAS; CON %s NO." % [_short(win.max()), _short(lose.min())]]
	if not win.is_empty():
		return [line, "CUALQUIERA DE TUS CARTAS DE %s LE GANA: USA LA MAS BAJA QUE BASTE." % Minors.SUITS[led].name]
	return [line, "NINGUNA DE LAS TUYAS LE GANA: ECHA LA QUE MENOS VALGA."]


func _ex_falla() -> Array:
	var trumps: Array = legal.filter(func(c): return Deck.is_trump(c))
	if trumps.is_empty():
		return []
	var low: int = trumps.min()
	if low == 1 and trumps.size() > 1:
		low = trumps.filter(func(c): return c != 1).min()
	return ["POR EJEMPLO, CON %s YA GANARIAS ESTA BAZA. NO GASTES UN TRIUNFO" % _short(low), "ALTO SI CON UNO BAJO BASTA (Y CUIDA EL 1: VALE MUCHO Y SE PIERDE FACIL)."]


func _ex_monta(high: int) -> Array:
	var over: Array = legal.filter(func(c): return Deck.is_trump(c) and c > high)
	if over.is_empty():
		return ["NO TIENES NINGUNO MAS ALTO QUE EL %d: PUEDES JUGAR CUALQUIER TRIUNFO." % high]
	return ["TUS TRIUNFOS MAS ALTOS QUE EL %d: %s." % [high, ", ".join(over.map(func(c): return str(c)))]]


func _ex_loco() -> Array:
	return ["EJEMPLO: SI SOLO TE QUEDA UN REY Y VAN A FALLARLO CON UN TRIUNFO,", "JUEGAME A MI Y GUARDA EL REY PARA OTRA BAZA."]


func _tut_score_lines(sc: Dictionary) -> Array:
	var got: float = sc.half / 2.0
	var need: float = sc.need / 2.0
	var lines := ["¡FIN DE LA MANO! SE SUMAN LOS PUNTOS DE TODAS LAS CARTAS QUE GANASTE",
		"(Y DE LAS 6 QUE APARTASTE): TIENES %s PUNTOS." % hud._num(got),
		"COMO GANASTE %d DE LAS TRES GRANDES (1, 21 Y LOCO), NECESITABAS %s." % [sc.oudlers, hud._num(need)]]
	if sc.won:
		lines.append("¡LO CONSEGUISTE! YA SABES JUGAR. ¡PRUEBA UNA PARTIDA DE VERDAD!")
	else:
		lines.append("ESTA VEZ NO LLEGASTE, PERO YA SABES JUGAR. ¡PRUEBA OTRA VEZ!")
	return lines


func _tut_turn() -> void:
	if not tutorial:
		return
	var led := led_suit_view()
	var trumps: Array = hand.filter(func(c): return Deck.is_trump(c))
	var won_total: int = tricks_won.reduce(func(a, b): return a + b, 0)
	if Deck.EXCUSE in hand and won_total >= 3:
		await _tut("loco", ["¡TIENES AL LOCO (A MI)! ME PUEDES JUGAR CUANDO QUIERAS, SIN", "SEGUIR NINGUNA REGLA. NO GANO NUNCA LA BAZA, PERO VUELVO A TU MONTON:", "USAME CUANDO SOLO PUEDAS JUGAR UNA CARTA BUENA QUE VAS A PERDER."] + _ex_loco(), Vector2(320, 284))
	if trick_nodes.is_empty():
		await _tut("sale", ["EMPIEZA LA BAZA Y SALES TU: JUEGA LA CARTA QUE QUIERAS.", "SU PALO SERA EL QUE MANDA, Y LOS DEMAS TENDRAN QUE SEGUIRLO.", "CONSEJO: SAL CON UN REY, QUE CASI SIEMPRE GANA. ELIGE Y PULSA ✕."] + _ex_sale(), Vector2(320, 284))
		return
	if led >= 0 and led < 4 and hand.any(func(c): return c != Deck.EXCUSE and Deck.suit(c) == led):
		await _tut("sirve", ["AQUI PONE QUE PALO MANDA: %s. SI TIENES CARTAS DE ESE PALO," % Minors.SUITS[led].name, "TIENES QUE JUGAR UNA (LAS QUE PUEDES JUGAR DAN SALTITOS).", "DE MENOR A MAYOR: AS, 2, 3... 10, SOTA, CABALLO, REINA Y REY."] + _ex_sirve(led), Vector2(60, 62))
	elif led >= 0 and led < 4 and not trumps.is_empty():
		var high := 0
		for e in trick_nodes:
			if Deck.is_trump(e[1].card):
				high = maxi(high, e[1].card)
		if high > 0:
			await _tut("monta", ["ALGUIEN YA HA PUESTO EL TRIUNFO %d. SI TIENES UN TRIUNFO" % high, "MAS ALTO, TIENES QUE PONERLO: SE LLAMA MONTAR.", "EN LOS TRIUNFOS GANA EL NUMERO MAS ALTO (EL 21 ES EL MAXIMO)."] + _ex_monta(high), Vector2(320, 284))
		else:
			await _tut("falla", ["¡NO TIENES %s, QUE ES EL PALO QUE MANDA!" % Minors.SUITS[led].name, "ENTONCES TIENES QUE JUGAR UN TRIUNFO: SE LLAMA FALLAR.", "CUALQUIER TRIUNFO, AUNQUE SEA EL 2, GANA A TODAS LAS CARTAS DE PALO."] + _ex_falla(), Vector2(320, 284))
	elif led == Deck.TRUMP:
		await _tut("triunfo", ["HAN EMPEZADO CON UN TRIUNFO: AHORA TODOS DEBEN JUGAR TRIUNFO,", "Y MAS ALTO QUE EL QUE VA GANANDO SI PUEDEN."], Vector2(320, 284))


func _is_local_human(p: int) -> bool:
	if p < 0 or p >= players.size():
		return false
	if mode == "online":
		return p == me
	return players[p].kind == "human"


func _plate_center(p: int) -> Vector2:
	return PLATE[slot(p)] + Vector2(48, 12)


## Sofá: si le toca a otro jugador humano, se tapa la mano y espera a que coja el mando.
func _maybe_curtain(p: int) -> void:
	if mode != "sofa" or players[p].kind != "human" or (p == me and sofa_shown):
		return
	_sofa_hide()
	curtain = p
	while curtain >= 0:
		await get_tree().process_frame
	_set_viewer(p)
	sofa_shown = true


## Sofá con varios humanos: tapa la mano a la vista (tras jugar, para que el siguiente no la vea).
func _sofa_hide() -> void:
	for c in hand:
		if nodes.has(c) and nodes[c].face_up:
			nodes[c].flip(false, 0.12)
	sofa_shown = false


func _sofa_humans() -> int:
	return players.filter(func(q): return q.kind == "human").size()


## Sofá: la pantalla pasa a ver la mesa desde el asiento p (su mano a la vista, el resto de dorsos).
func _set_viewer(p: int) -> void:
	me = p
	for c in hand:
		if nodes.has(c):
			nodes[c].queue_free()
			nodes.erase(c)
	for q in n:
		for b in backs[q]:
			b.queue_free()
		backs[q] = []
	hand = Deck.sorted(rules.hands[p])
	for c in hand:
		var cn := _new_card(c, false, Vector2(320, 420))
		nodes[c] = cn
		cn.flip(true, 0.2)
	for q in n:
		if q == p:
			continue
		for i in rules.hands[q].size():
			var cn := _new_card(-1, false, back_spot(slot(q), i, rules.hands[q].size())[0])
			backs[q].append(cn)
	if view_phase == "play":
		legal = rules.legal(p)
	elif view_phase == "discard":
		legal = rules.hands[p].filter(func(c): return rules.can_discard(c))
	# La baza y los montones se recolocan según el nuevo punto de vista
	for e in trick_nodes:
		e[1].target_pos = TRICK_SPOT[slot(e[0])]
	for q in n:
		var sq := slot(q)
		for k in pile_nodes[q].size():
			var cn: CardNode = pile_nodes[q][k]
			cn.target_pos = PILE_SPOT[sq] + Vector2(0, -minf(k, 30) * 0.35)
			cn.target_rot = PI / 2.0 if sq % 2 == 1 else 0.0
	Sfx.play("swish")


func _deck_pos(p: int) -> Vector2:
	match slot(p):
		0: return Vector2(320, 250)
		1: return Vector2(110, 170)
		2: return Vector2(320, 80)
	return Vector2(530, 170)


func _ev_deal(ev: Dictionary) -> void:
	_clear_table()
	var sess := session
	dealer = ev.dealer
	hand_no = ev.hand_no
	hands_total = ev.get("of", hands_total)  # el cliente no sabe cuántas manos eligió el anfitrión
	if mode == "sofa":
		for i in players.size():
			if players[i].kind == "human":
				me = i if me < 0 or players[me].kind != "human" else me
	var origin := _deck_pos(dealer)
	hud.banner("MANO %d DE %d · REPARTE %s" % [hand_no, hands_total, players[dealer].name], Pix.CREAM)
	# Mazo que se forma y se baraja
	var deck: Array = []
	for k in 10:
		var cn := _new_card(-1, false, origin + Vector2(0, -k * 0.6))
		cn.target_scale = 0.55
		cn._cur_scale = 0.55
		cn.z_index = 200 + k
		deck.append(cn)
	Sfx.play("shuffle", -2.0)
	for k in 6:
		var a: CardNode = deck[randi() % deck.size()]
		a.target_pos = origin + Vector2(randf_range(-26, 26), randf_range(-8, 4))
		a.target_rot = randf_range(-0.4, 0.4)
		Sfx.play("flip", -10.0, 1.3 + k * 0.05)
		await _wait(0.07)
		a.target_pos = origin
		a.target_rot = 0.0
	await _wait(0.2)
	if sess != session:
		return
	var seq: Array = ev.seq
	var mine: Array = []
	for i in seq.size():
		var d: Array = seq[i]
		var who: int = d[0]
		var c: int = d[1]
		if mode == "sofa":
			c = -1 if who != me else c
		var cn := _new_card(-1, false, origin)
		cn.setup(c, false)
		cn.target_scale = 0.55
		cn._cur_scale = 0.55
		cn.z_index = 300
		if who == -1:
			var k := chien_nodes.size()
			chien_nodes.append(cn)
			cn.fly_to(Vector2(270 + k * 20, 166), randf_range(-0.05, 0.05), 0.55, 0.22, 20.0, 1.0)
		elif slot(who) == 0:
			mine.append(c)
			nodes[c] = cn
			hand.append(c)
			cn.fly_to(hand_spot(hand.size() - 1, 18 if n == 4 else 24), 0.0, 1.0, 0.25, -30.0, 1.0)
		else:
			backs[who].append(cn)
			var sp := back_spot(slot(who), backs[who].size() - 1, 18 if n == 4 else 24)
			cn.fly_to(sp[0], sp[1], 0.5, 0.22, 30.0, 1.0)
		counts[who if who >= 0 else 0] += 1
		if i % 3 == 0:
			Sfx.play("tick", -12.0, 1.6 + randf() * 0.3)
		await _wait(0.022)
		if sess != session:
			return
	for cn in deck:
		cn.queue_free()
	await _wait(0.35)
	if sess != session:
		return
	# Mi mano se ordena y se da la vuelta en ola (en el sofá no: cada uno la ve al coger el mando)
	hand = Deck.sorted(hand)
	sofa_shown = false
	if mode == "sofa":
		return
	for i in hand.size():
		var cn: CardNode = nodes[hand[i]]
		cn.flip(true, 0.16)
		if i % 2 == 0:
			Sfx.play("flip", -10.0, 1.0 + i * 0.02)
		await _wait(0.035)
	await _wait(0.3)
	for i in hand.size():
		nodes[hand[i]].shine()
		await _wait(0.01)


func _ev_chien_show(cards: Array) -> void:
	hud.banner("EL PERRO", Pix.GOLD)
	for i in chien_nodes.size():
		var cn: CardNode = chien_nodes[i]
		cn.card = cards[i]
		cn.target_pos = Vector2(320 + (i - 2.5) * 74, 166)
		cn.target_scale = 1.0
		cn.target_rot = 0.0
		cn.z_index = 150
	await _wait(0.35)
	for i in chien_nodes.size():
		var cn: CardNode = chien_nodes[i]
		cn.flip(true, 0.2)
		Sfx.play("flip", -6.0, 1.0 + i * 0.06)
		fx.burst(cn.position, 8, Pix.GOLD, 30, 90, 0.4, 60, 1)
		if Deck.is_oudler(cards[i]) or (cards[i] > 21 and Deck.value(cards[i]) == 14):
			fx.ring(cn.position, 4, 40, 0.4, Pix.GOLD, 2)
			Sfx.play("ding", -4.0)
		await _wait(0.16)
	await _wait(1.4)


func _ev_take_chien(ev: Dictionary) -> void:
	var tk: int = ev.taker
	var cards: Array = ev.cards
	if slot(tk) == 0 and (mode != "sofa" or me == tk):
		for i in chien_nodes.size():
			var cn: CardNode = chien_nodes[i]
			nodes[cards[i]] = cn
			hand.append(cards[i])
		hand = Deck.sorted(hand)
		Sfx.play("swish")
		for cn in chien_nodes:
			cn.target_scale = 1.0
	else:
		for cn in chien_nodes:
			cn.flip(false, 0.14)
		await _wait(0.12)
		for cn in chien_nodes:
			backs[tk].append(cn)
		Sfx.play("swish")
	chien_nodes.clear()
	await _wait(0.6)


func _ev_chien_away(to: int) -> void:
	hud.banner("EL PERRO VA PARA %s" % (players[to].name if to >= 0 else "LA DEFENSA"), Pix.CREAM)
	await _wait(0.5)
	var dest_p := to if to >= 0 else (taker + 1) % n
	for cn in chien_nodes:
		_to_pile(cn, dest_p)
		await _wait(0.06)
	chien_nodes.clear()
	await _wait(0.4)


func _ev_discarded(ev: Dictionary) -> void:
	var tk: int = ev.p
	var cards: Array = ev.cards
	view_phase = "wait"
	turn_seat = -1
	for i in cards.size():
		var cn: CardNode
		if slot(tk) == 0 and cards[i] >= 0 and nodes.has(cards[i]):
			cn = nodes[cards[i]]
			hand.erase(cards[i])
			nodes.erase(cards[i])
			cn.flip(false, 0.12)
		elif not backs[tk].is_empty():
			cn = backs[tk].pop_back()
		if cn:
			_to_pile(cn, tk)
		Sfx.play("swish", -8.0, 1.2)
		await _wait(0.08)
	picked = []
	await _wait(0.4)


func _to_pile(cn: CardNode, p: int) -> void:
	var s := slot(p)
	var k: int = pile_nodes[p].size()
	pile_nodes[p].append(cn)
	cn.z_index = 10 + k
	var dest: Vector2 = PILE_SPOT[s] + Vector2(0, -minf(k, 30) * 0.35)
	if cn.face_up:
		cn.flip(false, 0.12)
	cn.fly_to(dest, randf_range(-0.08, 0.08) + (PI / 2.0 if s % 2 == 1 else 0.0), 0.42, 0.32, 24.0, 0.0)


func _ev_play(ev: Dictionary) -> void:
	var p: int = ev.p
	var c: int = ev.c
	var s := slot(p)
	var cn: CardNode
	view_phase = "wait"
	turn_seat = -1
	if s == 0 and nodes.has(c) and c in hand:
		cn = nodes[c]
		hand.erase(c)
		cursor = clampi(cursor, 0, maxi(0, hand.size() - 1))
	else:
		var list: Array = backs[p]
		cn = list.pop_at(randi() % list.size()) if not list.is_empty() else _new_card(-1, false, _deck_pos(p))
		cn.card = c
	nodes[c] = cn
	cn.z_index = 400 + trick_nodes.size()
	trick_nodes.append([p, cn])
	var dest: Vector2 = TRICK_SPOT[s]
	var rot := 0.0
	var trump := Deck.is_trump(c)
	var cut: bool = trump and ev.led >= 0 and ev.led != Deck.TRUMP
	var over: bool = trump and ev.high > 0 and c > ev.high
	Sfx.play("swish", -4.0, 1.1)
	if not cn.face_up:
		cn.flip(true, 0.2)
	var spins := 1.0 if c == Deck.EXCUSE or s != 0 else 0.0
	if randf() < 0.5 and s != 0:
		spins = -spins
	var showed: bool = arcana_anim and (trump or c == Deck.EXCUSE)
	if showed:
		# Arcano Mayor: su cinemática propia en el centro y luego baja a la baza
		await show.run(cn, c, dest, rot)
	else:
		# Golpe: llega grande, aplasta la mesa y se encoge con rebote hasta su sitio
		await cn.fly_to(dest, rot, 1.35, 0.26 if not trump else 0.21, 36.0 if s != 2 else -36.0, spins)
		cn.target_scale = 1.0
		cn.squash = Vector2(1.25, 0.78)
	Sfx.play("land", 0.0, 1.0)
	Sfx.play("hit", -14.0, 1.5)
	var sc := TableFx.suit_color(Deck.suit(c)) if c != Deck.EXCUSE else Color.WHITE
	fx.ring(dest, 20, 64, 0.32, Color(sc, 0.9), 2)
	for k in 10:
		var a := k * TAU / 10.0 + randf() * 0.3
		fx.streak(dest + Vector2.from_angle(a) * 40.0, dest + Vector2.from_angle(a) * randf_range(52, 70), 0.14, Color(sc.lightened(0.3), 0.8), 1)
	fx.puff(dest + Vector2(0, 30), Vector2.ZERO, 3, 16, 0.35, Color(1, 1, 1, 0.2))
	shake = maxf(shake, 1.5)
	cn.shine()
	if showed and not (cut or over):
		pass
	elif c == 21:
		_fx_21(dest)
	elif c == 1:
		Sfx.play("ding", 0.0, 1.4)
		fx.ring(dest, 4, 46, 0.45, Color("ffd0ff"), 2)
		fx.burst(dest, 26, Color("ffb0ff"), 40, 160, 0.6, 60, 1, Vector2.ZERO, PI, 2.0, [Color("ffb0ff"), Color.WHITE, Pix.GOLD])
		hud.comic(dest + Vector2(0, -60), "¡EL PEQUEÑO!", Color("ffb0ff"), 1.6, true)
	elif c == Deck.EXCUSE:
		Sfx.play("bounce", 0.0, 1.3)
		Sfx.play("bounce", -4.0, 1.7)
		cn.squash = Vector2(0.7, 1.3)
		fx.burst(dest, 30, Color.WHITE, 60, 180, 0.7, 120, 1, Vector2.UP, 1.2, 2.0, [Color("ff6b7a"), Color("ffd447"), Color("7ab8ff"), Color("5ff0b0")])
		hud.comic(dest + Vector2(0, -60), "¡EXCUSA!", Pix.GOLD, 1.6, true)
	elif cut or over:
		Sfx.play("hit", -2.0, 1.0 + (0.2 if over else 0.0))
		var dir := (dest - Vector2(320, 166)).normalized()
		fx.impact(dest, -dir if dir.length() > 0.1 else Vector2.UP, Color("b06aff"), 500.0 if over else 300.0)
		for k in 2:
			fx.slash(dest, 30 + k * 6, -2.6 + k * 0.5, -0.4 + k * 0.5, 0.22, Color("d8b0ff"), 3)
		hud.comic(dest + Vector2(0, -62), "¡MONTA!" if over else "¡FALLO!", Color("d8b0ff"), 2.0 if over else 1.7, true)
		shake = 3.0 if over else 2.0
	elif trump:
		Sfx.play("hit", -8.0, 1.3)
		fx.burst(dest, 14, Color("b06aff"), 40, 120, 0.4, 40, 1)
	elif Deck.value(c) == 14:
		Sfx.play("ding", -4.0, 0.9)
		for k in 6:
			fx.star(dest + Vector2(randf_range(-28, 28), randf_range(-40, 40)), Pix.GOLD, 0.5, 3)
	await _wait(0.15)


func _fx_21(at: Vector2) -> void:
	Sfx.play("boom")
	Sfx.play("reveal", -2.0, 1.1)
	shake = 9.0
	hud.flash(0.35)
	for k in 3:
		fx.ring(at, 6 + k * 4, 120 + k * 30, 0.5 + k * 0.12, [Pix.GOLD, Color.WHITE, Color("b06aff")][k], 3 - k)
	fx.sparks(at, 40, Vector2.UP, PI, 120, 380, 0.7, [Pix.GOLD, Color.WHITE, Color("ffe8a0")])
	fx.burst(at, 30, Pix.GOLD, 50, 200, 1.0, 80, 2)
	hud.comic(at + Vector2(0, -60), "¡EL MUNDO!", Pix.GOLD, 2.6, true)


func _ev_trick(ev: Dictionary) -> void:
	var w: int = ev.w
	await _wait(0.45)
	var win_cn: CardNode = null
	var cards: Array = trick_nodes.map(func(e): return e[1].card)
	var wi := Rules.trick_winner_idx(cards)
	if wi >= 0:
		win_cn = trick_nodes[wi][1]
		var wc: int = cards[wi]
		var first := -1
		for c0 in cards:
			if c0 != Deck.EXCUSE:
				first = c0
				break
		if Deck.is_trump(wc) and first >= 0 and not Deck.is_trump(first):
			last_win_reason = "GANA EL TRIUNFO %d: UN TRIUNFO GANA A LOS PALOS." % wc
		elif Deck.is_trump(wc):
			last_win_reason = "GANA EL %d: ES EL TRIUNFO MAS ALTO." % wc
		else:
			last_win_reason = "GANA %s: LA MAS ALTA DEL PALO QUE MANDA." % Deck.name(wc)
	if win_cn:
		win_cn.glow_col = Pix.GOLD
		win_cn.glow = 1.0
		win_cn.squash = Vector2(1.15, 1.15)
		win_cn.z_index = 500
		fx.ring(win_cn.position, 10, 60, 0.4, Pix.GOLD, 2)
		Sfx.play("ding", -6.0, 1.2)
	tricks_won[w] += 1
	await _wait(0.55)
	# Se juntan en el centro y salen volando al montón del ganador
	var mid := Vector2(320, 166)
	for e in trick_nodes:
		var cn: CardNode = e[1]
		cn.target_pos = mid + (cn.position - mid) * 0.25
		cn.target_rot = 0.0
	await _wait(0.18)
	var to := slot(w)
	Sfx.play("dash", -6.0)
	for e in trick_nodes:
		var cn: CardNode = e[1]
		cn.glow = 0.0
		var owner: int = e[0]
		if cn.card == Deck.EXCUSE and not ev.last:
			_to_pile(cn, owner)
		else:
			_to_pile(cn, w)
		fx.streak(cn.position, PILE_SPOT[to], 0.18, Color(1, 1, 1, 0.5), 1)
		nodes.erase(cn.card)
	var half := 0
	for c in cards:
		half += Deck.half_points(c)
	if w == taker:
		taker_half += half
		taker_oudlers += cards.filter(func(c): return Deck.is_oudler(c) and c != Deck.EXCUSE).size()
	var tp := _plate_center(w) + Vector2(0, -26 if to != 2 else 30)
	hud.comic(tp, "+%s" % hud._num(half / 2.0), Pix.GOLD if w == taker else Color("7ab8ff"), 1.4, false)
	trick_nodes.clear()
	var left := hand.size()
	for q in n:
		if slot(q) != 0:
			left = maxi(left, backs[q].size())
	if left == 1 and not ev.last:
		hud.comic(Vector2(320, 166), "¡ULTIMA BAZA!", Color("ff8a3a"), 2.4, true)
		Sfx.play("warn", -2.0)
		Sfx.play("charge", -8.0, 1.4)
	if ev.last and ev.petit >= 0:
		hud.banner("¡EL PEQUEÑO AL FINAL!", Color("ffb0ff"))
		Sfx.play("win")
		fx.converge(PILE_SPOT[to], 40, 100, 0.5, [Color("ffb0ff"), Color.WHITE], 40.0)
	await _wait(0.4)


func _ev_score(ev: Dictionary) -> void:
	last_score = ev
	scores = ev.totals
	view_phase = "score"
	waiting_ok = []
	for i in players.size():
		if players[i].kind in ["human", "remote"]:
			waiting_ok.append(i)
	var s: Dictionary = ev.s
	hud.show_score(ev)
	if (s.taker == me) == s.won or (s.taker != me and not s.won):
		Sfx.play("win")
		hud.confetti(80)
	else:
		Sfx.play("ko", -4.0)
		shake = 5.0
	await _wait(0.8)


func _collect_all() -> void:
	var all: Array = []
	for c in nodes:
		all.append(nodes[c])
	for q in n:
		all.append_array(backs[q])
	all.append_array(chien_nodes)
	# Fuera de la mano y de los dorsos, para que el abanico no las devuelva a su sitio
	hand.clear()
	backs = [[], [], [], []]
	chien_nodes.clear()
	view_phase = ""
	turn_seat = -1
	var dp := _deck_pos(dealer)
	for i in all.size():
		var cn: CardNode = all[i]
		if not is_instance_valid(cn):
			continue
		if cn.face_up:
			cn.flip(false, 0.1)
		cn.target_pos = dp + Vector2(0, -i * 0.2)
		cn.target_rot = 0.0
		cn.target_scale = 0.55
		cn.z_index = 200 + i
	Sfx.play("shuffle", -4.0)
	await _wait(1.0)
	_clear_table()


# --- Entrada en la mesa ---

func _my_pads() -> Array:
	if mode == "sofa":
		var p: Dictionary = players[me] if me >= 0 and me < players.size() else {}
		return pads.filter(func(x): return x.dev == p.get("dev", ""))
	return pads


func _table_input() -> void:
	if hud.tut_open:
		if auto_play:
			auto_wait += get_process_delta_time()
			if auto_wait > 0.7:
				auto_wait = 0.0
				hud.tut_next()
		elif _any("ok"):
			hud.tut_next()
		return
	if hud.score_open:
		for i in players.size():
			if not (i in waiting_ok):
				continue
			if _is_local_human(i):
				var ps: Array = pads if mode != "sofa" else pads.filter(func(x): return x.dev == players[i].dev)
				for p in ps:
					if p.pressed("ok"):
						Sfx.play("select")
						waiting_ok.erase(i)
						_act(i, "ok", 0)
		if auto_play and hud.score_t > 2.5 and me in waiting_ok:
			waiting_ok.erase(me)
			_act(me, "ok", 0)
		return
	if curtain >= 0:
		if auto_play:
			auto_wait += get_process_delta_time()
			if auto_wait > 1.5:
				auto_wait = 0.0
				curtain = -1
			return
		for p in pads:
			if p.dev == players[curtain].dev and p.pressed("ok"):
				Sfx.play("select")
				curtain = -1
		return
	if turn_seat != me or not _is_local_human(me):
		return
	if auto_play:
		auto_wait += get_process_delta_time()
		if auto_wait > 1.4:
			auto_wait = 0.0
			_auto_act()
		elif view_phase in ["play", "discard"] and not hand.is_empty() and int(auto_wait * 5.0) != int((auto_wait - get_process_delta_time()) * 5.0):
			cursor = (cursor + 1) % hand.size()
			if view_phase == "discard" and hand[cursor] in legal and picked.size() < 6 and randf() < 0.5:
				picked.append(hand[cursor])
		return
	var ps := _my_pads()
	var any := func(k): return ps.any(func(x): return x.pressed(k))
	match view_phase:
		"bid":
			var opts := _bid_options()
			if any.call("up"):
				bid_sel = (bid_sel + opts.size() - 1) % opts.size()
				Sfx.play("tick")
			if any.call("down"):
				bid_sel = (bid_sel + 1) % opts.size()
				Sfx.play("tick")
			if any.call("ok"):
				if tutorial and opts[bid_sel] == 0:
					Sfx.play("warn", -6.0)
					hud.comic(Vector2(320, 90), "¡ESTA VEZ APUESTA!", Pix.GOLD, 1.6, true)
					return
				view_phase = "wait"
				_act(me, "bid", opts[bid_sel])
		"play", "discard":
			if hand.is_empty():
				return
			if any.call("left"):
				cursor = (cursor + hand.size() - 1) % hand.size()
				Sfx.play("tick", -8.0, 1.2)
			if any.call("right"):
				cursor = (cursor + 1) % hand.size()
				Sfx.play("tick", -8.0, 1.2)
			cursor = clampi(cursor, 0, hand.size() - 1)
			var c: int = hand[cursor]
			if view_phase == "play" and any.call("ok"):
				if c in legal:
					view_phase = "wait"
					_act(me, "play", c)
				else:
					Sfx.play("warn", -6.0)
					nodes[c].squash = Vector2(0.9, 1.1)
					hud.pop_text(nodes[c].position + Vector2(0, -70), _why_not(c), Color("ff8a9a"))
			elif view_phase == "discard":
				if any.call("ok"):
					if c in picked:
						picked.erase(c)
						Sfx.play("tick")
					elif c in legal and picked.size() < 6:
						picked.append(c)
						Sfx.play("select")
					else:
						Sfx.play("warn", -6.0)
						hud.pop_text(nodes[c].position + Vector2(0, -70), "NO SE PUEDE APARTAR", Color("ff8a9a"))
				if (any.call("start") or any.call("alt")) and picked.size() == 6:
					view_phase = "wait"
					_act(me, "discard", picked.duplicate())


func _auto_act() -> void:
	match view_phase:
		"bid":
			view_phase = "wait"
			var b := force_bid if force_bid >= 0 and force_bid in _bid_options() else 0
			force_bid = -1
			_act(me, "bid", b)
		"play":
			if not legal.is_empty():
				view_phase = "wait"
				_act(me, "play", legal[randi() % legal.size()])
		"discard":
			for c in legal:
				if picked.size() < 6 and not (c in picked):
					picked.append(c)
			if picked.size() == 6:
				view_phase = "wait"
				_act(me, "discard", picked.duplicate())


func _bid_options() -> Array:
	if tutorial:
		return [1]
	var best := 0
	for b in bids:
		best = maxi(best, b)
	var out := [0]
	for b in range(1, 5):
		if b > best:
			out.append(b)
	return out


func _why_not(c: int) -> String:
	var led := -1
	for e in trick_nodes:
		if e[1].card != Deck.EXCUSE:
			led = Deck.suit(e[1].card)
			break
	if led >= 0 and led < 4 and Deck.suit(c) != led:
		return "HAY QUE SERVIR %s" % Minors.SUITS[led].name
	if Deck.is_trump(c) or led == Deck.TRUMP:
		return "HAY QUE MONTAR"
	return "HAY QUE FALLAR CON TRIUNFO"


# --- Capturas automáticas para revisar ---

func _shot(nm: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(capture_dir.path_join(nm + ".png"))


func _capture_run(args: Array) -> void:
	Sfx.muted = true
	await _wait(0.3)
	if "--casino" in args:
		await _capture_casino(args)
		return
	if "--host" in args or "--unirse" in args:
		await _capture_net(args)
		return
	if "--intro" in args:
		await _capture_front()
		return
	await _shot("menu")
	var ji := args.find("--jugadores")
	if ji >= 0 and ji + 1 < args.size():
		cfg.n = int(args[ji + 1])
		n = cfg.n
	var ki := args.find("--contrato")
	if ki >= 0 and ki + 1 < args.size():
		test_contract = int(args[ki + 1])
	if "--arcanos" in args:
		phase = "cine"
		Sfx.muted = false
		var ai_ := args.find("--arcanos")
		var only: Array = []
		if ai_ + 1 < args.size() and not args[ai_ + 1].begins_with("--"):
			only = Array(args[ai_ + 1].split(",")).map(func(x): return int(x))
		for c in range(22):
			if not only.is_empty() and not (c in only):
				continue
			var cn := _new_card(c, false, Vector2(320, 420))
			cn.z_index = 400
			var done := [false]
			var run := func():
				await show.run(cn, c, Vector2(320, 212), 0.05)
				done[0] = true
			run.call()
			await _wait(1.05)
			await _shot("cine_%02d" % c)
			while not done[0]:
				await get_tree().process_frame
			cn.queue_free()
			fx.clear()
		get_tree().quit()
		return
	if "--guia" in args:
		_menu_pick("guide")
		for pg in TarotGuide.PAGES:
			guide_page = pg
			guide_t = 0.0
			await _wait(3.6)
			await _shot("guia_%d" % pg)
		get_tree().quit()
		return
	Engine.time_scale = 2.0
	_menu_pick("solo")
	if "--sofa" in args:
		_go_menu()
		mode = "sofa"
		players = [{"name": "ANA", "kind": "human", "peer": 1, "dev": "kb", "pi": 0}, {"name": "LUIS", "kind": "human", "peer": 1, "dev": "joy9", "pi": 1}]
		_fill_ai()
		auto_play = true
		_start_match()
		var t0 := Time.get_ticks_msec()
		var got := 0
		while Time.get_ticks_msec() - t0 < 120000 and got < 2:
			await get_tree().process_frame
			if curtain >= 0 and auto_wait > 0.7:
				got += 1
				await _shot("sofa_telon_%d" % got)
				while curtain >= 0:
					await get_tree().process_frame
				await _wait(0.8)
				await _shot("sofa_vista_%d" % got)
		get_tree().quit()
		return
	if "--tuto" in args:
		_go_menu()
		_menu_pick("tuto")
		auto_play = true
		force_bid = 1
		var t0 := Time.get_ticks_msec()
		var shots := 0
		var last_key := 0
		var mouse_done := false
		while Time.get_ticks_msec() - t0 < 600000:
			await get_tree().process_frame
			if hud.tut_open and tut_seen.size() != last_key and hud.tut_t > 0.5:
				last_key = tut_seen.size()
				shots += 1
				await _shot("tuto_%02d" % shots)
			# Prueba del ratón: en mi primer turno de juego, pasar por encima de una carta legal y hacer clic
			if not mouse_done and view_phase == "play" and turn_seat == me and not hud.tut_open and not legal.is_empty():
				mouse_done = true
				auto_play = false
				var c: int = legal[0]
				var before := hand.size()
				await _wait(0.6)
				get_viewport().warp_mouse(nodes[c].position + Vector2(0, -30))
				await _wait(0.4)
				await _shot("raton_encima")
				var ev := InputEventMouseButton.new()
				ev.button_index = MOUSE_BUTTON_LEFT
				ev.pressed = true
				ev.position = nodes[c].position + Vector2(0, -30)
				Input.parse_input_event(ev)
				await _wait(0.1)
				var up := ev.duplicate()
				up.pressed = false
				Input.parse_input_event(up)
				await _wait(1.5)
				print("RATON: carta %s · mano %d -> %d" % [Deck.name(c), before, hand.size()])
				auto_play = true
			if phase == "over" or (hud.score_open and tut_seen.has("puntos")):
				await _wait(1.0)
				await _shot("tuto_fin")
				break
		get_tree().quit()
		return
	if "--humano" in args:
		auto_play = true
		force_bid = 2
		await _capture_human()
		return
	# Mi asiento lo juega también la IA para avanzar solo
	players[0].kind = "ai"
	players[0].name = "PRUEBA"
	me = 0
	var shots := {"deal": false, "bid": false, "chien": false, "play": false, "trick": false, "score": false}
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 170000:
		await get_tree().process_frame
		if hud.comics.size() > 0 and hud.comics[-1].t > 0.12 and hud.comics[-1].t < 0.2 and shots.get("comics", 0) < 4:
			shots["comics"] = shots.get("comics", 0) + 1
			await _shot("comic_%d" % shots.comics)
		if not shots.has("pasan") and hud.banner_t > 0.4 and hud.banner_text.begins_with("TODOS PASAN"):
			shots["pasan"] = true
			await _shot("todos_pasan")
		if not shots.deal and hand.size() > 8:
			shots.deal = true
			await _shot("reparto")
		if not shots.bid and bids.any(func(b): return b > 0):
			shots.bid = true
			await _shot("subasta")
		if not shots.chien and chien_nodes.size() == 6 and chien_nodes[0].face_up:
			shots.chien = true
			await _wait(0.3)
			await _shot("perro")
		if not shots.play and trick_nodes.size() == 3:
			shots.play = true
			await _wait(0.2)
			await _shot("baza")
		if not shots.trick and trick_nodes.size() == n and trick_nodes.any(func(e): return e[1].glow > 0.5):
			shots.trick = true
			await _shot("baza_ganada")
		if not shots.score and hud.score_open:
			shots.score = true
			await _wait(1.6)
			await _shot("puntos")
			if "--una-mano" in args:
				while phase != "over":
					await get_tree().process_frame
				await _wait(1.0)
				await _shot("final")
			break
	get_tree().quit()


func _capture_front() -> void:
	Sfx.muted = false
	phase = "intro"
	intro_t = 0.0
	for at in [0.5, 1.1, 1.55, 1.8, 1.95, 2.35, 2.7, 3.2]:
		while intro_t < at:
			await get_tree().process_frame
		await _shot("intro_%d" % int(at * 100))
	while phase == "intro":
		await get_tree().process_frame
	await _wait(1.2)
	await _shot("portada")
	menu_sel = 3
	await _wait(0.3)
	await _shot("portada_discord")
	menu_sel = 0
	_menu_pick("play")
	await _wait(0.12)
	await _shot("jugar_corte")
	await _wait(1.0)
	await _shot("jugar")
	menu_sel = 2
	await _wait(0.8)
	await _shot("jugar_sala")
	_set_page("look")
	await _wait(1.0)
	await _shot("personaje")
	cfg.look = {"color": 4, "c2": 2, "hat": 3, "skin": 2, "eyes": 2, "extra": 2}
	menu_sel = 2
	_build_menu()
	await _wait(0.6)
	await _shot("personaje_mago")
	for hk in Pix.HATS.size():
		cfg.look = {"color": hk, "c2": hk % 6, "hat": hk, "skin": hk % 6, "eyes": hk % 5, "extra": hk % 5}
		_build_menu()
		await _wait(0.35)
		await _shot("personaje_%d" % hk)
	_set_page("settings")
	await _wait(1.0)
	await _shot("ajustes")
	_set_page("title")
	if "--lan" in OS.get_cmdline_user_args():
		_menu_pick("play")
		_menu_pick("host")
		await _wait(0.8)
		lobby_sel = 1
		_lobby_pick("vueltas", 1)
		await _wait(0.4)
		await _shot("sala")
		lobby_sel = 0
		_lobby_pick("juego", 1)
		await _wait(0.4)
		await _shot("sala_blackjack")
	get_tree().quit()


func _capture_casino(args: Array) -> void:
	Sfx.muted = false
	if "--host" in args or "--unirse" in args:
		await _capture_casino_net(args)
		return
	_set_page("play")
	menu_sel = 6
	await _wait(0.8)
	await _shot("jugar_otros")
	_set_page("games")
	menu_sel = 2
	await _wait(1.0)
	await _shot("otros_juegos")
	for k in ["bj", "7m"]:
		_menu_pick(k)
		await _wait(0.6)
		await _shot("%s_apuesta" % k)
		auto_play = true
		for hand_i in 3:
			while casino.state != "player" and casino.state != "result":
				await get_tree().process_frame
			if hand_i == 0 and casino.state == "player":
				await _wait(0.1)
				await _shot("%s_turno" % k)
			while casino.state != "result":
				await get_tree().process_frame
			await _wait(0.7)
			await _shot("%s_resultado_%d" % [k, hand_i])
			casino._next_hand()
		auto_play = false
		_leave_casino()
	print("CASINO solo ok · fichas %d" % int(cfg.fichas))
	get_tree().quit()


## Dos pantallas por LAN: la primera abre la partida rápida de blackjack y la segunda se une.
func _capture_casino_net(args: Array) -> void:
	var tag := "host" if "--host" in args else "cliente"
	var k := "7mq" if "--7m" in args else "bjq"
	if tag == "cliente":
		await _wait(1.5)
	_menu_pick(k)
	var t0 := Time.get_ticks_msec()
	while phase != "lobby" and Time.get_ticks_msec() - t0 < 20000:
		await get_tree().process_frame
	while players.size() < 2 and Time.get_ticks_msec() - t0 < 20000:
		await get_tree().process_frame
	await _wait(1.0)
	await _shot("casino_red_sala_%s" % tag)
	while phase != "casino" and Time.get_ticks_msec() - t0 < 40000:
		await get_tree().process_frame
	await _wait(0.8)
	await _shot("casino_red_apuesta_%s" % tag)
	auto_play = true
	var got := {}
	var hands_done := 0
	while Time.get_ticks_msec() - t0 < 120000 and casino:
		await get_tree().process_frame
		if not got.has("espera") and casino.state == "ready":
			got["espera"] = true
			await _shot("casino_red_espera_%s" % tag)
		if not got.has("turno") and casino.state == "player":
			got["turno"] = true
			auto_play = false
			await _wait(0.3)
			await _shot("casino_red_turno_%s" % tag)
			auto_play = true
		if not got.has("otro") and casino.state == "wait" and casino.turn >= 0:
			got["otro"] = true
			await _shot("casino_red_otro_%s" % tag)
		if casino.state == "result":
			auto_play = false
			await _wait(1.2)
			await _shot("casino_red_resultado_%d_%s" % [hands_done, tag])
			print("CASINO RED %s mano %d: %s" % [tag, hands_done, str(casino.seats.map(func(sd): return [sd.name, sd.chips, sd.res, sd.delta]))])
			hands_done += 1
			if hands_done >= 2:
				break
			casino._next_hand()
			auto_play = true
	await _wait(1.5)
	Net.close()
	get_tree().quit()


func _capture_human() -> void:
	var got := {}
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 150000:
		await get_tree().process_frame
		if turn_seat == me and auto_wait > 0.8:
			var k: String = view_phase
			if k in ["bid", "discard", "play"] and not got.has(k):
				got[k] = true
				await _shot("humano_" + k)
		if got.has("play") and trick_nodes.size() == 0 and tricks_won.any(func(x): return x >= 2):
			break
	get_tree().quit()


func _capture_net(args: Array) -> void:
	auto_play = true
	Engine.time_scale = 2.0
	if "--host" in args:
		_menu_pick("quick" if "--rapida" in args else "host")
		var t0 := Time.get_ticks_msec()
		while players.size() < 2 and Time.get_ticks_msec() - t0 < 20000:
			await get_tree().process_frame
		await _wait(0.5)
		await _shot("red_sala_host")
		_fill_ai()
		_sync_players()
		_start_match()
	else:
		await _wait(1.5)
		_menu_pick("quick" if "--rapida" in args else "join")
		await _wait(1.5)
		await _shot("red_sala_cliente")
	var got := {}
	var t1 := Time.get_ticks_msec()
	var tag := "host" if "--host" in args else "cliente"
	while Time.get_ticks_msec() - t1 < 240000:
		await get_tree().process_frame
		if not got.has("mano") and hand.size() >= 18 and view_phase == "bid":
			got["mano"] = true
			await _shot("red_%s_mano" % tag)
		if not got.has("baza") and trick_nodes.size() == 2:
			got["baza"] = true
			await _wait(0.2)
			await _shot("red_%s_baza" % tag)
			if "--irse" in args and tag == "cliente":
				print("RED cliente: me voy a mitad de la mano")
				Net.close()
				get_tree().quit()
				return
		if hud.score_open:
			await _wait(1.6)
			await _shot("red_%s_puntos" % tag)
			print("RED %s: mano %d cartas en baza ok · marcador %s" % [tag, hand.size(), str(scores)])
			break
	await _wait(1.0)
	get_tree().quit()
