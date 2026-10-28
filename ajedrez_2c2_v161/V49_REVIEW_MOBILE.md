# Ajedrez 2c2 — V49 · Replay, bot y UI móvil

## Cambios principales

### Bot cooperativo
- La sugerencia del bot aparece antes de ejecutar su jugada.
- Una vez mostrada, se mantiene un mínimo de 2 segundos para poder leerla.
- El bot no ejecuta la jugada mientras ese tiempo de lectura siga activo.
- El tiempo de pensamiento sigue variando según el bot.
- Test dedicado: `V49 BOT SUGERENCIA: 5 OK / 0 FAIL`.

### Historial → Análisis
- `Analizar partida` entra directamente al estudio interactivo.
- Se eliminó la pantalla intermedia de replay/resumen.
- `Ver` también abre directamente el estudio.
- El estudio no usa controles de reproductor de vídeo.

### Estudio de partida
- Tablero primero, a tamaño móvil.
- Navegación compacta debajo del tablero con control anterior, `AUTO`, jugada actual y siguiente.
- Las jugadas quedan debajo del tablero, sin panel ni marco independiente.
- La tira de jugadas es horizontal y sirve de navegación directa.
- `AUTO` avanza jugada por jugada y se detiene al encontrar una clasificación importante del análisis de motor.
- El coach aparece solo cuando existe algo relevante que explicar.
- El coach se muestra como una burbuja contextual `🤖 COACH · ...` y destaca las casillas relevantes de la jugada.

### Interfaz móvil
- Escalado de tipografías y objetivos táctiles usando el tamaño físico de la ventana.
- Ajustes específicos para portrait y landscape.
- Acciones inferiores ampliadas para lectura/tacto.
- Paneles contextuales ampliados en portrait para evitar texto diminuto.
- Las tarjetas de jugador y sus nombres/títulos se adaptan al tamaño del dispositivo.

## Verificación

Probado con Godot 4.7.2:
- Replay móvil: **10 OK / 0 FALLARON**.
- Sugerencia de bot: **5 OK / 0 FAIL**.
- Historial/análisis: **20 OK / 0 FALLARON**.
- Suite principal: **39 OK / 0 FALLARON**.
- Capturas visuales realizadas en 390×844 y 844×390 con Xvfb + Godot 4.7.2.

## Motor

La arquitectura de análisis usa Stockfish UCI MultiPV. El binario Android ARM64 oficial está incluido en el proyecto, pero su ejecución nativa no puede verificarse dentro del entorno Linux x86_64 usado para estas pruebas; esa parte requiere ejecutar la app en Android ARM64.
