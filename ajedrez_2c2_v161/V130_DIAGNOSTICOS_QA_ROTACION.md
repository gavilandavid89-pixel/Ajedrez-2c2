# Ajedrez 2c2 V130 — Paquete QA íntegro

## Cambios
- El exportador QA incluye el diario actual y su segmento rotado `.1`. Antes, al superar el límite de tamaño del diario, el paquete podía omitir la parte anterior de la historia.
- Las capturas ahora añaden microsegundos al nombre para reducir colisiones entre capturas hechas en el mismo segundo o tras reiniciar la app.
- Se mantiene la restricción: la exportación manual de diagnóstico solo está disponible offline y se vuelve a comprobar al activar la acción.
- No se añade IA autónoma con capacidad de alterar partidas; los agentes son supervisores deterministas y los cambios competitivos siguen reservados al sistema autoritativo.

## Validación realizada con Godot 4.7.2
- `tests/v130_qa_bundle_rotation_tests.gd`: **4/4**.
- `tests/v129_offline_diagnostics_tests.gd`: **6/6**.
- `tests/v127_supervision_integration_tests.gd`: **15/15**.
- `tests/v128_journal_recovery_tests.gd`: **8/8**.
- `tests/v125_board_piece_supervisor_tests.gd`: **7/7**.
- `tests/v123_match_supervisor_tests.gd`: **22/22**.
- Total de suites ejecutadas en esta iteración: **62/62**.
- Importación del editor finalizó sin `SCRIPT ERROR`, `Parse Error` ni `ERROR:` en el registro.
- Ejecución headless de 300 frames terminó con código 0 y sin errores de scripts. Godot mostró únicamente el aviso de ejecución como administrador.

## Límites conocidos
- Esta validación headless no demuestra que cada detalle visual se vea perfecto en Android.
- La exportación crea `user://qa_supervisor_bundle.zip`; el compartirlo mediante el selector nativo de Android aún requiere integración específica.
- La captura automática no equivale a interceptar todos los errores del panel Debugger. Los errores de navegación instrumentados se registran, pero queda trabajo para instrumentar otras fuentes de error de runtime.
