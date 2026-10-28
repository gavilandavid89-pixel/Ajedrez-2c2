# V110 — Auditoría lógica, interacción social, Stockfish y NEXUS

## Cambios aplicados

- Chat, reacciones, sugerencias 2c2 y solicitudes de cambio ya no dependen del turno activo ni del tiempo de pensamiento de un bot.
- Los paneles de chat y reacciones no se cierran automáticamente cuando comienza el turno de un bot en una partida 2c2.
- Las sugerencias se registran desde el slot local y solo aceptan piezas del equipo del usuario con movimientos válidos en la posición actual. El movimiento sigue siendo una sugerencia fantasma; no mueve la pieza.
- La selección del tablero en modo sugerencia funciona aunque el turno activo corresponda a un bot. Los movimientos reales siguen bloqueados durante el turno del bot.
- Las solicitudes de cambio de posición se originan en el jugador local y no requieren que sea su turno. Se mantienen las condiciones de modo estratégico, partida activa y compañero activo.
- Stockfish ahora usa una sesión UCI secuencial: espera `uciok`, `readyok` y cada `bestmove` antes de enviar la siguiente búsqueda. Cambia MultiPV de forma explícita entre evaluación principal y evaluación de la jugada elegida, evitando mezclar resultados de posiciones.
- NEXUS rechaza resultados desconocidos; ya no los convierte silenciosamente en tablas ni modifica rating/copas por un resultado inválido.

## Reglas 2c2

No se cambió la rotación A-B-C-D, los colores, las condiciones de victoria, los relojes, ni la forma en que una jugada real avanza el turno. Solo se amplió la disponibilidad de acciones sociales y estratégicas no-movimiento.

## Validación

- Pruebas generales: 41/41.
- Pruebas de controles/flujo en pantalla: 18/18.
- Pruebas sociales de dominio: 29/29.
- Prueba de protocolo UCI con motor simulado: 5 comprobaciones internas sin fallos.

El protocolo Stockfish se verificó con un motor UCI simulado porque el binario incluido es Android ARM64 y no puede ejecutarse directamente en este entorno Linux. La ejecución real del binario en un teléfono Android queda pendiente de prueba física.
