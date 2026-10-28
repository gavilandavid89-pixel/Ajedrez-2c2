# V35 — Análisis y Replay interactivos

## Objetivo
Dejar de tratar Replay y Análisis como reproducción de vídeo. Ambos usan un tablero estático/interactivo y navegación manual por posiciones.

## Replay
- Tablero fijo en la posición seleccionada.
- Lista de jugadas navegable y pulsable.
- Controles primera/anterior/siguiente/última posición.
- Slider para saltar de posición.
- Sin reproducción automática.
- Botón compacto inferior `Analizar` / `Ver análisis`.

## Análisis
- Resumen de rendimiento con datos realmente almacenados.
- Revisión interactiva del tablero y lista de jugadas.
- Inspector de la jugada seleccionada.
- Soporte preparado para `classification` y `evaluation` si un futuro motor los proporciona.
- No se inventan accuracy, blunders ni evaluaciones sin motor.
- Acceso rápido `Ver partida` al replay completo.

La interacción toma como referencia conceptual el Game Review y Analysis de Chess.com, que separan la revisión resumida y el análisis interactivo por jugadas, en lugar de reproducir la partida como vídeo. https://support.chess.com/en/articles/10328363-how-do-i-use-game-review-on-the-app
