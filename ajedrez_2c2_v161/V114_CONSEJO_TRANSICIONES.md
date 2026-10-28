# Ajedrez 2c2 — V114: Transiciones de partida y reproducción

## Qué se añadió

Se incorporó `tests/v114_transition_tests.gd`, una suite automatizada de 13 comprobaciones centradas en una transición delicada: la promoción de peón y su coherencia con el estado de partida y la reproducción.

Comprueba que:

- Un peón que alcanza la última fila abre una promoción pendiente.
- La promoción no se resuelve antes de elegir pieza.
- Una elección no válida no consume la promoción pendiente.
- La subpromoción a caballo se acepta y se refleja en el tablero.
- El historial registra la pieza elegida.
- El reloj de medio movimiento se mantiene reiniciado después de la jugada de peón.
- El estado de reproducción se captura una sola vez cuando la promoción queda resuelta.
- El turno cambia después de resolver la promoción, no antes.
- El decodificador rechaza tableros malformados.
- La reproducción conserva el bando al turno, el reloj de medio movimiento y el tablero 8×8.

## Pruebas ejecutadas con Godot 4.7.2

| Suite | Resultado |
|---|---:|
| V114 — transiciones y promoción | 13/13 |
| V113 — casos límite del motor de reglas | 8/8 |
| V112 — reglas e input | 11/11 |
| Pruebas principales | 42/42 |
| NEXUS por equipos | 27/27 |
| NEXUS V2 | 10/10 |
| Sistema competitivo | 34/34 |
| Contexto competitivo | 11/11 |

Total sumado de estas suites: **156 aprobaciones**. Son resultados de suites independientes; no deben interpretarse como 156 escenarios únicos.

## Dictamen

Las pruebas no detectaron regresiones en las áreas cubiertas. No se necesitó modificar las reglas de movimiento ni alterar la rotación de turnos 2c2 para esta entrega; V114 agrega cobertura de regresión.

## Límites conocidos

- No equivale a una certificación exhaustiva de todas las reglas FIDE.
- No se ha realizado una prueba en un teléfono Android físico.
- La integración del motor Stockfish ARM64 en un dispositivo real sigue pendiente de validación.
- Los reclamos de tablas anunciando una jugada futura que causaría la tercera repetición siguen fuera del alcance actual.
