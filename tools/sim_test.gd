extends SceneTree
## Prueba sin ventana: manos completas entre IAs. Comprueba que los puntos suman 91 y mide la IA Monte Carlo
## (asiento 0) contra la política rápida (resto): godot --headless --path . -s res://tools/sim_test.gd -- <manos> <muestras>


func _initialize() -> void:
	var argv := OS.get_cmdline_user_args()
	var hands_n := int(argv[0]) if argv.size() > 0 else 20
	var samples := int(argv[1]) if argv.size() > 1 else 28
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var mc := TarotAI.new(7)
	mc.samples = samples
	var fast := TarotAI.new(9)
	var total := [0, 0, 0, 0]
	var played_hands := 0
	var worst_ms := 0
	var sum_ms := 0
	var n_dec := 0
	var bad := 0
	var dealer := 0
	var contracts := [0, 0, 0, 0, 0]
	while played_hands < hands_n:
		var r := Rules.new()
		r.deal(4, dealer, rng)
		dealer = (dealer + 1) % 4
		if r.phase == "redeal":
			continue
		while r.phase == "bid":
			r.bid(r.turn, mc.choose_bid(r, r.turn))
		if r.phase == "redeal":
			contracts[0] += 1
			continue
		contracts[r.contract] += 1
		if r.phase == "discard":
			if not r.discard(mc.choose_discard(r)):
				print("DESCARTE INVALIDO")
				bad += 1
				break
		while r.phase == "play":
			var p := r.turn
			var c: int
			if p == 0:
				var t0 := Time.get_ticks_msec()
				c = mc.choose_card(r, p)
				var dt := Time.get_ticks_msec() - t0
				worst_ms = maxi(worst_ms, dt)
				sum_ms += dt
				n_dec += 1
			else:
				c = fast.quick(r, p)
			var res := r.play(p, c)
			if res.has("error"):
				print("JUGADA ILEGAL ", p, " ", c)
				bad += 1
				break
		var hp := r.taker_half_points()
		var dp := 0
		for x in r.piles[1]:
			dp += Deck.half_points(x)
		if hp + dp != 182 or r.piles[0].size() + r.piles[1].size() != 78:
			print("PUNTOS MAL: ", hp, " + ", dp, " cartas ", r.piles[0].size() + r.piles[1].size())
			bad += 1
		var sc := r.score()
		for p in 4:
			total[p] += sc.per[p]
		played_hands += 1
	print("manos %d · errores %d · contratos (paso,peq,guar,sin,contra) %s" % [played_hands, bad, str(contracts)])
	print("marcador acumulado (0 = Monte Carlo): %s" % str(total))
	print("tiempo por decisión de la IA: medio %d ms · peor %d ms" % [sum_ms / maxi(1, n_dec), worst_ms])
	quit()
