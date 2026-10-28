# Test report — V146

Fecha: 2026-10-17  
Godot: `4.7.2.stable.official.ed1daf0bf`  
Renderizado de capturas: Xvfb + OpenGL Compatibility (`opengl3`, `gl_compatibility`).  
Audio: `Dummy` para el entorno virtual.

## Resultado

Todas las suites listadas abajo finalizaron con código de salida 0 y sin fallos en sus mensajes finales. La suite `account_hub_tests.gd` ahora espera a que termine `_ready()`/la carga persistida del Autoload `PlayerData` antes de limpiar el historial de prueba. Antes, `SceneTree._initialize()` podía ejecutarse demasiado pronto y dejar que registros de una ejecución anterior afectaran las aserciones. Tras ese ajuste, la suite aprobó 149/149 en dos ejecuciones Xvfb consecutivas.

| Suite | Resultado |
|---|---:|
| `tests/run_tests.gd` | 42/42 |
| `tests/v102_board_centering_tests.gd` | 58/58 |
| `tests/v141_mobile_layout_tests.gd` | 24/24 |
| `tests/v141_landscape_layout_tests.gd` | 33/33 |
| `tests/mobile_scroll_gesture_v141_tests.gd` | 6/6 |
| `tests/v145_responsive_content_scale_tests.gd` | 4/4 |
| `tests/v145_social_ui_factory_tests.gd` | 7/7 |
| `tests/v145_responsive_margin_lifecycle_tests.gd` | 8/8 |
| `tests/v144_professional_hud_tests.gd` | 10/10 |
| `tests/v134_agent_modularity_tests.gd` | 12/12 |
| `tests/v135_system_audit_tests.gd` | 14/14 |
| `tests/v142_mobile_ui_regression_tests.gd` | 11/11 |
| `tests/v131_offline_diagnostics_panel_tests.gd` | 6/6 |
| `tests/v146_board_layout_tests.gd` | 44/44 |
| `tests/v146_social_screen_fit_tests.gd` | 77/77 |
| `tests/account_hub_tests.gd` | 149/149 |

Los recuentos se suman aquí para facilitar el registro, pero algunas suites se solapan y no equivalen a casos únicos. La suite general solo cubre el conjunto que su runner conoce; no es una certificación total del producto.

## Arranque e importación

- `--headless --editor --path . --quit`: código de salida 0 al importar/escANear el proyecto después de los cambios.
- Escena principal bajo Xvfb, OpenGL Compatibility, `--quit-after 100`: código de salida 0.
- Capturas de pantallas sociales en vertical y horizontal: 9 pantallas por orientación, salida 0.
- Captura de HUD de partida en vertical y horizontal: salida 0.
- Se generaron 20 capturas bajo `qa_previews/v146/`.

Los lanzamientos Xvfb imprimen un aviso de VSync no compatible con el driver virtual. No afectó a la salida de las capturas. El editor gráfico inicializado con el driver por defecto tuvo un error de extensión de superficie Vulkan en el host; para las capturas se forzó OpenGL Compatibility y funcionó correctamente.

## Límites de lo que demuestran estas pruebas

- Xvfb y el viewport virtual no sustituyen un teléfono Android físico ni confirman la ergonomía real de los dedos/teclado virtual.
- Esta tanda es visual: no implementa un servidor autoritativo ni prueba matchmaking/reconexión online en red real.
- La geometría del tablero se preserva cuadrada. En vertical ocupa el ancho disponible; en horizontal se maximiza por altura y usa laterales para controles, evitando deformar casillas o recortar filas/columnas.
- Se debe volver a ejecutar la batería si se modifica `layout_metrics.gd`, `game_hud_layout.gd`, `ResponsiveContentScale`, `ResponsiveMarginController`, la fábrica social o las escenas asociadas.
