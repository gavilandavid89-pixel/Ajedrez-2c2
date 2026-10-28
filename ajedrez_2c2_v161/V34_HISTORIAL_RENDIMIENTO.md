# V34 — Historial, Replay y Rendimiento

## Flujo definitivo

### Historial
Cada partida muestra un único botón contextual:

- `Analizar partida` → primera vez.
- `Ver` → después de que el análisis se haya realizado.

La tarjeta del historial **no muestra la lista ni el contador de jugadas**. Las jugadas se consultan dentro del Replay.

### Replay
Es la pantalla que muestra la partida completa y permite recorrer sus posiciones.

- Mientras no exista análisis: botón compacto inferior `Analizar`.
- Después del análisis: ese acceso cambia a `Ver análisis`.

Pulsar `Analizar` es lo que marca `analysis_viewed = true`; simplemente entrar al Replay no consume el análisis.

### Análisis
La pantalla de análisis no incrusta el Replay ni repite la lista de jugadas.

Muestra el rendimiento final usando datos ya guardados de la partida: resultado, actividad de juego y progreso competitivo disponible.

Al final incorpora un acceso rápido `Ver partida` para volver directamente al Replay completo.

## Persistencia
`analysis_viewed` continúa formando parte del registro individual de la partida. El estado sobrevive al cierre y reapertura de la aplicación mediante `PlayerData`.
