# V96 — Corrección de relleno de piezas de skin

## Cambio solicitado
La skin opcional `graphite_gold` conserva el tablero y la identidad visual de V95, pero sus piezas ahora son sólidas:

- Blancas: silueta completamente rellena de blanco + detalles amarillos/dorados.
- Negras: silueta completamente rellena de negro profundo + contorno azul acero oscuro.
- La skin clásica original no se modifica y continúa siendo el valor predeterminado.

## Arquitectura
No se cambió la lógica de ajedrez ni la selección de skins. Solo se actualizaron los 12 PNG de `assets/pieces/skin_graphite_gold/` y se añadió una prueba específica `tests/filled_piece_skin_v96_tests.gd`.

## QA real
- Godot: 4.7.2.stable.official.ed1daf0bf.
- `filled_piece_skin_v96_tests.gd`: 24/24 OK.
- `default_skin_v93_tests.gd`: 37/37 OK.
- `run_tests.gd`: 39/39 OK.
- `movement_bot_regression_tests.gd`: 21/21 OK.
- Captura gráfica real con Xvfb + OpenGL llvmpipe: tablero `graphite_gold` inspeccionado visualmente; piezas blancas muestran relleno blanco y detalles dorados; piezas negras muestran relleno oscuro y contorno azul acero.
- Debugger: sin SCRIPT ERROR, Parse Error, Failed loading resource, leak u orphan detectado en las ejecuciones realizadas. Único warning gráfico: V-Sync no disponible en el driver virtual.
- Se compararon los PNG clásicos contra V95: ningún asset clásico cambió.
