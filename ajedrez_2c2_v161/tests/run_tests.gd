extends SceneTree

const ChessRules = preload("res://domain/chess/rules.gd")
const ChessGameState = preload("res://domain/chess/game_state.gd")
const EmotePickerScene = preload("res://scenes/emote_picker.tscn")
const PlayerCardScene = preload("res://scenes/player_card.tscn")
const PlayerDataScript = preload("res://domain/player/player_data.gd")
const EngineReviewTests = preload("res://tests/engine_review_integration_tests.gd")
const StockfishProtocolTests = preload("res://tests/stockfish_uci_protocol_tests.gd")

var passed := 0
var failed := 0
var rules := ChessRules.new()
var game := ChessGameState.new()

func _initialize() -> void:
    var root := Node.new()
    get_root().add_child(root)
    root.add_child(game)
    await process_frame

    _test("board is 8x8", rules.board_valid(game.board))
    _test("every row has 8 cells", _all_rows_are_eight())
    _test("h3 exists", game.get_piece(Vector2i(7,5)) == "")
    _test("white pawn e2 can move e4", rules.valid(game.board, Vector2i(4,6), Vector2i(4,4), "peon_blanca", game.castling_rights, game.en_passant_target))
    _test("white pawn e2 cannot move e5", not rules.valid(game.board, Vector2i(4,6), Vector2i(4,3), "peon_blanca", game.castling_rights, game.en_passant_target))
    _test("white knight b1 to a3", rules.valid(game.board, Vector2i(1,7), Vector2i(0,5), "caballo_blanca", game.castling_rights, game.en_passant_target))
    _test("rook a1 blocked", not rules.valid(game.board, Vector2i(0,7), Vector2i(0,5), "torre_blanca", game.castling_rights, game.en_passant_target))
    _test("same-team destination rejected", not rules.valid(game.board, Vector2i(0,7), Vector2i(0,6), "torre_blanca", game.castling_rights, game.en_passant_target))
    _test("capture works", _capture_test())
    _test("turn order A B C D", _turn_order_test())
    _test("suggestion is ghost and can be answered", _suggestion_test())
    _test("suggestion is hidden from opponents", _suggestion_visibility_test())
    _test("classic mode disables swap", _classic_mode_test())
    _test("question cooldown exists", _question_test())
    _test("swap is free and keeps current slot", _swap_test())
    _test("swap rejected does not change owners", _swap_reject_test())
    _test("surrender request + accept", _surrender_test())
    _test("draw flow reaches finish", _draw_test())
    _test("absence and return", _absence_test())
    _test("non-current teammate is not falsely absent", _non_current_absence_test())
    _test("absent teammate is covered by active teammate", _cover_absent_test())
    _test("both teammates absent lose", _both_absent_test())
    _test("team clock expires", _clock_test())
    _test("pair stats update on match end", _pair_stats_test())
    _test("2c2 draw updates draw stats without rating change", _pair_draw_stats_test())
    _test("rook check detects check", _check_test())
    _test("checkmate detects mate", _checkmate_test())
    _test("stalemate detects draw", _stalemate_test())
    _test("kings cannot be captured directly", _king_capture_rejected_test())
    _test("castling kingside works", _castling_test())
    _test("castling through check rejected", _castle_through_check_test())
    _test("en passant works", _en_passant_test())
    _test("promotion works", _promotion_test())
    _test("history records special moves", _special_history_test())
    _test("chat and emote are stored", _social_test())
    var picker_ok := await _emote_picker_test(root)
    var equipped_count: int = get_root().get_node_or_null("PlayerData").get_equipped_emotes().size() if get_root().get_node_or_null("PlayerData") != null else 0
    _test("emote picker builds equipped reaction buttons", picker_ok and equipped_count <= 6)
    var card_ok := await _player_card_emote_test(root)
    _test("player card contains emote badge", card_ok)
    var team_clock_ok := await _team_clock_layout_test(root)
    _test("one clock per team, none inside player cards", team_clock_ok)
    _test("player identity has persistent hidden ID", _player_identity_test())
    var engine_report := EngineReviewTests.new().run()
    _test("engine review FEN/UCI integration", int(engine_report.get("failed", []).size()) == 0)
    var uci_report := StockfishProtocolTests.new().run()
    for protocol_failure in uci_report.get("failed", []):
        push_error("STOCKFISH UCI: " + String(protocol_failure))
    _test("Stockfish waits for bestmove and keeps per-position scores", Array(uci_report.get("failed", [])).is_empty())
    _test("NEXUS rejects unknown outcomes instead of counting a draw", _invalid_outcome_test())

    print("\nRESULTADO FINAL: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)


func _player_identity_test() -> bool:
    var data = get_root().get_node_or_null("PlayerData")
    if data == null:
        return false
    var before_id: String = String(data.profile.get("id", ""))
    if before_id.is_empty() or not before_id.begins_with("USR_"):
        return false
    var before_name: String = String(data.profile.get("name", "Tú"))
    if not data.set_display_name("ABCDEFGHIJ"):
        return false
    var ten_ok: bool = String(data.profile.get("name", "")).length() == 10
    var eleven_rejected: bool = not data.set_display_name("ABCDEFGHIJK")
    var id_stable: bool = String(data.profile.get("id", "")) == before_id
    data.set_display_name(before_name)
    return ten_ok and eleven_rejected and id_stable

func _all_rows_are_eight() -> bool:
    for row in game.board:
        if row.size() != 8:
            return false
    return true

func _reset() -> void:
    game.reset_match()
    game.local_player_slot = 0

func _capture_test() -> bool:
    _reset()
    game.board = [
        ["", "", "", "", "rey_negro", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "peon_negro", "", ""],
        ["", "", "", "", "peon_blanca", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["rey_blanca", "", "", "", "", "", "", ""],
    ]
    game.current_slot = 0
    var ok := game.attempt_move(Vector2i(4,4), Vector2i(5,3))
    return ok and game.get_piece(Vector2i(5,3)) == "peon_blanca" and game.get_piece(Vector2i(4,4)) == "" and game.running

func _turn_order_test() -> bool:
    _reset()
    game._advance_turn()
    var b := game.current_slot == 1
    game._advance_turn()
    var c := game.current_slot == 2
    game._advance_turn()
    var d := game.current_slot == 3
    game._advance_turn()
    var a := game.current_slot == 0
    return b and c and d and a

func _suggestion_test() -> bool:
    _reset()
    game.board[6][4] = ""
    game.board[4][4] = "peon_blanca"
    var before: String = game.get_piece(Vector2i(4,4))
    var ok: bool = game.propose_suggestion(Vector2i(4,4), Vector2i(4,3))
    game.local_player_slot = 2
    game.answer_suggestion(true, 2)
    return ok and game.get_piece(Vector2i(4,4)) == before and not game.suggestion.is_empty() and bool(game.suggestion["accepted"])

func _suggestion_visibility_test() -> bool:
    _reset()
    game.board[6][4] = ""
    game.board[4][4] = "peon_blanca"
    if not game.propose_suggestion(Vector2i(4,4), Vector2i(4,3)):
        return false
    return game.suggestion_visible_to(0) and game.suggestion_visible_to(2) and not game.suggestion_visible_to(1) and not game.suggestion_visible_to(3)

func _question_test() -> bool:
    _reset()
    game.board[6][4] = ""
    game.board[4][4] = "peon_blanca"
    var ok: bool = game.propose_suggestion(Vector2i(4,4), Vector2i(4,3))
    game.local_player_slot = 2
    var questioned := game.question_suggestion(2)
    return ok and questioned and bool(game.suggestion.get("questioned", false)) and game.question_cooldown_until > game.now()

func _swap_test() -> bool:
    _reset()
    game.current_slot = 0
    var a: String = game.slot_owners[0]
    var c: String = game.slot_owners[2]
    var requested := game.request_swap()
    game.local_player_slot = 2
    var answered := game.answer_swap(true)
    return requested and answered and game.current_slot == 0 and game.current_owner() == c and game.slot_owners[0] == c and game.slot_owners[2] == a

func _swap_reject_test() -> bool:
    _reset()
    var before := game.slot_owners.duplicate()
    game.request_swap()
    game.answer_swap(false)
    return game.slot_owners == before

func _classic_mode_test() -> bool:
    _reset()
    game.set_strategic_mode(false)
    return not game.request_swap() and game.swap_request.is_empty()

func _surrender_test() -> bool:
    _reset()
    game.request_surrender()
    game.local_player_slot = 2
    game.answer_surrender(true)
    return not game.running and game.winner_team == ChessGameState.TEAM_BLACK

func _draw_test() -> bool:
    _reset()
    game.local_player_slot = 0
    game.request_draw()
    game.local_player_slot = 2
    var mate_ok := game.answer_draw(true, 2)
    game.local_player_slot = 1
    var first_rival := game.answer_draw(true, 1)
    game.local_player_slot = 3
    var second_rival := game.answer_draw(true, 3)
    return mate_ok and first_rival and second_rival and not game.running and game.winner_team == -1

func _absence_test() -> bool:
    _reset()
    game.mark_current_absent()
    var absent: bool = not game.slot_active[0]
    game.return_current_player()
    return absent and game.slot_active[0]

func _non_current_absence_test() -> bool:
    _reset()
    game.current_slot = 1
    var old_c: float = game.last_seen[2]
    var old_d: float = game.last_seen[3]
    game.last_seen[2] = game.now() - game.ABSENCE_SECONDS - 1.0
    game.last_seen[3] = game.now() - game.ABSENCE_SECONDS - 1.0
    game._process(0.1)
    var result: bool = game.slot_active[2] and game.slot_active[3] and game.current_slot == 1
    game.last_seen[2] = old_c
    game.last_seen[3] = old_d
    return result

func _cover_absent_test() -> bool:
    _reset()
    game.slot_active[2] = false
    game.current_slot = 2
    return game.current_slot_name() == "C" and game.current_owner() == "Jugador A" and game.current_team() == ChessGameState.TEAM_WHITE

func _both_absent_test() -> bool:
    _reset()
    game.slot_active[0] = false
    game.slot_active[2] = false
    game.force_slot_absent(0)
    return not game.running and game.winner_team == ChessGameState.TEAM_BLACK

func _clock_test() -> bool:
    _reset()
    game.team_time[0] = 0.001
    game._process(0.1)
    return not game.running and game.winner_team == ChessGameState.TEAM_BLACK

func _pair_stats_test() -> bool:
    _reset()
    var key := game.pair_key_for_team(ChessGameState.TEAM_WHITE)
    var before_games: int = int(game.pair_stats[key]["games"])
    var before_rating: int = int(game.pair_stats[key]["rating"])
    game.finish(ChessGameState.TEAM_WHITE, "Prueba")
    var stats: Dictionary = game.pair_stats[key]
    return int(stats["games"]) == before_games + 1 and int(stats["wins"]) >= 1 and int(stats["rating"]) == before_rating + 15


func _pair_draw_stats_test() -> bool:
    _reset()
    var key := game.pair_key_for_team(ChessGameState.TEAM_WHITE)
    var before: Dictionary = game.pair_stats[key].duplicate(true)
    game.finish(-1, "Tablas de prueba")
    var after: Dictionary = game.pair_stats[key]
    return int(after.get("games", 0)) == int(before.get("games", 0)) + 1 \
        and int(after.get("draws", 0)) == int(before.get("draws", 0)) + 1 \
        and int(after.get("rating", 0)) == int(before.get("rating", 0)) \
        and int(after.get("streak", 0)) == 0

func _check_test() -> bool:
    var b := [
        ["", "", "", "", "rey_negro", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "rey_blanca", "", "", "torre_blanca"],
    ]
    # Black king e8 is attacked by white rook e1.
    b[7][7] = ""
    b[7][4] = "torre_blanca"
    b[7][0] = "rey_blanca"
    return rules.in_check(b, false)

func _checkmate_test() -> bool:
    var b := [
        ["rey_negro", "torre_blanca", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "torre_blanca", ""],
        ["", "", "", "", "rey_blanca", "", "", ""],
    ]
    # Replace with a known simple mate position: black king a8, white queen b7, white king c6.
    b = [
        ["rey_negro", "", "", "", "", "", "", ""],
        ["", "dama_blanca", "", "", "", "", "", ""],
        ["", "", "rey_blanca", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
    ]
    return rules.is_checkmate(b, false)

func _stalemate_test() -> bool:
    var b := [
        ["rey_negro", "", "", "", "", "", "", ""],
        ["", "", "dama_blanca", "", "", "", "", ""],
        ["", "", "", "rey_blanca", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
    ]
    return rules.is_stalemate(b, false)

func _king_capture_rejected_test() -> bool:
    var b := [
        ["rey_negro", "", "", "", "", "", "", ""],
        ["", "torre_blanca", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "rey_blanca", "", "", ""],
    ]
    return not rules.valid(b, Vector2i(1,1), Vector2i(0,0), "torre_blanca")

func _castling_test() -> bool:
    var b := [
        ["torre_negro", "", "", "", "rey_negro", "", "", "torre_negro"],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["torre_blanca", "", "", "", "rey_blanca", "", "", "torre_blanca"],
    ]
    var rights := {"WK": true, "WQ": true, "BK": true, "BQ": true}
    return rules.valid(b, Vector2i(4,7), Vector2i(6,7), "rey_blanca", rights)

func _castle_through_check_test() -> bool:
    var b := [
        ["", "", "", "", "rey_negro", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["torre_blanca", "", "", "", "rey_blanca", "torre_negro", "", ""],
    ]
    var rights := {"WK": true, "WQ": true, "BK": false, "BQ": false}
    return not rules.valid(b, Vector2i(4,7), Vector2i(6,7), "rey_blanca", rights)

func _en_passant_test() -> bool:
    _reset()
    # White pawn e5, black pawn f5 has just advanced two squares; target f6.
    game.board = [
        ["", "", "", "", "rey_negro", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "peon_blanca", "peon_negro", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "rey_blanca", "", "", ""],
    ]
    game.en_passant_target = Vector2i(5,2)
    # Board coords: white pawn e5 = (4,3), so its ep target must be f4 = (5,2).
    return rules.valid(game.board, Vector2i(4,3), Vector2i(5,2), "peon_blanca", game.castling_rights, game.en_passant_target)

func _promotion_test() -> bool:
    _reset()
    game.board = [
        ["", "", "", "", "rey_negro", "", "", ""],
        ["peon_blanca", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "rey_blanca", "", "", ""],
    ]
    game.current_slot = 0
    var moved := game.attempt_move(Vector2i(0,1), Vector2i(0,0))
    var pending := game.pending_promotion == Vector2i(0,0)
    var promoted := game.choose_promotion("dama")
    return moved and pending and promoted and game.get_piece(Vector2i(0,0)) == "dama_blanca"

func _special_history_test() -> bool:
    _reset()
    game.board = [
        ["rey_negro", "", "", "", "", "", "", "torre_negro"],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", ""],
        ["torre_blanca", "", "", "", "rey_blanca", "", "", "torre_blanca"],
    ]
    var ok: bool = game.attempt_move(Vector2i(4,7), Vector2i(6,7))
    return ok and game.move_history.size() == 1 and bool(game.move_history[0]["castle"])

func _invalid_outcome_test() -> bool:
    var Nexus = preload("res://domain/competitive/nexus_team.gd")
    var original: Dictionary = {"rating": 1000, "best_rating": 1000, "uncertainty": 100.0, "volatility": 0.5, "form": 0.0, "last_activity_at": 100}
    var unchanged: Dictionary = Nexus.update_player(original, 1000.0, "mystery", 200)
    var invalid_normalized := preload("res://domain/competitive/competitive_system.gd").normalize_outcome("unknown") == ""
    var no_rating_delta := preload("res://domain/competitive/competitive_system.gd").rating_delta(1000, 1000, "unknown") == 0
    return invalid_normalized and no_rating_delta and unchanged == original

func _social_test() -> bool:
    _reset()
    game.local_player_slot = 0
    game.chat("hola")
    var first := game.emote("bien")
    var blocked := not game.emote("jajaja")
    game.emote_cooldown_until = game.now() - 0.1
    game.current_slot = 0
    game.local_player_slot = 0
    var second := game.emote("jajaja")
    var stored := game.chat_history.size() == 1 and game.emote_history.size() == 2
    game.reset_match(ChessGameState.MODE_2C2)
    game.local_player_slot = 0
    game.current_slot = 1 # turno rival: las acciones sociales siguen disponibles
    game.chat("mensaje fuera de turno")
    var off_turn_chat := game.chat_history.size() == 1
    var off_turn_emote := game.emote("bien")
    game.board[6][4] = ""
    game.board[4][4] = "peon_blanca"
    var off_turn_suggestion := game.propose_suggestion(Vector2i(4,4), Vector2i(4,3))
    var off_turn_swap := game.request_swap()
    game.reset_match(ChessGameState.MODE_1C1)
    game.local_player_slot = 0
    game.current_slot = 1
    game.chat("mensaje 1c1 fuera de turno")
    var off_turn_1c1 := game.chat_history.size() == 1 and game.emote("bien")
    game.reset_match(ChessGameState.MODE_VS_BOT)
    var vs_ai_blocked := not game.emote("bien")
    return stored and first and blocked and second and off_turn_chat and off_turn_emote and off_turn_suggestion and off_turn_swap and off_turn_1c1 and vs_ai_blocked


func _emote_picker_test(root: Node) -> bool:
    var data = root.get_node_or_null("PlayerData")
    var original: Array = data.get_equipped_emotes() if data != null else []
    if data != null and original.is_empty():
        var ids: Array[String] = []
        for item in preload("res://domain/player/emote_data.gd").all():
            ids.append(String(item["id"]))
            if ids.size() >= 6:
                break
        data.set_equipped_emotes(ids)
    var picker = EmotePickerScene.instantiate()
    root.add_child(picker)
    await process_frame
    var buttons: int = picker.get_node("Body/Grid").get_child_count()
    picker.queue_free()
    if data != null:
        data.set_equipped_emotes(original)
    var expected: int = original.size() if not original.is_empty() else 6
    return buttons == expected

func _player_card_emote_test(root: Node) -> bool:
    var card = PlayerCardScene.instantiate()
    root.add_child(card)
    await process_frame
    var badge = card.get_node_or_null("EmoteBadge")
    card.queue_free()
    return badge != null


func _team_clock_layout_test(root: Node) -> bool:
    var hud = preload("res://scenes/game_hud.tscn").instantiate()
    root.add_child(hud)
    await process_frame

    var black_clock = hud.get_node_or_null("BlackInfo/TeamClock")
    var white_clock = hud.get_node_or_null("WhiteInfo/TeamClock")
    var player_card_scene = preload("res://scenes/player_card.tscn")
    var card = player_card_scene.instantiate()
    root.add_child(card)
    await process_frame
    var player_clock = card.get_node_or_null("Clock")

    var ok = black_clock != null and white_clock != null and player_clock == null

    hud.queue_free()
    card.queue_free()
    return ok

func _test(name: String, ok: bool) -> void:
    if ok:
        passed += 1
        print("[OK] ", name)
    else:
        failed += 1
        print("[FAIL] ", name)
