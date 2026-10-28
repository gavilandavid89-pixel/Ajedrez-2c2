# Ajedrez 2c2 — V138: corrección visual y diagnóstico automático

## Cambios

- **Inicio:** el contenido largo deja de centrarse verticalmente dentro del área desplazable. La lista empieza desde arriba, evitando que el título quede cortado al cambiar la escala/altura del dispositivo. El área de scroll deja de consumir eventos de controles ajenos en sus zonas vacías.
- **Club:** se limitó la altura del encabezado, se reservó ancho real para «Miembros», se redujo el área del compositor de chat a una fila compacta y se cambió «ENVIAR» por un botón de icono para evitar que el texto se apile verticalmente en móviles estrechos.
- **Chat vacío:** el estado vacío queda centrado en el área de conversación y explica que todavía no hay mensajes.
- **Informes automáticos:** el diario QA se sigue guardando en cada evento. Al cerrar normalmente, el supervisor genera `user://qa_supervisor_bundle.zip`. Si el proceso termina sin ejecutar el cierre (crash/cierre forzado), deja un marcador; al siguiente inicio detecta la sesión interrumpida, escribe el evento y exporta automáticamente el paquete de recuperación. No se requiere abrir el menú de diagnóstico para que el archivo se cree.
- **Privacidad/uso:** el paquete queda en el directorio privado de datos de Godot (`user://`), no se envía por red automáticamente. Puede compartirse después desde el dispositivo.

## Validación ejecutada con Godot 4.7.2

- Importación del editor: salida 0; sin errores de análisis.
- `tests/v134_agent_modularity_tests.gd`: **12 OK / 0 fallidas**.
- `tests/v135_system_audit_tests.gd`: **14 OK / 0 fallidas**.
- `tests/v58_board_first_hud_tests.gd`: **50 OK / 0 fallidas**.
- `tests/v138_visual_runtime_smoke.gd`: **9 OK / 0 fallidas**.
- Arranque headless de 120 frames: salida 0, sin errores de GDScript.
- Vista previa gráfica virtual de Club: comprobada; encabezado/compositor compactos y estado vacío centrado.
- El flujo de recuperación se ejercitó en el entorno de prueba: se detectó `previous_session_ended_uncleanly` y se registró `recovered_session_bundle_result` con `ok=true`.

## Límites conocidos

- No equivale a una certificación en el teléfono Android físico; todavía debe probarse el toque real y una partida completa en el dispositivo.
- La línea `text_edit.cpp:6981 - Index p_gutter = -1 ...` no se reprodujo en los arranques ni en las pruebas actuales. No se encontró una llamada del proyecto que manipule gutters; el log original también indica que el proceso de depuración se detuvo. Queda registrada como incidencia pendiente de reproducir, no como solucionada.
- El entorno virtual de escritorio no dispone de dispositivo de audio; los mensajes ALSA que aparecen allí son de infraestructura y no se reproducen en la prueba headless.

## Cómo recuperar el informe después de un cierre inesperado

1. Volver a abrir el juego una vez; el supervisor detecta el marcador y genera el paquete automáticamente.
2. El archivo se encuentra en `user://qa_supervisor_bundle.zip` dentro de los datos privados de la aplicación Godot.
3. El paquete contiene diario QA, manifiesto/capturas disponibles y resumen del observador táctil. La captura de pantalla está limitada a 20 por el cierre automático para evitar paquetes pesados.
