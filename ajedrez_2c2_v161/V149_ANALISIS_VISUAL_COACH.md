# V149 — Análisis visual y coach táctico modular

## Cambios
- La pantalla de revisión conserva el tablero como elemento principal y amplía la tarjeta contextual del coach para incluir una variante legible y una acción explícita para ver la mejor jugada calculada por Stockfish.
- La acción **VER MEJOR** muestra el tablero previo a la jugada revisada y resalta origen/destino de la alternativa del motor. Al ocultarla, restaura el tablero real de la partida y su resaltado. Esto evita enseñar la alternativa sobre una posición posterior incompatible.
- La cabecera del coach muestra la clasificación y la pérdida estimada en centipeones; el texto se recorta con puntos suspensivos donde corresponda y se reduce la escala máxima de UI para evitar que la navegación se desborde en pantallas estrechas.
- Se conserva la separación entre `ReplayViewController`, `ReplayViewLayoutService`, `GameReviewService` y `ReviewTacticalCommentary`; el coach no añade servicios externos ni llamadas de red.
- Se corrigió una cadena mal escapada en una prueba de integración de la V148 que impedía compilar el archivo de tests.

## Validación con Godot 4.7.2 y Xvfb
- Importación/editor: ejecutado mediante Xvfb; scripts sin errores de parseo tras la corrección.
- Suite de regresión `tests/run_tests.gd`: 42 OK / 0 fallidos.
- Arranque gráfico de la app y escena de vista previa de revisión ejecutados con el renderer `gl_compatibility` bajo Xvfb. El entorno de CI informa errores de audio ALSA/V-Sync por ausencia de dispositivos, con fallback a audio dummy; no afectan al test funcional.
- La vista previa visual se usó para ajustar la escala de UI en ancho móvil y detectar el desbordamiento de controles. No sustituye la validación táctil en un dispositivo Android real.

## Límites conocidos
- La variante se presenta en coordenadas UCI legibles (`d2→d4`), no en notación algebraica SAN.
- La pérdida en centipeones sigue siendo la métrica del motor y no una prueba independiente de que una explicación táctica sea cierta.
- El coach táctico determinista no es un modelo de lenguaje; evita proveedores externos y debe formular afirmaciones prudentes cuando no hay evidencia táctica suficiente.
