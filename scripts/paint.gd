class_name Paint
extends RefCounted
## Pintura pixel para las ilustraciones: rampas de color con cambio de tono (sombras hacia violeta, luces hacia
## amarillo), esferas sombreadas con tramado, polígonos, capas con contorno y biselado, halos tramados y nubes.
## La luz viene siempre de arriba a la izquierda.

const LIGHT := Vector3(-0.55, -0.7, 0.46)


## Cinco tonos de un color: [0] sombra profunda … [2] base … [4] brillo.
static func ramp(base: Color) -> Array:
	var out := []
	for k in [-2, -1, 0, 1, 2]:
		var h := base.h
		var s := base.s
		var v := base.v
		if k < 0:
			h = _hue_toward(h, 0.74, 0.07 * -k)
			s = clampf(s + 0.07 * -k, 0.0, 1.0)
			v *= 1.0 - 0.21 * -k
		elif k > 0:
			h = _hue_toward(h, 0.14, 0.06 * k)
			s = clampf(s - 0.13 * k, 0.0, 1.0)
			v = clampf(v + (1.0 - v) * 0.42 * k + 0.04 * k, 0.0, 1.0)
		out.append(Color.from_hsv(h, s, v, base.a))
	return out


static func _hue_toward(h: float, target: float, amt: float) -> float:
	return wrapf(h + wrapf(target - h, -0.5, 0.5) * amt, 0.0, 1.0)


static func layer(w: int, h: int) -> Image:
	return Pix.img(w, h)


static func blendpx(i: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < i.get_width() and y < i.get_height():
		i.set_pixel(x, y, i.get_pixel(x, y).blend(c))


## Esfera (o elipse si squash != 1) sombreada en 5 tonos con tramado en los cambios de banda.
static func sphere(i: Image, cx: float, cy: float, r: float, rp: Array, squash := 1.0, spec := true) -> void:
	var ln := LIGHT.normalized()
	var ry := r * squash
	for y in range(floori(cy - ry) - 1, ceili(cy + ry) + 1):
		for x in range(floori(cx - r) - 1, ceili(cx + r) + 1):
			var dx := (x + 0.5 - cx) / r
			var dy := (y + 0.5 - cy) / ry
			var d2 := dx * dx + dy * dy
			if d2 > 1.0:
				continue
			var l := Vector3(dx, dy, sqrt(1.0 - d2)).dot(ln)
			var tt := (l + 0.3) / 1.25 + (0.06 if (x + y) % 2 == 0 else -0.06)
			var idx := clampi(roundi(tt * 4.0), 0, 4)
			if d2 > 0.82:
				idx = maxi(0, idx - 1)
			Pix.px(i, x, y, rp[idx])
	if spec and r >= 3.0:
		Pix.px(i, roundi(cx - r * 0.4), roundi(cy - ry * 0.45), Color(1, 1, 0.95))


static func ellipse(i: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(floori(cy - ry) - 1, ceili(cy + ry) + 1):
		for x in range(floori(cx - rx) - 1, ceili(cx + rx) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				Pix.px(i, x, y, c)


static func poly(i: Image, pts: PackedVector2Array, c: Color) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		r = r.expand(p)
	for y in range(floori(r.position.y), ceili(r.end.y) + 1):
		for x in range(floori(r.position.x), ceili(r.end.x) + 1):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				Pix.px(i, x, y, c)


## Bisela una capa: bordes de arriba/izquierda más claros, de abajo/derecha más oscuros.
static func bevel(l: Image, lite: Color, dark: Color) -> void:
	var src := l.duplicate()
	var w := l.get_width()
	var h := l.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a == 0.0:
				continue
			var up: bool = y == 0 or src.get_pixel(x, y - 1).a == 0.0
			var lf: bool = x == 0 or src.get_pixel(x - 1, y).a == 0.0
			var dn: bool = y == h - 1 or src.get_pixel(x, y + 1).a == 0.0
			var rt: bool = x == w - 1 or src.get_pixel(x + 1, y).a == 0.0
			if up or lf:
				l.set_pixel(x, y, lite)
			elif dn or rt:
				l.set_pixel(x, y, dark)


## Contorno de 1 px dentro del mismo tamaño de imagen (en los huecos que tocan algo pintado).
static func outline_in(l: Image, c := Pix.INK) -> void:
	var src := l.duplicate()
	var w := l.get_width()
	var h := l.get_height()
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var sx: int = x + d.x
				var sy: int = y + d.y
				if sx >= 0 and sy >= 0 and sx < w and sy < h and src.get_pixel(sx, sy).a > 0.0:
					l.set_pixel(x, y, c)
					break


static func put(dst: Image, src: Image, x: int, y: int) -> void:
	dst.blend_rect(src, Rect2i(0, 0, src.get_width(), src.get_height()), Vector2i(x, y))


## Halo tramado: anillos de opacidad decreciente, el último a cuadros.
static func glow(i: Image, cx: float, cy: float, r: float, c: Color, strength := 0.55) -> void:
	for y in range(floori(cy - r), ceili(cy + r) + 1):
		for x in range(floori(cx - r), ceili(cx + r) + 1):
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if d >= r:
				continue
			var band := ceilf((1.0 - d / r) * 4.0) / 4.0
			if band <= 0.25 and (x + y) % 2 == 1:
				continue
			blendpx(i, x, y, Color(c, band * strength))


static func speckle(i: Image, rect: Rect2i, c: Color, density: float, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			if rng.randf() < density and x >= 0 and y >= 0 and x < i.get_width() and y < i.get_height() and i.get_pixel(x, y).a > 0.0:
				blendpx(i, x, y, c)


## Nube de bolas sombreadas con la base plana.
static func cloud(i: Image, cx: float, cy: float, w: float, rp: Array) -> void:
	var n := maxi(3, int(w / 4.0))
	for k in n:
		var t := float(k) / (n - 1)
		var r := 2.5 + 2.2 * sin(t * PI)
		sphere(i, cx - w / 2.0 + t * w, cy - r * 0.5, r, rp, 1.0, false)
	Pix.rect(i, roundi(cx - w / 2.0), roundi(cy), roundi(w) + 1, 2, rp[1])


## Mata de hojas irregular: varias esferas solapadas de tamaños distintos y hojitas sueltas en el borde.
static func foliage(i: Image, cx: float, cy: float, size: float, rp: Array, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in 5:
		var o := Vector2(rng.randf_range(-1, 1), rng.randf_range(-0.7, 0.7)) * size * 0.55
		sphere(i, cx + o.x, cy + o.y, size * rng.randf_range(0.4, 0.62), rp, 1.0, false)
	for k in int(size * 3):
		var ang := rng.randf() * TAU
		var p := Vector2(cx, cy) + Vector2.from_angle(ang) * size * rng.randf_range(0.75, 1.05)
		Pix.px(i, roundi(p.x), roundi(p.y), rp[1] if ang > PI else rp[3])
	for k in int(size * 2):
		var p := Vector2(cx, cy) + Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * size * 0.6
		if i.get_pixel(clampi(roundi(p.x), 0, i.get_width() - 1), clampi(roundi(p.y), 0, i.get_height() - 1)).a > 0.0:
			Pix.px(i, roundi(p.x), roundi(p.y), rp[4] if p.y < cy else rp[0])


static func thick_line(i: Image, a: Vector2, b: Vector2, w: int, c: Color) -> void:
	var n := maxi(1, int(a.distance_to(b)))
	for k in n + 1:
		var p := a.lerp(b, float(k) / n)
		Pix.rect(i, roundi(p.x - (w - 1) / 2.0), roundi(p.y - (w - 1) / 2.0), w, w, c)


static func bezier(i: Image, a: Vector2, ctrl: Vector2, b: Vector2, w: int, c: Color) -> void:
	var prev := a
	for k in range(1, 33):
		var t := k / 32.0
		var p := a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t)
		thick_line(i, prev, p, w, c)
		prev = p


static func sparkle(i: Image, x: int, y: int, c: Color, big := false) -> void:
	Pix.px(i, x, y, Color.WHITE)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		Pix.px(i, x + d.x, y + d.y, c)
		if big:
			Pix.px(i, x + d.x * 2, y + d.y * 2, Color(c, 0.6))


static func lemniscate(i: Image, cx: float, cy: float, a: float, c: Color, dark: Color) -> void:
	for k in 120:
		var t := k / 120.0 * TAU
		var den := 1.0 + sin(t) * sin(t)
		var p := Vector2(cx + a * cos(t) / den, cy + a * sin(t) * cos(t) / den)
		Pix.px(i, roundi(p.x), roundi(p.y) + 1, dark)
	for k in 120:
		var t := k / 120.0 * TAU
		var den := 1.0 + sin(t) * sin(t)
		var p := Vector2(cx + a * cos(t) / den, cy + a * sin(t) * cos(t) / den)
		Pix.px(i, roundi(p.x), roundi(p.y), c)


## Suelo ondulado con hierba: borde claro, cuerpo con textura y sombra hacia abajo.
static func hills(i: Image, y0: float, amp: float, freq: float, ph: float, rp: Array, seed_v: int) -> void:
	var w := i.get_width()
	var h := i.get_height()
	for x in w:
		var top := roundi(y0 + sin(x * freq + ph) * amp)
		for y in range(maxi(top, 0), h):
			var d := y - top
			var c: Color = rp[4] if d == 0 else (rp[3] if d < 3 else (rp[2] if d < 9 else rp[1]))
			Pix.px(i, x, y, c)
	speckle(i, Rect2i(0, roundi(y0 - amp), w, h), Color(rp[0], 0.35), 0.06, seed_v)
