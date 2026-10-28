# V127 — Integración total de supervisión y QA

## Objetivo
Conectar los agentes existentes al ciclo real de la aplicación, en lugar de dejarlos como utilidades aisladas.

## Cambios
- `App.change_scene()` informa la pantalla solo después de que la escena se cargó, terminó la transición y pasó un frame visible. Las capturas automáticas ya no se toman detrás de la capa negra de transición.
- `SupervisorHub.report_scene_ready()` centraliza la notificación de pantalla, la captura de la pantalla lista y el registro de fallos de captura.
- `SupervisorHub` intenta registrar también la escena principal inicial, que no pasa por `App.change_scene()`.
- `RuntimeServices.change_scene()` dejó de anunciar prematuramente una transición exitosa; sigue registrando fallos inmediatos.
- `ChessBoardView` envía sus auditorías mediante `SupervisorHub.audit_board()`. Si una anomalía estructural aparece o cambia, se solicita una captura diagnóstica en ejecución gráfica, evitando repetir la misma captura en cada redibujado.
- `SupervisorHub.audit_replay()` ofrece un punto central para revisar replays; `GameReviewService` ya utiliza el agente de replay compartido.
- `SupervisorHub.export_qa_bundle()` crea bajo demanda `user://qa_supervisor_bundle.zip` con el diario de diagnóstico, el manifiesto de capturas y hasta 40 capturas PNG recientes. Es una operación explícita para limitar CPU/almacenamiento en móviles modestos.
- Añadida `tests/v127_supervision_integration_tests.gd` para verificar el cableado entre agentes, el seguimiento de pantallas, auditorías y el ZIP exportable.

## Verificación
- Importación del proyecto con Godot 4.7.2: exit code 0, sin `SCRIPT ERROR`, `Parse Error` ni `ERROR:` en el registro de importación. Se mantiene el aviso de ejecución como root del entorno de pruebas.
- V127: 15/15.
- V126 capturas: 8/8.
- V125 tablero/piezas: 7/7.
- V124 miniagentes: 12/12.
- V123 supervisor: 22/22.
- V122 gracia: 25/25.
- V121 sesión/reconexión: 17/17.
- V120 turnos/reconexión/resultado: 16/16.
- V119 carreras de transición: 29/29.
- V118 integración de delegación: 22/22.
- V117 delegación 2c2: 32/32.
- V116 política de desconexión: 18/18.
- V115 idempotencia de resultado: 6/6.
- V114 transiciones: 13/13.
- V103 orientación responsive: 42/42.
- V102 distribución vertical del tablero: 54/54.
- Ejecución gráfica con Xvfb durante 15 segundos y audio dummy: el proceso se mantuvo activo hasta el límite de observación; sin errores de scripts ni `ERROR:`. Aparecen advertencias de V-Sync no disponible y ejecución como root, propias del entorno.

## Observación visual
La captura automática real del menú (`screen_mode_menu`, 720×720) se guardó correctamente. En la captura se aprecia una tarjeta de contenido parcialmente detrás de la barra inferior fija. Puede ser el comportamiento esperado de una pantalla desplazable, pero queda marcada como punto de revisión visual para comprobar que el contenido no quede inaccesible.

## Límites honestos
- No existe aún backend de partidas online real; las reglas de autoridad/desconexión siguen siendo una base local preparada para integración.
- El agente de interfaz registra navegación y puede ejecutar comprobaciones de layout que se le proporcionen; no tiene todavía visión artificial general capaz de entender cualquier pantalla.
- La captura automática se dispara al entrar en pantallas y cuando la auditoría del tablero detecta una anomalía estructural. No graba vídeo continuamente ni captura cada jugada.
- Los logs y las capturas se guardan en `user://`; el ZIP exportable es el mecanismo para compartirlos posteriormente.
