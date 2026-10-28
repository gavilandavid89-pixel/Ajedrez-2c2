# V154 — Integración de eventos visuales globales

## Cambios

- `core/visual/board_visual_events.gd` ahora define IDs estables de origen (`match`, `replay`, `analysis`, `study`, `puzzle`) y tipos semánticos de resaltado (`last_move`, `selected`, `suggestion`, `error`).
- Añade métodos de publicación para inicio/final de animación, selección y variación; los arrays y diccionarios se copian antes de emitirse para evitar que consumidores modifiquen el dato del emisor.
- `ui/components/game/piece_move_animator.gd` consume `BoardVisualContract.MOVE_DURATION`, y usa la API de publicación centralizada en lugar de emitir señales del autoload directamente.
- El origen del animador es configurable (`visual_source`) para poder reutilizarlo desde análisis, estudio o puzzles sin etiquetar todos los eventos como partida en vivo.
- Se amplía el mapa de sistemas con las reglas de integración.

## Verificación

- Suite: `tests/run_tests.gd` — **42 OK / 0 fallaron**.
- Ejecutado con Godot 4.7.2 en modo headless bajo Xvfb.
- Este ciclo no modifica la composición visual, por lo que no hay una nueva captura visual que comparar.

## Limpieza pendiente

No se borran scripts solo por no tener referencias textuales directas. El proyecto contiene un conjunto amplio de pruebas históricas y herramientas de QA; antes de retirarlas se requiere separar tests activos, pruebas manuales y archivos archivables, y validar cargas dinámicas/autoloads. Esta entrega mejora la integración, pero no declara terminada la limpieza global.
