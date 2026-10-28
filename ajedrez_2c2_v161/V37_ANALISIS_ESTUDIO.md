# V37 — Análisis como estudio de partida

La revisión deja de funcionar como una página de estadísticas que obliga a deslizar para llegar al tablero.

## Cambio

Al entrar en **Analizar** se muestra directamente el estudio interactivo de la partida:

- tablero real;
- lista de jugadas;
- selección de posiciones;
- sin resumen de rendimiento encima;
- sin datos secundarios encima;
- sin inspector textual separado;
- sin botón redundante para volver a abrir el replay.

## Próxima etapa

El espacio queda preparado para una revisión automática movimiento por movimiento, inspirada conceptualmente en los estudios de Chess.com, pero sin copiar su interfaz ni fabricar resultados.

Cuando exista un evaluador real, cada movimiento podrá recibir una clasificación basada en esa evaluación y resaltarse en la lista. Las métricas como precisión, errores o rendimiento solo se mostrarán cuando puedan calcularse a partir de datos reales.
