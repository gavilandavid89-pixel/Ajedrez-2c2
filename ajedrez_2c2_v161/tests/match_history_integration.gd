extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")

var failed := 0

func _initialize() -> void:
    var player_data = root.get_node_or_null("PlayerData")
    if player_data == null:
        push_error("PlayerData autoload missing")
        quit(1)
        return
    var before_size: int = player_data.history.size()
    var before_id := String(player_data.history.back().get("match_id", "")) if before_size > 0 else ""
    var scene := GAME_SCENE.instantiate()
    root.add_child(scene)
    await process_frame
    var game = scene.game
    game.finish(game.TEAM_WHITE, "Jaque mate")
    await process_frame
    var record: Dictionary = player_data.history.back() if not player_data.history.is_empty() else {}
    var after_size: int = player_data.history.size()
    var new_record := not record.is_empty() and String(record.get("match_id", "")) != before_id
    _check(new_record and after_size >= mini(before_size, 100), "completed game is added to history")
    _check(not String(record.get("match_id", "")).is_empty(), "history record has match ID")
    _check(record.get("moves", []) is Array, "history record stores move list")
    _check(record.has("reason"), "history record stores result reason")
    _check(bool(record.get("analysis_ready", false)), "history record is marked analysis-ready")
    print("MATCH HISTORY INTEGRATION: %d OK / %d FALLARON" % [5 - failed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
