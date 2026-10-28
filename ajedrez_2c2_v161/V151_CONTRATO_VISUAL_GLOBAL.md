# V151 — Contrato visual global de tablero

## Objetivo
Unificar la escala de piezas y las señales visuales entre partida en vivo y análisis/replay. Las correcciones comunes se hacen en un contrato reutilizable, no en cada pantalla por separado.

## Cambios
- `core/visual/board_visual_contract.gd`: fuente común para la proporción de las piezas, colores semánticos de resaltado y duración de referencia de movimiento.
- `core/visual/board_visual_events.gd`: señales globales para cambios de estado, inicio/fin de animación, resaltado de casillas, selección y variaciones de análisis.
- `project.godot`: registra `BoardVisualEvents` como autoload.
- `ui/components/board.gd`: usa el contrato compartido para la escala de piezas y el color de sugerencias.
- `domain/replay/replay_board.gd`: usa la misma proporción de piezas que la partida y la misma clasificación de resaltado; publica cambios de estado y resaltado.
- `ui/components/game/piece_move_animator.gd`: publica los eventos globales de inicio y fin de animación de jugada.

## QA
- Godot 4.7.2 headless: 42 OK / 0 fallaron.
- Captura de análisis/replay generada mediante Xvfb.
- Las advertencias de audio/V-Sync corresponden al entorno virtual y se usa audio dummy.

## Límites
La animación existente de desplazamiento de piezas sigue implementada en el tablero de partida. Este ciclo prepara el contrato/eventos para que las pantallas se integren sin duplicar comportamiento, pero aún no convierte todas las animaciones del replay en una reproducción interpolada. Debe verificarse en dispositivo Android físico.
