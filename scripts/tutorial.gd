class_name TarotTutorial
extends RefCounted
## Tutorial guiado: un reparto fijo preparado a mano y un guion de seis bazas. En cada una el jugador juega la
## carta que toca (solo esa se puede elegir) y el Loco explica por qué; los rivales juegan cartas preparadas para
## enseñar servir, fallar, montar y el Loco. Después, la mano se termina sola y se explica el recuento.
## Asientos: 0 = tú (abajo), 1 = izquierda, 2 = arriba, 3 = derecha. Reparte el 3, así que sales tú.

const DEALER := 3


static func B(v: int) -> int:
	return Deck.minor(0, v)


static func C(v: int) -> int:
	return Deck.minor(1, v)


static func E(v: int) -> int:
	return Deck.minor(2, v)


static func O(v: int) -> int:
	return Deck.minor(3, v)


static func hands() -> Array:
	return [
		# Tú: 7 triunfos (con el 21 y el 1), tres reyes y cartas bajas que apartarás
		[21, 19, 18, 17, 15, 5, 1, B(14), C(14), O(14), O(13), O(2), E(5), E(8), B(2), C(3), B(12), C(12)],
		# Izquierda: sin copas (fallará tu rey), muchos oros, triunfos bajos
		[B(3), 6, E(10), 8, O(12), 13, 2, 7, O(1), O(3), O(4), O(5), O(6), O(7), O(9), O(10), O(11), B(1)],
		# Arriba: sin oros, con el Loco
		[B(7), C(4), E(2), 3, 14, 12, 9, 0, C(1), C(2), C(5), C(6), C(7), E(1), E(4), E(7), B(5), B(6)],
		# Derecha: sin oros, con el 16 para montar
		[B(11), C(9), E(13), 11, 16, 4, 10, C(8), C(10), C(11), E(9), E(11), E(12), E(14), B(8), B(9), B(10), B(13)],
	]


static func chien() -> Array:
	return [20, C(13), E(3), E(6), B(4), O(8)]


static func discard() -> Array:
	return [E(5), E(8), E(3), E(6), B(2), C(3)]


## Guion: por baza, las cuatro jugadas en orden [asiento, carta].
static func script() -> Array:
	return [
		[[0, B(14)], [1, B(3)], [2, B(7)], [3, B(11)]],
		[[0, C(14)], [1, 6], [2, C(4)], [3, C(9)]],
		[[1, E(10)], [2, E(2)], [3, E(13)], [0, 5]],
		[[0, 21], [1, 8], [2, 3], [3, 11]],
		[[0, O(2)], [1, O(12)], [2, 14], [3, 16]],
		[[3, 4], [0, 17], [1, 13], [2, 0]],
	]


static func scripted_card(trick: int, seat: int) -> int:
	var sc := script()
	if trick < 0 or trick >= sc.size():
		return -1
	for e in sc[trick]:
		if e[0] == seat:
			return e[1]
	return -1


## Mensajes del Loco. Claves: t<baza> = tu turno, o<baza>_<asiento> = tras una jugada de otro, a<baza> = al cerrar la baza.
const MSG := {
	"t0": ["SALES TU, ASI QUE TU CARTA DECIDE QUE PALO MANDA EN ESTA BAZA.",
		"JUEGA EL REY DE BASTOS (BRILLA EN TU MANO). ES LA CARTA MAS ALTA DE",
		"BASTOS: LOS DEMAS TENDRAN QUE ECHAR BASTOS Y NINGUNO PODRA GANARLE.",
		"SOLO PERDERIA SI ALGUIEN NO TUVIERA BASTOS Y JUGARA UN TRIUNFO."],
	"a0": ["¡BAZA PARA TI! TODOS ECHARON BASTOS Y TU REY ERA EL MAS ALTO.",
		"TE LLEVAS EL REY (4,5 PUNTOS) Y LA SOTA DE ERMITAÑO (1,5).",
		"QUIEN GANA UNA BAZA SALE EN LA SIGUIENTE: VUELVES A EMPEZAR TU."],
	"t1": ["AHORA JUEGA EL REY DE COPAS. CON EL DE BASTOS FUNCIONO...",
		"PERO FIJATE BIEN EN LO QUE HACE MAGO."],
	"o1_1": ["¡MAGO NO TIENE NI UNA COPA! CUANDO NO TIENES DEL PALO QUE MANDA,",
		"ESTAS OBLIGADO A JUGAR UN TRIUNFO: SE LLAMA FALLAR.",
		"Y UN TRIUNFO, AUNQUE SEA EL 6, GANA A CUALQUIER CARTA DE PALO."],
	"a1": ["MAGO GANA CON SU TRIUNFO 6 Y SE LLEVA TU REY DE COPAS.",
		"LECCION: UN REY SOLO ES SEGURO SI NADIE PUEDE FALLARLO.",
		"AHORA SALE MAGO, PORQUE HA GANADO."],
	"o2_3": ["MAGO HA SALIDO CON ESPADAS, ASI QUE MANDAN ESPADAS.",
		"PAPISA Y ERMITAÑO TENIAN ESPADAS Y HAN TENIDO QUE ECHARLAS.",
		"ERMITAÑO VA GANANDO CON SU REINA... PERO AHORA TE TOCA A TI."],
	"t2": ["¡TU NO TIENES ESPADAS! LAS APARTASTE AL PRINCIPIO, Y POR ESO",
		"AHORA PUEDES FALLAR Y GANAR LA BAZA. JUEGA EL TRIUNFO 5: ES TU",
		"TRIUNFO MAS BAJO Y YA BASTA PARA GANAR, ASI GUARDAS LOS ALTOS.",
		"(DESPUES DE TI YA NO JUEGA NADIE: ERES EL ULTIMO DE LA BAZA.)"],
	"a2": ["¡TE LLEVAS LA REINA DE ESPADAS (3,5 PUNTOS) CON UN TRIUNFO PEQUEÑO!",
		"ESTO ES LO QUE BUSCABAMOS AL APARTAR TODAS TUS ESPADAS."],
	"t3": ["AHORA SAL CON EL 21, EL MUNDO: LA CARTA MAS FUERTE DEL JUEGO.",
		"NADIE PUEDE GANARLA. Y COMO SALES CON TRIUNFO, LOS DEMAS TIENEN",
		"QUE ECHAR TRIUNFOS: ASI LES QUITAS LOS SUYOS Y LUEGO NO PODRAN",
		"FALLAR TUS CARTAS BUENAS. (CADA ARCANO TIENE SU ANIMACION.)"],
	"a3": ["CON EL 21 TE LLEVAS 4,5 PUNTOS Y TRES TRIUNFOS DE LOS RIVALES.",
		"EL 1, EL 21 Y YO SOMOS LAS TRES CARTAS GRANDES: CUANTAS MAS",
		"TENGAS AL FINAL, MENOS PUNTOS NECESITARAS PARA GANAR."],
	"t4": ["JUEGA EL 2 DE OROS: UNA CARTA BAJA QUE NO TE IMPORTA PERDER.",
		"VAS A VER QUE ES MONTAR."],
	"o4_2": ["PAPISA NO TIENE OROS, ASI QUE FALLA CON EL TRIUNFO 14."],
	"o4_3": ["ERMITAÑO TAMPOCO TIENE OROS. COMO YA HAY UN TRIUNFO EN LA MESA",
		"(EL 14), ESTA OBLIGADO A PONER UNO MAS ALTO SI LO TIENE:",
		"ESO ES MONTAR. PONE EL 16 Y SE LLEVA LA BAZA."],
	"a4": ["HAS PERDIDO ESTA BAZA, PERO SOLO REGALASTE TU 2 DE OROS (0,5).",
		"NO HACE FALTA GANARLAS TODAS: LO QUE CUENTA SON LOS PUNTOS."],
	"t5": ["ERMITAÑO HA SALIDO CON TRIUNFO (EL 4), ASI QUE MANDA TRIUNFO.",
		"TIENES QUE JUGAR UN TRIUNFO MAS ALTO QUE EL QUE VA GANANDO.",
		"JUEGA EL 17: ES ALTO, Y A MAGO Y PAPISA NO LES QUEDA NINGUNO",
		"MAYOR, ASI QUE NADIE PODRA SUPERARTE."],
	"o5_2": ["¡PAPISA ME HA JUGADO A MI, EL LOCO! SE ME PUEDE JUGAR SIEMPRE,",
		"SIN SEGUIR NINGUNA REGLA. NUNCA GANO LA BAZA, PERO VUELVO AL",
		"MONTON DE QUIEN ME JUEGA: ASI NO PIERDE UNA CARTA BUENA."],
	"a5": ["¡BAZA PARA TI CON EL 17! YA CONOCES LAS REGLAS IMPORTANTES:",
		"SERVIR EL PALO QUE MANDA, FALLAR CON TRIUNFO, MONTAR Y EL LOCO.",
		"EL RESTO DE LA MANO LO JUEGO YO POR TI, RAPIDO. MIRA COMO SUBE",
		"TU BARRA DE PUNTOS ARRIBA A LA IZQUIERDA."],
}
