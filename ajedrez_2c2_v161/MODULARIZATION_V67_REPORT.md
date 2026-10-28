# Ajedrez 2c2 — Modularización V67

## Objetivo
Cerrar la deuda modular restante de `domain/chess/game_state.gd` sin cambiar reglas de ajedrez ni reglas 2c2.

## Resultado
`game_state.gd` queda como estado + fachada pública. Las responsabilidades extraídas son:

- `domain/chess/game_match_lifecycle_service.gd`
  - reset/inicialización de partida
  - reloj por equipos
  - presencia/ausencia
  - turnos y representación de compañero
  - perfiles de slot
  - cierre y resultado de partida
  - estadísticas de pareja locales de la partida
- `domain/chess/game_move_service.gd`
  - selección/validación de movimiento
  - aplicación de movimientos
  - en passant
  - enroque y derechos especiales
  - promoción
  - resolución post-movimiento
- `domain/chess/game_bot_service.gd`
  - bots temporales
  - detección de turno de bot
  - ejecución de jugada del bot
  - sugerencia generada por bot
- `domain/chess/game_social_service.gd` ya existente
  - Sugerir, Cambio, Rendirse, Tablas, chat y reacciones
- `domain/replay/match_replay_state_service.gd` ya existente
  - captura y serialización del replay

La API histórica de `ChessGameState` se conserva mediante delegadores para no romper escenas ni pruebas existentes.

## Tamaño del núcleo
- `game_state.gd`: 669 → 330 líneas.
- Ciclo/presencia: 397 líneas.
- Movimiento: 230 líneas.
- Bots: 65 líneas.

El estado central ya no contiene implementaciones directas de movimientos ni de bots.

## QA V67 — Godot 4.7.2
- Importación/editor: OK, sin errores de parser.
- Contratos del dominio V67: **10/10**.
- Contratos de módulos V67: **20/20**.
- Arquitectura modular: **42/42**.
- Núcleo completo: **39/39**.
- Account Hub: **149/149**.
- Personalización: **14/14**.
- V58 HUD: **42/42**.
- V59 HUD: **25/25**.
- V60 orientación/chat/acciones: **15/15**.
- V61 Sugerir compacto: **22/22**.
- NEXUS-TEAM: **27/27**.
- Storage: **18/18**.
- Movimiento/Bot regression: **21/21**.
- Tanda 8 stress/break-game: **5366/5366**.
- Tanda 9 estabilidad: **19/19**.
- Base extra: **9/9**.
- Historial: **5/5**.
- Matchmaking: **8/8**.
- Online setup: **37/37**.
- Tandas 5–7: **23/23**.
- V49 bot/sugerencia: **8/8**.
- V50 Sugerir: **19/19**.
- V56 1c1: **5/5**.
- V57 presentación 1c1: **5/5**.
- Identidad de jugador: **7/7**.
- UI regression: **53/53**.
- Replay analysis V35: **3/3**.

## Comportamientos críticos verificados
- Movimiento táctil sin doble toque.
- Movimiento humano → respuesta de bot.
- Tres bots temporales 2c2 completan su ciclo.
- Turnos A → B → C → D intactos.
- Sugerir sigue siendo propuesta/ghost y no mueve la pieza.
- Ausencia y cobertura del compañero intactas.
- Relojes y timeout intactos.
- Enroque, en passant, promoción, jaque, mate y ahogado intactos.
- NEXUS y 1c1 siguen aislados del gameplay.

## Nota sobre un test antiguo
`tests/replay_vs_game_board_v46.gd` continúa fallando en V67 con el mismo comportamiento observado en un V66 limpio: sus expectativas de layout de replay son incompatibles con la implementación actual y además intenta acceder a `ReplayLayout/ReplayNavigation`. No se modificó como parte de V67 porque la falla es preexistente y no está relacionada con `game_state`.

## Warnings de ejecución
Las ejecuciones headless continúan mostrando warnings de ALSA/root y algunos `ObjectDB/resource leaks` al terminar los runners. No aparecen `SCRIPT ERROR`, errores de parser ni fallos funcionales en las suites verdes.

## Regla futura
Toda feature nueva con estado, interacción o lógica propia debe nacer como módulo/servicio/componente independiente con contrato, y la pantalla/coordinador solo debe orquestarla.
