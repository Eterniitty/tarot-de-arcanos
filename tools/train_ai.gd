extends SceneTree
## Entrena la IA jugando contra sí misma y escribe lo aprendido en scripts/ai_params.gd.
##  1) Subasta: miles de repartos; cada asiento toma con cada tipo de contrato y se juega la mano entera.
##     Una regresión (ridge) aprende el margen esperado según los rasgos de la mano.
##  2) Juego y umbrales: descenso por coordenadas. Cada cambio se enfrenta a la mejor versión con repartos
##     duplicados (las mismas cartas jugadas dos veces cambiando de asiento) y solo se queda si gana claro.
##  3) Validación con repartos nuevos contra la IA de antes del entrenamiento.
## godot --headless --path . -s res://tools/train_ai.gd -- <repartos_subasta> <repartos_duelo> <vueltas>

const SPACE := {
	"t1": [-20.0, -14.0, -10.0, -6.0, -3.0, 0.0, 3.0, 6.0, 10.0],
	"t2": [0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 40.0],
	"t3": [10.0, 20.0, 30.0, 40.0, 50.0, 65.0],
	"t4": [15.0, 25.0, 35.0, 45.0, 60.0, 80.0],
	"lead_trumps": [3, 4, 5, 6, 7, 8, 30],
	"lead_trump_min": [6, 10, 12, 15, 18],
	"partner_strong": [8, 11, 13, 15, 17, 19, 22],
	"excuse_pts": [2, 4, 5, 7, 99],
	"taker_long": [0, 1],
	"def_long": [0, 1],
	"king_lead": [0, 1],
}

const LIVELY := {"t1": -10.0, "t2": 6.0, "t3": 20.0, "t4": 30.0}

var t_start := 0


func _initialize() -> void:
	t_start = Time.get_ticks_msec()
	var argv := OS.get_cmdline_user_args()
	var n_reg := int(argv[0]) if argv.size() > 0 else 3000
	var n_duel := int(argv[1]) if argv.size() > 1 else 1200
	var rounds := int(argv[2]) if argv.size() > 2 else 2
	var baseline: Dictionary = TarotAIParams.PLAY.duplicate()
	var best := baseline.duplicate()
	var w: Array = []
	_log("Ajuste por coordenadas: %d vueltas, %d repartos x2 por prueba" % [rounds, n_duel])
	for rd in rounds:
		# --- 1) Subasta, aprendida con la forma de jugar actual ---
		w = _train_bids(n_reg, best)
		TarotAI.bid_w = w
		# --- 2) Juego y umbrales ---
		var improved := false
		for key in SPACE:
			for v in SPACE[key]:
				if v == best[key]:
					continue
				var cand := best.duplicate()
				cand[key] = v
				var gain := duel(cand, best, n_duel, 1000 + rd * 77)
				if gain > 1.2:
					_log("  vuelta %d · %s: %s -> %s  (+%.1f por mano)" % [rd + 1, key, str(best[key]), str(v), gain])
					best = cand
					improved = true
		if not improved:
			break
	# --- 3) Validación con repartos nuevos ---
	var val := 4000
	var g_play := duel(best, baseline, val, 999331)
	# Contra la IA de antes del todo: subasta antigua (por valoración) y juego antiguo
	var gain_all := duel_vs_old(best, baseline, val, 424242)
	_log("VALIDACION (%d repartos x2 nuevos): nuevo juego %+.1f por mano · nuevo todo vs IA antigua %+.1f por mano" % [val, g_play, gain_all])
	# Subasta animada: el óptimo puro pasa en 2 de cada 3 repartos; estos umbrales cuestan ~0,6 puntos
	# por mano y dejan un 33 % de repartos en blanco con Pequeñas, Guardias y alguna Guardia sin.
	for k in LIVELY:
		best[k] = LIVELY[k]
	_write(w, best, "entrenado %s · %d repartos de subasta x12 manos · ajuste %d repartos x2 · validacion vs IA antigua %+.1f puntos por mano" % [
		Time.get_date_string_from_system(), n_reg, n_duel, gain_all])
	_log("Escrito scripts/ai_params.gd")
	quit()


func _log(s: String) -> void:
	print("[%4ds] %s" % [(Time.get_ticks_msec() - t_start) / 1000, s])


# --- Subasta: datos y regresión ---

func _train_bids(n_deals: int, prm: Dictionary) -> Array:
	var ai := TarotAI.new(5)
	ai.prm = prm
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var X := [[], [], []]
	var Y := [[], [], []]
	var made := 0
	var dealer := 0
	while made < n_deals:
		var r := Rules.new()
		r.deal(4, dealer, rng)
		dealer = (dealer + 1) % 4
		if r.phase != "bid":
			continue
		made += 1
		for t in 4:
			var f := TarotAI.bid_features(r.hands[t])
			for ct in 3:
				var k: int = [1, 3, 4][ct]
				var g := r.copy()
				while g.phase == "bid":
					g.bid(g.turn, k if g.turn == t else 0)
				if g.phase == "discard":
					g.discard(ai.choose_discard(g))
				while g.phase == "play":
					g.play(g.turn, ai.quick(g, g.turn))
				X[ct].append(f)
				Y[ct].append(TarotAI.outcome(g))
		if made % 1000 == 0:
			_log("subasta: %d repartos jugados" % made)
	var out: Array = []
	var names := ["con perro", "sin perro", "contra el perro"]
	for ct in 3:
		var cut := int(X[ct].size() * 0.8)
		var wv := _ridge(X[ct].slice(0, cut), Y[ct].slice(0, cut), 1.0)
		# Calidad con el 20 % que no vio
		var ss := 0.0
		var st := 0.0
		var hits := 0
		var mean := 0.0
		for i in range(cut, X[ct].size()):
			mean += Y[ct][i]
		mean /= maxf(1.0, X[ct].size() - cut)
		for i in range(cut, X[ct].size()):
			var pr := _dot(wv, X[ct][i])
			ss += pow(Y[ct][i] - pr, 2)
			st += pow(Y[ct][i] - mean, 2)
			if (pr >= 0.0) == (Y[ct][i] >= 0.0):
				hits += 1
		_log("modelo %s: R2 %.2f · acierta si gana o pierde el %.0f%% (manos no vistas)" % [names[ct], 1.0 - ss / st, 100.0 * hits / (X[ct].size() - cut)])
		out.append(wv)
	return out


func _dot(w: Array, f: Array) -> float:
	var v := 0.0
	for i in w.size():
		v += w[i] * f[i]
	return v


## Regresión ridge: (XᵀX + λI) w = Xᵀy, resuelta por eliminación de Gauss.
func _ridge(X: Array, Y: Array, lam: float) -> Array:
	var d: int = X[0].size()
	var A: Array = []
	var b: Array = []
	for i in d:
		var row: Array = []
		row.resize(d)
		row.fill(0.0)
		A.append(row)
		b.append(0.0)
	for k in X.size():
		var f: Array = X[k]
		for i in d:
			b[i] += f[i] * Y[k]
			for j in d:
				A[i][j] += f[i] * f[j]
	for i in range(1, d):
		A[i][i] += lam
	for col in d:
		var piv := col
		for r in range(col + 1, d):
			if absf(A[r][col]) > absf(A[piv][col]):
				piv = r
		var tmp = A[col]
		A[col] = A[piv]
		A[piv] = tmp
		var tb = b[col]
		b[col] = b[piv]
		b[piv] = tb
		for r in range(col + 1, d):
			var m: float = A[r][col] / A[col][col]
			for c in range(col, d):
				A[r][c] -= m * A[col][c]
			b[r] -= m * b[col]
	var w: Array = []
	w.resize(d)
	w.fill(0.0)
	for i in range(d - 1, -1, -1):
		var s: float = b[i]
		for j in range(i + 1, d):
			s -= A[i][j] * w[j]
		w[i] = s / A[i][i]
	return w


# --- Duelos ---

## Puntos medios por mano y asiento de `a` frente a `b`, con repartos duplicados (cada uno se juega dos
## veces: `a` en los asientos 0 y 2, luego en 1 y 3).
func duel(a: Dictionary, b: Dictionary, n_deals: int, seed_v: int) -> float:
	var A := TarotAI.new(11)
	A.set_level(1)
	A.blunder = 0.0
	A.prm = a
	var B := TarotAI.new(13)
	B.set_level(1)
	B.blunder = 0.0
	B.prm = b
	return _match(A, B, n_deals, seed_v)


## El entrenado contra la IA de antes (subasta por valoración sin ruido y juego por defecto).
func duel_vs_old(a: Dictionary, base: Dictionary, n_deals: int, seed_v: int) -> float:
	var A := TarotAI.new(11)
	A.set_level(1)
	A.blunder = 0.0
	A.prm = a
	var B := OldAI.new(13)
	B.prm = base
	return _match(A, B, n_deals, seed_v)


func _match(A: TarotAI, B: TarotAI, n_deals: int, seed_v: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var total := 0.0
	var made := 0
	var dealer := 0
	while made < n_deals:
		var r := Rules.new()
		r.deal(4, dealer, rng)
		dealer = (dealer + 1) % 4
		if r.phase != "bid":
			continue
		made += 1
		for swap in 2:
			var g := r.copy()
			var who := func(p: int) -> TarotAI: return A if (p % 2) == swap else B
			while g.phase == "bid":
				g.bid(g.turn, who.call(g.turn).choose_bid(g, g.turn))
			if g.phase == "discard":
				g.discard(who.call(g.taker).choose_discard(g))
			if g.phase != "play":
				continue
			while g.phase == "play":
				g.play(g.turn, who.call(g.turn).quick(g, g.turn))
			var sc := g.score()
			for p in 4:
				if (p % 2) == swap:
					total += sc.per[p] / 2.0
	return total / (n_deals * 2.0)


# --- Escribir lo aprendido ---

func _write(w: Array, best: Dictionary, note: String) -> void:
	var rows: Array = []
	for ct in 3:
		rows.append("[" + ", ".join(w[ct].map(func(x): return "%.4f" % x)) + "]")
	var keys: Array = []
	for k in best:
		var v = best[k]
		keys.append("\"%s\": %s" % [k, ("%.1f" % v) if v is float else str(v)])
	var src := """class_name TarotAIParams
## Lo aprendido por tools/train_ai.gd (se reescribe al entrenar; no editar a mano).

## Pesos de la subasta: margen esperado (puntos por multiplicador) según los rasgos de la mano,
## para [Pequeña/Guardia (con perro), Guardia sin, Guardia contra].
const BID_W := [
	%s,
	%s,
	%s,
]
## Umbrales de la subasta y ajustes de la política rápida de juego.
const PLAY := {%s}
const TRAINING := "%s"
""" % [rows[0], rows[1], rows[2], ", ".join(keys), note]
	var f := FileAccess.open("res://scripts/ai_params.gd", FileAccess.WRITE)
	f.store_string(src)
	f.close()


## La IA de antes del entrenamiento, como rival de referencia.
class OldAI extends TarotAI:
	func choose_bid(r: Rules, p: int) -> int:
		var v := TarotAI.hand_value(r.hands[p])
		var want := 0
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
