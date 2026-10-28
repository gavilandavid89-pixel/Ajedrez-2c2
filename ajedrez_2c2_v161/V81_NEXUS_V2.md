# Ajedrez 2c2 — V81 NEXUS V2

## Objetivo
Mejorar el sistema NEXUS sin modificar ninguna regla de juego 2c2.

## Cambios
- NEXUS core actualizado a versión 2.
- Incertidumbre: aprendizaje más gradual; no pierde utilidad demasiado rápido.
- K adaptativo: combina incertidumbre y volatilidad con una curva suave.
- Volatilidad: responde a resultados sorprendentes y se normaliza lentamente.
- Forma: representa rendimiento reciente y se desvanece durante la inactividad.
- Inactividad: aumenta incertidumbre sin quitar rating directamente.
- Confianza interna derivada de incertidumbre, sin exponer variables internas en UI pública.
- 1c1 ahora usa el mismo núcleo NEXUS-SOLO, pero mantiene rating, copas, historial y estado completamente separados de 2c2.
- NEXUS-TEAM continúa siendo independiente del NEXUS individual.
- NEXUS-TEAM mantiene estados independientes por pareja.
- Migración suave: se conserva el rating/coplas existentes; los estados antiguos reciben campos V2 sin reiniciar progreso.

## Lo que NO cambió
- Reglas de partidas 2c2.
- Mecánicas Sugerir/Cambio.
- Separación competitiva entre 1c1 y 2c2.
- Separación entre NEXUS individual y NEXUS-TEAM.
- Sistema de copas y ligas.

## Benchmark de simulación
Se comparó el núcleo actual contra NEXUS V2 en 3 modelos de resultado y 4 escenarios (stationary, drift, improvers, farm), con 24.000 partidas por corrida y 3 semillas.

Promedio por modelo de resultado:

| Modelo | Sistema | LogLoss | Brier | Calibración | RankCorr |
|---|---|---:|---:|---:|---:|
| current_like | Actual | 0.54569 | 0.16373 | 0.03889 | 0.97196 |
| current_like | NEXUS V2 | **0.53677** | **0.16048** | **0.01687** | **0.97217** |
| moderate_draw | Actual | 0.55912 | 0.17183 | 0.03470 | 0.96934 |
| moderate_draw | NEXUS V2 | **0.55172** | **0.16914** | **0.01374** | **0.96956** |
| high_draw | Actual | 0.57017 | 0.16087 | 0.03181 | 0.96933 |
| high_draw | NEXUS V2 | **0.56366** | **0.15851** | **0.01223** | 0.96908 |

Resultado: V2 mejora LogLoss, Brier y calibración en los tres modelos. La correlación de ranking permanece prácticamente igual, con una diferencia mínima en el escenario high_draw.

## Validación Godot 4.7.2
- Import/editor: PASS.
- NEXUS V2: 8/8 PASS.
- Competitive regression: 34/34 PASS.
- NEXUS-TEAM regression: 27/27 PASS.
- 1c1 progression: 5/5 PASS.
- Account Hub: 149/149 PASS.
- Profile UI: 9/9 PASS.
- History/Profile/Matchmaking/Online Setup y demás pruebas relacionadas ejecutadas sin fallos competitivos.
- Smoke de la aplicación real en 720x720: arranca y permanece ejecutándose sin `SCRIPT ERROR` ni `Parse Error`. Los avisos de V-Sync/audio corresponden al entorno de ejecución.

## Nota
La confianza es un dato interno derivado de la incertidumbre. No se añade como estadística pública del perfil.
