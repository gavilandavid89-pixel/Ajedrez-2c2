# V125 — Agente especializado de tablero y piezas

## Objetivo
Añadir un supervisor determinista que inspecciona la estructura del tablero y la correspondencia visual de las piezas para detectar defectos que pueden pasar inadvertidos en una revisión manual.

## Qué revisa
- Tablero de 8 filas por 8 columnas.
- Identificadores de piezas conocidos.
- Correspondencia entre cada pieza presente y las claves de textura del conjunto seleccionado.
- Exactamente un rey blanco y un rey negro en el estado observado.
- Rectángulo del tablero válido y cuadrado.
- Tamaño de viewport válido y nombres no vacíos de tema y conjunto de piezas.
- Registra en el diario persistente solo cuando cambia la huella del diagnóstico, evitando escribir el mismo evento en cada redibujado.

## Integración
- Nuevo agente: `domain/supervision/board_piece_supervisor_agent.gd`.
- `SupervisorHub` lo inicializa y comparte el diario persistente con él.
- `ui/components/board.gd` lo ejecuta cuando cambia el estado del juego, el diseño del tablero, el viewport o se vuelve a dibujar el tablero tras un cambio.
- Los resultados se registran en `user://supervisor_diagnostics.jsonl` bajo el agente `board_piece_agent`.

## Límites
Es una auditoría estructural y visual indirecta. No demuestra que cada sprite se vea bien en pantalla ni que el movimiento sea legal. Tampoco inspecciona píxeles, solapamientos reales de texturas o todos los errores internos del Debugger. Los problemas encontrados se registran; el agente no modifica las piezas ni el estado autoritativo de la partida.

## Validación ejecutada con Godot 4.7.2
- Agente tablero/piezas: 7/7.
- Miniagentes V124: 12/12.
- Supervisor de partidas V123: 22/22.
- Política de gracia V122: 25/25.
- Sesión/conexión V121: 17/17.
- Turnos/reconexión/resultados V120: 16/16.
- Regresión UI: 53/53 (con aviso de instancia ObjectDB filtrada al salir de esa prueba).
- Regresión movimiento/bots: 18/18.
- Skin de piezas: 24/24.
- Centrado del tablero: 54/54.
- Importación de editor: completada sin `SCRIPT ERROR`, `Parse Error` ni `ERROR:`.
- Ejecución principal headless: se mantuvo activa durante 20 segundos hasta el límite de observación; sin errores en Output. Esto no sustituye una inspección visual manual en Android.

## Nota del consejo
Se mantiene la regla: el supervisor observa y registra; no decide movimientos, no cambia resultados y no sustituye la autoridad de la partida. La inspección visual automática por píxeles y la captura integral del panel Debugger son tareas futuras.
