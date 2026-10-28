# QA v21 — movimiento, bots y regresión integral

## Causa raíz encontrada
`game_state.gd` no compilaba en Godot 4.7.2 por la llamada estática al controlador de bots mediante un preload local. La compilación fallida dejaba inutilizado el estado de partida, por lo que el tablero no podía ejecutar movimientos y los bots tampoco podían responder.

## Correcciones
- Referencia explícita y estable a `ChessBotController`.
- Turnos de bot generalizados mediante `bot_slots`.
- VS IA conserva el bot elegido por el usuario.
- Bots temporales para matchmaking público online simulado mientras no existe servidor real.
- 2c2 simulado: compañero y rivales temporales ejecutan sus propios turnos; el ciclo vuelve al jugador.
- 1c1 simulado: el rival temporal responde.
- Salas privadas por código no activan bots temporales.
- El tablero bloquea la entrada durante un turno de IA.
- Sugerir/cambiar/tablas/rendirse/chat/reacciones quedan bloqueados durante un turno de IA.
- Corregido el contador de feedback de audio para que las jugadas puedan disparar su sonido.
- Corregidos identificadores de la dama negra para mantener `dama_negro` en todo el proyecto.
- Añadida prueba permanente de interacción real del tablero y bots.

## Pruebas en Godot 4.7.2
- 38/38 núcleo
- 9/9 base extra
- 6/6 integración VS IA
- 39/39 bots
- 18/18 regresión movimiento/bots/online temporal
- 24/24 competitivo
- 8/8 matchmaking
- 37/37 configuración online
- 3/3 shell online
- 9/9 perfil/UI
- 100/100 Account Hub
- 23/23 tandas 5–7
- 5354/5354 ruptura/estrés
- 18/18 almacenamiento
- 6/6 refinamiento
- 51/51 regresión UI
- 1504/1504 responsive
- 8/8 identidad

Total: **7255/7255 comprobaciones OK**.

También se ejecutó el proyecto completo y el arranque principal terminó con código 0. Las advertencias ALSA/V-Sync y las fugas reportadas al salir pertenecen al entorno de laboratorio/arnés de pruebas; no produjeron fallos funcionales y todas las baterías finalizaron con 0 fallos.
