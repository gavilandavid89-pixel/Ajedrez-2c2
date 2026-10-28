# V42 — Verificación de V41 / Stockfish

## Resultado

- Godot 4.7.2: ejecución headless del conjunto principal: **39 OK / 0 fallaron**.
- Partida de prueba: **8 jugadas / 9 posiciones de replay** generadas correctamente.
- Bot Mateo: movimiento humano + turno del bot + movimiento del bot: **OK**.
- Interfaz de Replay/Análisis: renderizada en 390×844 y navegación hasta la posición 9: **OK**.
- El informe visual de análisis usado para esta captura fue un informe de prueba ya formado; **no se debe interpretar como una ejecución de Stockfish**.
- Stockfish incluido: binario real **Android ARM64 / AArch64**, verificado como ELF estático.

## Correcciones aplicadas

1. `bot_controller.gd` ahora precarga explícitamente `rules.gd` y `bot_data.gd`, evitando la resolución frágil de las clases globales durante la carga de `game_state.gd`.
2. La prueba del motor dejó de esperar falsamente que no existiera el binario real.
3. `stockfish_engine.gd` crea `user://engine/` antes de copiar el ejecutable.

## Límite de esta verificación

El entorno usado para esta prueba es **Linux x86_64**, mientras que el ejecutable distribuido es **Android ARM64**. Por eso el ELF no puede ejecutarse físicamente en este runner (produce `Exec format error`/código 126). La prueba real `uci -> bestmove` debe hacerse en Android ARM64.

No se declara Stockfish como funcional en Android hasta comprobar en un dispositivo/emulador ARM64 que devuelve `uciok`, `readyok` y `bestmove` durante una partida real.
