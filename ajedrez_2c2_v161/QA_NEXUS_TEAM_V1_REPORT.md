# QA NEXUS-TEAM V1

Fecha: 2026-10-04
Motor: Godot 4.7.2

## Pruebas específicas

- NEXUS-TEAM: 27 OK / 0 fallaron
- Competitive legacy/compatibilidad: 34 OK / 0 fallaron
- Account Hub: 149 OK / 0 fallaron

## Regresión general

- Core runner: 39 OK / 0 fallaron
- Bot difficulty: 39/39
- Bot integration: 6/6
- Movement/Bot regression: 21/21
- UI regression: 53/53
- Visual responsive audit: 1392/1392
- Responsive touch: 30/30
- Responsive mode menu: 37/37
- Orientation/layout: 22/22
- Navigation: 17/17
- Storage: 18/18
- Runtime service safety: 4/4
- Tandas 5-7: 23/23
- Tanda 8 stress: 5360/5360
- Tanda 9 stability: 19/19
- Matchmaking: 8/8
- Online setup: 37/37
- Online matchmaking shell: 3/3
- Match history: 5/5
- V49 replay mobile: 10/10
- V50 suggestion flow: 19/19
- V56 1c1 progression: 5/5
- V57 1c1 presentation: 5/5
- V58 Board First HUD: 42/42
- V59 gameplay HUD: 25/25
- V60 orientation/chat/actions: 15/15
- V61 suggestion compact: 22/22

## Invariantes validadas

- 1c1 y 2c2 permanecen aislados.
- A+B y B+A comparten estado.
- A+B y A+C conservan historiales independientes.
- Cambiar compañero no altera directamente la fuerza individual.
- Pareja nueva tiene incertidumbre propia alta.
- Inactividad aumenta incertidumbre.
- `pair_effect` permanece dentro de ±120.
- El ranking individual no consume `pair_strength`.
- El ranking de parejas sí consume `pair_strength`.
- Pareja actual y mejor pareja son estados diferentes.
- Mejor pareja no se valida antes de 3 partidas.
- Las pruebas del juego general continúan verdes.

## Advertencias no críticas

Algunos tests pueden emitir warnings de teardown (`ObjectDB leaked`) o de entorno de audio/headless. No hubo aserciones fallidas asociadas a ellos.
