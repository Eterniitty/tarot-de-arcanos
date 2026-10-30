extends Node
## Sonido sintetizado por código al arrancar (ningún archivo de audio): papel de carta, golpes con grave,
## campanas con armónicos inarmónicos, arpa pulsada (Karplus-Strong), trompeta con vibrato y reverberación
## por ecos múltiples para dar espacio. Cada reproducción varía un poco el tono para que no suene repetido.

const RATE := 32000

var bank := {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0
var muted := false
var _rng := RandomNumberGenerator.new()

# Notas (Hz)
const C4 := 261.63
const E4 := 329.63
const G4 := 392.0
const A4 := 440.0
const C5 := 523.25
const D5 := 587.33
const E5 := 659.25
const G5 := 783.99
const A5 := 880.0
const C6 := 1046.5


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 1234
	for i in 16:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	# --- Cartas ---
	bank.flip = _wav(_mix([_paper(0.06, 0.55, 0.55), _thump(0.05, 420, 260, 0.12)]))
	bank.tick = _wav(_mix([_paper(0.018, 0.35, 0.8), _sine(0.02, 2400, 2000, 0.05, 60.0)]))
	bank.swish = _wav(_reverb(_whoosh(0.22, 0.45, 0.15, 0.7), 0.18))
	bank.land = _wav(_mix([_thump(0.14, 170, 60, 0.6), _paper(0.05, 0.5, 0.45)]))
	bank.shuffle = _wav(_riffle(0.5))
	# --- Interfaz ---
	bank.select = _wav(_reverb(_mix([_pluck(E5, 0.25, 0.32), _pluck(A5, 0.25, 0.18, 0.03)]), 0.2))
	bank.join = _wav(_reverb(_mix([_pluck(C5, 0.3, 0.3), _pluck(G5, 0.3, 0.3, 0.07)]), 0.25))
	bank.leave = _wav(_reverb(_mix([_pluck(G5, 0.3, 0.3), _pluck(C5, 0.3, 0.3, 0.07)]), 0.25))
	bank.warn = _wav(_mix([_sine(0.09, 330, 330, 0.25, 30.0, 0.003), _sine(0.12, 262, 262, 0.25, 26.0, 0.003, 0.1)]))
	bank.count = _wav(_bell(A5, 0.4, 0.3))
	# --- Música de los efectos ---
	bank.ding = _wav(_reverb(_mix([_bell(1568.0, 0.9, 0.28), _bell(2349.0, 0.7, 0.12, 0.02)]), 0.35))
	bank.reveal = _wav(_reverb(_harp([C5, E5, G5, C6, E5 * 2.0], 0.055, 0.9, 0.3), 0.4))
	bank.win = _wav(_reverb(_mix([_harp([C5, E5, G5, C6], 0.08, 1.2, 0.3), _bell(C6, 1.4, 0.18, 0.34), _bell(G5, 1.4, 0.14, 0.42), _brass([G4, C5], 0.5, 0.18, 0.3)]), 0.45))
	bank.go = _wav(_reverb(_brass([G4, C5, E5], 0.42, 0.28), 0.4))
	bank.teleport = _wav(_reverb(_harp([E5, A5, C6, E5 * 2.0, A5 * 2.0], 0.035, 0.6, 0.22), 0.5))
	bank.orb = _wav(_reverb(_mix([_bell(A5, 0.7, 0.25), _sine(0.4, 900, 380, 0.2, 7.0)]), 0.35))
	bank.arcano = _wav(_reverb(_mix([_bell(C5, 2.0, 0.24), _bell(G5, 1.8, 0.16, 0.06), _bell(E5 * 2.0, 1.6, 0.1, 0.12), _sine(1.6, C4 / 2.0, C4 / 2.0, 0.22, 1.6)]), 0.55))
	bank.heart = _wav(_mix([_thump(0.14, 90, 45, 0.8), _thump(0.14, 80, 40, 0.6, 0.18)]))
	bank.charge = _wav(_reverb(_mix([_sine(0.8, 180, 1500, 0.2, 2.0, 0.0, 0.0, 9.0), _whoosh(0.8, 0.18, 0.05, 0.6)]), 0.3))
	# --- Golpes ---
	bank.hit = _wav(_mix([_thump(0.16, 160, 50, 0.7), _paper(0.06, 0.45, 0.3), _noise(0.12, 0.25, 0.12)]))
	bank.hit_big = _wav(_reverb(_mix([_thump(0.35, 120, 35, 0.9), _noise(0.3, 0.45, 0.1), _paper(0.08, 0.5, 0.3)]), 0.25))
	bank.boom = _wav(_reverb(_mix([_thump(0.9, 90, 28, 1.0), _noise(0.7, 0.55, 0.06), _noise(0.15, 0.3, 0.4)]), 0.35))
	bank.thunder = _wav(_reverb(_mix([_crackle(1.1, 0.55), _thump(1.0, 70, 30, 0.7)]), 0.45))
	bank.crumble = _wav(_reverb(_rubble(0.7, 0.5), 0.25))
	bank.swing = _wav(_whoosh(0.18, 0.55, 0.25, 0.9))
	bank.dash = _wav(_reverb(_mix([_whoosh(0.28, 0.5, 0.2, 0.8), _sine(0.2, 220, 90, 0.18, 12.0)]), 0.2))
	bank.bounce = _wav(_boing(0.32, 0.4))
	bank.jump2 = _wav(_mix([_sine(0.14, 500, 1100, 0.25, 12.0), _pluck(G5, 0.15, 0.12)]))
	bank.ko = _wav(_reverb(_brass([G4, E4, C4], 0.3, 0.25), 0.35))
	# --- Máquina de la intro ---
	bank.servo = _wav(_mix([_sine(0.36, 180, 520, 0.12, 1.5, 0.02, 0.0, 34.0), _whoosh(0.36, 0.12, 0.05, 0.3)]))
	bank.clunk = _wav(_reverb(_mix([_thump(0.24, 150, 55, 0.85), _paper(0.05, 0.5, 0.25), _bell(820.0, 0.2, 0.06)]), 0.15))
	bank.clank = _wav(_reverb(_mix([_thump(0.5, 110, 38, 1.0), _noise(0.3, 0.4, 0.15), _bell(1240.0, 0.7, 0.13), _bell(1730.0, 0.55, 0.08, 0.01), _paper(0.06, 0.6, 0.4)]), 0.3))
	bank.rivet = _wav(_reverb(_mix([_bell(2093.0, 0.55, 0.2), _bell(3136.0, 0.35, 0.1), _thump(0.08, 300, 150, 0.4)]), 0.3))
	# Compatibilidad con nombres antiguos
	bank.jump = bank.jump2
	bank.crack = bank.flip


func play(name: String, vol_db := 0.0, pitch := 1.0) -> void:
	if muted or not bank.has(name):
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = bank[name]
	p.volume_db = vol_db
	p.pitch_scale = pitch * randf_range(0.97, 1.03)
	p.play()


# --- Generadores ---

func _buf(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE) + 2)
	return out


## Seno con barrido exponencial f0→f1, caída exponencial `decay`, ataque, retraso y vibrato opcional.
func _sine(dur: float, f0: float, f1: float, vol: float, decay := 6.0, attack := 0.003, delay := 0.0, trem := 0.0) -> PackedFloat32Array:
	var out := _buf(dur + delay)
	var ph := 0.0
	var off := int(delay * RATE)
	var n := int(dur * RATE)
	for i in n:
		var t := float(i) / RATE
		var u := float(i) / n
		var f := f0 * pow(f1 / f0, u)
		ph += f / RATE
		var env := minf(1.0, t / maxf(0.0005, attack)) * exp(-decay * t)
		if trem > 0.0:
			env *= 0.75 + 0.25 * sin(t * trem * TAU)
		out[off + i] = sin(ph * TAU) * vol * env
	return out


## Golpe grave: seno que cae de tono muy rápido (el «tum» de una carta o de un impacto).
func _thump(dur: float, f0: float, f1: float, vol: float, delay := 0.0) -> PackedFloat32Array:
	var out := _buf(dur + delay)
	var off := int(delay * RATE)
	var n := int(dur * RATE)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := f1 + (f0 - f1) * exp(-t * 28.0)
		ph += f / RATE
		out[off + i] = sin(ph * TAU) * vol * minf(1.0, t / 0.002) * exp(-t * 9.0 / dur)
	return out


## Chasquido de papel: ruido de banda (diferencia de dos filtros) con caída muy rápida.
func _paper(dur: float, vol: float, bright: float) -> PackedFloat32Array:
	var out := _buf(dur)
	var lo := 0.0
	var hi := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var x := _rng.randf_range(-1.0, 1.0)
		hi += (x - hi) * clampf(bright, 0.05, 1.0)
		lo += (x - lo) * 0.04
		out[i] = (hi - lo) * vol * 1.6 * exp(-t * 6.0 / dur) * minf(1.0, t / 0.0008)
	return out


## Fiuuu: ruido cuyo filtro sube y baja (forma de campana) con un poco de silbido.
func _whoosh(dur: float, vol: float, c0: float, c1: float) -> PackedFloat32Array:
	var out := _buf(dur)
	var y := 0.0
	var y2 := 0.0
	for i in out.size():
		var u := float(i) / out.size()
		var shape := sin(u * PI)
		var k := lerpf(c0, c1, shape) * 0.5
		y += (_rng.randf_range(-1.0, 1.0) - y) * k
		y2 += (y - y2) * k
		out[i] = (y - y2 * 0.5) * vol * 2.2 * pow(shape, 1.5)
	return out


func _noise(dur: float, vol: float, cutoff: float) -> PackedFloat32Array:
	var out := _buf(dur)
	var y := 0.0
	for i in out.size():
		var t := float(i) / RATE
		y += (_rng.randf_range(-1.0, 1.0) - y) * cutoff
		out[i] = y * vol * 2.0 * exp(-t * 5.0 / dur)
	return out


## Barajar: una cascada de chasquidos que se aceleran.
func _riffle(dur: float) -> PackedFloat32Array:
	var out := _buf(dur)
	var t := 0.0
	var gap := 0.04
	while t < dur - 0.03:
		var s := _paper(0.025, 0.4 * _rng.randf_range(0.6, 1.0), _rng.randf_range(0.4, 0.8))
		var off := int(t * RATE)
		for i in s.size():
			if off + i < out.size():
				out[off + i] += s[i]
		t += gap
		gap = maxf(0.012, gap * 0.9)
	return out


## Trueno: ruido grave con chasquidos sueltos.
func _crackle(dur: float, vol: float) -> PackedFloat32Array:
	var out := _noise(dur, vol, 0.05)
	for k in 14:
		var at := _rng.randf_range(0.0, dur * 0.6)
		var s := _paper(0.04, vol * 0.8, 0.5)
		var off := int(at * RATE)
		for i in s.size():
			if off + i < out.size():
				out[off + i] += s[i]
	return out


## Escombros: muchos golpecitos y ruido.
func _rubble(dur: float, vol: float) -> PackedFloat32Array:
	var out := _noise(dur, vol * 0.6, 0.08)
	for k in 18:
		var at := _rng.randf_range(0.0, dur * 0.8)
		var s := _thump(0.08, _rng.randf_range(200, 400), 80, vol * 0.5)
		var off := int(at * RATE)
		for i in s.size():
			if off + i < out.size():
				out[off + i] += s[i]
	return out


## Muelle: el tono oscila arriba y abajo y se apaga («boing»).
func _boing(dur: float, vol: float) -> PackedFloat32Array:
	var out := _buf(dur)
	var ph := 0.0
	for i in out.size():
		var t := float(i) / RATE
		var f := 320.0 + 220.0 * sin(t * 38.0) * exp(-t * 6.0) + t * 200.0
		ph += f / RATE
		out[i] = (sin(ph * TAU) + 0.3 * sin(ph * TAU * 2.0)) * vol * exp(-t * 7.0) * minf(1.0, t / 0.003)
	return out


## Campana: parciales inarmónicos que se apagan a distinto ritmo (suena a metal de verdad).
func _bell(f: float, dur: float, vol: float, delay := 0.0) -> PackedFloat32Array:
	var out := _buf(dur + delay)
	var off := int(delay * RATE)
	var partials := [[1.0, 1.0, 2.2], [2.0, 0.55, 3.0], [2.76, 0.42, 4.0], [5.4, 0.25, 6.0], [8.93, 0.12, 8.0]]
	var n := int(dur * RATE)
	for i in n:
		var t := float(i) / RATE
		var s := 0.0
		for p in partials:
			s += sin(TAU * f * p[0] * t) * p[1] * exp(-t * p[2] / dur * 1.6)
		out[off + i] = s * vol * 0.5 * minf(1.0, t / 0.002)
	return out


## Cuerda pulsada (Karplus-Strong): un retardo que se va suavizando.
func _pluck(f: float, dur: float, vol: float, delay := 0.0) -> PackedFloat32Array:
	var out := _buf(dur + delay)
	var off := int(delay * RATE)
	var period := maxi(2, int(RATE / f))
	var ring := PackedFloat32Array()
	ring.resize(period)
	for i in period:
		ring[i] = _rng.randf_range(-1.0, 1.0)
	var idx := 0
	var n := int(dur * RATE)
	for i in n:
		var a := ring[idx]
		var b := ring[(idx + 1) % period]
		ring[idx] = (a + b) * 0.497
		out[off + i] = a * vol
		idx = (idx + 1) % period
	return out


func _harp(notes: Array, step: float, tail: float, vol: float) -> PackedFloat32Array:
	var parts: Array = []
	for k in notes.size():
		parts.append(_pluck(notes[k], tail, vol, k * step))
	return _mix(parts)


## Metal de viento: suma de armónicos con vibrato y entrada suave, nota tras nota.
func _brass(notes: Array, step: float, vol: float, delay := 0.0) -> PackedFloat32Array:
	var dur := step * notes.size() + 0.25
	var out := _buf(dur + delay)
	for k in notes.size():
		var f: float = notes[k]
		var off := int((delay + k * step) * RATE)
		var n := int((step + (0.25 if k == notes.size() - 1 else 0.04)) * RATE)
		var ph := 0.0
		for i in n:
			var t := float(i) / RATE
			ph += f * (1.0 + 0.006 * sin(t * 33.0)) / RATE
			var s := 0.0
			for h in range(1, 7):
				s += sin(ph * TAU * h) / h * (1.0 if h < 3 else 0.6)
			var env := minf(1.0, t / 0.03) * (1.0 if i < n - 1600 else float(n - i) / 1600.0)
			if off + i < out.size():
				out[off + i] += s * vol * 0.45 * env
	return out


func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = maxi(n, (p as PackedFloat32Array).size())
	var out := PackedFloat32Array()
	out.resize(n)
	for p in parts:
		var a: PackedFloat32Array = p
		for i in a.size():
			out[i] += a[i]
	return out


## Reverberación: ecos múltiples que se apagan, más una cola, mezclados con el sonido seco.
func _reverb(dry: PackedFloat32Array, wet: float) -> PackedFloat32Array:
	var taps := [[0.023, 0.6], [0.041, 0.5], [0.067, 0.42], [0.089, 0.34], [0.121, 0.27], [0.163, 0.2], [0.217, 0.14]]
	var tail := int(0.35 * RATE)
	var out := PackedFloat32Array()
	out.resize(dry.size() + tail)
	for i in dry.size():
		out[i] = dry[i]
	for tp in taps:
		var d := int(tp[0] * RATE)
		var g: float = tp[1] * wet
		for i in dry.size():
			out[i + d] += dry[i] * g
	# Suaviza un poco la cola
	var y := 0.0
	for i in range(dry.size(), out.size()):
		y += (out[i] - y) * 0.5
		out[i] = y * (1.0 - float(i - dry.size()) / tail)
	return out


func _wav(data: PackedFloat32Array) -> AudioStreamWAV:
	# Limitador suave para que nada sature
	var peak := 0.001
	for v in data:
		peak = maxf(peak, absf(v))
	var g := 0.9 / peak if peak > 0.9 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in data.size():
		var x := data[i] * g
		x = x / (1.0 + absf(x) * 0.15)
		bytes.encode_s16(i * 2, int(clampf(x, -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	return s
