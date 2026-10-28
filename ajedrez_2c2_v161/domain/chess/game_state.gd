extends Node
class_name ChessGameState

const ChessRules = preload("res://domain/chess/rules.gd")
const ChessGameSocialService = preload("res://domain/chess/game_social_service.gd")
const MatchReplayStateService = preload("res://domain/replay/match_replay_state_service.gd")
const ChessGameMatchLifecycleService = preload("res://domain/chess/game_match_lifecycle_service.gd")
const ChessGameMoveService = preload("res://domain/chess/game_move_service.gd")
const ChessGameBotService = preload("res://domain/chess/game_bot_service.gd")
const TeamControlDelegationPolicy = preload("res://domain/online/team_control_delegation.gd")

signal state_changed
signal log_line(text: String)
signal match_finished(winner_team: int, reason: String)
signal promotion_required(square: Vector2i)
signal terminal_reconnect_requested(slot: int)

const TEAM_WHITE := 0
const TEAM_BLACK := 1
const SLOTS := 4
const ABSENCE_SECONDS := 60.0
const SUGGESTION_COOLDOWN := 2.0
const QUESTION_COOLDOWN := 2.0
const EMOTE_COOLDOWN := 2.0
const MATCH_SECONDS := 600.0
const DEFAULT_MATCH_MINUTES := 10
const NO_SQUARE := Vector2i(-1, -1)

const MODE_2C2 := 0
const MODE_1C1 := 1
const MODE_VS_BOT := 2
const MODE_1C1_LOCAL := 3

var rules: ChessRules = ChessRules.new()
var mode: int = MODE_2C2
var board: Array = []
var slot_owners := ["Jugador A", "Jugador B", "Jugador C", "Jugador D"]
var slot_colors := [TEAM_WHITE, TEAM_BLACK, TEAM_WHITE, TEAM_BLACK]
var slot_active := [true, true, true, true]
var slot_profile_ids := ["you", "rival1", "mate", "rival2"]
var current_slot := 0
# El turno y el jugador local no son el mismo concepto. El cliente actual usa el slot 0.
var local_player_slot := 0
var selected := NO_SQUARE
var running := true
var winner_team := -1
var winner_reason := ""
var bot_id := "mateo"
var bot_target_elo: int = 400
var bot_target_nexus: int = 200
var bot_slots: Dictionary = {}

var strategic_mode: bool = true

var suggestion: Dictionary = {}
var suggestion_cooldown_until := 0.0
var question_cooldown_until := 0.0
var emote_cooldown_until := 0.0
var last_emote_id := ""
var last_emote_slot := -1
var emote_serial := 0
var surrender_request := {}
var draw_state: Dictionary = {"stage": 0, "by_slot": -1, "target_team": -1, "accepted_by": []}
var swap_request := {}
var last_seen := [0.0, 0.0, 0.0, 0.0]
var match_minutes: int = DEFAULT_MATCH_MINUTES
var match_seconds: float = MATCH_SECONDS
var team_time := [MATCH_SECONDS, MATCH_SECONDS]

var castling_rights := {"WK": true, "WQ": true, "BK": true, "BQ": true}
var en_passant_target := NO_SQUARE
# FIDE draw tracking: half-moves since the last pawn move/capture and occurrence counts.
var halfmove_clock: int = 0
var position_repetition_counts: Dictionary = {}
var match_uid: String = ""
var pending_promotion := NO_SQUARE
var pending_move_index: int = -1
var move_history: Array[Dictionary] = []
var chat_history: Array[String] = []
var emote_history: Array[String] = []
var replay_states: Array[Dictionary] = []

var pair_stats: Dictionary = {}
var social_service: ChessGameSocialService
var replay_service: MatchReplayStateService
var lifecycle_service: ChessGameMatchLifecycleService
var move_service: ChessGameMoveService
var bot_service: ChessGameBotService
# Bridge between local 2c2 slot state and the future server-authoritative delegation policy.
var team_delegation_policy: RefCounted
# Slot whose already-started delegated turn remains owned by the teammate until turn advance.
var delegated_turn_actor: Dictionary = {}

func _ensure_social_service() -> void:
    if social_service == null:
        social_service = ChessGameSocialService.new(self)
    else:
        social_service.bind(self)

func _ensure_replay_service() -> void:
    if replay_service == null:
        replay_service = MatchReplayStateService.new(self)
    else:
        replay_service.bind(self)

func _ensure_lifecycle_service() -> void:
    if lifecycle_service == null:
        lifecycle_service = ChessGameMatchLifecycleService.new(self)
    else:
        lifecycle_service.bind(self)

func _ensure_move_service() -> void:
    if move_service == null:
        move_service = ChessGameMoveService.new(self)
    else:
        move_service.bind(self)

func _ensure_bot_service() -> void:
    if bot_service == null:
        bot_service = ChessGameBotService.new(self)
    else:
        bot_service.bind(self)

func _ensure_domain_services() -> void:
    _ensure_social_service()
    _ensure_replay_service()
    _ensure_lifecycle_service()
    _ensure_move_service()
    _ensure_bot_service()

func _ready() -> void:
    _ensure_domain_services()
    reset_match(MODE_2C2)
    set_process(true)

func reset_match(new_mode: int = MODE_2C2, new_time_minutes: int = -1) -> void:
    _ensure_lifecycle_service()
    lifecycle_service.reset_match(new_mode, new_time_minutes)

func now() -> float:
    _ensure_lifecycle_service()
    return lifecycle_service.now()

func _process(delta: float) -> void:
    _ensure_lifecycle_service()
    lifecycle_service.process(delta)

func _check_absence() -> void:
    _ensure_lifecycle_service()
    lifecycle_service._check_absence()

func _ensure_pair_stats() -> void:
    _ensure_lifecycle_service()
    lifecycle_service.ensure_pair_stats()

func pair_key_for_team(team: int) -> String:
    _ensure_lifecycle_service()
    return lifecycle_service.pair_key_for_team(team)

func any_active_on_team(team: int) -> bool:
    _ensure_lifecycle_service()
    return lifecycle_service.any_active_on_team(team)

func active_teammate(slot: int) -> int:
    _ensure_lifecycle_service()
    return lifecycle_service.active_teammate(slot)

func current_team() -> int:
    _ensure_lifecycle_service()
    return lifecycle_service.current_team()

func current_actor_slot() -> int:
    _ensure_lifecycle_service()
    return lifecycle_service.current_actor_slot()

func current_owner() -> String:
    _ensure_lifecycle_service()
    return lifecycle_service.current_owner()

func current_slot_name() -> String:
    _ensure_lifecycle_service()
    return lifecycle_service.current_slot_name()

func set_local_player_slot(slot: int) -> bool:
    _ensure_lifecycle_service()
    return lifecycle_service.set_local_player_slot(slot)

func assign_roles_for_local_team(local_team: int) -> void:
    _ensure_lifecycle_service()
    lifecycle_service.assign_roles_for_local_team(local_team)

func randomize_roles() -> void:
    _ensure_lifecycle_service()
    lifecycle_service.randomize_roles()

func local_team() -> int:
    _ensure_lifecycle_service()
    return lifecycle_service.local_team()

func is_2c2() -> bool:
    return mode == MODE_2C2

## Internal/testable connection-state bridge. This is not a network detector;
## a future authenticated server adapter must be the only online caller.
func set_slot_connection_status(slot: int, status: String) -> bool:
    if mode != MODE_2C2 or slot < 0 or slot >= SLOTS or team_delegation_policy == null:
        return false
    if status not in [TeamControlDelegationPolicy.STATUS_CONNECTED, TeamControlDelegationPolicy.STATUS_GRACE, TeamControlDelegationPolicy.STATUS_DISCONNECTED]:
        return false
    # A late reconnect after the match has ended only routes the UI back to the
    # result screen. It must never reopen or mutate the finished match.
    if not running:
        if status == TeamControlDelegationPolicy.STATUS_CONNECTED and team_delegation_policy.is_match_terminal(String(match_uid)):
            terminal_reconnect_requested.emit(slot)
        return false
    var profile_id := String(slot_profile_ids[slot]).strip_edges()
    if profile_id.is_empty() or not team_delegation_policy.set_player_status(profile_id, status):
        return false
    if status == TeamControlDelegationPolicy.STATUS_DISCONNECTED:
        slot_active[slot] = false
        # If their turn is already live, the active partner owns this turn even
        # if the original player reconnects before the move is completed.
        if current_slot == slot:
            _lock_current_delegated_turn(slot)
    elif status == TeamControlDelegationPolicy.STATUS_CONNECTED:
        slot_active[slot] = true
        last_seen[slot] = now()
        # Do not erase delegated_turn_actor here. The return takes effect for
        # control only on the next turn, never mid-turn.
    # Grace deliberately preserves the existing seat and does not delegate.
    state_changed.emit()
    return true

func _lock_current_delegated_turn(slot: int) -> void:
    if mode != MODE_2C2 or slot < 0 or slot >= SLOTS:
        return
    var mate := lifecycle_service.active_teammate(slot) if lifecycle_service != null else -1
    if mate >= 0 and bool(slot_active[mate]):
        delegated_turn_actor[slot] = mate

func refresh_team_delegation_policy() -> void:
    team_delegation_policy = TeamControlDelegationPolicy.new()
    if mode != MODE_2C2:
        return
    var white: Array[String] = []
    var black: Array[String] = []
    for slot in range(SLOTS):
        var pid := String(slot_profile_ids[slot]).strip_edges()
        if pid.is_empty():
            return
        if int(slot_colors[slot]) == TEAM_WHITE:
            white.append(pid)
        elif int(slot_colors[slot]) == TEAM_BLACK:
            black.append(pid)
    if white.size() != 2 or black.size() != 2:
        return
    if not team_delegation_policy.register_team("white", white[0], white[1]) or not team_delegation_policy.register_team("black", black[0], black[1]):
        team_delegation_policy = null
        return
    for slot in range(SLOTS):
        if not bool(slot_active[slot]):
            team_delegation_policy.set_player_status(String(slot_profile_ids[slot]), TeamControlDelegationPolicy.STATUS_DISCONNECTED)

func set_slot_profile(slot: int, profile_id: String, display_name: String = "") -> bool:
    _ensure_lifecycle_service()
    return lifecycle_service.set_slot_profile(slot, profile_id, display_name)

func mark_seen(slot: int) -> void:
    _ensure_lifecycle_service()
    lifecycle_service.mark_seen(slot)

func _advance_turn() -> void:
    _ensure_lifecycle_service()
    lifecycle_service.advance_turn()

func _normalize_current_turn() -> void:
    _ensure_lifecycle_service()
    lifecycle_service._normalize_current_turn()

func get_piece(pos: Vector2i) -> String:
    _ensure_move_service()
    return move_service.get_piece(pos)

func current_piece_allowed(piece: String) -> bool:
    _ensure_move_service()
    return move_service.current_piece_allowed(piece)

func attempt_move(from: Vector2i, to: Vector2i, promotion_piece: String = "dama", by_bot: bool = false) -> bool:
    _ensure_move_service()
    return move_service.attempt_move(from, to, promotion_piece, by_bot)

func choose_promotion(kind: String) -> bool:
    _ensure_move_service()
    return move_service.choose_promotion(kind)

func suggestion_visible_to(viewer_slot: int) -> bool:
    _ensure_social_service()
    return social_service.suggestion_visible_to(viewer_slot)

func propose_suggestion(from: Vector2i, to: Vector2i) -> bool:
    _ensure_social_service()
    return social_service.propose_suggestion(from, to)

func answer_suggestion(accept: bool, voter_slot: int = -1) -> bool:
    _ensure_social_service()
    return social_service.answer_suggestion(accept, voter_slot)

func question_suggestion(viewer_slot: int = -1) -> bool:
    _ensure_social_service()
    return social_service.question_suggestion(viewer_slot)

func set_strategic_mode(enabled: bool) -> void:
    _ensure_social_service()
    social_service.set_strategic_mode(enabled)

func request_swap() -> bool:
    _ensure_social_service()
    return social_service.request_swap()

func answer_swap(accept: bool) -> bool:
    _ensure_social_service()
    return social_service.answer_swap(accept)

func request_surrender() -> bool:
    _ensure_social_service()
    return social_service.request_surrender()

func answer_surrender(accept: bool) -> bool:
    _ensure_social_service()
    return social_service.answer_surrender(accept)

func required_draw_voters() -> Array[int]:
    _ensure_social_service()
    return social_service.required_draw_voters()

func request_draw() -> bool:
    _ensure_social_service()
    return social_service.request_draw()

func answer_draw(accept: bool, voter_slot: int = -1) -> bool:
    _ensure_social_service()
    return social_service.answer_draw(accept, voter_slot)

func mark_current_absent() -> void:
    _ensure_lifecycle_service()
    lifecycle_service.mark_current_absent()

func force_slot_absent(slot: int) -> void:
    _ensure_lifecycle_service()
    lifecycle_service.force_slot_absent(slot)

func return_player(slot: int) -> bool:
    _ensure_lifecycle_service()
    return lifecycle_service.return_player(slot)

func return_current_player() -> bool:
    _ensure_lifecycle_service()
    return lifecycle_service.return_current_player()

func chat(text: String) -> void:
    _ensure_social_service()
    social_service.chat(text)

func emote(emote_id: String) -> bool:
    _ensure_social_service()
    return social_service.emote(emote_id)

func finish(winning_team: int, reason: String) -> void:
    _ensure_lifecycle_service()
    lifecycle_service.finish(winning_team, reason)

func set_temporary_bot(slot: int, bot_profile_id: String) -> bool:
    _ensure_bot_service()
    return bot_service.set_temporary_bot(slot, bot_profile_id)

func clear_bot_slots() -> void:
    _ensure_bot_service()
    bot_service.clear_bot_slots()

func is_bot_slot(slot: int) -> bool:
    _ensure_bot_service()
    return bot_service.is_bot_slot(slot)

func is_bot_turn() -> bool:
    _ensure_bot_service()
    return bot_service.is_bot_turn()

func bot_take_turn() -> bool:
    _ensure_bot_service()
    return bot_service.bot_take_turn()

func bot_prepare_suggestion() -> bool:
    _ensure_bot_service()
    return bot_service.bot_prepare_suggestion()

func _capture_replay_state() -> void:
    _ensure_replay_service()
    replay_service.capture_state()

func repetition_count_for_current_position() -> int:
    _ensure_replay_service()
    return replay_service.current_position_repetition_count()

func can_claim_draw_by_repetition() -> bool:
    return running and repetition_count_for_current_position() >= 3

func can_claim_draw_by_fifty_moves() -> bool:
    return running and halfmove_clock >= 100

func claim_draw_by_rule() -> bool:
    if not running:
        return false
    if can_claim_draw_by_repetition():
        finish(-1, "Tablas reclamadas por triple repetición")
        return true
    if can_claim_draw_by_fifty_moves():
        finish(-1, "Tablas reclamadas por la regla de los 50 movimientos")
        return true
    return false

func check_automatic_draw_rules() -> bool:
    if not running:
        return false
    if halfmove_clock >= 150:
        finish(-1, "Tablas automáticas por la regla de los 75 movimientos")
        return true
    if repetition_count_for_current_position() >= 5:
        finish(-1, "Tablas automáticas por quintuple repetición")
        return true
    return false

func replay_data() -> Dictionary:
    _ensure_replay_service()
    return replay_service.data()

static func decode_replay_state(state: Dictionary) -> Dictionary:
    return MatchReplayStateService.decode_state(state)

func replay_moves() -> Array[Dictionary]:
    _ensure_replay_service()
    return replay_service.moves()

func square_name(pos: Vector2i) -> String:
    _ensure_move_service()
    return move_service.square_name(pos)

func piece_label(piece: String) -> String:
    _ensure_move_service()
    return move_service.piece_label(piece)

func _emit_log(text: String) -> void:
    log_line.emit(text)
