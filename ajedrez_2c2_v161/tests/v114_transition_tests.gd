extends SceneTree

const GameStateScript = preload("res://domain/chess/game_state.gd")
const ReplayStateScript = preload("res://domain/replay/match_replay_state_service.gd")

var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game = GameStateScript.new()
    get_root().add_child(game)
    await process_frame
    game.reset_match(game.MODE_1C1)
    game.local_player_slot = 0

    # Isolated promotion position: kings are safe, white pawn is one step from promotion.
    game.board = _empty_board()
    game.board[7][4] = "rey_blanca"
    game.board[0][7] = "rey_negro"
    game.board[1][0] = "peon_blanca"
    game.castling_rights = {"WK":false,"WQ":false,"BK":false,"BQ":false}
    game.en_passant_target = Vector2i(-1, -1)
    game.halfmove_clock = 7
    game.move_history.clear()
    game.replay_states.clear()
    game.position_repetition_counts.clear()
    game._capture_replay_state()
    var before_states: int = game.replay_states.size()
    _check(game.attempt_move(Vector2i(0,1), Vector2i(0,0)), "Pawn reaches last rank and opens promotion choice")
    _check(game.pending_promotion == Vector2i(0,0) and game.pending_move_index == 0, "Promotion remains pending until player chooses a piece")
    _check(not game.choose_promotion("king") and game.pending_promotion == Vector2i(0,0), "Invalid promotion choice cannot consume the pending move")
    _check(game.choose_promotion("caballo"), "Valid underpromotion to knight is accepted")
    _check(game.board[0][0] == "caballo_blanca" and game.pending_promotion == Vector2i(-1,-1), "Promotion changes the board and clears pending state")
    _check(game.move_history.size() == 1 and game.move_history[0].get("promotion", "") == "caballo", "Replay history records the exact promoted piece")
    _check(game.halfmove_clock == 0, "Promotion move keeps the halfmove clock reset")
    _check(game.replay_states.size() == before_states + 1, "Promotion captures exactly one resolved replay state")
    _check(game.current_team() == game.TEAM_BLACK, "Turn advances only after promotion is resolved")

    # A malformed replay state must fail closed instead of producing a partial board.
    var decoded_bad: Dictionary = ReplayStateScript.decode_state({"board":"short"})
    _check(decoded_bad.is_empty(), "Replay decoder rejects malformed board payload")

    # Replay serialization preserves side-to-move and counters.
    var valid_state: Dictionary = game.replay_states.back()
    var decoded: Dictionary = ReplayStateScript.decode_state(valid_state)
    _check(decoded.get("side_to_move", -1) == game.current_team(), "Replay stores the resolved side to move")
    _check(int(decoded.get("halfmove_clock", -1)) == game.halfmove_clock, "Replay stores the resolved halfmove clock")
    _check(decoded.get("board", []).size() == 8 and decoded.get("board", [])[0].size() == 8, "Replay decoder restores an 8x8 board")

    print("V114 TRANSITIONS: %d OK / %d FAILED" % [passed, failed])
    for failure in failures:
        push_error(failure)
    quit(0 if failed == 0 else 1)

func _empty_board() -> Array:
    var board: Array = []
    for y in range(8):
        var row: Array[String] = []
        for x in range(8):
            row.append("")
        board.append(row)
    return board

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        failures.append(label)
        print("[FAIL] ", label)
