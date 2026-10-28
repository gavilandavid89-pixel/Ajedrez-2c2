# Ajedrez 2c2 — Arquitectura modular V67

## Regla principal
Cada funcionalidad tiene un módulo propietario. Las pantallas coordinan; no deben convertirse en almacenes de lógica ajena.

### Fronteras
- `core/`: infraestructura, navegación, tema, layout, almacenamiento y servicios transversales.
- `domain/chess/`: estado y reglas de la partida.
- `domain/competitive/`: competitivo 1c1/2c2 y NEXUS-TEAM.
- `domain/player/`: identidad, competitivo, historial, rankings y personalización del jugador.
- `domain/bots/`: decisiones y calibración de bots.
- `domain/replay/`: captura de estado, tablero de replay, navegación visual, layout y análisis.
- `ui/screens/`: una pantalla = un coordinador de pantalla.
- `ui/components/`: componentes reutilizables y módulos visuales independientes.
- `tests/`: contratos y regresiones.

## Separaciones V66
### PlayerData
`player_data.gd` queda como fachada/coordinador público.
- `player_persistence_service.gd`: carga, guardado, migraciones y normalización persistente.
- `player_competitive_service.gd`: NEXUS/NEXUS-TEAM, resultados y estados de pareja.
- `player_history_service.gd`: historial y trazabilidad de partidas.
- `player_ranking_service.gd`: rankings, ligas, copas y progreso.
- `player_customization_service.gd`: identidad visual, ajustes y reacciones.

Los servicios reciben el mismo anfitrión y no duplican la fuente de verdad. La fachada mantiene la API histórica y garantiza inicialización diferida para llamadas tempranas.

### MatchReplayView
`match_replay_view.gd` queda como fachada del estudio de replay.
- `replay_board.gd`: representación visual del tablero de replay.
- `replay_view_controller.gd`: posición, jugadas, análisis y navegación.
- `replay_view_layout_service.gd`: construcción y responsive del estudio.
- `match_replay_state_service.gd`: captura/serialización/decodificación del estado de replay.

La vista puede recibir configuración antes de entrar al árbol de escena; su inicialización es segura y diferida.

### Game
`ui/screens/game.gd` queda como coordinador de pantalla.
- `game_input_controller.gd`: entrada táctil/mouse, selección y acciones de movimiento.
- `game_bot_coordinator.gd`: espera, calibración temporal y ciclo de turno del bot.
- `game_match_result_service.gd`: cierre de partida y registro del resultado.
- `game_flow_controller.gd`: reset, revancha, retorno y apertura del análisis.

Los módulos usan una fachada del anfitrión; no cambian las reglas 1c1/2c2.

### StorageManager
`storage_manager.gd` queda como fachada del sistema de almacenamiento.
- `storage_file_service.gd`: filesystem, JSON atómico, backup y metadatos.
- `storage_profile_service.gd`: perfil, migración y cachés de perfil/historial.
- `storage_cache_service.gd`: caché por namespace/clave.
- `storage_sync_service.gd`: cola offline y sincronización futura.

Las señales públicas continúan emitiéndose desde `StorageManager`.

## Regla para futuras features
Una feature nueva no se añade directamente a una pantalla existente si posee estado, interacción o lógica propia. Debe recibir su propio módulo/componente y una prueba de contrato. La pantalla solo registra, configura y comunica eventos.

## Contratos y pruebas
`tests/modular_architecture_tests.gd` verifica la existencia de las fronteras y `tests/module_contracts_v66_tests.gd` comprueba que los módulos extraídos pueden instanciarse de forma independiente. Las regresiones de gameplay/UI siguen ejecutándose sobre las escenas reales.

## Dependencias
Preferir dependencias unidireccionales:
`UI → servicios/dominio → datos`.
Un componente visual no debe editar directamente otro componente visual. El coordinador comunica mediante API/señales.

## 2c2
La modularización no cambia las reglas de 2c2. Sugerir, Cambio, turnos, equipos, aceptación/rechazo, victoria/derrota y comunicación siguen perteneciendo al dominio de partida. NEXUS-TEAM permanece aislado del gameplay.

## Separaciones V67
`game_state.gd` queda como estado + fachada pública del dominio de partida.
- `game_match_lifecycle_service.gd`: inicialización/reset, reloj, presencia, turnos, equipos, retorno/ausencia y cierre de partida.
- `game_move_service.gd`: validación/aplicación de movimientos, derechos especiales, en passant, promoción y resolución posterior al movimiento.
- `game_bot_service.gd`: integración de bots temporales, turno de bot y sugerencia de bot.
- `game_social_service.gd`: Sugerir, Cambio, Rendirse, Tablas, chat y reacciones.
- `match_replay_state_service.gd`: captura/serialización del replay.

La fachada conserva las APIs históricas para escenas y pruebas, mientras cada responsabilidad tiene un único módulo propietario.


## V70 · Social modular
- `domain/social/friends_service.gd`: amistad aceptada + solicitudes y fuente post-partida.
- `domain/social/clubs_service.gd`: catálogo paginado, búsqueda, creación, acceso, detalle y club activo.
- `domain/social/club_chat_service.gd`: mensajes y desafíos amistosos; los desafíos sociales llevan contrato explícito `competitive=false` y no modifican NEXUS, rating, copas ni puntos de pareja.
- `ui/components/social/social_ui_factory.gd`: componentes visuales comunes para pantallas sociales.
- `ui/screens/more_screen.gd`: pantalla independiente para Ajustes y opciones secundarias.
- `ui/screens/friends_screen.gd`: amigos aceptados.
- `ui/screens/club_browser_screen.gd`: listado con búsqueda + carga incremental.
- `ui/screens/club_detail_screen.gd`: detalle inicial de un club.
- `ui/screens/club_create_screen.gd`: alta de club con iconos de app o galería.
- `ui/screens/club_chat_screen.gd`: chat persistente del club y desafíos amistosos.
- Cada pantalla social tiene su contrato y navegación propia; la barra principal solo decide el destino.
