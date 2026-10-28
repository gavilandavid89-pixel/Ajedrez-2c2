# V39 — Tira compacta y motor de ajedrez

## Interfaz

La hoja de movimientos dejó de ser una tabla vertical. Ahora es una sola tira horizontal compacta debajo del tablero:

`Inicio  1. e2-e4  1... e7-e5  2. g1-f3  2... b8-c6 ...`

La tira ocupa una altura fija pequeña y se desplaza horizontalmente cuando la partida supera el ancho disponible. Al seleccionar una jugada, el tablero salta directamente a esa posición.

## Revisión

Se retiró el evaluador heurístico provisional de V38. Ya no se guardan `analysis_report`, `review_classification`, `review_loss` ni alternativas calculadas por el bot.

El análisis futuro se delegará a un motor UCI real. Stockfish es un motor UCI de código abierto bajo GPLv3 y su proyecto oficial documenta compilación para Android con NDK; la integración deberá incluir las obligaciones de licencia y el código fuente correspondiente a la versión distribuida.

## Regla

No mostrar “mejor”, “error”, “imprecisa”, precisión o evaluaciones hasta que provengan del motor real.
