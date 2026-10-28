# V58 — Board First HUD

## Objetivo
Rehacer la jerarquía del HUD móvil para que el tablero sea siempre el elemento principal.

## Cambios
- En portrait, el tablero ocupa todo el ancho del viewport y mantiene proporción 1:1.
- Eliminada la barra superior de modo/online/tiempo durante la partida.
- El reloj queda en un bloque independiente junto al jugador/equipo.
- El turno se comunica iluminando sutilmente el reloj activo con el tema visual existente.
- Eliminado `TU TURNO` / `TURNO RIVAL`.
- `Sugerir` y `Cambio` se muestran exclusivamente en 2c2.
- 1c1 conserva únicamente sus controles propios.
- En inicio, el perfil queda representado solo por su icono.
- Se conservaron controles compactos de navegación en partida para no depender de la barra superior retirada.
- Los jugadores 2c2 se adaptan a tarjetas compactas en móviles estrechos.

## Validación
- V58 board-first HUD: 42/42
- Responsive UI audit: 1368/1368
- Core: 39/39
- Movimiento/bots: 22/22
- Sugerir: 19/19
- Competitivo 1c1/2c2: 34/34
- Menú responsive: 37/37
- Historial/perfil smoke: 5/5
- Touch targets: 30/30
- Account Hub: 144/144
- Profile UI: 9/9
- Tandas 5-7: 23/23
- Bot suggestion timing: 8/8

La mecánica del 2c2 no fue modificada. La mecánica de Sugerir tampoco fue modificada.
