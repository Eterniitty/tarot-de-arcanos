class_name TarotAIParams
## Lo aprendido por tools/train_ai.gd (se reescribe al entrenar; no editar a mano).

## Pesos de la subasta: margen esperado (puntos por multiplicador) según los rasgos de la mano,
## para [Pequeña/Guardia (con perro), Guardia sin, Guardia contra].
const BID_W := [
	[-88.4907, 24.9388, 11.2810, 18.9482, -4.4429, 5.8357, 2.8889, 0.9082, 8.0670, 2.8547, 1.1873, 0.0589, -4.3165, 0.9151, 1.5558, 1.0972, 3.1199],
	[-89.2216, 21.1782, 4.0842, 8.5397, -3.8714, 4.0847, 3.6596, 1.1613, 7.5491, 2.8107, 1.3662, -0.0698, -0.1163, 0.0848, 0.5122, 0.9847, 4.0148],
	[-93.6702, 16.7860, 5.0940, 8.2041, -3.1239, 3.3718, 2.7676, 0.7654, 6.4337, 2.6028, 1.2204, 0.1249, -0.0543, 0.1544, 0.4448, 0.7203, 3.0021],
]
## Umbrales de la subasta y ajustes de la política rápida de juego.
const PLAY := {"t1": -10.0, "t2": 6.0, "t3": 20.0, "t4": 30.0, "lead_trumps": 6, "lead_trump_min": 12, "partner_strong": 15, "excuse_pts": 5, "taker_long": 1, "def_long": 0, "king_lead": 1}
const TRAINING := "entrenado 2026-10-30 · 8000 repartos de subasta x12 manos · ajuste 2000 repartos x2 · validacion vs IA antigua +6.1 puntos por mano · subasta animada (tools/bid_profile.gd): 33% de repartos en blanco en vez de 63%, -0.6 puntos"
