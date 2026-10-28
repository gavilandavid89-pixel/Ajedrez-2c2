# Auditoría de importación Android — V146

## Hallazgos

1. El proyecto original contenía 89 capturas de QA dentro de `qa_previews/` (aprox. 2,6 MB). Son resultados generados por scripts de prueba, no recursos necesarios para jugar. Se retiraron del paquete principal; los scripts de captura pueden volver a generarlas.
2. Había cuatro imágenes de galerías antiguas en la raíz (`V97_GRAPHITE_GOLD_*` y `skin_piece_gallery.png`) con sus archivos `.import`. No se encontraron referencias desde código ejecutable, escenas ni recursos de interfaz. Se retiraron del paquete principal.
3. El archivo más grande con diferencia es `engine/stockfish/stockfish_android_arm64` (100.695.968 bytes, ELF Android ARM64). Es un motor de ajedrez incluido intencionalmente para el análisis de partidas; no se eliminó porque rompería esa función. Es el elemento de mayor tamaño a evaluar si el editor Android sigue cerrándose al importar, pero su presencia por sí sola no prueba que cause el cierre.
4. El proyecto declara 16 Autoloads y registra alrededor de 266 clases globales durante el escaneo. No se halló un error de parseo GDScript en la importación de prueba Linux.

## Verificaciones realizadas en esta revisión

- Godot 4.7.2 Linux, importación de editor en modo headless: finalizó con código 0. En el primer arranque aparecieron errores transitorios de carga de una fuente antes de que terminara su importación; al repetir el arranque, no aparecieron errores.
- `tests/run_tests.gd`: 42 OK / 0 fallidos.
- Acceso de solo lectura al binario Stockfish por `FileAccess.file_exists`: correcto en la prueba local.

## Límite importante

Estas pruebas no reproducen el editor Godot en Android ni certifican que el cierre del teléfono esté resuelto. La limpieza reduce archivos visuales innecesarios que el importador debe indexar, pero el ahorro de tamaño es pequeño frente al binario Stockfish de unos 96 MiB. La causa del cierre al 100 % sigue sin confirmarse.
