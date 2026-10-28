extends SceneTree

const PlayerDataScript = preload("res://domain/player/player_data.gd")
const BotDataScript = preload("res://domain/bots/bot_data.gd")
const ChessGameState = preload("res://domain/chess/game_state.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var data := PlayerDataScript.new()
    root.add_child(data)
    await process_frame
    _test_reactions(data)
    _test_profile_history(data)
    _test_bot_personalities()
    await _test_replay_snapshots()
    print("TANDAS 5-7 RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)

func _test_reactions(data: Object) -> void:
    var original: Array = data.get_equipped_emotes()
    _ok(original.size() <= data.MAX_EQUIPPED_EMOTES, "loadout <= 6")
    _ok(data.set_equipped_emotes([]), "permite dejar reacciones vacías")
    _ok(data.get_equipped_emotes().is_empty(), "loadout vacío persiste en memoria")
    _ok(data.toggle_emote_equipped("bien"), "puede equipar una reacción válida")
    _ok(not data.move_equipped_emote("bien", 1), "no mueve fuera de rango")
    _ok(data.toggle_emote_equipped("bien"), "puede desequipar una reacción")
    _ok(not data.toggle_emote_equipped("no_existe"), "rechaza reacción inexistente")
    _ok(data.set_equipped_emotes(original), "restaura loadout original")

func _test_profile_history(data: Object) -> void:
    var before: int = data.history.size()
    var replay := {"version":1, "states":[{"board":"........................................................"}]}
    data.record_noncompetitive_match({"mode": 1, "outcome":"win", "moves": [], "replay_data": replay})
    _ok(data.history.size() == before + 1, "historial admite nueva partida")
    _ok(data.history[-1].has("replay_data"), "historial conserva replay_data")
    data.history.pop_back()

func _test_bot_personalities() -> void:
    var profiles := BotDataScript.profiles()
    _ok(profiles.size() == 5, "cinco perfiles de bot")
    var seen := {}
    for p in profiles:
        var behavior: Dictionary = p.get("behavior", {})
        seen[JSON.stringify(behavior)] = true
        _ok(behavior.size() >= 6, "perfil %s tiene parámetros de estilo" % String(p["name"]))
    _ok(seen.size() == 5, "cada bot tiene personalidad distinta")

func _test_replay_snapshots() -> void:
    var game := ChessGameState.new()
    root.add_child(game)
    game.reset_match(3, 1)
    await process_frame
    var initial: Dictionary = game.replay_data()
    _ok(int(initial.get("version", 0)) == 1, "replay versionado")
    _ok(initial.get("states", []).size() == 1, "replay guarda posición inicial")
    _ok(String(initial["states"][0].get("board", "")).length() == 64, "snapshot compacta 64 casillas")
    _ok(game.attempt_move(Vector2i(4,6), Vector2i(4,4)), "movimiento de prueba válido")
    var after: Dictionary = game.replay_data()
    _ok(after.get("states", []).size() == 2, "replay añade estado después de mover")
    _ok(int(after["states"][1].get("turn", -1)) == 1, "snapshot guarda el siguiente turno")
