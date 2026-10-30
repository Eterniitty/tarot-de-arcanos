class_name Pad
extends RefCounted
## Un mando o el teclado, con detección de pulsación (flanco) y repetición al mantener las flechas.
## Botones: ok (✕/Espacio/Intro), back (○/Retroceso/Esc), alt (△/Tab), zoom (□/Q), start (Options/Intro), flechas.

var dev := "kb"  # "kb" o "joy<N>"
# El ratón se suma al teclado: la mesa decide qué cuenta como clic válido (sobre una carta, una opción...).
static var mouse_ok := false
static var mouse_alt := false
static var mouse_zoom := false
var _prev := {}
var _now := {}
var _rep := {}


func _init(d := "kb") -> void:
	dev = d


func joy_id() -> int:
	return int(dev.substr(3)) if dev.begins_with("joy") else -1


func poll(delta: float) -> void:
	_prev = _now
	_now = _read()
	for k in ["left", "right", "up", "down"]:
		if _now.get(k, false):
			_rep[k] = _rep.get(k, 0.0) + delta
		else:
			_rep[k] = 0.0


func _read() -> Dictionary:
	var r := {}
	if dev == "kb":
		r.left = Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A)
		r.right = Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)
		r.up = Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W)
		r.down = Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)
		r.ok = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER)
		r.back = Input.is_key_pressed(KEY_BACKSPACE) or Input.is_key_pressed(KEY_ESCAPE)
		r.alt = Input.is_key_pressed(KEY_TAB) or Input.is_key_pressed(KEY_F)
		r.start = Input.is_key_pressed(KEY_ENTER)
		r.zoom = Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_Z) or mouse_zoom
		r.ok = r.ok or mouse_ok
		r.alt = r.alt or mouse_alt
	else:
		var d := joy_id()
		var ax := Input.get_joy_axis(d, JOY_AXIS_LEFT_X)
		var ay := Input.get_joy_axis(d, JOY_AXIS_LEFT_Y)
		r.left = ax < -0.5 or Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_LEFT)
		r.right = ax > 0.5 or Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_RIGHT)
		r.up = ay < -0.5 or Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_UP)
		r.down = ay > 0.5 or Input.is_joy_button_pressed(d, JOY_BUTTON_DPAD_DOWN)
		r.ok = Input.is_joy_button_pressed(d, JOY_BUTTON_A)
		r.back = Input.is_joy_button_pressed(d, JOY_BUTTON_B)
		r.alt = Input.is_joy_button_pressed(d, JOY_BUTTON_Y)
		r.start = Input.is_joy_button_pressed(d, JOY_BUTTON_START)
		r.zoom = Input.is_joy_button_pressed(d, JOY_BUTTON_X)
	return r


func pressed(k: String) -> bool:
	if _now.get(k, false) and not _prev.get(k, false):
		return true
	# Repetición de las flechas al mantener (0,32 s y luego cada 0,08 s)
	if k in ["left", "right", "up", "down"] and _now.get(k, false):
		var h: float = _rep.get(k, 0.0)
		if h > 0.32 and fmod(h - 0.32, 0.08) < get_process_delta():
			return true
	return false


func held(k: String) -> bool:
	return _now.get(k, false)


static func get_process_delta() -> float:
	return 1.0 / maxf(30.0, Engine.get_frames_per_second())
