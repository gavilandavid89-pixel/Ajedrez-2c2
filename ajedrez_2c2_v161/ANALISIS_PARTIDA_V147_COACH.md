# Ajedrez 2c2 V147 — Análisis guiado y coach

## Referencias de diseño
Se revisaron las guías públicas de Chess.com Game Review y Game Analysis. Los patrones que tomamos como referencia (sin copiar su identidad visual) son: evaluación de la partida, clasificación de jugadas, navegación jugada a jugada, coach contextual, mejor continuación y una línea sugerida sincronizada con el tablero.

Fuentes:
- https://support.chess.com/en/articles/8584089-how-does-game-review-work
- https://support.chess.com/en/articles/10328363-how-do-i-use-game-review-on-the-app
- https://support.chess.com/en/articles/8583825-how-do-i-use-the-analysis-board

## Cambios V147
- El coach deja de aparecer únicamente en jugadas consideradas importantes: ahora acompaña cada jugada que tenga resultado de análisis.
- El título del coach refleja la clasificación de la jugada; para resultados sin clasificación se usa «IDEA DEL MOTOR».
- El texto contextual añade la mejor alternativa del motor cuando todavía no está presente en el comentario.
- Se conserva la variante principal (`pv`) de Stockfish en el informe por jugada y se muestra una vista previa de hasta cuatro movimientos UCI.
- La burbuja se amplía moderadamente para permitir tres líneas en móviles.
- Se añadieron contratos de regresión para comprobar la conexión entre comentario, mejor jugada y variante.

## Revisión lógica
- El índice del análisis sigue vinculado al estado del tablero: la posición `index` muestra el análisis de la jugada `index - 1`.
- El análisis sigue ejecutándose en un hilo de trabajo, fuera del hilo principal, y el resultado se aplica al volver a la pantalla mediante el flujo existente.
- No se ha añadido una API de IA externa. Los comentarios se generan con reglas locales usando clasificación, pérdida de evaluación y salida real de Stockfish, por lo que no dependen de internet ni de un servicio de pago.
- La variante se presenta en notación UCI (`e2e4`, etc.), no en notación algebraica SAN. Esto evita inventar una conversión SAN que el proyecto todavía no tiene.

## Validación pendiente
Este entorno no dispone de un ejecutable de Godot, así que no se afirma que los scripts hayan sido compilados ni que las suites hayan corrido dentro del motor. Se ejecutaron comprobaciones estáticas de los cambios y verificación de integridad del ZIP. Debe probarse en Godot 4.7.2 y en Android antes de considerar V147 validada.
