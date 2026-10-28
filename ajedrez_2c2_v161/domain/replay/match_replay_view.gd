extends Control
class_name MatchReplayView

const ReplayBoardScript = preload("res://domain/replay/replay_board.gd")
const ReplayViewControllerScript = preload("res://domain/replay/replay_view_controller.gd")
const ReplayViewLayoutScript = preload("res://domain/replay/replay_view_layout_service.gd")
const MoveClassificationStyle = preload("res://core/review/move_classification_style.gd")

const TEXT := Color("#F0E3C4")
const MUTED := Color("#A89B83")
const GOLD := Color("#D5A84E")
const BORDER := Color("#3D3428")
const MOVE_STRIP_HEIGHT := 48.0
const NAV_HEIGHT := 52.0
const COACH_HEIGHT := 124.0
const AUTO_INTERVAL := 0.28
const IMPORTANT_CLASSIFICATIONS := MoveClassificationStyle.IMPORTANT
const CLASS_COLORS := MoveClassificationStyle.COLORS

signal position_changed(index: int, move: Dictionary)
signal analysis_requested

var _states: Array = []
var _moves: Array = []
var _index := 0
var _board: Control
var _position_label: Label
var _move_label: Label
var _move_list: HBoxContainer
var _move_scroll: ScrollContainer
var _move_grid_scroll: ScrollContainer
var _move_grid: VBoxContainer
var _coach_panel: PanelContainer
var _coach_title: Label
var _coach_text: Label
var _coach_line: Label
var _best_move_button: Button
var _show_best_move := false
var _board_side := 280.0
var _workspace: Control
var _engine_analysis: Array = []
var _previous_button: Button
var _auto_button: Button
var _next_button: Button
var _auto_review := false
var _auto_clock := 0.0
var controller: ReplayViewController
var layout_service: ReplayViewLayoutService
var _initialized := false
var _review_mode := "replay"
var _analysis_entry_button: Button
var _result_label: Label
var _white_player_header: Control
var _black_player_header: Control
var _match_metadata: Dictionary = {}

func _draw() -> void:
    # Respaldo visual por si el Control se monta fuera del tema global.
    draw_rect(Rect2(Vector2.ZERO, size), Color("#07111F"), true)

func _ready() -> void:
    _ensure_initialized()
    queue_redraw()

func _ensure_initialized() -> void:
    if _initialized:
        return
    controller = ReplayViewControllerScript.new(self)
    layout_service = ReplayViewLayoutScript.new(self)
    layout_service.build()
    _initialized = true

func _process(delta: float) -> void:
    controller._process(delta)

func configure_view(title: String) -> void:
    _ensure_initialized()
    controller.configure_view(title)

func set_engine_analysis(report: Dictionary) -> void:
    _ensure_initialized()
    controller.set_engine_analysis(report)

func set_review_mode(mode: String) -> void:
    _ensure_initialized()
    controller.set_review_mode(mode)

func request_analysis() -> void:
    analysis_requested.emit()
    var match_events = get_node_or_null("/root/MatchEvents")
    if match_events != null:
        var match_id := String(_match_metadata.get("match_id", "replay"))
        match_events.analysis_requested.emit(match_id, _index)

func set_replay_data(replay: Dictionary, moves: Array = []) -> void:
    _ensure_initialized()
    if replay is Dictionary:
        set_match_metadata(replay.get("metadata", replay.get("match", {})) if replay.get("metadata", replay.get("match", {})) is Dictionary else {})
    controller.set_replay_data(replay, moves)

func set_match_metadata(metadata: Dictionary) -> void:
    _match_metadata = metadata.duplicate(true)
    # Legacy history entries store players by slot; newer entries may provide
    # explicit white_player / black_player snapshots.
    var players: Variant = _match_metadata.get("players", [])
    var colors: Variant = _match_metadata.get("player_colors", [])
    if players is Array and not players.is_empty():
        for i in range(players.size()):
            var color := String(colors[i]) if colors is Array and i < colors.size() else ("white" if i == 0 else "black")
            if color not in ["white", "black"]:
                continue
            var key := "white_player" if color == "white" else "black_player"
            if not _match_metadata.has(key):
                var player_name := String(players[i])
                if player_name in ["you", "Tú"]:
                    player_name = "Tú"
                elif player_name in ["rival1", "rival2"]:
                    player_name = "Rival"
                elif player_name == "mate":
                    player_name = "Compañero"
                _match_metadata[key] = {"name": player_name, "nexus": _match_metadata.get("nexus", null)}
    var opponents: Variant = _match_metadata.get("opponents", [])
    if not _match_metadata.has("black_player") and opponents is Array and not opponents.is_empty():
        _match_metadata["black_player"] = {"name": ", ".join(PackedStringArray(opponents)), "nexus": _match_metadata.get("nexus", null)}
    if not _match_metadata.has("white_player"):
        var white_name := String(_match_metadata.get("partner", ""))
        white_name = "Tú + " + white_name if not white_name.is_empty() else "Tú"
        _match_metadata["white_player"] = {"name": white_name, "nexus": _match_metadata.get("nexus", null)}
    if int(_match_metadata.get("mode", -1)) == 2 and not _match_metadata.has("black_player"):
        _match_metadata["black_player"] = {"name": "Bot " + String(_match_metadata.get("bot_id", "" )).capitalize(), "nexus": _match_metadata.get("bot_nexus", null)}
    _ensure_initialized()
    var context_service = get_node_or_null("/root/MatchContext") if is_inside_tree() else null
    if context_service != null and context_service.has_method("begin_match"):
        context_service.begin_match(_match_metadata)
    var match_events = get_node_or_null("/root/MatchEvents") if is_inside_tree() else null
    if match_events != null:
        match_events.publish_match_loaded(String(_match_metadata.get("match_id", "replay")), _match_metadata)
        var players_snapshot: Variant = _match_metadata.get("players", {})
        if players_snapshot is Dictionary:
            if players_snapshot.get("white", {}) is Dictionary:
                match_events.publish_player("white", players_snapshot.get("white", {}))
            if players_snapshot.get("black", {}) is Dictionary:
                match_events.publish_player("black", players_snapshot.get("black", {}))
        if _match_metadata.get("white_player", {}) is Dictionary:
            match_events.publish_player("white", _match_metadata.get("white_player", {}))
        if _match_metadata.get("black_player", {}) is Dictionary:
            match_events.publish_player("black", _match_metadata.get("black_player", {}))
    if is_instance_valid(_result_label):
        match String(_match_metadata.get("outcome", "")):
            "win": _result_label.text = "VICTORIA"
            "loss": _result_label.text = "DERROTA"
            "draw": _result_label.text = "TABLAS"
            _: _result_label.text = String(_match_metadata.get("result", "REPLAY" )).to_upper()
    _refresh_player_headers()

func _refresh_replay_clocks(move_index: int) -> void:
    if not is_instance_valid(_white_player_header) or not is_instance_valid(_black_player_header):
        return
    var clocks: Variant = _match_metadata.get("clocks", {})
    var white_time := float(_match_metadata.get("white_time", clocks.get("white", 0.0) if clocks is Dictionary else 0.0))
    var black_time := float(_match_metadata.get("black_time", clocks.get("black", 0.0) if clocks is Dictionary else 0.0))
    var active_color := ""
    var history: Variant = _match_metadata.get("clock_history", [])
    if history is Array and not history.is_empty():
        var chosen: Dictionary = history[0] if history[0] is Dictionary else {}
        for entry in history:
            if entry is Dictionary and int(entry.get("move_index", 0)) <= move_index:
                chosen = entry
        white_time = float(chosen.get("white_seconds", white_time))
        black_time = float(chosen.get("black_seconds", black_time))
        active_color = String(chosen.get("active_color", ""))
    _white_player_header.set_clock(white_time, active_color == "white")
    _black_player_header.set_clock(black_time, active_color == "black")
    var context_service = get_node_or_null("/root/MatchContext") if is_inside_tree() else null
    if context_service != null and context_service.has_method("set_clocks"):
        context_service.set_clocks(white_time, black_time, active_color)
    var match_events = get_node_or_null("/root/MatchEvents") if is_inside_tree() else null
    if match_events != null:
        match_events.publish_clock(move_index, white_time, black_time, active_color)

func _refresh_player_headers() -> void:
    if not is_instance_valid(_white_player_header) or not is_instance_valid(_black_player_header):
        return
    var players: Variant = _match_metadata.get("players", {})
    if not players is Dictionary:
        players = {}
    var white: Variant = _match_metadata.get("white_player", players.get("white", {}))
    var black: Variant = _match_metadata.get("black_player", players.get("black", {}))
    if white is Dictionary and _white_player_header.has_method("set_player_data"):
        _white_player_header.set_player_data(white)
    if black is Dictionary and _black_player_header.has_method("set_player_data"):
        _black_player_header.set_player_data(black)
    _refresh_replay_clocks(_index)

func set_replay_position(index: int) -> void:
    _ensure_initialized()
    controller.set_replay_position(index)

func toggle_auto_review() -> void:
    _ensure_initialized()
    controller.toggle_auto_review()

func stop_auto_review() -> void:
    _ensure_initialized()
    controller.stop_auto_review()

func _refresh() -> void:
    _ensure_initialized()
    controller._refresh()

func _refresh_navigation_state() -> void:
    _ensure_initialized()
    controller._refresh_navigation_state()

func _rebuild_move_list() -> void:
    _ensure_initialized()
    controller._rebuild_move_list()

func _format_move_compact(move: Dictionary) -> String:
    _ensure_initialized()
    return controller._format_move_compact(move)

func _make_move_button(label: String, state_index: int, move: Dictionary = {}) -> Button:
    _ensure_initialized()
    return controller._make_move_button(label, state_index, move)

func _format_move_tooltip(move: Dictionary) -> String:
    _ensure_initialized()
    return controller._format_move_tooltip(move)

func _refresh_move_analysis_styles() -> void:
    _ensure_initialized()
    controller._refresh_move_analysis_styles()

func _is_important_index(index: int) -> bool:
    _ensure_initialized()
    return controller._is_important_index(index)

func _refresh_context_coach() -> void:
    _ensure_initialized()
    controller._refresh_context_coach()

func toggle_best_move() -> void:
    _ensure_initialized()
    controller.toggle_best_move()

func _refresh_board_highlight() -> void:
    _ensure_initialized()
    controller._refresh_board_highlight()

func _refresh_move_selection() -> void:
    _ensure_initialized()
    controller._refresh_move_selection()

func _ensure_selected_move_visible() -> void:
    _ensure_initialized()
    controller._ensure_selected_move_visible()

func _resize() -> void:
    _ensure_initialized()
    layout_service.resize()

func _mobile_ui_scale(viewport_size: Vector2) -> float:
    _ensure_initialized()
    return layout_service.mobile_ui_scale(viewport_size)

func _make_nav_button(symbol: String, tooltip: String) -> Button:
    _ensure_initialized()
    return layout_service.make_nav_button(symbol, tooltip)

func _make_auto_button() -> Button:
    _ensure_initialized()
    return layout_service.make_auto_button()

