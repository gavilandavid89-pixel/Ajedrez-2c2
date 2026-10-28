# Ajedrez 2c2 — Modularización V64

## Objetivo
Reducir responsabilidades cruzadas para que modificar una feature no requiera editar accidentalmente otras partes del juego.

## Cambios
- `ui/components/account_page_renderer.gd`: Perfil, Ranking, Copas, Historial, Análisis, Replay, Apariencia, Reacciones, Ajustes, Más y Ayuda salen de `account_hub.gd`.
- `ui/components/game/game_hud_layout.gd`: toda la geometría responsive, layout de equipos, controles inferiores, popups y resultado sale de `game_hud.gd`.
- `domain/player/player_customization_service.gd`: identidad visual, ajustes, avatar, nombre, apariencia y reacciones salen de `player_data.gd`.
- Chat y overlays permanecen en componentes independientes.
- `MODULE_ARCHITECTURE.md` define fronteras y contrato para futuras features.
- `tests/modular_architecture_tests.gd` se amplió a 18 checks y verifica módulos obligatorios y que las escenas no posean scripts ejecutables propios.

## Compatibilidad
Los métodos públicos existentes se conservaron como delegadores. Esto evita romper escenas, tests o llamadas existentes mientras el código real vive en su módulo propietario.

## Reglas 2c2
No se modificaron reglas de partida. Sugerir, Cambio, turnos, equipos, aceptación/rechazo, victoria/derrota, tablas y comunicación permanecen en el dominio de partida.
NEXUS-TEAM permanece separado del gameplay.

## QA
- Godot 4.7.2 editor/import: OK, sin errores de parser.
- Core: 39/39.
- Arquitectura: 18/18.
- Account Hub: 149/149.
- Personalización: 14/14.
- V58: 42/42.
- V59: 25/25.
- V60: 15/15.
- V61: 22/22.
- NEXUS-TEAM: 27/27.

## Próximas fronteras de modularización
Los módulos grandes restantes que deben continuar dividiéndose por responsabilidad son:
- `domain/chess/game_state.gd`: turnos/ausencia, movimientos, propuestas 2c2, comunicación, bots y replay.
- `domain/player/player_data.gd`: competitivo, historial, temporadas/rankings y persistencia.
- `domain/replay/match_replay_view.gd`: reproducción, navegación, análisis visual y layout.
- `ui/screens/game.gd`: coordinación de partida, input y bots.
- `core/services/storage_manager.gd`: persistencia y caché.

La regla es seguir reduciendo estos coordinadores sin cambiar sus contratos públicos ni las reglas del juego.
