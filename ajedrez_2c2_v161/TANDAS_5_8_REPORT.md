# Ajedrez 2c2 — Tandas 5 a 8

## Tanda 5 — Perfil y datos conectados
- Perfil ampliado con resumen por modalidad 1c1/2c2.
- Récords: mejor rating, racha, número de parejas y mejor pareja.
- Estadísticas por pareja y pareja histórica.
- Logros: solo estructura/espacio visual preparado; condiciones y recompensas pendientes.
- Reacciones: inventario separado del equipamiento, máximo 6 equipadas, equipar/desequipar/reordenar.
- Replay persistente incluido en el historial de partidas.

## Tanda 6 — Personalidad de bots
- Cinco perfiles mantienen sus objetivos internos de dificultad.
- Cada bot dispone además de parámetros de estilo independientes.
- El motor de selección pondera agresividad, desarrollo, centro, seguridad del rey, simplificación y riesgo.
- La calibración existente permanece separada de la personalidad.

## Tanda 7 — Audio y feedback
- Servicio central `AudioFeedback` como autoload.
- Feedback generado para movimiento, captura, enroque, promoción y resultado.
- Ajuste de sonido expuesto en Ajustes.
- El juego dispara feedback desde un único servicio para no duplicar lógica en cada escena.

## Replay persistente
Cada partida guarda un registro compacto de estados:
- tablero de 64 casillas codificado;
- turno;
- ranura activa;
- derechos de enroque;
- objetivo de captura al paso;
- estado de ejecución;
- versión del formato.

El replay se guarda dentro del registro de la partida y puede reconstruirse/decodificarse sin volver a interpretar toda la secuencia de movimientos.

## Tanda 8 — Romper el juego / QA
Se ejecutaron partidas aleatorias, estrés de bots, round-trip del replay, jerarquía de overlays y servicio de audio.

### Resultados principales
- Núcleo de ajedrez: **38/38**
- Tandas 5–7: **23/23**
- Tanda 8: **5368/5368**
- Account Hub: **100/100**
- Perfil: **9/9**
- Bots: **39/39**
- Integración de bots: **6/6**
- Base extra: **9/9**
- UI Regression: **51/51**
- Responsive Visual Audit: **1504/1504**
- Competitivo: **24/24**
- Matchmaking: **8/8**
- Online setup: **37/37**
- Online shell: **3/3**
- Historial: **5/5**
- Entrada de perfil: **4/4**
- Smoke visual de reacciones: **3/3**

## Prueba gráfica
Se generaron capturas reales con Godot 4.7.2 usando Xvfb para móvil y paisaje, incluyendo el selector de reacciones. El selector muestra únicamente las reacciones equipadas y se mantiene dentro de la interfaz.

## Advertencias conocidas
- En el entorno Linux de prueba no existe un dispositivo ALSA; Godot usa el driver de audio dummy. Esto no produjo fallos de las pruebas de gameplay/UI.
- Tanda 8 termina con advertencias de liberación de recursos del arnés de estrés (9 instancias ObjectDB y 2 recursos). Las aserciones de juego fueron **5368/5368**. Es un punto de limpieza del test para la fase de refinado.
- `player_identity_tests.gd` es un módulo `RefCounted` y no debe ejecutarse directamente como `SceneTree`; su cobertura está integrada en `tests/run_tests.gd`, que pasa 38/38.

## Pendientes para la fase de refinado
1. Refinar el catálogo visual de apariencia y añadir temas/packs reales cuando se decidan.
2. Limpiar completamente los avisos de liberación del test de estrés.
3. Hacer una pasada visual global de todas las pantallas y ajustar espaciados/jerarquías donde todavía se pueda pulir.
4. Mantener logros sin activar hasta decidir condiciones y recompensas.
