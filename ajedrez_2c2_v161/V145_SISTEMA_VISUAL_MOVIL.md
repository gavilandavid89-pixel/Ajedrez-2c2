# Ajedrez 2c2 — V145 Sistema visual móvil

## Principios
- El tablero conserva prioridad visual durante la partida; jugadores, relojes y acciones se organizan como grupos secundarios con espacios consistentes.
- Las pantallas sociales usan una fábrica visual compartida para colores, paneles, botones, títulos y márgenes responsivos.
- La interfaz base se define en 390 × 844, una referencia móvil vertical; el layout debe adaptarse a anchos estrechos y a horizontal mediante contenedores y medición del viewport.
- Los títulos largos reducen tipografía de forma controlada y usan truncado de respaldo para no salir del ancho útil.
- Los controles interactivos conservan zonas táctiles grandes; el selector de icono de club usa un botón compacto no textual para no forzar saltos de línea.
- El desplazamiento debe ganar cuando el dedo supera el umbral de arrastre; el gesto no debe activar el botón al soltar.

## Ciclo de vida
`ResponsiveMarginController` posee la suscripción a `Viewport.size_changed`. Usa referencias débiles y desconecta la señal en `_exit_tree()`, evitando callbacks de redimensionado que queden vivos tras destruir una pantalla.

## Qué probar al cambiar diseño
1. Inicio arriba y tras varios desplazamientos.
2. Clubes → detalle → chat → miembros.
3. Más → Cuenta y cada subpágina de configuración.
4. Arrastrar empezando encima de tarjetas y botones.
5. Girar entre vertical y horizontal y volver a vertical.
6. Partida 1c1 y 2c2, incluyendo pantalla de resultado y volver al inicio.

## Restricciones
Las reglas de movimiento y turnos 2c2 no deben alterarse como solución a un problema visual. Las pantallas existentes siguen usando controles dinámicos en algunos flujos; las nuevas vistas deben preferir escenas, contenedores, anclajes y componentes reutilizables desde el editor de Godot cuando resulte práctico.

## Implementación y verificación de la tanda (2026-10-17)

- La referencia de proyecto en `project.godot` ahora es 390 × 844, en lugar de 720 × 720.
- `ResponsiveContentScale` compensa el encogimiento de los controles en horizontal con `Window.content_scale_factor` proporcional a la altura real; en vertical se mantiene en 1.0.
- `ResponsiveMarginController` administra márgenes verticales/horizontales con referencias débiles y desconexión explícita al salir del árbol.
- La fábrica social aplica tamaños mínimos de 52 px para acción principal y 48 px para secundaria, reduce títulos largos y añade truncado con puntos suspensivos.
- La navegación inferior reduce su tipografía en teléfonos estrechos; las pantallas con barra inferior reservan 120 px en vertical. En horizontal, Más y Miembros dejan espacio a la barra lateral.
- El chat adapta el tamaño y las columnas del selector de reacciones a la anchura disponible; se corrigió una inserción duplicada de textura en las reacciones con imagen.
- Capturas revisadas disponibles en `qa_previews/v145/portrait/` y `qa_previews/v145/landscape/`.

Pruebas ejecutadas: suite base 42/42; móvil V141 24/24; paisaje V141 33/33; regresión móvil V142 11/11; HUD V144 10/10; scroll táctil 6/6; agentes V134 12/12; contratos V135 14/14; panel de diagnósticos V131 6/6; controlador responsive 8/8; fábrica social 7/7; escala responsive 4/4. La suma aritmética es 177 aprobaciones, con solapamiento entre suites.

Limitación: la validación gráfica se hizo con Xvfb/llvmpipe, no en un Android físico. El factor de escala horizontal debe verificarse en distintos tamaños, densidades, teclado virtual y HUD de partida antes de considerar cerrada la tanda.
