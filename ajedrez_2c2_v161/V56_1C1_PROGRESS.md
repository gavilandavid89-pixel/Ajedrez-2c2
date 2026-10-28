# V56 — Progreso competitivo 1c1 refinado

## Cambios

- Corregido un bug del historial: las partidas 1c1 ahora guardan `rating_after` y `cups_after` desde `individual_1c1`, no desde el bloque 2c2.
- Añadida racha de victorias 1c1, aislada del 2c2. Una derrota o tablas reinicia la racha.
- El menú principal muestra rating, liga, copas, racha y distancia hasta la siguiente liga para 1c1.
- El resultado de una partida 1c1 muestra cambio de rating/copas, totales posteriores, liga y racha.
- Los resultados 2c2 conservan su presentación y mecánicas.

## Límites

- No se modificó ninguna regla del 2c2.
- No se modificó la mecánica Sugerir.
- No se modificaron turnos, equipos, compañeros, legalidad ni comunicación del 2c2.

## QA previsto

- Suite competitiva
- Suite V56 específica 1c1
- UI regression
- Responsive mode menu
- Core runner
