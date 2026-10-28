# V146 — Sistema visual responsivo y organización por pantalla

Fecha: 2026-10-17  
Motor: Godot 4.7.2.stable.official.ed1daf0bf  
Base: copia de trabajo derivada de `ajedrez_2c2_v145_interfaz_responsive.zip`.

## Objetivo de esta tanda

Mejorar la composición de cada pantalla con capturas ejecutadas bajo Xvfb. No se trató como una tarea de escalar toda la UI en bloque: se ajustaron tablero/HUD, encabezados, separaciones, anchos mínimos, etiquetas, botones, barras de navegación, scroll y organización de tarjetas según orientación.

## Regla geométrica del tablero

- Vertical: el tablero de 8 × 8 mantiene celdas cuadradas, se centra y llega hasta los márgenes laterales seguros de 8 unidades lógicas (por ejemplo, 374 × 374 en 390 × 844).
- Horizontal: el tablero mantiene las celdas cuadradas y se maximiza contra la altura útil de la pantalla. En 844 × 390 ocupa aproximadamente 366 × 366; jugadores, relojes y acciones se distribuyen en raíles laterales.
- **No deformar el tablero para forzar que el cuadrado cubra literalmente todo el ancho panorámico.** En 844 × 390, un tablero cuadrado de 844 de ancho no cabe en 390 de alto. Hacerlo implicaría casillas rectangulares o recortar filas/columnas; V146 prioriza geometría de ajedrez correcta y jugabilidad.
- `core/layout/layout_metrics.gd` sigue siendo la fuente de verdad para el rectángulo del tablero, la pila vertical y los raíles horizontales.

## Cambios por responsabilidad

### Partida y HUD

- `core/layout/layout_metrics.gd`: márgenes de tablero, altura de equipos, espaciado entre bloques y tamaño del área de acciones actualizados; nueva `portrait_stack_metrics()` reutiliza métricas en lugar de repetir números de la pila vertical.
- `ui/components/game/game_hud_layout.gd`: en horizontal, acciones de equipo en la columna izquierda; emojis/chat/menú debajo; jugadores y relojes en laterales; línea de movimientos debajo del grupo de jugadores a la derecha. En vertical, controles y jugadores conservan sus zonas sin tapar el tablero.
- `ui/components/player_card.gd`: tarjetas verticales compactas mantienen un avatar de al menos 48 unidades lógicas, y el layout horizontal ubica el avatar a la izquierda con el nombre a su derecha.

### Fábrica visual y navegación

- `ui/components/social/social_ui_factory.gd`: helper estático `is_landscape(host)` para compartir la detección de orientación.
- `ResponsiveMarginController` continúa como propietario de los márgenes: usa una referencia débil, escucha `Viewport.size_changed` y se desconecta en `_exit_tree()`.
- Los cambios de pantalla usan contenedores/anchos mínimos y truncado controlado; no dependen solo de aumentar fuentes.

### Pantallas sociales

- Inicio/Amigos/Más/Clubes: separaciones, tarjetas, subtítulos, botones y tamaños compactos específicos para horizontal; se mantiene la navegación lateral en horizontal y la inferior en vertical.
- Creación de club: los iconos se agrupan en una tira que se desplaza horizontalmente cuando no caben; el botón de Galería conserva su ancho, altura y texto.
- Detalle de club: se eliminó la segunda autoridad de márgenes; `ScrollContainer` y contenido respetan el ancho disponible. El enlace de miembros, el texto de acceso, jerarquía y filas de miembros tienen límites de tamaño apropiados para móvil.
- Miembros: las filas llenan el ancho útil; avatar, nombre y rol usan bloques independientes; en vertical las acciones bajan a una segunda fila y en horizontal comparten la fila si hay ancho suficiente. Nombres y roles vuelven a ser visibles en vertical.
- Chat: cabecera, botón de miembros/desafío, estado vacío y compositor se organizan según la orientación, con zonas táctiles de 48 unidades lógicas como mínimo para controles principales.
- Perfil/Cuenta: la cuadrícula de personalización pasa a una columna en móvil estrecho; etiquetas de estadísticas tienen altura reservada; desaparece un margen lateral vacío de 160 unidades en horizontal y el texto de estado deja espacio al icono flotante de historial. Las filas de parejas restringen los mínimos horizontales de etiquetas, permiten envolver detalles largos y apilan el ranking debajo en pantallas estrechas para que el historial de parejas no ensanche el contenido.

## Capturas de revisión visual

Las capturas repetibles del proyecto están en:

- `qa_previews/v146/portrait/`
- `qa_previews/v146/landscape/`

Cada orientación contiene: `home.png`, `friends.png`, `clubs.png`, `club_detail.png`, `club_create.png`, `members.png`, `chat.png`, `more.png`, `account.png`, `game.png`.

Las pantallas sociales se capturan con un club de demostración seleccionado para que Chat/Miembros/Detalle sean renderizables. Las capturas describen la interfaz local, no un servidor online activo.

## Repetir capturas con Xvfb

Desde la raíz del proyecto, usando el ejecutable Godot 4.7.2:

```bash
GODOT=/ruta/a/Godot_v4.7.2-stable_linux.x86_64
xvfb-run -a -s '-screen 0 1280x900x24' "$GODOT" \
  --display-driver x11 --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --path . --script res://tests/capture_v146_social.gd

xvfb-run -a -s '-screen 0 1280x900x24' "$GODOT" \
  --display-driver x11 --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --path . --script res://tests/capture_v146_social_landscape.gd

xvfb-run -a -s '-screen 0 1280x900x24' "$GODOT" \
  --display-driver x11 --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --path . --script res://tests/capture_v146_game_portrait.gd

xvfb-run -a -s '-screen 0 1280x900x24' "$GODOT" \
  --display-driver x11 --rendering-driver opengl3 \
  --rendering-method gl_compatibility --audio-driver Dummy \
  --path . --script res://tests/capture_v146_game_landscape.gd
```

En este entorno, ejecutar la importación del editor con `--headless --editor --quit`; se valida la ejecución/renderizado de escenas con los scripts bajo Xvfb. El editor gráfico con el driver por defecto encontró un fallo de extensión Vulkan del entorno, por lo que para las capturas se fuerza OpenGL Compatibility.

## Pruebas añadidas

- `tests/v146_board_layout_tests.gd`: 44 comprobaciones del tamaño, geometría cuadrada, límites del tablero y separación de raíles en varios viewports verticales/horizontales.
- `tests/v146_social_screen_fit_tests.gd`: 77 comprobaciones de ajuste de ScrollContainers, contenido de Detalle y Perfil, botones de Miembros, tira de iconos y botón de Galería en varias dimensiones lógicas y orientaciones.

## Pendiente

1. Validar en un Android físico rotación, zonas táctiles físicas, teclado virtual y scroll iniciado encima de tarjetas.
2. Revisar la interacción de overlays de sugerencias, chat/emotes y pantalla final sobre partidas largas 1c1/2c2.
3. Validar todas las subpáginas de Cuenta y Más y capturar escalas reales adicionales.
4. Repetir las suites de reglas y transición si una futura modificación toca lógica de partida; esta tanda no cambia reglas ni conecta servidor online.
