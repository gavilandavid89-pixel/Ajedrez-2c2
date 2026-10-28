# V133 — Precisión de agentes QA

## Objetivo
Aumentar la precisión temporal y de correlación de los agentes antes de la primera prueba manual en Godot/Android, sin modificar reglas de ajedrez, turnos 2c2 ni decisiones de entrada.

## Cambios
- El agente táctil asigna identificador de sesión y secuencia a cada evento; conserva el índice del puntero táctil de Godot.
- El doble toque exige que el primer toque haya terminado con liberación, corresponda al mismo dedo, esté dentro de 360 ms entre pulsaciones y a no más de 28 px. Registra tiempo entre pulsaciones y tiempo entre liberación/segunda pulsación por separado.
- Añade detección diagnóstica de liberaciones huérfanas, pulsaciones duplicadas sin liberar, pulsaciones largas, arrastres, entradas bloqueadas y toques fuera de las coordenadas del tablero.
- Cada resultado de interacción se vincula con la secuencia de pulsación, incluye latencia monotónica, cambio de selección y cambio de contador de movimientos.
- El resumen táctil se incluye como `touch_observer_summary.json` dentro del paquete QA para facilitar análisis sin tener que reconstruir todo desde JSONL.
- El exportador evita consultar el directorio de capturas cuando todavía no existe, eliminando un error ruidoso en Output en una instalación nueva.
- Mantiene la observación pasiva: no consume eventos ni altera la lógica de juego. No agrega capturas por toque ni grabación continua.

## Verificación
- Prueba nueva V133: 15/15.
- Suites V132, V131, V130, V129, V128, V127, V126, V125, V124 y V123: todas aprobadas.
- Total de las suites ejecutadas: 114 comprobaciones aprobadas, 0 fallidas.
- Godot 4.7.2: importación de proyecto con código de salida 0; no se detectaron `SCRIPT ERROR`, `Parse Error` ni `ERROR:` en la importación final.
- Las suites se ejecutaron en modo headless; no equivale a validar el tacto real en una pantalla Android física.

## Qué buscar en el próximo paquete QA
- `touch_observer_summary.json`: resumen de contadores por sesión.
- `supervisor_diagnostics.jsonl`: eventos `touch_observed`, `double_tap_observed` y `touch_action_result`.
- `related_press_sequence`, `press_sequence`, `monotonic_ms`, `latency_since_press_ms`, `selection_changed` y `move_count_changed`: claves para reconstruir una interacción.

## Límite
Un toque que no llegue al nodo/controlador observado no se puede inferir a partir de los eventos que sí llegaron. La prueba real deberá comprobar si la ruta de entrada de la pantalla concreta entrega los eventos esperados y si el problema del doble toque ocurre en el juego o antes, en la interfaz.
