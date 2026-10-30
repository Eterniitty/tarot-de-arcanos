# Tarot de Arcanos

Juego de bazas con las 78 cartas del tarot en pixel art, hecho en Godot 4.7 todo por código.

- **Tarot**: un jugador contra la IA (Fácil, Normal, Difícil, Experto), en el sofá con varios mandos, u online por Steam (partida rápida o sala con amigos).
- **Otros juegos con la misma baraja**: Blackjack y Siete y media contra la banca, en solitario u online hasta 4 jugadores.
- Personaje a medida, tutorial guiado y reglas ilustradas.

## Abrirlo

1. Instala [Godot 4.7](https://godotengine.org/) (versión estándar o .NET).
2. Abre `project.godot`. La primera vez Godot reimporta los recursos (la carpeta `.godot/` no está en el repo).
3. El online usa [GodotSteam](https://godotsteam.com/) (en `addons/godotsteam`, licencia MIT) y necesita Steam abierto. Sin Steam se puede probar por LAN con `--lan`.

## Herramientas

- `tools/train_ai.gd`: entrena la IA jugando contra sí misma y escribe `scripts/ai_params.gd`.
- `tools/levels_test.gd`: enfrenta dos niveles de IA y mide la diferencia.
