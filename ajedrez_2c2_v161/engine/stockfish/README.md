# Stockfish 19 — Android ARM64

El proyecto incluye ahora el binario oficial de Stockfish 19 para Android ARM64:

`stockfish_android_arm64`

El ejecutable se extrae desde los recursos empaquetados a `user://` en tiempo de ejecución y se marca como ejecutable antes de iniciar el motor UCI.

Arquitectura: AArch64 / ARM64.
Plataforma: Android.
Protocolo: UCI.

El análisis de partidas se realiza mediante `stockfish_engine.gd` y `game_review_service.gd`; no se utiliza la heurística provisional de versiones anteriores.

## Licencia

Stockfish se distribuye bajo GPLv3. Se conserva `Copying.txt` y la documentación upstream incluida en este directorio. El código fuente correspondiente debe mantenerse disponible conforme a las obligaciones de la licencia cuando se distribuya el binario.
