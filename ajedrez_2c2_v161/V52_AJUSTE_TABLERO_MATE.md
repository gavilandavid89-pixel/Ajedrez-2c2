# V52 — Tablero de resultado y resaltado de mate

Cambios puntuales sobre V51:

- El resaltado de jaque mate ahora pinta la casilla completa con una capa roja translúcida.
- El borde rojo queda dentro de la casilla, sin crecer hacia fuera y alterar visualmente su tamaño.
- Al finalizar la partida, el tablero recalcula su layout y recupera el espacio que dejan los controles inferiores.
- En móvil corto (ej. 360x640) el tablero de resultado pasa de ~238 px a ~290 px de lado.
- El panel de resultado se compacta y queda inmediatamente debajo del tablero.
- El historial "Movimientos" se mantiene durante la partida, pero se oculta al mostrar el resultado para evitar solapamientos.
- No se modificaron reglas de ajedrez, Sugerir, turnos ni movimiento de piezas.

Pruebas Godot 4.7.2:
- 39/39 tests base
- 51/51 UI regression
- 19/19 flujo Sugerir
- 23/23 refinamiento
- 22/22 movimiento/bots
- 10/10 replay móvil
