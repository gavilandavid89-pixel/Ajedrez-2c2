# V109 — Auditoría de tipografía, alineación y desbordes

## Cambios
- Se añadió la familia tipográfica Inter al proyecto y se configuró como fuente global de la interfaz.
- Se incluyó la licencia de la fuente en `assets/fonts/OFL-LICENSE.txt`.
- Se ajustó la jerarquía de tamaños de los títulos, secciones, botones y navegación compartida.
- Se aumentaron tamaños demasiado pequeños en etiquetas de pantallas sociales y de configuración.
- Se habilitó el ajuste de línea en las tarjetas de «Más opciones» para evitar que las descripciones corten el borde derecho.
- Se corrigió el ancho mínimo de «Preparado» en las filas de proveedores de cuenta para impedir que la palabra se parta.
- Se redujo la escala tipográfica extra del perfil/cuenta: el proyecto ya escala los elementos de `canvas_items`, y aplicar una segunda escala causaba tarjetas de estadísticas demasiado anchas.
- Se limitaron los textos de las tarjetas estadísticas y se ajustó su tamaño para que respeten el ancho disponible.
- Se añadió espacio al bloque de jugadores inferior del HUD de partida para que los nombres no se solapen con la barra de acciones.
- Se ajustó el tamaño de la barra lateral en horizontal y se mejoró la legibilidad de sus etiquetas.

## Inspección visual en ejecución
Revisadas mediante ejecución del proyecto en Godot, capturando la aplicación (sin editor visible):
- Inicio vertical y horizontal
- Más opciones
- Amigos
- Clubes
- Perfil público
- Perfil/cuenta con estadísticas
- Acceso a cuenta
- Selección de rival IA
- Tablero y HUD de partida

## Pruebas
- `tests/run_tests.gd`: 39/39
- `tests/orientation_layout_v22.gd`: 22/22
- `tests/full_screen_flow_audit_v87.gd`: 18/18; 247 interacciones revisadas

Las pruebas se realizaron con Godot 4.7.2 en entorno de escritorio Linux. La adaptación final debe confirmarse también en un teléfono Android físico; los vídeos adjuntos son grabaciones reales de la aplicación ejecutada en Godot, no del editor.
