# V38 — Revisión movimiento por movimiento

## Objetivo

La pantalla de Análisis pasa de ser un informe a un estudio de la partida. Cada posición se compara con las alternativas legales disponibles y la jugada realizada recibe una clasificación de revisión local.

## Evaluador

Se reutiliza el evaluador táctico existente de los bots mediante un servicio independiente (`analysis_service.gd`). Esto permite comparar jugadas sin duplicar reglas de ajedrez.

No se presenta como Stockfish ni como una evaluación de motor certificada. El origen se guarda como `local_heuristic` para poder sustituirlo más adelante por un motor de mayor profundidad sin cambiar la interfaz.

## Datos guardados

Cada informe contiene:

- versión del informe;
- origen del evaluador;
- resultado por movimiento;
- mejor alternativa encontrada;
- pérdida de evaluación de la jugada realizada;
- resumen de mejores/buenas/imprecisas/errores;
- lista de momentos críticos.

El informe se guarda dentro del registro de historial como `analysis_report`.

## Clasificaciones actuales

- `mejor`: la jugada coincide con la mejor alternativa o queda dentro del margen mínimo.
- `buena`: pérdida pequeña.
- `imprecisa`: pérdida intermedia.
- `error`: pérdida importante.
- `error_grave`: pérdida muy grande.

Los umbrales son internos del evaluador local y podrán recalibrarse cuando se incorpore un motor dedicado.

## Interfaz

El análisis no añade otro bloque superior ni obliga a desplazarse por un informe. El tablero permanece como elemento principal y las jugadas se resaltan directamente en la hoja de movimientos.
