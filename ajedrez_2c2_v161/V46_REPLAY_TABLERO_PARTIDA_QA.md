# V46 — Replay con geometría de tablero de Partida

## Objetivo
La pantalla de Replay fue corregida para que el tablero siga el mismo comportamiento geométrico que el tablero de la pantalla de partida, en lugar de quedar dentro de una tarjeta/panel propio.

## Distribución
- Movimientos realizados: arriba del tablero, como texto de navegación horizontal, sin panel, fondo ni borde propio.
- Tablero: cuadrado 1:1; en vertical usa todo el ancho disponible, igual que `Board` en Partida.
- Navegación: inmediatamente debajo del tablero.
- Replay: dejó de heredar `PanelContainer`; no crea un marco propio alrededor de movimientos + tablero.
- En las pantallas de estudio (`replay` / `analysis`) se eliminó el margen lateral artificial del contenedor para permitir ancho completo.
- Se eliminó la tarjeta intermedia que envolvía el Replay dentro de Historial.

## Corrección adicional
Se reservó en el layout la altura completa del tablero. Antes, el siguiente elemento de la pantalla podía superponerse al tablero porque el control Replay no reservaba su altura real.

## Verificación Godot 4.7.2
- Parse/editor check: OK.
- `tests/replay_analysis_v35_tests.gd`: 3/3 OK.
- Comparación directa Partida vs Replay a 390×844: OK.
  - `Board` de Partida: `board_rect = (0, 200)`, tamaño lógico `720×720`.
  - Replay: tablero `720×720`, misma alineación horizontal `x=0`.
  - Movimientos quedan antes del tablero.
  - Navegación queda inmediatamente después del tablero.
- Captura visual: `/mnt/data/v46_replay_portrait.png`.

## Nota de entorno
La prueba visual se ejecutó con Godot 4.7.2 en escritorio mediante Xvfb/llvmpipe. La resolución física de captura fue 390×844; Godot mantiene un viewport lógico distinto por `canvas_items`, por lo que las comprobaciones geométricas se comparan en el mismo espacio lógico usado por la pantalla de Partida.
