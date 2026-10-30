class_name TableFx
extends Node2D
## Lo que se pinta sobre el tapete y debajo de las cartas: la mesa se tiñe del color del palo que manda en la baza,
## un anillo con flechas que giran en el sentido del juego y un cometa que corre hacia quien tiene el turno.

const CENTER := Vector2(320, 166)
const RX := 132.0
const RY := 84.0
const SUIT_COLS := [Color("5ff07a"), Color("ff5a6a"), Color("7ab8ff"), Color("ffd447"), Color("b06aff")]

var game: Node
var t := 0.0
var tint := Color(0, 0, 0, 0)
var pulse := 0.0  # destello del anillo al cambiar de palo
var comet_a := PI / 2.0
var _last_led := -2


static func suit_color(s: int) -> Color:
	return SUIT_COLS[s] if s >= 0 and s < SUIT_COLS.size() else Color.WHITE


## Ángulo en el anillo de cada asiento en pantalla (0 abajo, 1 izquierda, 2 arriba, 3 derecha).
static func seat_angle(s: int) -> float:
	return [PI / 2.0, PI, PI * 1.5, TAU][s]


func _process(delta: float) -> void:
	t += delta
	pulse = maxf(0.0, pulse - delta * 2.0)
	var led: int = game.led_suit_view() if game.phase == "table" else -1
	if led != _last_led:
		if led >= 0:
			pulse = 1.0
		_last_led = led
	var target := Color(suit_color(led), 0.16) if led >= 0 else Color(0, 0, 0, 0)
	tint = tint.lerp(target, 1.0 - exp(-5.0 * delta))
	# El cometa avanza siempre en el sentido del juego hasta el asiento que tiene el turno
	if game.turn_seat >= 0 and game.phase == "table":
		var goal := seat_angle(game.slot(game.turn_seat))
		while goal < comet_a - 0.01:
			goal += TAU
		comet_a = lerpf(comet_a, goal, 1.0 - exp(-6.0 * delta))
		if comet_a > TAU * 2.0:
			comet_a -= TAU
	queue_redraw()


func _ell(a: float, grow := 0.0) -> Vector2:
	return CENTER + Vector2(cos(a) * (RX + grow), sin(a) * (RY + grow * 0.64))


func _draw() -> void:
	if game.phase != "table":
		return
	# Tinte del palo: óvalos concéntricos que se apagan hacia fuera
	if tint.a > 0.005:
		for k in 6:
			var g := 1.0 - k * 0.15
			var pts := PackedVector2Array()
			for i in 40:
				var a := i * TAU / 40.0
				pts.append(CENTER + Vector2(cos(a) * RX * g * 1.25, sin(a) * RY * g * 1.25))
			draw_colored_polygon(pts, Color(tint, tint.a * 0.35))
	# Anillo punteado con flechas que corren en el sentido del juego
	var ring_col := Color(suit_color(_last_led), 0.35 + pulse * 0.6) if _last_led >= 0 else Color(Pix.GOLD, 0.22)
	var steps := 72
	for i in steps:
		var a := i * TAU / steps
		if i % 2 == 0:
			var p := _ell(a, pulse * 10.0)
			draw_rect(Rect2(p.round(), Vector2(1, 1)), ring_col)
	var spd := 0.5
	for k in 8:
		var a := fmod(t * spd + k * TAU / 8.0, TAU)
		var p := _ell(a)
		var tan := (_ell(a + 0.02) - p).normalized()
		var nrm := tan.orthogonal()
		var c := Color(ring_col, ring_col.a * 0.9)
		for j in 3:
			var q := p - tan * j
			draw_rect(Rect2((q + nrm * (2 - j)).round(), Vector2.ONE), c)
			draw_rect(Rect2((q - nrm * (2 - j)).round(), Vector2.ONE), c)
	# Cometa del turno con estela
	if game.turn_seat >= 0:
		for k in 14:
			var a := comet_a - k * 0.035
			var p := _ell(a)
			var s := 3.0 - k * 0.18
			draw_rect(Rect2(p - Vector2(s, s) / 2.0, Vector2(s, s)), Color(Pix.GOLD, (1.0 - k / 14.0) * 0.9))
		var head := _ell(comet_a)
		draw_rect(Rect2(head - Vector2(1, 1), Vector2(3, 3)), Color.WHITE)
