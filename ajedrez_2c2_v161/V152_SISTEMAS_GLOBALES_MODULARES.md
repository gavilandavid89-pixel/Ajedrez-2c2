# V152 — Sistemas globales modulares

## Objetivo
Preparar el proyecto para añadir nuevas pantallas (estudio, puzzles, análisis, espectadores u otros modos) conectándolas a sistemas compartidos, en vez de copiar comportamiento visual y de aplicación.

## Nuevo módulo `core/events/`
- `GlobalEvents` es un autoload para eventos de aplicación que no pertenecen exclusivamente al ajedrez.
- Incluye ciclo de pantalla, cambios de preferencias, notificaciones, solicitudes de modal, operaciones largas y conectividad.
- Los payloads de diccionario se copian al publicarlos para evitar que quien emite cambie datos ya entregados.
- Operaciones largas rechazan IDs vacíos o duplicados y no permiten finalizaciones desconocidas.

## Mapa de módulos
`core/systems/GLOBAL_SYSTEMS_MAP.md` define la propiedad recomendada para los sistemas compartidos: visual de tablero, eventos, tema, layout, navegación, servicios, dominio ajedrecístico y revisión de partidas.

## Regla para pantallas nuevas de ajedrez
Reutilizar `ChessBoardView` y `BoardVisualContract`; publicar estado y resaltados con `BoardVisualEvents`. Las pantallas no deben definir escalas de pieza, colores semánticos ni reglas de movimiento propias. El dominio mantiene la autoridad sobre el estado; los eventos visuales solo comunican cambios.

## Pruebas
- Suite principal: 42 OK / 0 fallidas.
- `tests/global_events_tests.gd`: 5 OK / 0 fallidas (aislamiento de payload, limpieza de notificaciones, límite de duración, deduplicación y ciclo de operaciones).
- Ejecutado con Godot 4.7.2 y Xvfb.

## Límites
El bus global ya está disponible, pero las pantallas existentes no se han migrado masivamente a él en esta versión. Se hará por subsistema y con pruebas de regresión, evitando una reescritura grande. Las animaciones de tablero siguen siendo una tarea separada de integración.
