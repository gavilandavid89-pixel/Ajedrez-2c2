# V155 — Tablero compartido y eventos visuales

## Cambios implementados

- Nuevo `core/visual/board_piece_renderer.gd`: centraliza el cálculo del tamaño de las piezas, el centrado y la sombra. El tablero de partida (`ui/components/board.gd`) y el de replay (`domain/replay/replay_board.gd`) usan ahora el mismo renderer y la misma proporción definida en `BoardVisualContract`.
- El tablero de partida publica snapshots defensivos del estado visual a `BoardVisualEvents` al recibir estado, cambiar orientación y animar movimientos.
- La selección del tablero publica coordenadas algebraicas normalizadas; una cadena vacía representa explícitamente el fin de la selección.
- Se añadieron pruebas de contrato para selección, deselección, copia profunda del estado y tamaño de pieza inválido.
- Se regeneraron capturas reales del proyecto ejecutado con Godot 4.7.2 bajo Xvfb.

## Validación ejecutada

- Importación de recursos: correcta (`Godot 4.7.2 --headless --editor --import --quit`, código 0).
- Suite principal: `42 OK / 0 FALLARON`.
- Pruebas de eventos globales: `9 OK / 0 FAIL`.
- Captura de pantallas: script `tests/capture_visual_review.gd` ejecutado; capturas de móvil vertical, móvil horizontal y menús generadas.

## Alcance y limitaciones conocidas

- Esta versión comparte de verdad el cálculo/dibujo de piezas entre partida y replay, y amplía el contrato de eventos de partida. No implica que todos los módulos de estudio, puzzles y análisis estén migrados a un único nodo de tablero interactivo: el replay conserva su propio control de dibujo y su lógica de navegación.
- No se realizó una prueba física en Android. La importación Android del proyecto debe volver a validarse en el dispositivo de destino.
- No se eliminó código antiguo automáticamente. La auditoría encontró una base grande con cargas dinámicas y dependencias de escenas; borrar archivos sin un análisis de referencias más profundo sería arriesgado.
- La captura confirma renderizado visual en escritorio con viewport de móvil, no rendimiento ni compatibilidad física Android.
