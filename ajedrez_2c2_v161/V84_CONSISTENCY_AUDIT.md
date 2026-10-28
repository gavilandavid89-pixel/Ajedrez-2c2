# Ajedrez 2c2 — V84 Auditoría de consistencia e incoherencias

Fecha: 5 de octubre de 2026
Motor validado: Godot 4.7.2 real
Viewport de smoke: 720×720

## Objetivo

Revisar el proyecto completo desde dos perspectivas:

1. Revisión principal: coherencia entre código, datos, servicios, UI, tests y documentación.
2. Revisión crítica separada (“alter ego 🗿”): buscar contradicciones, estados que puedan divergir, supuestos ocultos y tests que estén simulando una realidad distinta a la del producto.

La segunda revisión es una pasada adversarial separada; no se afirma la existencia de un segundo modelo/agent externo.

## Inconsistencias corregidas

### 1. Turno != jugador local

El estado de partida usaba `current_slot` para algunas acciones que realmente pertenecen al jugador que está viendo/interactuando con la partida. Esto afectaba especialmente respuestas a Sugerir y podía afectar Rendición, Cambio y Tablas cuando el turno activo era el compañero.

Corrección:
- Se añadió `local_player_slot` al estado de partida.
- Se añadió `set_local_player_slot()`.
- El cliente actual mantiene al jugador en slot 0.
- El HUD decide si una solicitud corresponde al usuario local usando `local_player_slot`, no el turno actual.
- Los botones de respuesta de Sugerir y Tablas usan el slot local.

No se modificaron turnos, equipos ni reglas 2c2.

### 2. Sugerir podía mostrarse a un jugador pero responderse con el slot equivocado

El HUD podía mostrar la sugerencia al slot local mientras `game.current_slot` representaba al compañero. La acción se enviaba entonces con el slot del turno, no con el receptor real.

Corrección:
- Las acciones `accept_suggestion`, `reject_suggestion` y `challenge` usan `local_player_slot`.
- Test añadido que fuerza `current_slot = 2` mientras el receptor local es slot 0.

### 3. Retos amistosos 2c2 guardaban una lista de jugadores incompleta

El reto exigía tres aceptaciones adicionales, pero al iniciar la amistosa el `match_data` solo contenía al creador.

Corrección:
- Se conserva `acceptor_ids`.
- Se conserva `acceptor_names`.
- La partida amistosa guarda `player_ids` y `players` completos.
- Un 2c2 aceptado contiene creador + tres participantes.
- Se rechaza una segunda aceptación del mismo participante.

### 4. Test social incoherente con la identidad real

Un test antiguo llamaba `accept_challenge()` sin indicar participante, lo que representaba al mismo jugador local que había creado el reto. Con la identidad real, eso es correctamente rechazado.

Corrección:
- El test ahora representa a un participante distinto mediante un ID explícito.

### 5. Identidad `Eragon` hardcodeada en servicios sociales

Había identidad fija en chat/retos/creación de clubes.

Corrección:
- La identidad local se toma de `PlayerData.profile`.
- El fundador de nuevos clubes usa el nombre actual.
- Los retos y mensajes nuevos usan identidad dinámica.

Los datos demo históricos que muestran `Eragon` permanecen como fixtures de demostración, no como identidad runtime.

### 6. `PLAYER_K_MAX` no coincidía con la fórmula V2

La constante declaraba 32 pero la fórmula permitía hasta 34.

Corrección:
- `PLAYER_K_MAX = 34`.
- Test de límites añadido.

### 7. Constantes de decaimiento NEXUS antiguas no coincidían con el comportamiento actual

`FORM_DECAY` y `VOLATILITY_DECAY` conservaban valores de una revisión anterior mientras el cálculo utilizaba otros valores.

Corrección:
- Las constantes representan ahora el comportamiento real (`0.90` y `0.94`).
- El cálculo usa las constantes, evitando duplicación de valores.

### 8. Fallback de compañero podía usar el rating propio

Cuando faltaba el snapshot del compañero, el código podía usar el rating propio del jugador como sustituto para sembrar NEXUS-TEAM.

Corrección:
- El fallback es neutral: `NexusTeam.DEFAULT_RATING` (1000).
- Así no se inventa fuerza del compañero a partir de la propia.

### 9. NEXUS-TEAM mantiene explícitamente versión V2 después de actualizar una pareja

Las parejas nuevas ya nacían versionadas, pero una actualización de una estructura antigua dependía de la normalización previa.

Corrección:
- `update_pair()` establece explícitamente `nexus_version = 2`.

### 10. Migración antigua podía heredar defaults NEXUS V2 y parecer ya migrada

Los diccionarios modernos ya traían campos V2 por defecto. Una carga de datos vieja sin `nexus_version` podía heredar esos campos y evitar la rama de migración correcta.

Corrección:
- Al cargar un bloque antiguo sin `nexus_version`, se eliminan solo los campos V2 derivados antes de normalizar.
- Rating/copas históricas se conservan.
- La migración se mantiene suave.

### 11. Actividad temporal de 1c1, 2c2 y pareja

Los timestamps guardados como `0` podían bloquear la reconstrucción desde historial.

Corrección:
- 2c2 recupera última actividad desde historial.
- 1c1 recupera su última actividad independiente.
- Cada pareja recupera su última actividad desde su propio `pair_key`/pareja.

### 12. `pair_stats` local de partida puede confundirse con NEXUS-TEAM

Existe todavía un `pair_stats` dentro del ciclo transitorio de partida que aplica ajustes locales de `+15/-10`.

Decisión:
- No se elimina porque es usado por tests/ciclo actual.
- Se documentó explícitamente como estado transitorio y no como fuente persistente de competitivo.
- La fuente persistente sigue siendo `PlayerData` + NEXUS-TEAM.

## Inconsistencias/gaps detectados pero no cambiados

### A. Acceso a clubes privados/NEXUS todavía no está aplicado en `join_club()`

La UI ofrece:
- Público
- Privado con NEX mínimo
- Solo NEXUS

Pero `ClubsService.join_club()` todavía no aplica esas restricciones.

No se inventó una solución porque el proyecto posee NEXUS 1c1 y NEXUS 2c2 independientes y la documentación no define cuál de ellos controla la entrada al club. Antes de imponer una regla hay que decidir la semántica de “NEX mínimo” para clubes.

### B. NEXUS-TEAM y `pair_stats` son dos representaciones

Aunque ahora están documentadas como capas distintas, mantener dos nombres para estados de pareja aumenta el riesgo futuro de divergencia. `pair_stats` debe permanecer transitorio o retirarse en una pasada de limpieza dedicada.

### C. El contexto competitivo online todavía no recibe un snapshot autoritativo real

`competitive_match_context` ya existe como contrato. El matchmaking actual sigue siendo local/simulado, y los bots aportan ELO temporal. La conexión a un servidor real que entregue ratings individuales, rating de pareja e incertidumbre todavía queda pendiente.

### D. Migración histórica tiene un límite objetivo

El historial persistido conserva las últimas 100 partidas. Una cuenta antigua que tenga más de 100 partidas mixtas antes de la separación 1c1/2c2 no puede reconstruirse perfectamente más atrás de ese límite porque los datos ya no existen en el archivo persistido.

### E. Semántica de “NEXUS” en clubes necesita definición de producto

La UI social usa “NEXUS” en singular mientras el competitivo ya distingue 1c1 y 2c2. No se cambió la interfaz porque elegir automáticamente uno de los dos ratings sería inventar una regla de producto.

### F. Algunos bloques antiguos son legado explícito

Hay código marcado como compatibilidad, mocks/demo y capturas antiguas. No se eliminaron en esta auditoría para evitar convertir una revisión de coherencia en una limpieza destructiva. Quedan candidatos para una pasada exclusiva de deuda técnica.

## Validación

### Tests relevantes

- Consistency Audit V84: **18/18**
- Sugerencias V50: **21/21**
- NEXUS V2: **10/10**
- NEXUS-TEAM: **27/27**
- Match Context: **11/11**
- Social V70: **36/36**
- Social V71: **9/9**
- Competitive/Core runner: **39/39**
- Account Hub: **149/149**
- Profile UI: **9/9**

### Godot real

- Godot 4.7.2 estable.
- Importación/editor headless correcta.
- Smoke real de la aplicación en 720×720 ejecutado durante 14 s; terminó por timeout esperado, sin `SCRIPT ERROR` ni `Parse Error`.
- Advertencias presentes: V-Sync del driver y ejecución como root en el entorno de prueba.
- El runner completo sigue mostrando al finalizar: `1 resources still in use at exit`. Esto es una advertencia de limpieza del entorno/test runner y no produjo fallos de pruebas.

## Conclusión

La auditoría no encontró una razón para volver a rediseñar NEXUS V2. Las incoherencias corregidas estaban principalmente en integración de estados, identidad, migración y separación entre “turno” y “jugador local”.

La arquitectura competitiva actual queda conceptualmente separada en:

- NEXUS-SOLO 1c1
- NEXUS-SOLO 2c2
- NEXUS-TEAM por pareja
- Match Context como contrato de datos

Las áreas que quedan abiertas requieren decisiones de producto o infraestructura, no otra modificación matemática improvisada.
