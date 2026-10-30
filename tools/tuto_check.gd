extends SceneTree
## Comprueba el tutorial: reparto de 78 cartas sin repetir, guion legal y resultado final de la mano.


func _initialize() -> void:
	var all := {}
	for h in TarotTutorial.hands():
		print("mano: %d cartas" % h.size())
		for c in h:
			all[c] = all.get(c, 0) + 1
	for c in TarotTutorial.chien():
		all[c] = all.get(c, 0) + 1
	var bad: Array = []
	for c in Deck.N:
		if all.get(c, 0) != 1:
			bad.append("%s x%d" % [Deck.name(c), all.get(c, 0)])
	print("cartas mal repartidas: ", bad)
	var r := Rules.new()
	r.n = 4
	r.deal(4, TarotTutorial.DEALER, RandomNumberGenerator.new())
	r.set_fixed(TarotTutorial.hands(), TarotTutorial.chien(), TarotTutorial.DEALER)
	print("reparto animado: %d pasos" % r.deal_seq.size())
	while r.phase == "bid":
		r.bid(r.turn, 1 if r.turn == 0 else 0)
	print("contrato %d de %d" % [r.contract, r.taker])
	print("descarte valido: ", r.discard(TarotTutorial.discard()))
	var ai := TarotAI.new(5)
	var sc := TarotTutorial.script()
	for t in sc.size():
		for e in sc[t]:
			if r.turn != e[0]:
				print("ERROR baza %d: le toca a %d y el guion dice %d" % [t, r.turn, e[0]])
			var ok: bool = e[1] in r.legal(e[0])
			if not ok:
				print("ERROR baza %d: %s no es legal para %d (legales %s)" % [t, Deck.name(e[1]), e[0], str(r.legal(e[0]).map(func(c): return Deck.name(c)))])
			var res := r.play(e[0], e[1])
			if res.has("winner"):
				print("baza %d gana %d" % [t, res.winner])
	while r.phase == "play":
		r.play(r.turn, ai.quick(r, r.turn))
	var s := r.score()
	print("puntos %.1f · necesita %.1f · grandes %d · gana %s · por jugador %s" % [s.half / 2.0, s.need / 2.0, s.oudlers, str(s.won), str(s.per)])
	quit()
