class_name CardNode
extends Node2D
## Una carta en la mesa. Persigue su destino (posición, giro y escala) con un muelle amortiguado, así cualquier
## cambio de sitio sale suave y con un poco de rebote. Vuelos en arco con giro, volteo con perspectiva (sesgo),
## sombra que se separa al levantarse, aplastamiento al aterrizar y brillo diagonal.

var card := -1
var face_up := false
var target_pos := Vector2.ZERO
var target_rot := 0.0
var target_scale := 1.0
var lift := 0.0  # 0..1: lo despegada que está de la mesa (sombra y escala)
var stiff := 170.0
var damp := 17.0
var vel := Vector2.ZERO
var rot_vel := 0.0
var squash := Vector2.ONE
var dim := 0.0  # oscurecer cartas que no se pueden jugar
var glow := 0.0  # aura de color (carta ganadora, seleccionable)
var glow_col := Color.WHITE
var flying := false
var t := 0.0
var shine_x := -999.0

var spr: Sprite2D
var _flip_amt := 1.0  # escala horizontal del volteo
var _skew := 0.0


func _init() -> void:
	spr = Sprite2D.new()
	add_child(spr)
	spr.texture = Deck.back()


func setup(c: int, up: bool) -> void:
	card = c
	face_up = up
	spr.texture = Deck.texture(c) if up and c >= 0 else Deck.back()


func snap() -> void:
	position = target_pos
	rotation = target_rot
	_cur_scale = target_scale
	vel = Vector2.ZERO
	rot_vel = 0.0


func _process(delta: float) -> void:
	t += delta
	if not flying:
		var acc := (target_pos - position) * stiff - vel * damp
		vel += acc * delta
		position += vel * delta
		var ra := wrapf(target_rot - rotation, -PI, PI) * stiff - rot_vel * damp
		rot_vel += ra * delta
		rotation += rot_vel * delta
		_cur_scale = lerpf(_cur_scale, target_scale, 1.0 - exp(-12.0 * delta))
	squash = squash.lerp(Vector2.ONE, 1.0 - exp(-10.0 * delta))
	scale = Vector2(_cur_scale * squash.x * _flip_amt, _cur_scale * squash.y)
	spr.skew = _skew
	if shine_x > -900.0:
		shine_x += delta * 260.0
		if shine_x > 160.0:
			shine_x = -999.0
	queue_redraw()
	if _over:
		_over.queue_redraw()


var _cur_scale := 1.0
var _over: Node2D


func _draw() -> void:
	var w := Arcana.W / 2.0
	var h := Arcana.H / 2.0
	# Sombra: se separa y se aclara cuanto más levantada está la carta
	var sh := Vector2(2.0, 3.0) + Vector2(3.0, 5.0) * lift
	draw_set_transform(sh.rotated(-rotation) / maxf(0.01, scale.x), 0.0, Vector2.ONE)
	draw_rect(Rect2(-w + 1, -h + 1, w * 2 - 2, h * 2 - 2), Color(0.02, 0.0, 0.06, 0.38 - lift * 0.12))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if glow > 0.01:
		for k in 3:
			var g := 2 + k * 2
			draw_rect(Rect2(-w - g, -h - g, w * 2 + g * 2, h * 2 + g * 2), Color(glow_col, glow * (0.35 - k * 0.1)), false, 2.0)


## Cubre la carta (oscura si no se puede jugar) y el brillo diagonal: se dibuja encima del sprite.
func _ready() -> void:
	var over := Node2D.new()
	_over = over
	spr.add_child(over)
	over.draw.connect(func():
		var w := Arcana.W / 2.0
		var h := Arcana.H / 2.0
		if dim > 0.01:
			over.draw_rect(Rect2(-w + 1, -h + 1, w * 2 - 2, h * 2 - 2), Color(0.05, 0.02, 0.12, dim * 0.55))
		if shine_x > -900.0 and face_up:
			for y in range(-int(h) + 1, int(h) - 1):
				var x := shine_x - 80.0 - y * 0.6
				if x > -w + 1 and x < w - 3:
					over.draw_rect(Rect2(x, y, 3, 1), Color(1, 1, 1, 0.45))
					over.draw_rect(Rect2(x + 5, y, 1, 1), Color(1, 1, 1, 0.25)))


func shine() -> void:
	shine_x = 0.0


## Vuelo en arco (Bezier) hasta el destino, girando `spins` vueltas; al llegar, aplasta y sigue con el muelle.
func fly_to(dest: Vector2, rot: float, sc: float, dur: float, arc := 40.0, spins := 0.0) -> void:
	flying = true
	var from := position
	var r0 := rotation
	var s0 := _cur_scale
	var ctrl := (from + dest) / 2.0 + (dest - from).orthogonal().normalized() * arc + Vector2(0, -absf(arc) * 0.6)
	var tw := create_tween()
	tw.tween_method(func(k: float):
		var e := 1.0 - pow(1.0 - k, 2.2)
		var a := from.lerp(ctrl, e)
		var b := ctrl.lerp(dest, e)
		position = a.lerp(b, e)
		rotation = lerpf(r0, rot + spins * TAU, e)
		_cur_scale = lerpf(s0, sc, e)
		lift = sin(k * PI) * 1.0, 0.0, 1.0, dur)
	await tw.finished
	position = dest
	rotation = rot
	target_pos = dest
	target_rot = rot
	target_scale = sc
	_cur_scale = sc
	vel = Vector2.ZERO
	rot_vel = 0.0
	lift = 0.0
	flying = false
	squash = Vector2(1.18, 0.84)


## Voltea la carta (hacia la cara o el dorso) con perspectiva.
func flip(up: bool, dur := 0.16) -> void:
	var tw := create_tween()
	tw.tween_method(func(k: float):
		_flip_amt = cos(k * PI / 2.0)
		_skew = sin(k * PI) * 0.25, 0.0, 1.0, dur / 2.0)
	await tw.finished
	face_up = up
	spr.texture = Deck.texture(card) if up and card >= 0 else Deck.back()
	tw = create_tween()
	tw.tween_method(func(k: float):
		_flip_amt = sin(k * PI / 2.0)
		_skew = -sin((1.0 - k) * PI) * 0.25, 0.0, 1.0, dur / 2.0)
	await tw.finished
	_flip_amt = 1.0
	_skew = 0.0
	squash = Vector2(1.1, 0.92)
