# V158 — Contexto global y layout compartido

## Objetivo

Conservar identidad, reloj e información del resultado como datos de la partida, no como estado privado de Replay o Analysis. Mantener el tablero con la misma escala base de `ChessLayoutMetrics` y una estructura visual consistente entre partida y replay.

## Sistemas añadidos

- `core/context/match_context_service.gd` (autoload `MatchContext`): snapshot defensivo de metadatos, jugadores, relojes, historial de relojes por jugada y resultado.
- `core/events/match_events.gd` (autoload `MatchEvents`): eventos semánticos para carga/fin de partida, jugadores, relojes, replay, navegación y análisis.
- `ui/components/player/player_header.gd`: componente compartido de cabecera que reutiliza `PlayerCard` y muestra rating y reloj.

## Integración

- La partida publica snapshots de reloj y actualiza jugadores a través de `MatchContext`.
- El resultado guardado incluye colores por slot, relojes y el historial de relojes capturado durante la partida.
- Replay restaura los nombres, avatares, ratings y relojes desde los metadatos guardados; al navegar, selecciona el snapshot de reloj correspondiente a la jugada.
- Replay y análisis comparten `ChessLayoutMetrics` como base de tamaño del tablero.
- Replay muestra jugadores, relojes y resultado. Al entrar en análisis, oculta las cabeceras y el resultado para priorizar el tablero; volver a Replay los restaura.
- El botón «Analizar partida» sigue siendo una acción explícita y no inicia el motor automáticamente.

## Eventos principales

`MatchEvents` expone `match_loaded`, `match_started`, `match_finished`, `match_result_changed`, `player_updated`, `clock_updated`, `replay_started`, `replay_paused`, `replay_position_changed`, `replay_speed_changed`, `analysis_requested`, `analysis_started`, `analysis_progress`, `analysis_completed` y `variation_selected`.

Los payloads de diccionarios/arrays se copian antes de emitirse cuando corresponde. Las coordenadas y los valores de reloj se normalizan en los servicios que los publican.

## Validación ejecutada

- Suite principal: 42 OK / 0 fallos.
- Separación Replay/Analysis: 9 OK / 0 fallos.
- Contexto global y cabecera: 7 OK / 0 fallos.
- Capturas reales con Godot 4.7.2 bajo Xvfb: partida en vivo, replay con metadatos y modo análisis sin cabeceras.
- La captura en este entorno muestra errores de inicialización de audio ALSA; Godot cae al driver de audio dummy. Esto no afecta a la validación visual, pero no equivale a una prueba de audio en dispositivo Android.

## Pendiente

- Integrar el mismo componente de cabecera dentro del HUD en vivo (el HUD actual ya muestra las tarjetas y relojes, pero mantiene su layout heredado para equipos 2c2).
- Persistir historial de reloj para partidas antiguas que no guardaron snapshots; en esos casos se muestran los tiempos finales disponibles o `0:00` si no hay datos.
- Prueba física en Android y verificación del rendimiento del motor en el dispositivo objetivo.
