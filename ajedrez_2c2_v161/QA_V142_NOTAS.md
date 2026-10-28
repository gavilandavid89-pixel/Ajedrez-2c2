# V142 — regresiones móviles y estabilidad

Cambios principales:
- La transición global ya no espera indefinidamente `scene_changed`; tras el cambio de escena deja dos frames para estabilizar la pantalla y siempre ejecuta el fade-out y oculta la capa.
- Inicio ya no utiliza un `CenterContainer` que centraba verticalmente el contenido y dejaba una zona vacía que parecía una cortina. El título y las secciones quedan en flujo vertical y el área desplazable respeta la navegación inferior.
- Las subpáginas de cuenta aplican un pase de legibilidad táctil en móvil: texto pequeño se eleva a 18–20 px y botones/entradas tienen altura mínima de 48–50 px.
- Miembros usa callbacks ligados con validación de referencias, acciones compactas y margen responsivo.
- El análisis de replay ya no usa una lambda local como callable de Thread; utiliza un método ligado para evitar capturas de variables de una pantalla que puede destruirse mientras Stockfish trabaja.
- Los avisos temporales de Inicio ya no dependen de una lambda que captura la pantalla; se validan mediante generación y callback de instancia.
- La pantalla final de partida tiene un botón fijo y siempre visible «VOLVER AL INICIO», independiente de analizar o desplazarse. Se aumentaron zonas táctiles y tipografía del resultado.
- El bloque del tablero en retrato se sesga hacia arriba para reducir los grandes espacios negros y acercar los controles al área de juego. No se cambian las reglas ni los turnos 2c2.

## Validación en Godot 4.7.2
- Importación limpia en segunda ejecución: sin errores de parseo ni GDScript.
- Arranque gráfico Xvfb de 300 frames: sin errores GDScript/parseo/lambda. El entorno virtual no tiene dispositivo ALSA ni soporte VSync, por lo que aparecen avisos/errores de inicialización de audio y VSync que no son errores de lógica del juego.
- Pruebas automatizadas: 148 aprobadas, 0 fallidas en las suites ejecutadas:
  - V142 Mobile UI Regression: 11/11
  - V58 Board First HUD: 50/50
  - Responsive Mode Menu V26: 37/37
  - Profile UI: 9/9
  - V134 Agent Modularity: 12/12
  - V135 System Audit: 14/14
  - Match Result V71: 15/15
- Se capturaron vistas de Inicio, partida móvil y resultado a 390x844 / 360x640 para inspección.

## Limitaciones honestas
- Xvfb simula una ventana gráfica; no reemplaza el tacto real del LG K50.
- No se certifica que el error de editor `text_edit.cpp:6981` esté resuelto; no se reprodujo aquí.
- Debe comprobarse en Android el recorrido Inicio → Más → cada subpágina, Inicio → Club → Miembros, scroll que atraviesa botones y salida directa desde el resultado.
