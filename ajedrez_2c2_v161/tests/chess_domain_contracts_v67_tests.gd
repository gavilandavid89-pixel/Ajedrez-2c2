extends SceneTree

const ChessGameState = preload("res://domain/chess/game_state.gd")
const MatchLifecycle = preload("res://domain/chess/game_match_lifecycle_service.gd")
const MoveService = preload("res://domain/chess/game_move_service.gd")
const BotService = preload("res://domain/chess/game_bot_service.gd")
const SocialService = preload("res://domain/chess/game_social_service.gd")
const ReplayService = preload("res://domain/replay/match_replay_state_service.gd")

func _initialize() -> void:
    var host := Node.new()
    get_root().add_child(host)
    var game := ChessGameState.new()
    host.add_child(game)
    var modules := [
        MatchLifecycle.new(game), MoveService.new(game), BotService.new(game),
        SocialService.new(game), ReplayService.new(game)
    ]
    var checks := modules.size() + 5
    var failures := 0
    for module in modules:
        if module == null:
            failures += 1
    game._ensure_domain_services()
    if game.lifecycle_service == null: failures += 1
    if game.move_service == null: failures += 1
    if game.bot_service == null: failures += 1
    if game.social_service == null: failures += 1
    if game.replay_service == null: failures += 1
    var report := {
        "checks": checks,
        "failures": failures,
        "services": modules.size(),
    }
    print("V67 CHESS DOMAIN CONTRACTS: %d OK / %d FAIL" % [checks - failures, failures])
    modules.clear()
    host.queue_free()
    quit(1 if failures > 0 else 0)
