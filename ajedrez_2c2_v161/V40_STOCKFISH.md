# V40 — Motor real y tablero compacto

## Cambios

- El tablero del estudio vuelve a un tamaño normal: no ocupa toda la pantalla vertical.
- La tira de jugadas sigue siendo horizontal y compacta.
- Se eliminó el evaluador heurístico provisional de V38.
- Se añadió `game_review_service.gd` para transformar el replay guardado a FEN y las jugadas a UCI.
- Se añadió `stockfish_engine.gd` para comunicarse con Stockfish mediante UCI.
- El análisis usa una búsqueda del motor para la mejor línea y otra restringida a la jugada realizada, permitiendo calcular la pérdida de evaluación sin duplicar las reglas de ajedrez.
- Los resultados se guardan como `engine_analysis` en el historial.
- La tira de movimientos puede mostrar la clasificación y la mejor jugada cuando existe un reporte real del motor.

## Motor

La integración incluye binarios oficiales de Stockfish 19 para Android ARM32 (ARMv7 NEON) y ARM64 (AArch64), y selecciona el correspondiente a la arquitectura detectada. La copia a `user://` y el permiso de ejecución se intentan en tiempo de ejecución, pero eso no demuestra que Android permita ejecutar el archivo en todos los dispositivos/versiones. La prueba UCI con el binario real en una exportación Android instalada sigue pendiente; no debe confundirse con las pruebas del protocolo simulado.

La distribución debe conservar las obligaciones de GPLv3 y el código fuente correspondiente. La validación automatizada de ABI y regresión se encuentra en `.github/workflows/validate-stockfish-architectures.yml`.

## Estado de la prueba

Godot 4.7.2: 39/39 pruebas base + integración FEN/UCI.

La comprobación de ejecución del motor real queda pendiente hasta disponer del binario ARM64 dentro del proyecto. No se simula Stockfish si el binario no está presente.
