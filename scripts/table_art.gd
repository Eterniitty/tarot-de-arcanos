class_name TableArt
extends RefCounted
## Tapete de terciopelo pintado por código: tramado con brillo en el centro, viñeta, bordado dorado en círculo con
## los cuatro palos, sol y luna, y un ribete de estrellas.


static func felt(w: int, h: int) -> Image:
	var i := Pix.img(w, h)
	var c := Vector2(w / 2.0, h / 2.0 - 14.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var tones := [Color("120a24"), Color("1c1036"), Color("261646"), Color("301c56"), Color("3a2266")]
	for y in h:
		for x in w:
			var d := Vector2((x - c.x) / (w * 0.62), (y - c.y) / (h * 0.62)).length()
			var v := clampf(1.0 - d, 0.0, 1.0) * 4.0
			var bayer: float = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]][y % 4][x % 4] / 16.0
			var k := clampi(int(v + bayer - 0.3), 0, 4)
			var col: Color = tones[k]
			# Pelo del terciopelo: vetas diagonales sutiles
			if (x * 3 + y * 7 + rng.randi() % 3) % 29 == 0:
				col = col.lightened(0.06)
			i.set_pixel(x, y, col)
	# Bordado circular
	var gold := Color("c9892a")
	var gold_l := Color("ffd447")
	for r_k in [[96.0, 0.55], [104.0, 0.35], [140.0, 0.22]]:
		var r: float = r_k[0]
		var steps := int(TAU * r)
		for s in steps:
			var a := s * TAU / steps
			var p := c + Vector2(cos(a) * r * 1.25, sin(a) * r * 0.72)
			if s % 3 != 0:
				Paint.blendpx(i, roundi(p.x), roundi(p.y), Color(gold, r_k[1]))
	for k in 24:
		var a := k * TAU / 24.0
		var p := c + Vector2(cos(a) * 100.0 * 1.25, sin(a) * 100.0 * 0.72)
		Paint.blendpx(i, roundi(p.x), roundi(p.y), Color(gold_l, 0.7))
		if k % 6 == 0:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				Paint.blendpx(i, roundi(p.x) + d.x, roundi(p.y) + d.y, Color(gold_l, 0.45))
	# Los cuatro palos bordados en el anillo (tenues)
	for s in 4:
		var a := -PI / 2.0 + s * TAU / 4.0 + PI / 4.0
		var p := c + Vector2(cos(a) * 122.0 * 1.25, sin(a) * 122.0 * 0.72)
		var sym := Minors.pip(s, 1)
		_ghost(i, sym, roundi(p.x) - sym.get_width() / 2, roundi(p.y) - sym.get_height() / 2, 0.28)
	# Sol y luna en los lados
	for side in [-1, 1]:
		var p := c + Vector2(side * 230.0, -6.0)
		for y in range(-9, 10):
			for x in range(-9, 10):
				var d := Vector2(x, y).length()
				var on := d <= 7.5 if side < 0 else (d <= 7.5 and Vector2(x - 3, y - 2).length() > 6.0)
				if on and (x + y) % 2 == 0:
					Paint.blendpx(i, roundi(p.x) + x, roundi(p.y) + y, Color(gold_l, 0.22))
		if side < 0:
			for k in 8:
				var a := k * TAU / 8.0
				for rr in range(9, 13):
					Paint.blendpx(i, roundi(p.x + cos(a) * rr), roundi(p.y + sin(a) * rr), Color(gold_l, 0.2))
	# Estrellas sueltas
	for k in 70:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		Paint.blendpx(i, x, y, Color(1, 1, 1, rng.randf_range(0.08, 0.22)))
	# Ribete
	for x in w:
		for y in [2, h - 3]:
			if x % 4 != 0:
				Paint.blendpx(i, x, y, Color(gold, 0.35))
	return i


static func _ghost(dst: Image, src: Image, ox: int, oy: int, a: float) -> void:
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y)
			if c.a > 0.0 and (x + y) % 2 == 0:
				Paint.blendpx(dst, ox + x, oy + y, Color(c, a))
