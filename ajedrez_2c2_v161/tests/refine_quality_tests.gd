extends SceneTree

const PLAYER := preload("res://domain/player/player_data.gd")
const REPLAY := preload("res://domain/replay/match_replay_view.gd")
const ACCOUNT := preload("res://scenes/account_hub.tscn")
const GAME := preload("res://domain/chess/game_state.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var data := get_root().get_node_or_null("PlayerData")
    if data == null:
        data = PLAYER.new()
        data.name = "PlayerData"
        root.add_child(data)
        await process_frame
    _test(data._default_equipped_emotes().size() == data.MAX_EQUIPPED_EMOTES, "loadout inicial completo")
    _test(data._default_equipped_emotes().all(func(id): return not String(id).is_empty()), "loadout inicial usa ids válidos")
    data.set_appearance("board_theme", "invalid")
    _test(data.get_appearance("board_theme", "classic") == "classic", "apariencia rechaza ids inválidos")

    var game := GAME.new()
    root.add_child(game)
    game.reset_match(GAME.MODE_1C1_LOCAL)
    var replay_data := game.replay_data()
    var viewer := REPLAY.new()
    root.add_child(viewer)
    await process_frame
    viewer.set_replay_data(replay_data, [])
    _test(viewer._states.size() == 1, "visor carga snapshot inicial")
    viewer.set_replay_position(0)
    _test(viewer._index == 0, "visor mantiene primera posición")

    var record := {"match_id":"REFINE", "mode":GAME.MODE_1C1_LOCAL, "outcome":"win", "moves":[], "move_count":0, "replay_data":replay_data}
    data.record_noncompetitive_match(record)
    var account := ACCOUNT.instantiate()
    root.add_child(account)
    await process_frame
    account.selected_history_index = 0
    account.page = "analysis"
    account._refresh()
    await process_frame
    await process_frame
    _test(account.tabs.visible == false, "análisis oculta navegación secundaria")
    print("REFINAMIENTO RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _test(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
