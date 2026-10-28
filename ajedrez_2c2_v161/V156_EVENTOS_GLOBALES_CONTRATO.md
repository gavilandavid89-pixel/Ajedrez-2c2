# V156 — Contrato de eventos globales

## Objetivo
Completar la capa de eventos antes de ampliar el bot de análisis. Los eventos son contratos de comunicación; no sustituyen las reglas de ajedrez ni almacenan el estado canónico de una partida.

## Bus global de aplicación
`GlobalEvents` (`core/events/global_events.gd`, autoload) agrupa navegación de pantallas, preferencias, notificaciones, solicitudes de modal, operaciones con estado y conectividad. Los payloads de contexto/modal se copian de forma profunda.

## Bus visual de ajedrez
`BoardVisualEvents` (`core/visual/board_visual_events.gd`, autoload) agrupa eventos visuales compartidos:

- `board_state_changed`: snapshot de la vista; se copia de forma profunda.
- `square_highlight_changed`: origen, destino y categoría semántica (`last_move`, `selected`, `suggestion`, `error`). Los escaques se normalizan y validan.
- `piece_selected`: selección normalizada; `""` significa deselección explícita.
- `board_interaction_changed`: escaque seleccionado y destinos legales normalizados, sin duplicados.
- `board_presentation_changed`: orientación, tema del tablero y conjunto de piezas.
- `move_committed`: la lógica de juego ya aceptó/actualizó la jugada.
- `move_animation_started` / `move_animation_finished`: ciclo de animación, separado de la confirmación lógica.
- `analysis_variation_changed`: variante que desea presentar el módulo de análisis.
- `board_focus_requested`: petición para enfocar un escaque en una vista compatible.

Los emisores aceptan únicamente fuentes conocidas: `match`, `replay`, `analysis`, `study` y `puzzle`. Los movimientos y escaques se validan antes de publicar; los diccionarios/arrays expuestos se copian para reducir acoplamiento accidental.

## Integración real en esta versión
- La vista de partida publica snapshots, selección/deselección, destinos legales, cambios de orientación, resaltado del último movimiento y confirmación de jugada.
- El animador de partida publica el comienzo y el fin de la animación, diferenciados del evento de jugada confirmada.
- La vista de replay publica snapshots y resalta las casillas usando la categoría visual `suggestion`; la clasificación textual sigue siendo responsabilidad de la vista de replay.
- Los eventos globales son un autoload de la aplicación; las vistas consultan el nodo por ruta para seguir siendo instanciables en pruebas aisladas.

## Validación
- `tests/global_events_tests.gd`: 13 OK / 0 FAIL.
- `tests/run_tests.gd`: 42 OK / 0 FAIL.
- No hubo cambios visuales en V156; no se generó una captura nueva para esta iteración.

## Límites conocidos
Los módulos de análisis/estudio/puzzles aún no consumen todos los eventos ni comparten un único control interactivo de tablero. La próxima etapa debe migrarlos por separado y verificar que los eventos no creen ciclos ni dupliquen la autoridad del estado de partida.
