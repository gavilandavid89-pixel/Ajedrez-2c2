# V35 — Reporte de pruebas

## Cambios validados
- Replay ya no se comporta como reproducción automática: tablero fijo, lista de jugadas, navegación manual y slider.
- Análisis separado de Replay: resumen de rendimiento + revisión interactiva.
- La jugada seleccionada actualiza el detalle de la jugada.
- `analysis_viewed` se marca solo al pulsar Analizar.
- Historial mantiene una sola acción primaria: `Analizar partida` y, tras analizar, `Ver`.
- Replay ofrece `Analizar`/`Ver análisis` en un botón compacto.
- Análisis ofrece acceso rápido `Ver partida`.
- Replay/Análisis ocultan el rail principal en modo enfocado para aprovechar el espacio del tablero.
- Paisaje y retrato usan layouts adaptativos distintos.

## Pruebas Godot 4.7.2
- `tests/run_tests.gd`: 38/38
- `tests/account_hub_tests.gd`: 144/144
- `tests/history_interface_v35_tests.gd`: 18/18
- `tests/navigation_v31_tests.gd`: 17/17
- `tests/personalization_tests.gd`: 14/14
- `tests/refine_quality_tests.gd`: 6/6
- `tests/storage_runtime_scene.tscn`: 10/10
- `tests/replay_analysis_v35_tests.gd`: 3/3

Total de estas baterías: 250/250.

## Validación visual
Capturas realizadas con Godot 4.7.2 + renderer gráfico bajo Xvfb:
- Historial vertical.
- Replay vertical.
- Análisis vertical con jugada seleccionada.
- Replay horizontal.
- Análisis horizontal.

## Límite de la validación
La prueba visual usa Linux/llvmpipe dentro del entorno de trabajo. Queda pendiente la comprobación final en Android físico para densidad, táctil y orientación real.
