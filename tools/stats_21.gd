extends SceneTree
## Estadística: ¿cuánto ayuda tener el 21? Juega muchas manos entre IAs rápidas y compara.


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var ai := TarotAI.new(3)
	var hands := 0
	var with21_take := 0
	var with21_take_win := 0
	var no21_take := 0
	var no21_take_win := 0
	var holder_pts := 0
	var holder_hands := 0
	var other_pts := 0
	var other_hands := 0
	var dealer := 0
	while hands < 1500:
		var r := Rules.new()
		r.deal(4, dealer, rng)
		dealer = (dealer + 1) % 4
		if r.phase == "redeal":
			continue
		var holder := -1
		for p in 4:
			if 21 in r.hands[p]:
				holder = p
		while r.phase == "bid":
			r.bid(r.turn, ai.choose_bid(r, r.turn))
		if r.phase == "redeal":
			continue
		if r.phase == "discard":
			r.discard(ai.choose_discard(r))
		while r.phase == "play":
			r.play(r.turn, ai.quick(r, r.turn))
		var s := r.score()
		hands += 1
		if r.taker == holder:
			with21_take += 1
			with21_take_win += 1 if s.won else 0
		else:
			no21_take += 1
			no21_take_win += 1 if s.won else 0
		for p in 4:
			if p == holder:
				holder_pts += s.per[p]
				holder_hands += 1
			else:
				other_pts += s.per[p]
				other_hands += 1
	print("manos: %d" % hands)
	print("apuesta quien tiene el 21: %d veces, gana %.0f%%" % [with21_take, 100.0 * with21_take_win / maxi(1, with21_take)])
	print("apuesta otro (sin el 21): %d veces, gana %.0f%%" % [no21_take, 100.0 * no21_take_win / maxi(1, no21_take)])
	print("puntos medios por mano: con el 21 %.1f · sin el 21 %.1f" % [float(holder_pts) / holder_hands, float(other_pts) / other_hands])
	quit()
