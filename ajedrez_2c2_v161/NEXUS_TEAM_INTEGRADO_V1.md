# NEXUS-TEAM integrado — V1

NEXUS-TEAM ya está integrado como sistema competitivo exclusivo de 2c2.

## Separación

- 1c1 conserva su propio rating/copas/racha.
- 2c2 usa NEXUS-TEAM.
- Una partida 1c1 no toca ningún estado 2c2.
- Una partida 2c2 no toca ningún estado 1c1.

## Jugador 2c2

Además del rating visible se guardan:

- incertidumbre;
- volatilidad;
- forma;
- última actividad;
- versión del modelo.

La inactividad aumenta incertidumbre; no quita rating directamente.

## Parejas

Cada pareja exacta tiene estado propio:

- `pair_strength`;
- `pair_uncertainty`;
- `pair_effect` limitado a ±120;
- partidas y W/D/L;
- pico de fuerza;
- última actividad.

A+B y B+A comparten identidad canónica. A+B y A+C son estados independientes.

## Pareja actual

`current_pair_id` identifica la pareja usada actualmente. Cambiar de compañero no reinicia ni penaliza al jugador y conserva todos los historiales anteriores.

## Mejor pareja

`best_pair_id` solo se declara cuando existe evidencia mínima de 3 partidas para evitar coronar como “mejor pareja” una sola partida afortunada.

## Rankings

- ranking individual 2c2: fuerza individual 2c2;
- ranking de parejas: `pair_strength` de cada pareja exacta;
- las parejas no transfieren puntos al rating individual.

El perfil muestra pareja actual, mejor pareja y sus posiciones. El ranking de parejas marca las entradas propias correspondientes.

## Copas

Se conservó la capa de copas/progresión existente para evitar cambiar reglas no definidas. El nuevo modelo de rating no convierte estadísticas de gameplay en puntos de rating.

## Reglas del 2c2 intactas

NEXUS-TEAM no modifica turnos, equipos, movimientos legales, Sugerir, Cambio, comunicación, victoria, derrota ni tablas.
