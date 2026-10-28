# Ajedrez 2c2 — V113 Consejo: auditoría extrema de reglas

## Alcance

Ronda adicional de pruebas sobre la base V112. No se cambió la lógica de juego: se añadieron pruebas dirigidas a situaciones límite del motor de reglas, para comprobar el comportamiento existente antes de considerar una modificación.

## Nuevas regresiones cubiertas

1. El enroque se rechaza si la casilla de tránsito está atacada.
2. El enroque se rechaza si falta la torre, aunque el derecho de enroque indique `true`.
3. El rey no puede capturar una pieza defendida por el rey rival.
4. Una torre clavada no puede abandonar la línea y exponer a su rey.
5. La captura al paso se rechaza si abre una línea de torre contra el rey propio.
6. Los peones atacan diagonalmente incluso cuando la casilla objetivo está vacía.
7. Se reconoce el jaque mate cuando el rey no dispone de respuesta legal.
8. Se reconoce el ahogado cuando el bando no está en jaque y carece de movimientos legales.

## Resultados ejecutados en Godot 4.7.2

| Suite | Resultado |
|---|---:|
| Nuevos casos límite V113 | 8/8 |
| Reglas/input V112 | 11/11 |
| Pruebas principales | 42/42 |
| NEXUS por equipos | 27/27 |
| NEXUS V2 | 10/10 |
| Sistema competitivo | 34/34 |
| Contexto de partida competitiva | 11/11 |
| Mantenimiento social | 29/29 |
| Orientación y diseño adaptable | 22/22 |

Total de pruebas aprobadas en las suites enumeradas: **194**. Es la suma de resultados de suites independientes; algunas cubren áreas relacionadas, por lo que no equivale a 194 escenarios únicos.

## Hallazgos y límites

- La primera versión de la prueba de ataque de peón apuntaba a una fila incorrecta. Se corrigió el caso de prueba para respetar la orientación del tablero; no requirió modificar el motor.
- Esta ronda no ha encontrado un fallo de reglas que justifique cambiar `rules.gd`.
- No se afirma que todas las reglas FIDE estén exhaustivamente cubiertas: la prueba de repetición por jugada anunciada (reclamo antes de ejecutarla) sigue fuera del alcance de la implementación actual.
- No se ha probado en un dispositivo Android físico ni se ha verificado la integración real con el binario Android ARM64 de Stockfish en un teléfono. Las pruebas de motor anteriores de la V112 incluían protocolo simulado.

## Archivos

- `tests/v113_chess_edge_tests.gd`: nueva suite ejecutable.
- Base funcional conservada desde V112.

## Dictamen del consejo

**Aprobado para continuar con la siguiente ronda de auditoría**, sin reescribir reglas que ya pasan sus pruebas. El siguiente objetivo razonable es probar transiciones completas de partida (promoción pendiente, finalización, repetición de resultado y reproducción) y revisar las reglas de tablas contra casos de referencia adicionales.
