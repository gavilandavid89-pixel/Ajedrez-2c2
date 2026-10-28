# V55 — Competitivo 1c1 independiente

## Objetivo

El modo 1c1 competitivo tiene ahora un progreso completamente separado del 2c2.

- 1c1: `individual_1c1`
- 2c2: `individual`
- Parejas 2c2: `pair_records`

Una partida 1c1 nunca modifica el rating o las copas 2c2, y una partida 2c2 nunca modifica el rating o las copas 1c1.

## Persistencia

`PlayerData` guarda ambos bloques en el mismo perfil, pero como estructuras independientes. El cache de perfil también expone `rating_1c1` y `cups_1c1`.

## Ranking

Se prepararon rankings separados:

- `individual_1c1_rank_rows()`
- `individual_1c1_cup_rank_rows()`
- `individual_rank_rows()` (2c2 individual)
- `individual_cup_rank_rows()` (2c2 individual)
- `pair_rank_rows()` (2c2 parejas)
- `pair_cup_rank_rows()` (2c2 parejas)

La pantalla de clasificaciones muestra explícitamente el modo para evitar mezclar posiciones.

## Matchmaking

El matchmaking local usa el rating correspondiente al modo:

- 2c2 → rating 2c2
- 1c1 → rating 1c1

## Migración

Los perfiles creados antes de V55 no tenían `individual_1c1`. Si existe historial competitivo, V55 reconstruye los bloques por modo utilizando los `rating_delta` y `cup_delta` guardados. Esto evita que las antiguas partidas 1c1 continúen inflando el progreso 2c2.

Si no existe historial suficiente, se mantiene un bloque 1c1 nuevo en 1000 rating / 0 copas.

## Límites respetados

- No se modificó ninguna regla del 2c2.
- No se modificó la mecánica Sugerir.
- No se alteró el sistema de parejas 2c2.
- No se activó lógica online real.
- Temporadas siguen preparadas, sin lógica definitiva.

## QA V55

- Competitive: 30/30
- Account Hub: 144/144
- UI regression: 12/12
- Mode Menu responsive: 27/27
- Responsive touch targets: 30/30
- Core runner: 39/39
- Tandas 5–7: 23/23
- Tanda 8: 5355/5355
- Tanda 9: 17/17
