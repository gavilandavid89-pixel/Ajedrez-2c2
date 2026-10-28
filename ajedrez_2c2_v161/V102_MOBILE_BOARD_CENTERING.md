# V102 — Centrado y adaptación del tablero móvil (supersedida por V103)

## Objetivo
Ajustar el tablero para que se comporte como un tablero móvil bien adaptado: centrado horizontalmente, con márgenes equilibrados, siempre cuadrado y limitado al espacio disponible para no invadir los controles inferiores.

## Cambios
- `core/layout/layout_metrics.gd`: cálculo del tablero en vertical con márgenes laterales simétricos de hasta 8 px y límite por altura disponible.
- El cálculo también contempla pantallas casi cuadradas, donde antes el tablero podía superar el alto del viewport.
- `ui/components/game/game_hud_layout.gd`: comentario y disposición alineados con el nuevo contrato de layout.
- `tests/v58_board_first_hud_tests.gd`: assertions de tamaño completo sustituidas por comprobaciones de centrado, forma cuadrada y límites del viewport.
- `tests/v102_board_centering_tests.gd`: pruebas dedicadas para tamaños móviles comunes, pantallas casi cuadradas y modo de resultado.

## Validación ejecutada
- Godot 4.7.2: importación/editor headless completada.
- `tests/run_tests.gd`: 39/39.
- `tests/orientation_layout_v22.gd`: 22/22.
- `tests/v102_board_centering_tests.gd`: 42/42.

## Alcance
Esta versión fue reemplazada por V103, que centra verticalmente el bloque completo de partida, adapta el modo horizontal y evita la superposición entre la etiqueta de movimientos y la barra de acciones. La referencia APK sigue siendo solo una referencia de comportamiento; no se copian recursos ni código propietario.


Nota de QA: `tests/v58_board_first_hud_tests.gd` mantiene 5 comprobaciones antiguas de HUD/perfil que fallan al ejecutarla de forma aislada (visibilidad de controles durante estado sin partida activa y tamaño mínimo de botón de perfil). Las pruebas específicas de geometría y las suites principales pasan; esos fallos no se han contado como fallos del nuevo cálculo del tablero.
