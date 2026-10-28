# V150 — Ajuste responsive inicial del análisis

- Se limita el ancho disponible del tablero al ancho real del viewport para evitar que el tablero se recorte horizontalmente en pruebas móviles estrechas.
- Se da a la burbuja del coach una superficie verde-negra más diferenciada y un acento dorado lateral; se mejora el contraste de título y explicación.
- La estructura sigue modular en `domain/replay/replay_view_layout_service.gd`.

## Verificación
- Godot 4.7.2 con Xvfb / GL Compatibility.
- Suite: 42 OK / 0 fallaron.
- La captura de humo no pudo mostrar el coach: en este entorno Linux, el ejecutable de Stockfish incluido es Android ARM64 y el análisis acaba indicando que Stockfish no respondió. No se afirma que el motor funcione en Linux; el binario se conserva para Android.
- No probado en dispositivo Android físico.
