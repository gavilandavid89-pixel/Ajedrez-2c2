# V157 — Replay limpio y análisis explícito

## Objetivo
Separar la reproducción de una partida de la experiencia de análisis. El replay no debe iniciar Stockfish ni mostrar comentarios, clasificaciones o sugerencias sin una acción explícita del usuario.

## Cambios
- `MatchReplayView` incorpora los modos `replay` y `analysis`; el modo por defecto es `replay`.
- Se añade la señal `analysis_requested`, sin iniciar el motor desde el componente de replay.
- El replay muestra una acción `✦ Analizar partida`; al pulsarla, la pantalla de historial navega a la vista de análisis existente.
- La vista de análisis se configura explícitamente en modo `analysis` y mantiene el inicio del motor allí.
- Comentarios del coach, colores de clasificación, resaltados de jugadas y acceso a mejores jugadas quedan reservados al modo análisis.
- La reproducción automática funciona en replay sin necesitar datos del motor. En análisis puede detenerse al llegar a una jugada importante.
- Se elimina el botón duplicado debajo del replay; queda una única entrada contextual dentro de la propia vista.
- El cambio de modo es seguro antes de que el control entre en el árbol de escena.

## Verificación
- Suite principal: 42 OK / 0 fallidas.
- Pruebas de separación replay/análisis: 7 OK / 0 fallidas.
- Prueba de integración replay/análisis: 3 comprobaciones OK.
- Capturas reales de Godot: `v157_replay_limpio.png` y `v157_modo_analisis.png`.
- Importación del proyecto comprobada; el log no contiene errores de parseo/compilación de scripts modificados. En este entorno, Godot sigue mostrando advertencias de audio sin dispositivo y un recurso de fuente importado que falta en la caché, independientes de los cambios V157.

## Pendiente
- Prueba física Android.
- Revisión visual completa en pantallas pequeñas y horizontales.
- El motor solo se inicia en la pantalla de análisis; la disponibilidad real depende del binario de Stockfish y la plataforma.
