extends SceneTree
## Compara perfiles de subasta: cuánto pierden o ganan frente a la subasta entrenada (repartos duplicados)
## y qué partidas dan (repartos en blanco y mezcla de contratos).


func _initialize() -> void:
	var base: Dictionary = TarotAIParams.PLAY.duplicate()
	var profiles := [
		{"t1": -6.0, "t2": 6.0, "t3": 22.0, "t4": 32.0},
		{"t1": -10.0, "t2": 6.0, "t3": 20.0, "t4": 30.0},
		{"t1": -14.0, "t2": 8.0, "t3": 20.0, "t4": 30.0},
		{"t1": -10.0, "t2": 10.0, "t3": 15.0, "t4": 25.0},
		{"t1": -18.0, "t2": 6.0, "t3": 18.0, "t4": 28.0},
	]
	for pf in profiles:
		var cand := base.duplicate()
		for k in pf:
			cand[k] = pf[k]
		var st := _run(cand, base, 1500, 77)
		print("%s -> %+.2f por mano vs entrenada · blanco %.0f%% · peq/guar/sin/contra %s · gana el que toma %.0f%%" % [
			str(pf), st.gain, st.pass, str(st.mix), st.win])
	quit()


func _run(a: Dictionary, b: Dictionary, n_deals: int, seed_v: int) -> Dictionary:
	var A := TarotAI.new(11)
	A.set_level(1)
	A.blunder = 0.0
	A.prm = a
	var B := TarotAI.new(13)
	B.set_level(1)
	B.blunder = 0.0
	B.prm = b
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var total := 0.0
	var made := 0
	var dealer := 0
	var mix := [0, 0, 0, 0, 0]
	var games := 0
	var wins := 0
	# Mezcla de contratos con los cuatro asientos usando el perfil
	while made < n_deals:
		var r := Rules.new()
		r.deal(4, dealer, rng)
		dealer = (dealer + 1) % 4
		if r.phase != "bid":
			continue
		made += 1
		var g0 := r.copy()
		while g0.phase == "bid":
			g0.bid(g0.turn, A.choose_bid(g0, g0.turn))
		mix[g0.contract] += 1
		if g0.phase == "discard":
			g0.discard(A.choose_discard(g0))
		if g0.phase == "play":
			while g0.phase == "play":
				g0.play(g0.turn, A.quick(g0, g0.turn))
			games += 1
			wins += 1 if g0.score().won else 0
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
	return {"gain": total / (n_deals * 2.0), "pass": 100.0 * mix[0] / n_deals, "mix": mix.slice(1), "win": 100.0 * wins / maxi(1, games)}
