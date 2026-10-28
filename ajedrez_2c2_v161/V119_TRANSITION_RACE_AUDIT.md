# Ajedrez 2c2 — V119: auditoría de transiciones y eventos tardíos

## Cambios aplicados

1. **Protección contra eventos de conexión atrasados.** Una vez que un jugador está marcado como desconectado, un evento tardío `grace_period` ya no puede volver a activar su estado de gracia ni revocar la delegación temporal. La reconexión explícita sí puede restaurar el asiento.
2. **Partidas terminadas inmutables frente a eventos de conexión.** `set_slot_connection_status()` rechaza cambios cuando la partida ya no está en curso. Una reconexión tardía no altera los asientos ni reactiva el control tras mate, tablas o rendición.
3. **Pruebas de secuencias completas.** Se añadió `tests/v119_transition_race_tests.gd`, con escenarios de desconexión → delegación → oferta de tablas → reconexión, eventos atrasados, segunda desconexión y rendición seguida de reconexión tardía.

## Resultados en Godot 4.7.2

Todas las suites listadas terminaron con código de salida 0:

| Suite | Resultado |
|---|---:|
| Nuevas carreras de transición V119 | 27/27 |
| Integración de delegación V118 | 21/21 |
| Política de delegación V117 | 32/32 |
| Política de desconexión V116 | 18/18 |
| Reglas/input V112 | 11/11 |
| Pruebas principales | 42/42 |
| NEXUS por equipos | 27/27 |
| NEXUS V2 | 10/10 |
| Sistema competitivo | 34/34 |
| Contexto competitivo | 11/11 |
| Orientación/layout | 22/22 |
| Transiciones V114 | 13/13 |
| Idempotencia de resultados V115 | 6/6 |
| Mantenimiento social | 29/29 |
| Funciones sociales V70 | 36/36 |
| Extensiones sociales V71 | 9/9 |

**Total sumado: 348 aprobaciones** entre suites independientes, con solapamiento de cobertura; no deben interpretarse como 348 casos únicos.

## Límites

- El estado de conexión sigue siendo inyectado mediante un puente interno. Todavía no hay detector de red ni servidor autoritativo.
- No se ha probado una partida online entre dispositivos reales.
- No se modificaron reglas del tablero ni la rotación normal de turnos; el cambio protege la transición de estados.

## Dictamen

La suite nueva y las suites de regresión seleccionadas pasan. La próxima fase debe comprobar movimientos reales en los turnos delegados (incluida promoción), sincronización del historial, eventos sociales simultáneos y el contrato que usará un futuro adaptador de red para entregar eventos ordenados y autenticados.
