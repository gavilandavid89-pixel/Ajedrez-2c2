extends SceneTree

const ChessRules = preload("res://domain/chess/rules.gd")
const ChessGameState = preload("res://domain/chess/game_state.gd")
const BotData = preload("res://domain/bots/bot_data.gd")
const BotController = preload("res://domain/bots/bot_controller.gd")
const HudScene = preload("res://scenes/game_hud.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    await _stress_random_games()
    await _stress_bots()
    await _test_replay_roundtrip()
    await _test_overlay_priority()
    await _test_audio_feedback()
    print("TANDA 8 RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)

func _stress_random_games() -> void:
    var rules := ChessRules.new()
    var rng := RandomNumberGenerator.new()
    rng.seed = 20260930
    for game_index in range(8):
        var game := ChessGameState.new()
        root.add_child(game)
        game.reset_match(3, 1)
        var plies := 0
        while game.running and plies < 180:
            var white := game.current_team() == ChessGameState.TEAM_WHITE
            var choices: Array[Dictionary] = []
            for y in range(8):
                for x in range(8):
                    var from := Vector2i(x,y)
                    var piece: String = game.board[y][x]
                    if piece.is_empty() or rules.is_white(piece) != white:
                        continue
                    for to in rules.legal_moves(game.board, from, game.castling_rights, game.en_passant_target):
                        choices.append({"from":from,"to":to})
            if choices.is_empty():
                break
            var pick: Dictionary = choices[rng.randi_range(0, choices.size() - 1)]
            var before: int = game.replay_data().get("states", []).size()
            var moved := game.attempt_move(pick["from"], pick["to"], "dama")
            _ok(moved, "random game %d legal move %d" % [game_index, plies])
            if game.pending_promotion != game.NO_SQUARE:
                _ok(game.choose_promotion("dama"), "random game promotion resolves")
            _ok(rules.board_valid(game.board), "random game board stays valid")
            _ok(_king_count(game.board, true) == 1 and _king_count(game.board, false) == 1, "random game keeps one king per side")
            _ok(game.replay_data().get("states", []).size() >= before + 1, "random game replay grows")
            plies += 1
        game.queue_free()
        await process_frame

func _stress_bots() -> void:
    for profile in BotData.profiles():
        var game := ChessGameState.new()
        root.add_child(game)
        game.bot_id = String(profile["id"])
        game.bot_target_elo = int(profile["elo"])
        game.reset_match(2, 1)
        var turns := 0
        while game.running and turns < 20:
            if game.current_slot == 1:
                _ok(game.bot_take_turn(), "bot %s returns a move" % String(profile["name"]))
            else:
                var legal := game.rules.legal_moves(game.board, Vector2i(4,6), game.castling_rights, game.en_passant_target)
                var moved := false
                for y in range(8):
                    for x in range(8):
                        var from := Vector2i(x,y)
                        var piece: String = game.board[y][x]
                        if piece.is_empty() or not game.rules.is_white(piece):
                            continue
                        var moves := game.rules.legal_moves(game.board, from, game.castling_rights, game.en_passant_target)
                        if not moves.is_empty():
                            moved = game.attempt_move(from, moves[0])
                            break
                    if moved:
                        break
            turns += 1
        _ok(turns > 0, "bot %s completed stress turns" % String(profile["name"]))
        game.queue_free()
        await process_frame

func _test_replay_roundtrip() -> void:
    var game := ChessGameState.new()
    root.add_child(game)
    game.reset_match(3, 1)
    game.attempt_move(Vector2i(4,6), Vector2i(4,4))
    var replay := game.replay_data()
    var states: Array = replay.get("states", [])
    var decoded := ChessGameState.decode_replay_state(states[states.size()-1]) if not states.is_empty() else {}
    _ok(decoded.size() > 0, "replay state decodifica")
    _ok(decoded.get("board", []) == game.board, "replay reconstruye exactamente el tablero")
    _ok(decoded.get("turn", -1) == game.current_slot, "replay conserva turno")
    game.queue_free()
    await process_frame

func _test_overlay_priority() -> void:
    var hud = HudScene.instantiate()
    root.add_child(hud)
    await process_frame
    hud.set_game(ChessGameState.new())
    await process_frame
    _ok(hud.get_node("Result").z_index > hud.get_node("MiniPanel").z_index, "resultado por encima de confirmación")
    _ok(hud.get_node("MiniPanel").z_index > hud.get_node("EmotePicker").z_index, "confirmación por encima de reacción")
    _ok(hud.get_node("EmotePicker").z_index == hud.get_node("ChatPanel").z_index, "utilidades comparten capa")
    hud.get_node("ChatPanel").visible = true
    hud.get_node("HistoryPanel").visible = true
    hud._toggle_emotes()
    _ok(not hud.get_node("ChatPanel").visible and not hud.get_node("HistoryPanel").visible and hud.get_node("EmotePicker").visible, "abrir reacciones cierra utilidades hermanas")
    hud.queue_free()
    await process_frame

func _test_audio_feedback() -> void:
    var audio = root.get_node_or_null("AudioFeedback")
    _ok(audio != null, "servicio de audio está registrado")
    if audio != null:
        audio.play_feedback("move")
        audio.play_feedback("capture")
        audio.play_feedback("result")
        _ok(audio.player != null, "audio tiene reproductor central")

func _king_count(board: Array, white: bool) -> int:
    var needle := "rey_blanca" if white else "rey_negro"
    var count := 0
    for row in board:
        for piece in row:
            if piece == needle:
                count += 1
    return count
