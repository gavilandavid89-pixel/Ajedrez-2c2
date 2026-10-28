# Historial, Replay y análisis de partidas

## Historial
Cada partida finalizada conserva localmente sus datos de partida y su replay. La tarjeta del Historial muestra solo la información necesaria para identificarla: modalidad, resultado, fecha y rival/pareja. La lista de jugadas no se muestra aquí; se consulta dentro del Replay.

Cada registro tiene un único botón contextual:
- `Analizar partida` → cuando todavía no se ha realizado el análisis.
- `Ver` → después de analizar; abre la partida completa en Replay.

## Replay
El Replay contiene la partida completa y sus controles de navegación. En la parte inferior se utiliza una acción compacta:
- `Analizar` → abre el rendimiento final y marca el análisis como realizado.
- `Ver análisis` → cuando el análisis ya existe, permite volver a ese resumen sin ocupar espacio adicional.

Entrar al Replay no marca automáticamente una partida como analizada.

## Análisis
La pantalla de análisis no incrusta el Replay ni repite la lista de jugadas. Muestra el rendimiento final con los datos realmente guardados de la partida: resultado, estadísticas de actividad y progreso competitivo disponible.

Incluye un botón rápido `Ver partida` para abrir inmediatamente el Replay completo.

El análisis con motor queda separado hasta integrar un evaluador real; no se generan evaluaciones falsas.

## Persistencia
`analysis_viewed` forma parte de cada registro de partida y se guarda mediante `PlayerData`, por lo que el estado se conserva entre sesiones.
