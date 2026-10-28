# Stockfish 19 — Android ARM32 y ARM64

Este directorio conserva dos ejecutables oficiales de Stockfish 19, cada uno para una ABI distinta:

- `stockfish_android_arm32`: Android ARMv7 con NEON (ELF de 32 bits).
- `stockfish_android_arm64`: Android AArch64 (ELF de 64 bits).

`domain/bots/stockfish_engine.gd` selecciona el archivo a partir de `Engine.get_architecture_name()`. Si la arquitectura no se reconoce, no elige una ABI por descarte. Las pruebas de regresión verifican ARM32, ARMv7, ARM64, AArch64 y arquitecturas no compatibles.

## Nota de empaquetado Android

La presencia y validación del ejecutable en GitHub no demuestra que Android permita ejecutarlo desde una copia dentro de `user://`. La API de procesos de Godot necesita una ruta real a un archivo ejecutable; las restricciones del sistema Android y el modo de empaquetado deben comprobarse en una exportación instalada. La prueba de ejecución UCI con el binario real en un dispositivo Android sigue pendiente; las pruebas simuladas del protocolo UCI no la sustituyen.

Para comprobar los archivos en CI, consulta `.github/workflows/validate-stockfish-architectures.yml`. Ese flujo valida los encabezados ELF de ambas arquitecturas y ejecuta la batería de regresión del proyecto en Godot 4.7.2.

## Licencia

Stockfish se distribuye bajo GPLv3. Se conserva `Copying.txt` y la documentación upstream incluida en este directorio. Al distribuir la aplicación con estos binarios, debe mantenerse disponible el código fuente correspondiente conforme a las obligaciones de la licencia.
