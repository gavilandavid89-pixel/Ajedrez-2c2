# Ajedrez 2c2 — Informe de modularización V66

## Objetivo
Completar la modularización de los cuatro monolitos señalados después de V65 sin cambiar las reglas de 2c2 ni alterar la API pública usada por las pantallas y tests.

## Cambios realizados

### 1. `domain/player/player_data.gd`
Reducción a fachada/coordinador con delegación a:
- `player_persistence_service.gd`
- `player_competitive_service.gd`
- `player_history_service.gd`
- `player_ranking_service.gd`
- `player_customization_service.gd` (ya existente)

Se añadió inicialización diferida de servicios para que las llamadas tempranas desde tests y otros coordinadores sean seguras.

### 2. `domain/replay/match_replay_view.gd`
Reducción a fachada con:
- `replay_board.gd`
- `replay_view_controller.gd`
- `replay_view_layout_service.gd`
- `match_replay_state_service.gd` (V65)

La vista ahora puede recibir configuración y datos antes de `_ready()` sin producir referencias nulas. El layout posterga su primer resize hasta estar dentro del árbol de escena.

### 3. `ui/screens/game.gd`
Reducción a coordinador con:
- `game_input_controller.gd`
- `game_bot_coordinator.gd`
- `game_match_result_service.gd`
- `game_flow_controller.gd`

Se repararon referencias que pertenecían a la pantalla original (`get_viewport`, `_on_state_changed`, configuración y navegación) para que los nuevos módulos funcionen de forma independiente.

### 4. `core/services/storage_manager.gd`
Reducción a fachada con:
- `storage_file_service.gd`
- `storage_profile_service.gd`
- `storage_cache_service.gd`
- `storage_sync_service.gd`

Se mantuvo la señal `storage_changed` pública y se corrigió su emisión desde el servicio de perfil.

## Protección arquitectónica
- `modular_architecture_tests.gd`: 36 checks / 0 fallos.
- `module_contracts_v66_tests.gd`: 17 / 17 módulos instanciables.

## QA final con Godot 4.7.2
- Core: 39/39
- Contratos V66: 17/17
- Arquitectura: 36/36
- Personalización: 14/14
- NEXUS-TEAM: 27/27
- Account Hub: 149/149
- Replay/análisis: 3/3
- Storage: 18/18
- V58: 42/42
- V59: 25/25
- V60: 15/15
- V61: 22/22
- Tests de bots/movimiento/integración ejecutados con RC 0
- Importación/editor Godot 4.7.2: sin errores de parser
- Batería final: sin `SCRIPT ERROR` ni errores de llamadas nulas

## Reglas preservadas
No se modificaron intencionalmente las reglas de 2c2, Sugerir, Cambio, turnos, equipos, aceptación/rechazo, condiciones de victoria/derrota ni el aislamiento competitivo 1c1/2c2.

## Tamaño de los coordinadores objetivo
- `player_data.gd`: 288 líneas
- `match_replay_view.gd`: 156 líneas
- `game.gd`: 167 líneas
- `storage_manager.gd`: 109 líneas

Estos archivos ahora coordinan módulos especializados en lugar de contener todas las responsabilidades internas.

## Siguiente bloque pendiente
`domain/chess/game_state.gd` sigue siendo el principal coordinador grande del dominio. Ya tiene separadas comunicación social y captura de replay, pero todavía agrupa ciclo de partida, resolución de movimientos, presencia y coordinación interna del dominio. Esa será la siguiente deuda modular antes de retomar features nuevas.
