extends SceneTree
## Enfrenta dos niveles de IA con repartos duplicados (cada reparto se juega dos veces cambiando de asiento)
## y dice cuántos puntos por mano saca el nivel A al B y qué parte de las partidas de 8 manos gana.
## godot --headless --path . -s res://tools/levels_test.gd -- <nivel A> <nivel B> <repartos> <semilla>


func _initialize() -> void:
	var argv := OS.get_cmdline_user_args()
	var la := int(argv[0])
	var lb := int(argv[1])
	var n_deals := int(argv[2]) if argv.size() > 2 else 100
	var rng := RandomNumberGenerator.new()
	rng.seed = int(argv[3]) if argv.size() > 3 else 5
	var A := TarotAI.new(21)
	A.set_level(la)
	var B := TarotAI.new(22)
	B.set_level(lb)
	var diffs: Array = []  # por reparto: puntos de A por asiento (media de los dos lados)
	var made := 0
	var dealer := 0
	var t0 := Time.get_ticks_msec()
	while made < n_deals:
		var r := Rules.new()
		r.deal(4, dealer, rng)
		dealer = (dealer + 1) % 4
		if r.phase != "bid":
			continue
		made += 1
		var d := 0.0
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
				g.play(g.turn, who.call(g.turn).decide_card(g, g.turn))
			var sc := g.score()
			for p in 4:
				if (p % 2) == swap:
					d += sc.per[p] / 4.0
		diffs.append(d)
	var mean := 0.0
	for x in diffs:
		mean += x
	mean /= diffs.size()
	var var_s := 0.0
	for x in diffs:
		var_s += pow(x - mean, 2)
	var se := sqrt(var_s / (diffs.size() - 1) / diffs.size())
	# Partidas de 8 manos: bloques de 8 repartos seguidos
	var games := 0
	var won := 0
	for i in range(0, diffs.size() - 7, 8):
		var s := 0.0
		for k in 8:
			s += diffs[i + k]
		games += 1
		won += 1 if s > 0.0 else 0
	print("RESULTADO %s vs %s: %+.1f ± %.1f puntos por mano y asiento · gana %d de %d partidas de 8 manos · %d s" % [
		TarotAI.LEVELS[la].name, TarotAI.LEVELS[lb].name, mean, se, won, games, (Time.get_ticks_msec() - t0) / 1000])
	quit()
