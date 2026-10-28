# V59 — Gameplay HUD & Mobile Refactor

## Objetivo
Reducir ruido visual durante la partida, priorizar el tablero y desacoplar controles secundarios en escenas independientes.

## Cambios
- `Rendirse` y `Tablas` viven en `GameActionMenu` como escena independiente.
- `ChatPanel` es una escena independiente y funciona en 1c1 online y 2c2.
- `Sugerir` y `Cambio` solo existen en 2c2.
- El jugador se muestra como avatar + nombre (máximo 10 caracteres), sin tarjeta/fondo.
- El reloj es independiente del bloque del jugador.
- Se eliminó el indicador textual `TU TURNO/TURNO RIVAL`; el reloj activo recibe un énfasis visual sutil.
- En móvil vertical el tablero ocupa todo el ancho y conserva proporción cuadrada.
- El chat aparece debajo del tablero en vertical para no cubrirlo.
- En horizontal 2c2 los cuatro jugadores se apilan en los laterales para conservar legibilidad.
- Las pantallas secundarias/controles se mantienen desacoplados para reducir el acoplamiento del árbol principal y facilitar futuras optimizaciones de navegación.

## Mecánicas protegidas
No se modificaron reglas de 2c2, turnos, equipos, compañeros, Sugerir, Cambio, legalidad, victoria/derrota ni comunicación de compañero.

## Validación
- Core: 39/39
- UI regression: 53/53
- Visual responsive: 1392/1392
- V59 HUD: 25/25
- Movimiento/Bots: 21/21
- Sugerencias V50: 19/19
- Touch targets: 30/30
- Competitivo: 34/34
- Presentación 1c1: 5/5
- Board First HUD: 42/42

Las advertencias ALSA/VSync pertenecen al entorno de renderizado de laboratorio (llvmpipe/Xvfb) y no son fallos funcionales.
