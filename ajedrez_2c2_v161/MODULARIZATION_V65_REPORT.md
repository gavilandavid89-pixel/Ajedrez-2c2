# Ajedrez 2c2 — Modularización V65

## Objetivo
Continuar la modularización total sin modificar las reglas ni la filosofía de 2c2.

## Extracciones de esta tanda
- `domain/chess/game_social_service.gd`
  - Sugerir / responder / cuestionar
  - Cambio
  - Rendición
  - Tablas
  - Chat
  - Emotes
  - Modo estratégico
- `domain/replay/match_replay_state_service.gd`
  - Codificación del tablero para replay
  - Captura de estados
  - Serialización de replay
  - Decodificación de estados
  - Acceso a movimientos del replay

`domain/chess/game_state.gd` conserva la API pública mediante delegadores, evitando romper las escenas y tests existentes.

## Reglas preservadas
- No se modificaron turnos, equipos, colores ni movimientos legales.
- Sugerir sigue siendo propuesta visual y no movimiento automático.
- Cambio y Sugerir siguen limitados a 2c2.
- Rendición y tablas conservan su flujo existente.
- Replay conserva el formato y contrato existentes.

## QA Godot 4.7.2
- Core: 39/39
- Arquitectura: 20/20
- Personalización: 14/14
- V58: 42/42
- V59: 25/25
- V60: 15/15
- V61: 22/22
- NEXUS-TEAM: 27/27
- Importación/editor: OK

## Siguiente deuda modular
Todavía quedan responsabilidades grandes por separar, principalmente:
- `domain/chess/game_state.gd` — ciclo de partida/movimiento/presencia/bots
- `domain/player/player_data.gd` — persistencia, historial, competitivo y migraciones
- `domain/replay/match_replay_view.gd` — presentación/navegación de replay
- `ui/screens/game.gd` — coordinación de entrada/ciclo de partida
- `core/services/storage_manager.gd` — backend/cache/serialización

La próxima tanda debe continuar estas separaciones antes de volver al desarrollo de nuevas funciones.
