# V45 — Replay: movimientos limpios

## Cambio visual
- La lista de movimientos queda directamente sobre el tablero.
- Se eliminó el panel/tarjeta que rodeaba la lista.
- Se eliminaron los bordes y fondos visibles de cada movimiento.
- La lista conserva desplazamiento horizontal y selección táctil.
- El tablero mantiene formato 1:1 y ocupa todo el ancho útil en vertical.
- La navegación queda inmediatamente debajo del tablero.

## QA
- Godot 4.7.2 estable.
- Proyecto cargado y clases registradas sin errores de script.
- Captura visual ejecutada a 390×844.
- Secuencia verificada: movimientos arriba → tablero → navegación abajo.
- No se añadieron elementos visuales nuevos a la zona de movimientos.

## Nota de entorno
La prueba visual usa Godot en Linux/Xvfb con renderizado llvmpipe. El aviso de ALSA corresponde al dispositivo de audio ausente del entorno de prueba y no a un error del replay.
