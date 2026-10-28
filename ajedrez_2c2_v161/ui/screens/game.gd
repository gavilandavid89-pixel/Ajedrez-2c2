extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const Competitive = preload("res://domain/competitive/competitive_system.gd")
const ChessGameState = preload("res://domain/chess/game_state.gd")
const AppConfig = preload("res://core/services/app.gd")
const BotDataScript = preload("res://domain/bots/bot_data.gd")

func _app() -> Node:
    return RuntimeServicesScript.get_autoload("App")

func _selected_mode() -> int:
    var app = _app()
    return int(app.selected_mode) if app != null else AppConfig.MODE_2C2

func _selected_time_minutes() -> int:
    var app = _app()
    return int(app.selected_time_minutes) if app != null else 10

var game: ChessGameState
var board_view: ChessBoardView
var hud
var bot_wait := 0.0
var bot_think_time := 1.20
var bot_suggestion_sent := false
var bot_suggestion_hold := 0.0
var bot_turn_key := ""
var bot_delay_rng := RandomNumberGenerator.new()
var last_move_count := 0
var last_feedback_move_count := 0
var audio_feedback
var last_result_entry: Dictionary = {}
var _pointer_down := false
var _pointer_down_square := Vector2i(-1, -1)
var _active_pointer_index := -1
var suggestion_mode := false
var input_controller: GameInputController
var bot_controller: GameBotCoordinator
var result_service: GameMatchResultService
var flow_controller: GameFlowController

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _ensure_controllers()
    audio_feedback = RuntimeServicesScript.get_autoload("AudioFeedback")
    game = ChessGameState.new()
    add_child(game)
    var match_context = get_node_or_null("/root/MatchContext")
    if match_context != null and match_context.has_method("begin_match"):
        match_context.begin_match({"match_id": "live_%d" % Time.get_ticks_msec(), "mode": _selected_mode(), "time_control_minutes": _selected_time_minutes()})
    game.reset_match(_selected_mode(), _selected_time_minutes())
    game.randomize_roles()
    game.match_finished.connect(_on_match_finished)
    game.terminal_reconnect_requested.connect(_on_terminal_reconnect_requested)
    if game.mode == AppConfig.MODE_VS_BOT:
        var app = _app()
        if app != null:
            game.bot_id = String(app.selected_bot_id)
            game.bot_target_elo = int(app.selected_bot_elo)
            game.bot_target_nexus = int(app.selected_bot_nexus)
        bot_think_time = BotDataScript.thinking_time_for(game.bot_id)
    board_view = get_node("Board") as ChessBoardView
    hud = get_node("HUD")
    if board_view != null:
        # El tablero se orienta según el rol del jugador local, no según la skin.
        board_view.set_flipped(game.local_team() == game.TEAM_BLACK)
        board_view.set_game(game)
        board_view.square_pressed.connect(_on_board_square)
        if board_view.move_animator != null and not board_view.move_animator.move_landed.is_connected(_on_move_animation_finished):
            board_view.move_animator.move_landed.connect(_on_move_animation_finished)
    if hud != null:
        hud.set_game(game)
        hud.back_requested.connect(_go_back)
        hud.reset_requested.connect(_reset)
        hud.rematch_requested.connect(_rematch)
        if hud.has_signal("analysis_requested"):
            hud.analysis_requested.connect(_open_latest_analysis)
        hud.action_requested.connect(_on_action)
    game.state_changed.connect(_on_state_changed)
    game.promotion_required.connect(func(_square):
        if hud != null:
            hud.refresh()
    )
    last_move_count = game.move_history.size()
    last_feedback_move_count = last_move_count
    _on_state_changed()

func _ensure_controllers() -> void:
    if input_controller == null:
        input_controller = GameInputController.new(self)
    if bot_controller == null:
        bot_controller = GameBotCoordinator.new(self)
    if result_service == null:
        result_service = GameMatchResultService.new(self)
    if flow_controller == null:
        flow_controller = GameFlowController.new(self)

func _input(event: InputEvent) -> void:
    _ensure_controllers()
    input_controller._input(event)

func _logical_square_at(point: Vector2) -> Vector2i:
    _ensure_controllers()
    return input_controller._logical_square_at(point)

func _unhandled_input(event: InputEvent) -> void:
    _ensure_controllers()
    input_controller._unhandled_input(event)

func _process(delta: float) -> void:
    _ensure_controllers()
    bot_controller._process(delta)

func _on_board_square(pos: Vector2i) -> void:
    _ensure_controllers()
    input_controller._on_board_square(pos)

func _on_action(action: String) -> void:
    _ensure_controllers()
    input_controller._on_action(action)

func _confirm_surrender_enabled() -> bool:
    _ensure_controllers()
    return input_controller._confirm_surrender_enabled()

func _on_state_changed() -> void:
    var current_count := game.move_history.size() if game != null else 0
    # Reinicio/rematch: no conservar el resaltado ni una animación de la partida anterior.
    if current_count < last_move_count and board_view != null:
        board_view.last_move_highlight.clear()
        if board_view.move_animator != null:
            board_view.move_animator.stop_animation(false)
        board_view.queue_redraw()
        last_feedback_move_count = current_count
    var had_new_move := current_count > last_move_count
    if board_view:
        if game != null and game.mode == AppConfig.MODE_1C1_LOCAL and had_new_move:
            board_view.set_flipped(not board_view.flipped)
        if had_new_move:
            board_view.animate_move(game.move_history[current_count - 1])
        board_view.refresh_layout()
        board_view.queue_redraw()
    last_move_count = current_count

func _on_move_animation_finished(move: Dictionary) -> void:
    if audio_feedback == null or game == null:
        return
    var app = _app()
    if app != null and bool(app.navigation_audit_mode):
        return
    var count := game.move_history.size()
    if count <= last_feedback_move_count:
        return
    if bool(move.get("en_passant", false)) or not str(move.get("captured", "")).is_empty():
        audio_feedback.play_feedback("capture_impact")
    else:
        audio_feedback.play_feedback("move_impact")
    # La confirmación de promoción sigue siendo un sonido secundario; el
    # golpe de aterrizaje ocurre primero y siempre al final del trayecto.
    if str(move.get("promotion", "")) == "pending":
        audio_feedback.play_feedback("promotion")
    last_feedback_move_count = count

func _reset() -> void:
    _ensure_controllers()
    flow_controller._reset()

func _open_latest_analysis() -> void:
    _ensure_controllers()
    flow_controller._open_latest_analysis()

func _rematch() -> void:
    _ensure_controllers()
    flow_controller._rematch()

func _go_back() -> void:
    _ensure_controllers()
    flow_controller._go_back()

func _on_match_finished(team: int, reason: String) -> void:
    _ensure_controllers()
    var result_payload := {"winner_team": team, "reason": reason, "move_count": game.move_history.size() if game != null else 0}
    var match_context = get_node_or_null("/root/MatchContext")
    if match_context != null and match_context.has_method("set_result"):
        match_context.set_result(result_payload)
    var match_events = get_node_or_null("/root/MatchEvents")
    if match_events != null:
        var app = _app()
        var match_id := String(game.match_uid) if game != null else ""
        match_events.match_finished.emit(match_id, result_payload)
    result_service._on_match_finished(team, reason)


func _on_terminal_reconnect_requested(_slot: int) -> void:
    # Clash Royale-like return path: show the already-finalized result, without
    # restoring gameplay, timers, turns, or connection ownership.
    if hud != null and hud.has_method("show_result_screen_after_reconnect"):
        hud.show_result_screen_after_reconnect()
