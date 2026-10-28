# Ajedrez 2c2 V112 — reglas, análisis, entrada táctil y robustez

## Cambios aplicados

### Reglas de tablas
- Se añadió el contador FIDE de medios movimientos: aumenta en jugadas normales y enroques; se reinicia en movimientos de peón, capturas y captura al paso.
- Se registran posiciones para detectar triple repetición reclamable y quintuple repetición automática. La clave considera piezas, bando al turno, derechos de enroque y captura al paso solo cuando existe una captura legal posible.
- Se añadió la reclamación de tablas por repetición triple o regla de los 50 movimientos al flujo existente de tablas. Cuando no hay una reclamación válida, el flujo de propuesta de tablas —incluido el consenso 2c2— sigue igual.
- Se aplican tablas automáticas al alcanzar 75 movimientos completos sin captura ni movimiento de peón (150 medios movimientos), o quintuple repetición. Jaque mate y ahogado se resuelven antes, por prioridad reglamentaria.
- Se corrigió la validación de captura al paso para exigir que el peón rival que debe capturarse exista realmente.
- Las estadísticas transitorias de pareja 2c2 ahora registran victorias, derrotas y tablas; un empate reinicia la racha y no altera el rating.

### Replay y motor
- El FEN de análisis usa el bando real al turno guardado en la posición, no la paridad del slot 2c2. Esto evita evaluar desde el color equivocado cuando el orden local/rival está invertido.
- El replay conserva el contador de medios movimientos para producir FEN más fieles.
- Se añadieron regresiones para demostrar que mate en 1 se evalúa mejor que mate en 5 y que, estando perdido, retrasar el mate es preferible.
- El análisis sigue ejecutándose en un hilo, ahora valida el fallo al iniciar ese hilo, recibe copias de los datos y guarda el resultado en el historial de la partida correcta aunque cambie la selección mientras analiza.

### Resultados competitivos (NEXUS)
- Cada partida recibe un identificador estable durante su ciclo de vida.
- `record_result()` comprueba ese identificador antes de modificar rating, copas, estadísticas o historial. Repetir la misma confirmación no cuenta la partida dos veces.
- La telemetría no reenvía un resultado marcado como duplicado.

### Selección táctil y sugerencias
- La pieza de origen se selecciona en el evento de presión de un solo toque; no requiere doble toque ni esperar a soltar.
- El gesto de arrastre solo se procesa si empezó dentro del tablero, para que los toques en HUD/espacios externos no terminen como movimientos accidentales.
- Se agregó una prueba de integración que pulsa el origen y el destino con toques separados y verifica que se envía una sugerencia fantasma sin mover la pieza.

## Pruebas ejecutadas con Godot 4.7.2
- Suite general: 42/42.
- Reglas, tablas, FEN, idempotencia y selección táctil: 11/11.
- NEXUS-TEAM: 27/27.
- NEXUS V2: 10/10.
- Orientación/distribución: 22/22.
- Flujos de pantalla: 18/18; 261 interacciones recorridas.
- Funciones sociales: 29/29, 36/36 y 9/9 en las suites correspondientes.
- Integración de análisis/FEN: 15/15, incluyendo distancia de mate.
- Protocolo UCI simulado: 9/9.

## Límites conocidos
- El motor Stockfish empaquetado es Android ARM64. El protocolo se probó con un motor simulado en Linux; todavía falta validarlo en un teléfono Android físico.
- La reclamación de repetición se habilita cuando la posición actual ya apareció tres veces; no se implementó la variante avanzada de reclamar anunciando una jugada que produciría la tercera repetición.
- Las reglas de tablas implementadas aquí son las de ajedrez estándar y no alteran la rotación, cooperación, turnos, colores ni flujo de sugerencias de 2c2.
