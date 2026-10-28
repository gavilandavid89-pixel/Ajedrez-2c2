extends SceneTree

const PlayerPersistenceService = preload("res://domain/player/player_persistence_service.gd")
const PlayerCompetitiveService = preload("res://domain/player/player_competitive_service.gd")
const PlayerHistoryService = preload("res://domain/player/player_history_service.gd")
const PlayerRankingService = preload("res://domain/player/player_ranking_service.gd")
const ReplayBoard = preload("res://domain/replay/replay_board.gd")
const ReplayViewController = preload("res://domain/replay/replay_view_controller.gd")
const ReplayViewLayoutService = preload("res://domain/replay/replay_view_layout_service.gd")
const GameInputController = preload("res://ui/components/game/game_input_controller.gd")
const GameBotCoordinator = preload("res://ui/components/game/game_bot_coordinator.gd")
const GameMatchResultService = preload("res://ui/components/game/game_match_result_service.gd")
const GameFlowController = preload("res://ui/components/game/game_flow_controller.gd")
const StorageFileService = preload("res://core/services/storage_file_service.gd")
const StorageProfileService = preload("res://core/services/storage_profile_service.gd")
const StorageCacheService = preload("res://core/services/storage_cache_service.gd")
const StorageSyncService = preload("res://core/services/storage_sync_service.gd")
const MatchReplayView = preload("res://domain/replay/match_replay_view.gd")
const ChessGameState = preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
    var host := Node.new()
    var modules := [
        PlayerPersistenceService.new(host), PlayerCompetitiveService.new(host),
        PlayerHistoryService.new(host), PlayerRankingService.new(host),
        ReplayBoard.new(), ReplayViewController.new(host), ReplayViewLayoutService.new(host),
        GameInputController.new(host), GameBotCoordinator.new(host),
        GameMatchResultService.new(host), GameFlowController.new(host),
        StorageFileService.new(host), StorageProfileService.new(host),
        StorageCacheService.new(host), StorageSyncService.new(host),
    ]
    var checks := modules.size() + 2
    var failures := 0
    for module in modules:
        if module == null:
            failures += 1
    if MatchReplayView.new() == null:
        failures += 1
    if ChessGameState.new() == null:
        failures += 1
    modules.clear()
    host.free()
    print("V66 MODULE CONTRACTS: %d OK / %d FAIL" % [checks - failures, failures])
    quit(1 if failures > 0 else 0)
