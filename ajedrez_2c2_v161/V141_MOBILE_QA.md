# Ajedrez 2c2 — V141: QA visual, scroll táctil y pantallas responsivas

## Resumen
La vista previa gráfica bajo Xvfb y los gestos de desplazamiento revelaron varios defectos que las pruebas de contrato anteriores no detectaban. Se corrigieron en el proyecto V141 y se añadieron pruebas de regresión para que no vuelvan a pasar inadvertidos.

## Cambios principales

1. **Gestos táctiles globales:** al arrastrar sobre un botón o tarjeta, el scroll toma el gesto al superar el umbral; soltar después de arrastrar no activa el botón. Los toques breves siguen funcionando. Si el eje dominante no existe en el contenedor, se usa el eje disponible.
2. **Inicio en vertical:** se corrigió el ancho excedido que hacía que el contenido se saliera de la pantalla. El subtítulo y la actividad mensual ahora se ajustan a la anchura disponible. El scroll reserva el espacio de la navegación inferior.
3. **Clubes:** las filas internas de las tarjetas ahora llenan el botón en lugar de colapsar en columnas de una letra. Las tarjetas privadas y por invitación tienen altura suficiente para que la información envuelta no se monte sobre la siguiente al deslizar.
4. **Amigos:** se corrigió la distribución de las tarjetas para mantener el nombre y el estado en una fila legible.
5. **Miembros:** el listado ahora usa el ancho completo disponible. Cada tarjeta separa la identidad de las acciones, evitando que «PERFIL», «ROL» o «EXPULSAR» se compriman en columnas verticales enormes. Se reservó el espacio de navegación inferior.
6. **Orientación horizontal:** la barra lateral tenía un ancho real de 356 px aunque estaba diseñada para 160 px. Se sustituyó su contenedor de tamaño dependiente del contenido por un `Panel` de ancho fijo y se creó un helper compartido para que Club, Chat, Miembros, Amigos, Más, Perfil y visor de partidas dejen libre el área de navegación lateral.
7. **Cambio de pantalla:** el callback diferido de reconstrucción del historial de Inicio ahora comprueba que la escena siga en el árbol después de cada `await`; se evitó el error al navegar mientras la reconstrucción estaba pendiente.
8. **Informes QA:** se conserva la exportación automática del paquete de diagnóstico al cerrar normalmente y la recuperación automática en el siguiente inicio si quedó la marca de una sesión interrumpida. El diario identifica esta versión como V141.

## Pruebas ejecutadas

| Suite | Resultado |
|---|---:|
| Importación del editor Godot 4.7.2 | Exit 0, sin errores de análisis GDScript |
| `v141_mobile_layout_tests.gd` | 24 OK / 0 fallidas |
| `mobile_scroll_gesture_v141_tests.gd` | 6 OK / 0 fallidas |
| `home_scroll_v69_tests.gd` | 28 OK / 0 fallidas |
| `v58_board_first_hud_tests.gd` | 50 OK / 0 fallidas |
| `v134_agent_modularity_tests.gd` | 12 OK / 0 fallidas |
| `v135_system_audit_tests.gd` | 14 OK / 0 fallidas |
| `v141_landscape_layout_tests.gd` con viewport gráfico horizontal | 23 OK / 0 fallidas |
| Arranque de humo de 600 frames | Exit 0, sin errores GDScript |

Las seis suites principales suman **134 comprobaciones aprobadas** en la pasada de regresión. Las 23 comprobaciones horizontales se ejecutaron por separado con Xvfb en una ventana gráfica apaisada.

## Revisión visual y desplazamiento
Se capturaron e inspeccionaron Inicio arriba y después de deslizar; la lista de Clubes arriba y en una posición avanzada; Amigos; Más; el chat del club; Miembros; y las vistas apaisadas de Inicio, Clubes, Chat y Miembros. La prueba automatizada de toque también comprobó que un arrastre que comienza encima de «JUGAR» desplaza el contenido y no activa el botón, mientras que un toque corto sí lo activa.

Las capturas de evidencia se incluyen en `qa_previews/v141/` dentro del ZIP. También se entrega una previsualización en mosaico por separado.

## Limitaciones conocidas
- La prueba visual se ejecutó en Linux/Xvfb, simulando tamaños de pantalla móviles; **no equivale a una prueba táctil en un Android físico**.
- El error de editor `text_edit.cpp:6981` sobre `p_gutter = -1` no se reprodujo en esta pasada; no se marca como resuelto.
- El entorno gráfico no dispone de un dispositivo ALSA real y Godot recurrió al audio dummy durante las capturas. Esto no produjo errores GDScript ni afectó la comprobación visual.
- No se alteraron las reglas de turno del ajedrez ni las reglas 2c2.
