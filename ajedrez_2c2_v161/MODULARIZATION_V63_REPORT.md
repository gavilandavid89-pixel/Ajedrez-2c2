# Modularización V63

## Objetivo
Separar responsabilidades para que cambiar una función concreta (por ejemplo Chat) no requiera editar módulos ajenos.

## Hecho en V63

- Scripts productivos reorganizados por responsabilidad: `core/`, `domain/`, `ui/`.
- Navegación centralizada mediante `ScreenCatalog` + `NavigationService`.
- Tema base centralizado mediante `ThemeTokens` + `ThemeService`.
- Chat extraído a componente/controlador propio: `GameChatController` + `GameChatPanel`.
- Sugerencias y paneles contextuales extraídos a `GameOverlayController`; GameHUD conserva solo la fachada/orquestación.
- La escena de Chat ya tiene dueño propio y expone señales/métodos, evitando acceso directo del HUD a la implementación interna.
- NEXUS-TEAM permanece completamente dentro de `domain/competitive/`.
- Prueba automática de arquitectura: 14/14.
- Core general: 39/39.
- NEXUS-TEAM: 27/27.
- Account Hub: 149/149.
- UI regression: 53/53.
- Responsive touch: 30/30.
- Suggestion V61: 22/22.
- Importación de proyecto Godot sin errores de parser.

## Regla de mantenimiento

Una futura modificación de Chat debe tocar `ui/components/game/game_chat_*` y su contrato/señales, no `domain/chess`, `domain/competitive`, `player_data` ni otros módulos.

## QA posterior al corte de overlays

- Core: 39/39.
- NEXUS-TEAM: 27/27.
- Account Hub: 149/149.
- UI regression: 53/53.
- V61 suggestion: 22/22.
- Importación Godot: limpia.

## Próxima frontera de modularización

Los siguientes monolitos aún contienen varias responsabilidades internas y deben seguir dividiéndose sin cambiar comportamiento: `ui/screens/account_hub.gd` y partes internas de `ui/screens/game_hud.gd`. Esta tanda no los marca como "completamente extraídos" para no falsear el estado real.

## Inventario actual

- `core/layout/layout_metrics.gd`
- `core/navigation/navigation_service.gd`
- `core/navigation/screen_catalog.gd`
- `core/services/app.gd`
- `core/services/audio_feedback.gd`
- `core/services/cloud_sync.gd`
- `core/services/runtime_services.gd`
- `core/services/storage_manager.gd`
- `core/theme/theme_contract.gd`
- `core/theme/theme_service.gd`
- `core/theme/theme_tokens.gd`
- `domain/bots/bot_controller.gd`
- `domain/bots/bot_data.gd`
- `domain/bots/bot_decision_benchmark.gd`
- `domain/bots/calibration_runner.gd`
- `domain/bots/stockfish_engine.gd`
- `domain/chess/game_state.gd`
- `domain/chess/rules.gd`
- `domain/competitive/competitive_system.gd`
- `domain/competitive/matchmaking_logic.gd`
- `domain/competitive/nexus_team.gd`
- `domain/player/emote_data.gd`
- `domain/player/player_data.gd`
- `domain/player/profile_data.gd`
- `domain/replay/game_review_service.gd`
- `domain/replay/match_replay_view.gd`
- `ui/components/board.gd`
- `ui/components/emote_picker.gd`
- `ui/components/game/game_chat_controller.gd`
- `ui/components/game/game_chat_panel.gd`
- `ui/components/game_action_menu.gd`
- `ui/components/player_card.gd`
- `ui/components/qr_preview.gd`
- `ui/navigation/main_navigation.gd`
- `ui/screens/account_hub.gd`
- `ui/screens/bot_setup.gd`
- `ui/screens/game.gd`
- `ui/screens/game_hud.gd`
- `ui/screens/loading.gd`
- `ui/screens/mode_menu.gd`
- `ui/screens/online_matchmaking.gd`
- `ui/screens/online_setup.gd`
