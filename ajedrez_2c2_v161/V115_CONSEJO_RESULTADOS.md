# Ajedrez 2c2 — V115: Idempotencia de resultados

## Hallazgo real

La auditoría encontró una asimetría: los resultados competitivos ya rechazaban un segundo registro con el mismo `match_id`, pero `record_noncompetitive_match()` siempre añadía una fila nueva. Si una señal de finalización se repetía durante una transición o reintento, una partida local/práctica podía aparecer duplicada en el historial.

## Corrección

`domain/player/player_history_service.gd` ahora busca un `match_id` estable antes de guardar una partida no competitiva. Si ya existe, devuelve la entrada previa con `duplicate=true` y `ok=true`, sin sobrescribir el resultado original, añadir una fila, guardar ni emitir un segundo cambio de historial. Cuando no hay ID suministrado, sigue generando uno nuevo como antes.

## Pruebas añadidas

`tests/v115_result_idempotency_tests.gd` verifica:

1. Un segundo final de partida local/práctica se identifica como duplicado.
2. No se añade otra fila al historial.
3. El resultado original no puede ser reemplazado por un reintento contradictorio.
4. Un resultado competitivo inválido se rechaza sin mutar el historial.
5. El procesamiento competitivo duplicado no vuelve a alterar rating ni partidas.

La suite contiene **6 comprobaciones** automatizadas.

## Regresión ejecutada en Godot 4.7.2

| Suite | Resultado |
|---|---:|
| Pruebas principales | 42/42 |
| V113 — casos límite del motor | 8/8 |
| V114 — transiciones y promoción | 13/13 |
| V115 — idempotencia de resultados | 6/6 |
| NEXUS por equipos | 27/27 |
| NEXUS V2 | 10/10 |
| Sistema competitivo | 34/34 |
| Contexto competitivo | 11/11 |
| V112 — reglas e input | 11/11 |

Total sumado: **162 aprobaciones** en las suites enumeradas. Son suites independientes con posible solapamiento, no 162 escenarios únicos.

## Alcance y límites

La corrección está cubierta por pruebas automatizadas de Godot y las suites relacionadas pasaron. La importación del proyecto finalizó con código de salida 0 y sin errores de script o parseo en el registro revisado.

Esto no sustituye la validación de desconexiones de red reales ni pruebas en Android físico. La idempotencia se basa en un `match_id` estable: las llamadas sin ID siguen generando identificadores distintos para no fusionar partidas legítimas diferentes.

## Dictamen del consejo

Se corrigió un defecto reproducible en el registro de partidas no competitivas sin alterar la lógica de ajedrez ni el sistema 2c2. Próximo objetivo: auditar que cada motivo de finalización (mate, tablas, abandono y desconexión) se traduzca en un único resultado coherente, especialmente cuando se mezclan eventos tardíos de red y transiciones de escena.
