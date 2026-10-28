# Calibración interna de bots

Fecha: 2026-09-30

## Qué se calibró
La escala 400 / 700 / 1000 / 1300 / 1600 se utiliza como **Elo objetivo aproximado para la interfaz y el diseño de dificultad**. No se presenta como un Elo humano oficial.

El comportamiento del bot se calibra con cuatro componentes:
- aleatoriedad intencionada;
- ruido en la evaluación;
- profundidad de búsqueda;
- selección entre los mejores candidatos.

## Medición utilizada
Se generaron 30 posiciones a partir de partidas cortas aleatorias y se comparó la jugada elegida por cada bot contra la mejor jugada inmediata disponible mediante la evaluación interna del motor.

Indicadores:
- `avg_quality`: calidad media normalizada (1.0 = coincide con la mejor evaluación inmediata).
- `acceptable_rate`: porcentaje de jugadas con pérdida <= 80 puntos de evaluación.
- `blunder_rate`: porcentaje de jugadas con pérdida >= 350 puntos.

## Resultado de la calibración actual
| Bot | Elo objetivo | Calidad media | Aceptables | Errores graves |
|---|---:|---:|---:|---:|
| Mateo | 400 | 0.7702 | 33.3% | 23.3% |
| Nora | 700 | 0.8234 | 43.3% | 13.3% |
| Táctico | 1000 | 0.8626 | 56.7% | 13.3% |
| Estratega | 1300 | 0.9196 | 73.3% | 6.7% |
| Experto | 1600 | 0.9979 | 100.0% | 0.0% |

La progresión interna es monotónica y deja una diferencia clara entre niveles.

## Importante sobre el Elo
Una equivalencia del tipo "este bot es exactamente 1000 Elo humano" requiere calibrarlo contra un conjunto externo de partidas o rivales cuyo rating sea conocido y bajo condiciones de tiempo comparables. Esta calibración interna no afirma eso. Su objetivo actual es que la **curva de dificultad del juego sea progresiva y reproducible**.

## Repetir la calibración
Ejecutar:
`res://domain/bots/bot_decision_benchmark.gd`

Los resultados se guardan en:
`res://bot_decision_benchmark.json`

El experimento de auto-partidas `res://domain/bots/calibration_runner.gd` se conserva como herramienta adicional, pero no se usa como fuente principal de la cifra de dificultad porque las tablas y el límite de jugadas pueden introducir ruido en una muestra pequeña. Si se ejecuta, escribe su resultado auxiliar en `user://bot_calibration_results.json` para no intentar modificar el directorio del proyecto o una instalación exportada.
