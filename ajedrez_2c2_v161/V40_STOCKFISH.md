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

La integración espera el binario oficial de Stockfish 19 para Android ARM64 en:

`res://engine/stockfish/stockfish_android_arm64`

Al primer uso se copia a `user://engine/` y se ejecuta desde allí. No se usa almacenamiento público.

La descarga oficial de Stockfish ofrece un paquete Android ARM64 y Stockfish usa el protocolo UCI. La distribución debe conservar las obligaciones de GPLv3 y el código fuente correspondiente.

## Estado de la prueba

Godot 4.7.2: 39/39 pruebas base + integración FEN/UCI.

La comprobación de ejecución del motor real queda pendiente hasta disponer del binario ARM64 dentro del proyecto. No se simula Stockfish si el binario no está presente.
