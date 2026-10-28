# Ajedrez 2c2 — V137 correcciones de errores reportados

## Correcciones aplicadas
- `ui/components/board.gd`: eliminada una declaración duplicada de `hub` dentro del mismo ámbito, que impedía compilar `ChessBoardView` y afectaba a `game.gd` y pruebas dependientes.
- `ui/screens/mode_menu.gd`: quitada la asignación inválida `custom_minimum_size` sobre `AcceptDialog`; el tamaño de apertura se gestiona con `popup_centered(Vector2i(...))`.
- `domain/replay/game_review_service.gd`: eliminado el acceso a `SceneTree`/`Node` desde el worker que analiza el replay.
- `ui/screens/account_hub.gd`: inspección observacional del replay movida al hilo principal antes de iniciar el worker.
- Inicio: reducido el tamaño del botón de perfil y ajustadas sus posiciones/dimensiones para cumplir el objetivo de control compacto.
- Test V58: afinada la aserción de reinicio para reflejar los permisos reales del modo; el botón Volver debe permanecer disponible, pero Reiniciar solo aparece en partida local/contra bot.

## Validación realizada con Godot 4.7.2
- Importación headless del editor: salida 0; segunda importación sin errores de parseo/importación.
- Lanzamiento GUI bajo Xvfb durante 300 frames: salida 0; sin errores de GDScript ni de las tres incidencias reportadas. Se observaron advertencias del entorno de audio/V-Sync de esta máquina de pruebas, no errores de lógica del proyecto.
- `tests/v58_board_first_hud_tests.gd`: 50 OK / 0 fallidas.
- `tests/v134_agent_modularity_tests.gd`: 12 OK / 0 fallidas.
- `tests/v135_system_audit_tests.gd`: 14 OK / 0 fallidas.

## Pendiente / límites
- No puedo certificar aún la interacción táctil en un Android real.
- La revisión automatizada no demuestra por sí sola que el menú de Club quede visualmente bien en todos los tamaños ni identifica de forma concluyente la capa descrita como «cortina invisible». Hace falta reproducir esa ruta de navegación con una captura de pantalla y prueba de toque en el dispositivo donde aparece.
- No se modificó la lógica de turnos 2c2.
- Se conserva la arquitectura de escenas existente. La regla para próximos cambios visuales sigue siendo priorizar escenas `.tscn`, contenedores y anclajes en el editor de Godot; usar GDScript solo cuando la UI necesite comportamiento dinámico.
