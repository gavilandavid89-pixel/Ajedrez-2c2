# V91 — Reforma del Inicio y separación de clasificación

Cambios implementados:
- Racha diaria compacta junto al avatar: `x🔥`.
- Objetivo diario reducido a una línea discreta debajo de las acciones principales.
- Separación vertical amplia entre las acciones principales y el contenido secundario.
- Temporada separada conceptualmente de la clasificación: el Inicio ya no muestra "Liga" dentro de la tarjeta de temporada.
- Actividad mensual presentada como una línea compacta, no como una tarjeta adicional.
- Rankings accesibles directamente desde el menú `⋮`.
- Clasificación separada por modo: 1c1 y 2c2. Las tablas de un modo no se mezclan con las del otro.
- 2c2 conserva clasificación de jugadores y de parejas; 1c1 conserva su clasificación individual independiente.

QA ejecutado antes del empaquetado:
- Home scroll: 28/28 OK.
- Ranking modes: 6/6 OK.
- Runner general: 39/39 OK.
- Flujo de pantallas: 18/18 OK, 252 interacciones.
- No hubo SCRIPT ERROR, Parse Error, Failed loading resource, ObjectDB leaks, recursos retenidos ni Orphan en las pruebas de proyecto.
- Ejecución gráfica real: salida limpia del proyecto; los únicos errores son ALSA por ausencia de dispositivo de audio en el entorno virtual, con fallback de Godot al driver dummy, además del warning de V-Sync del renderer virtual.
