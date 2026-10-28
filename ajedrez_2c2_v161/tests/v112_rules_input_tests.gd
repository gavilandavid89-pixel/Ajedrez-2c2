extends SceneTree

const GameStateScript = preload("res://domain/chess/game_state.gd")
const GameScene = preload("res://scenes/game.tscn")
const ReviewScript = preload("res://domain/replay/game_review_service.gd")
const RulesScript = preload("res://domain/chess/rules.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")

class NoopPersistence:
    extends "res://domain/player/player_persistence_service.gd"
    func save_data() -> void:
        pass

var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var game := GameStateScript.new()
    get_root().add_child(game)
    await process_frame

    game.reset_match(game.MODE_1C1)
    game.local_player_slot = 0
    var cycle_ok := true
    for _cycle in range(2):
        cycle_ok = cycle_ok and game.attempt_move(Vector2i(6,7), Vector2i(5,5))
        cycle_ok = cycle_ok and game.attempt_move(Vector2i(6,0), Vector2i(5,2))
        cycle_ok = cycle_ok and game.attempt_move(Vector2i(5,5), Vector2i(6,7))
        cycle_ok = cycle_ok and game.attempt_move(Vector2i(5,2), Vector2i(6,0))
    _check(cycle_ok and game.can_claim_draw_by_repetition(), "Triple repetition is claimable after the same legal position appears three times")
    _check(game.request_draw() and not game.running and game.winner_reason.contains("triple repetición"), "A valid repetition claim ends immediately without team vote")

    game.reset_match(game.MODE_1C1)
    game.local_player_slot = 0
    game.halfmove_clock = 99
    _check(game.attempt_move(Vector2i(6,7), Vector2i(5,5)) and game.can_claim_draw_by_fifty_moves(), "Fifty-move claim uses the halfmove clock")
    game.reset_match(game.MODE_1C1)
    game.local_player_slot = 0
    game.halfmove_clock = 100
    _check(game.request_draw() and not game.running and game.winner_reason.contains("50 movimientos"), "Fifty-move claim ends immediately when requested")

    game.reset_match(game.MODE_1C1)
    game.halfmove_clock = 42
    _check(game.attempt_move(Vector2i(4,6), Vector2i(4,4)) and game.halfmove_clock == 0, "Pawn move resets halfmove clock")

    game.reset_match(game.MODE_1C1)
    game.local_player_slot = 0
    game.halfmove_clock = 149
    _check(game.attempt_move(Vector2i(6,7), Vector2i(5,5)) and not game.running and game.winner_reason.contains("75 movimientos"), "Seventy-five move rule ends automatically at 150 halfmoves")

    game.reset_match(game.MODE_1C1)
    game.local_player_slot = 0
    game.board = [
        ["", "", "", "", "rey_negro", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "peon_blanca", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["rey_blanca", "", "", "", "", "", "", ""],
    ]
    game.en_passant_target = Vector2i(3,2)
    _check(not game.rules.valid(game.board, Vector2i(4,3), Vector2i(3,2), "peon_blanca", game.castling_rights, game.en_passant_target), "En passant rejected if the pawn to capture is missing")

    var review := ReviewScript.new()
    var state := {"board":"rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR", "castling":"KQkq", "ep":[-1,-1], "turn":2, "side_to_move":1, "halfmove_clock":99}
    var fen := review._state_to_fen(review._decode_state(state), 2)
    _check(fen.contains(" b KQkq - 99 2"), "Replay FEN uses real side-to-move and halfmove clock, not 2c2 slot parity")

    var data := PlayerDataScript.new()
    data.name = "V112IdempotencyQA"
    get_root().add_child(data)
    await process_frame
    # Keep this regression suite from overwriting a developer's local profile.
    data.persistence_service = NoopPersistence.new(data)
    data.profile["id"] = "USR_V112_IDEMPOTENCY"
    data.history.clear()
    data.pair_records.clear()
    data.current_pair_id = ""
    data.current_partner = {"id":"", "name":"", "pair_key":""}
    data.best_pair_id = ""
    data.individual = {"cups":0,"lifetime_cups":0,"games":0,"wins":0,"losses":0,"draws":0,"rating":1200,"best_rating":1200,"uncertainty":240.0,"volatility":0.5,"form":0.0,"last_activity_at":0,"nexus_version":2}
    data.individual_1c1 = {"cups":0,"lifetime_cups":0,"games":0,"wins":0,"losses":0,"draws":0,"rating":1000,"best_rating":1000,"streak":0}
    var detail := {"match_id":"V112-IDEMPOTENT-MATCH", "partner_rating_before":1200}
    var first_result: Dictionary = data.record_result(1, "win", "", 1000, 1000, "", detail)
    var rating_after_first := int(data.individual_1c1["rating"])
    var games_after_first := int(data.individual_1c1["games"])
    var second_result: Dictionary = data.record_result(1, "loss", "", 1000, 1000, "", detail)
    _check(not bool(first_result.get("duplicate", false)) and bool(second_result.get("duplicate", false)) and int(data.individual_1c1["rating"]) == rating_after_first and int(data.individual_1c1["games"]) == games_after_first, "Repeated result ID does not update NEXUS or history twice")

    var game_ui = GameScene.instantiate()
    get_root().add_child(game_ui)
    await process_frame
    await process_frame
    game_ui.game.assign_roles_for_local_team(game_ui.game.TEAM_WHITE)
    game_ui.board_view.set_flipped(false)
    game_ui._on_action("suggest")
    var board = game_ui.board_view
    var cell: float = board.board_rect.size.x / 8.0
    var local_e2: Vector2 = board.board_rect.position + Vector2(4.5, 6.5) * cell
    var screen_e2: Vector2 = board.get_global_transform_with_canvas() * local_e2
    var press := InputEventScreenTouch.new()
    press.position = screen_e2
    press.pressed = true
    press.index = 0
    game_ui.input_controller._input(press)
    var release := InputEventScreenTouch.new()
    release.position = screen_e2
    release.pressed = false
    release.index = 0
    game_ui.input_controller._input(release)
    _check(board.selected == Vector2i(4,6), "Single tap selects suggestion source immediately")
    var local_e4: Vector2 = board.board_rect.position + Vector2(4.5, 4.5) * cell
    var screen_e4: Vector2 = board.get_global_transform_with_canvas() * local_e4
    press = InputEventScreenTouch.new()
    press.position = screen_e4
    press.pressed = true
    press.index = 0
    game_ui.input_controller._input(press)
    release = InputEventScreenTouch.new()
    release.position = screen_e4
    release.pressed = false
    release.index = 0
    game_ui.input_controller._input(release)
    _check(not game_ui.game.suggestion.is_empty() and game_ui.game.move_history.is_empty(), "One-tap-per-square suggestion sends ghost intent without moving the piece")

    print("V112 REGLAS/INPUT: %d OK / %d FALLARON" % [passed, failed])
    for failure in failures:
        push_error(failure)
    quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        failures.append(label)
        print("[FAIL] ", label)
