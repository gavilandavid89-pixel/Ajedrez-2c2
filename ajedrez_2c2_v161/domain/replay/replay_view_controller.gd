extends RefCounted
class_name ReplayViewController

const ChessGameState = preload("res://domain/chess/game_state.gd")
const MoveClassificationStyle = preload("res://core/review/move_classification_style.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var _states: Array:
    get: return host._states
    set(value): host._states = value
var _moves: Array:
    get: return host._moves
    set(value): host._moves = value
var _index: int:
    get: return int(host._index)
    set(value): host._index = value
var _board: Variant:
    get: return host._board
var _position_label: Variant:
    get: return host._position_label
var _move_label: Variant:
    get: return host._move_label
var _move_list: Variant:
    get: return host._move_list
var _move_scroll: Variant:
    get: return host._move_scroll
var _coach_panel: Variant:
    get: return host._coach_panel
var _coach_title: Variant:
    get: return host._coach_title
var _coach_text: Variant:
    get: return host._coach_text
var _coach_line: Variant:
    get: return host._coach_line
var _best_move_button: Variant:
    get: return host._best_move_button
var _engine_analysis: Array:
    get: return host._engine_analysis
    set(value): host._engine_analysis = value
var _previous_button: Variant:
    get: return host._previous_button
var _auto_button: Variant:
    get: return host._auto_button
var _next_button: Variant:
    get: return host._next_button
var _auto_review: bool:
    get: return bool(host._auto_review)
    set(value): host._auto_review = value
var _auto_clock: float:
    get: return float(host._auto_clock)
    set(value): host._auto_clock = value
var TEXT: Color:
    get: return host.TEXT
var MUTED: Color:
    get: return host.MUTED
var GOLD: Color:
    get: return host.GOLD
var MOVE_STRIP_HEIGHT: float:
    get: return float(host.MOVE_STRIP_HEIGHT)
var IMPORTANT_CLASSIFICATIONS: Array:
    get: return host.IMPORTANT_CLASSIFICATIONS
var CLASS_COLORS: Dictionary:
    get: return host.CLASS_COLORS
var NAV_HEIGHT: float:
    get: return float(host.NAV_HEIGHT)
var COACH_HEIGHT: float:
    get: return float(host.COACH_HEIGHT)
var AUTO_INTERVAL: float:
    get: return float(host.AUTO_INTERVAL)

func position_changed_emit(index: int, move: Dictionary) -> void:
    host.position_changed.emit(index, move)

func _process(delta: float) -> void:
    if not _auto_review:
        return
    _auto_clock += delta
    if _auto_clock < AUTO_INTERVAL:
        return
    _auto_clock = 0.0
    if _index >= _states.size() - 1:
        stop_auto_review()
        return
    set_replay_position(_index + 1)
    if host._review_mode == "analysis" and _is_important_index(_index):
        stop_auto_review()

func configure_view(title: String) -> void:
    # Se conserva por compatibilidad, pero el estudio ya no necesita una cabecera separada.
    pass

func set_review_mode(mode: String) -> void:
    var normalized := "analysis" if mode.to_lower() == "analysis" else "replay"
    host._review_mode = normalized
    # Player cards and clocks are part of the match/replay surface. Game Review
    # intentionally hides them so the analysis workspace can focus on the board.
    if is_instance_valid(host._black_player_header):
        host._black_player_header.visible = normalized == "replay"
    if is_instance_valid(host._white_player_header):
        host._white_player_header.visible = normalized == "replay"
    var match_events = host.get_node_or_null("/root/MatchEvents") if host.is_inside_tree() else null
    if match_events != null:
        var match_id := String(host._match_metadata.get("match_id", "replay"))
        if normalized == "analysis":
            match_events.analysis_started.emit(match_id)
        else:
            match_events.replay_started.emit(match_id)
    if is_instance_valid(host._result_label):
        host._result_label.visible = normalized == "replay"
    if is_instance_valid(host._analysis_entry_button):
        host._analysis_entry_button.visible = normalized == "replay"
        if host._analysis_entry_button.get_parent() is Control:
            host._analysis_entry_button.get_parent().visible = normalized == "replay"
    if is_instance_valid(_coach_panel):
        _coach_panel.visible = normalized == "analysis" and not _current_review().is_empty()
    if is_instance_valid(_move_scroll):
        _move_scroll.visible = normalized == "analysis"
    if is_instance_valid(host._move_grid_scroll):
        host._move_grid_scroll.visible = normalized == "replay"
    if normalized == "replay":
        host._show_best_move = false
        _board.set_highlight("", "", "")
    _refresh_move_analysis_styles()
    _refresh_context_coach()
    if host.is_inside_tree():
        _refresh_board_highlight()
        host.call_deferred("_resize")
    _refresh_navigation_state()

func set_engine_analysis(report: Dictionary) -> void:
    _engine_analysis = report.get("moves", []).duplicate(true) if report is Dictionary and report.get("moves", []) is Array else []
    host._show_best_move = false
    _refresh_move_analysis_styles()
    _refresh()

func set_replay_data(replay: Dictionary, moves: Array = []) -> void:
    stop_auto_review()
    _states.clear()
    _moves = moves.duplicate(true) if moves is Array else []
    var raw_states: Variant = replay.get("states", []) if replay is Dictionary else []
    if raw_states is Array:
        for item in raw_states:
            if item is Dictionary:
                var decoded := ChessGameState.decode_replay_state(item)
                if not decoded.is_empty():
                    _states.append(decoded)
    _index = clampi(_index, 0, max(0, _states.size() - 1))
    var match_id := String(replay.get("match_id", replay.get("id", "replay")))
    var match_events = host.get_node_or_null("/root/MatchEvents")
    if match_events != null:
        match_events.publish_match_loaded(match_id, replay.get("metadata", {}) if replay.get("metadata", {}) is Dictionary else {})
    var match_context = host.get_node_or_null("/root/MatchContext")
    if match_context != null and match_context.has_method("begin_match"):
        match_context.begin_match(replay.get("metadata", {}) if replay.get("metadata", {}) is Dictionary else {})
    _rebuild_move_list()
    _refresh()

func set_replay_position(index: int) -> void:
    if _states.is_empty():
        _index = 0
        _refresh()
        return
    _index = clampi(index, 0, _states.size() - 1)
    _refresh()
    var move: Dictionary = _moves[_index - 1] if _index > 0 and _index - 1 < _moves.size() else {}
    position_changed_emit(_index, move)
    var match_events = host.get_node_or_null("/root/MatchEvents")
    if match_events != null:
        match_events.publish_replay_position("replay", _index)

func toggle_auto_review() -> void:
    if _auto_review:
        stop_auto_review()
        return
    _auto_review = true
    _auto_clock = 0.0
    _auto_button.text = "■"
    _auto_button.tooltip_text = "Pausar reproducción"
    if host._review_mode == "analysis" and _is_important_index(_index):
        set_replay_position(_index + 1)
    if _index >= _states.size() - 1:
        stop_auto_review()

func stop_auto_review() -> void:
    _auto_review = false
    _auto_clock = 0.0
    if is_instance_valid(_auto_button):
        _auto_button.text = "AUTO"
        _auto_button.tooltip_text = "Reproducir la partida automáticamente"

func _refresh() -> void:
    var total := _states.size()
    _position_label.text = "Jugada %d" % _index

    if total == 0:
        _move_label.text = "Sin partida"
        _board.set_state({})
        _coach_panel.visible = false
        _refresh_navigation_state()
        return

    if _index == 0:
        _move_label.text = "Inicio"
    elif _index - 1 < _moves.size():
        var move: Dictionary = _moves[_index - 1]
        _move_label.text = "%d. %s → %s" % [_index, String(move.get("from", "")), String(move.get("to", ""))]
    else:
        _move_label.text = "Jugada %d" % _index

    _board.set_state(_states[_index])
    if host.has_method("_refresh_replay_clocks"):
        host._refresh_replay_clocks(_index)
    host._show_best_move = false
    _refresh_move_selection()
    _refresh_move_analysis_styles()
    _refresh_context_coach()
    _refresh_board_highlight()
    _refresh_navigation_state()

func _refresh_navigation_state() -> void:
    if is_instance_valid(_previous_button):
        _previous_button.disabled = _index <= 0
    if is_instance_valid(_next_button):
        _next_button.disabled = _index >= max(0, _states.size() - 1)
    if is_instance_valid(_auto_button):
        _auto_button.disabled = _states.size() <= 1
        if not _auto_review and _auto_button.disabled:
            _auto_button.text = "AUTO"

func _rebuild_move_list() -> void:
    if is_instance_valid(_move_list):
        for child in _move_list.get_children():
            child.queue_free()
    if is_instance_valid(host._move_grid):
        for child in host._move_grid.get_children():
            child.queue_free()
    if _states.is_empty():
        var empty := Label.new()
        empty.text = "Sin jugadas"
        empty.add_theme_color_override("font_color", MUTED)
        empty.add_theme_font_size_override("font_size", 16)
        if is_instance_valid(_move_list):
            _move_list.add_child(empty.duplicate())
        if is_instance_valid(host._move_grid):
            host._move_grid.add_child(empty)
        return

    # Barra horizontal de análisis: la clasificación ya existente solo colorea
    # esta vista, sin alterar la identidad visual de blancas/negras.
    if is_instance_valid(_move_list):
        _move_list.add_child(_make_move_button("Inicio", 0))
        for i in range(_moves.size()):
            var move: Dictionary = _moves[i] if _moves[i] is Dictionary else {}
            var number := int(i / 2) + 1
            var prefix := "%d.%s" % [number, "" if i % 2 == 0 else ".."]
            _move_list.add_child(_make_move_button(prefix + " " + _format_move_compact(move), i + 1, move))

    # Planilla de replay: número | jugada blanca | jugada negra.
    if is_instance_valid(host._move_grid):
        var start_row := HBoxContainer.new()
        start_row.add_theme_constant_override("separation", 8)
        var start_button := _make_move_button("Inicio", 0)
        start_button.custom_minimum_size = Vector2(70, 34)
        start_row.add_child(start_button)
        var start_hint := Label.new()
        start_hint.text = "Posición inicial"
        start_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        start_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        start_hint.add_theme_color_override("font_color", MUTED)
        start_row.add_child(start_hint)
        host._move_grid.add_child(start_row)
        var row_count := int(ceil(float(_moves.size()) / 2.0))
        for row_index in range(row_count):
            var row := HBoxContainer.new()
            row.add_theme_constant_override("separation", 6)
            var number_label := Label.new()
            number_label.text = "%d." % (row_index + 1)
            number_label.custom_minimum_size = Vector2(28, 34)
            number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
            number_label.add_theme_color_override("font_color", MUTED)
            row.add_child(number_label)
            var white_index := row_index * 2
            var white_move: Dictionary = _moves[white_index] if white_index < _moves.size() and _moves[white_index] is Dictionary else {}
            var white_button := _make_move_button(_format_move_compact(white_move), white_index + 1, white_move) if white_index < _moves.size() else _make_move_button("—", -1)
            white_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            white_button.custom_minimum_size = Vector2(0, 34)
            white_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
            row.add_child(white_button)
            var black_index := white_index + 1
            var black_move: Dictionary = _moves[black_index] if black_index < _moves.size() and _moves[black_index] is Dictionary else {}
            var black_button := _make_move_button(_format_move_compact(black_move), black_index + 1, black_move) if black_index < _moves.size() else _make_move_button("", -1)
            black_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            black_button.custom_minimum_size = Vector2(0, 34)
            black_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
            black_button.disabled = black_index >= _moves.size()
            row.add_child(black_button)
            host._move_grid.add_child(row)

func _format_move_compact(move: Dictionary) -> String:
    if move.is_empty():
        return "—"
    return "%s-%s" % [String(move.get("from", "?")), String(move.get("to", "?"))]

func _make_move_button(label: String, state_index: int, move: Dictionary = {}) -> Button:
    var b := Button.new()
    b.text = label
    b.alignment = HORIZONTAL_ALIGNMENT_CENTER
    b.custom_minimum_size = Vector2(62 if state_index == 0 else 88, MOVE_STRIP_HEIGHT)
    b.toggle_mode = true
    b.set_meta("state_index", state_index)
    var normal := StyleBoxFlat.new()
    normal.bg_color = Color("#101D2E")
    normal.set_corner_radius_all(7)
    normal.content_margin_left = 7
    normal.content_margin_right = 7
    normal.content_margin_top = 3
    normal.content_margin_bottom = 3
    var hover := normal.duplicate()
    hover.bg_color = Color("#1A3047")
    var pressed := normal.duplicate()
    pressed.bg_color = Color("#123B50")
    pressed.border_color = Color("#26C6DA")
    pressed.set_border_width_all(1)
    b.add_theme_stylebox_override("normal", normal)
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", pressed)
    b.add_theme_color_override("font_color", MUTED)
    b.add_theme_font_size_override("font_size", 22)
    b.tooltip_text = _format_move_tooltip(move)
    b.pressed.connect(func():
        stop_auto_review()
        set_replay_position(state_index)
    )
    return b

func _format_move_tooltip(move: Dictionary) -> String:
    if move.is_empty():
        return "Posición inicial"
    return "%s → %s" % [String(move.get("from", "?")), String(move.get("to", "?"))]

func _refresh_move_analysis_styles() -> void:
    if not is_instance_valid(_move_list):
        return
    var button_groups: Array = []
    if is_instance_valid(_move_list):
        button_groups.append(_move_list)
    if is_instance_valid(host._move_grid):
        button_groups.append(host._move_grid)
    for group in button_groups:
        for child in group.find_children("*", "Button", true, false):
            var state_index := int(child.get_meta("state_index", -1))
            var classification := ""
            if host._review_mode == "analysis" and state_index > 0 and state_index - 1 < _engine_analysis.size() and _engine_analysis[state_index - 1] is Dictionary:
                classification = str(_engine_analysis[state_index - 1].get("classification", ""))
            var color: Color = MoveClassificationStyle.color_for(classification, MUTED) if host._review_mode == "analysis" else TEXT
            child.add_theme_color_override("font_color", color)
            child.add_theme_color_override("font_hover_color", CLASS_COLORS.get(classification, TEXT) if host._review_mode == "analysis" else TEXT)
            child.add_theme_color_override("font_pressed_color", CLASS_COLORS.get(classification, TEXT) if host._review_mode == "analysis" else TEXT)

func _is_important_index(index: int) -> bool:
    if index <= 0 or index - 1 >= _engine_analysis.size():
        return false
    var review: Variant = _engine_analysis[index - 1]
    if not (review is Dictionary):
        return false
    return MoveClassificationStyle.is_important(str(review.get("classification", "")))

func _refresh_context_coach() -> void:
    if not is_instance_valid(_coach_panel):
        return
    var review: Dictionary = _current_review()
    var classification := str(review.get("classification", ""))
    var has_commentary := not review.is_empty() and not str(review.get("coach_text", "")).is_empty()
    _coach_panel.visible = host._review_mode == "analysis" and has_commentary
    if not has_commentary:
        return

    var loss := maxf(0.0, float(review.get("loss", 0.0)))
    var title := classification.to_upper() if not classification.is_empty() else "IDEA DEL MOTOR"
    _coach_title.text = "COACH  ·  " + title + "  ·  %.0f cp" % loss
    _coach_title.add_theme_color_override("font_color", MoveClassificationStyle.color_for(classification, GOLD))

    var commentary := str(review.get("coach_text", ""))
    var tactical: Dictionary = review.get("tactical_report", {}) if review.get("tactical_report", {}) is Dictionary else {}
    var notes: Array = tactical.get("notes", []) if tactical.get("notes", []) is Array else []
    # Las notas ya forman parte de coach_text cuando las genera GameReviewService.
    # Si no hay texto base, se permite mostrar la explicación estructurada.
    if commentary.is_empty() and not notes.is_empty():
        commentary = " ".join(notes)
    _coach_text.text = commentary

    var line: Array = review.get("best_line", []) if review.get("best_line", []) is Array else []
    var best_move := str(review.get("best_move", ""))
    if best_move.is_empty() and not line.is_empty():
        best_move = String(line[0])
    var readable_line: Array[String] = []
    for i in range(mini(5, line.size())):
        var uci := String(line[i])
        if _is_uci_move(uci):
            readable_line.append(uci.substr(0, 2) + "→" + uci.substr(2, 2))
    _coach_line.text = "Variante: " + (" · ".join(readable_line) if not readable_line.is_empty() else "sin variante disponible")
    _best_move_button.visible = _is_uci_move(best_move)
    _best_move_button.disabled = not _is_uci_move(best_move)
    _best_move_button.text = "OCULTAR" if host._show_best_move else "VER MEJOR"

func toggle_best_move() -> void:
    var review := _current_review()
    var best_move := str(review.get("best_move", ""))
    if best_move.is_empty():
        var line: Array = review.get("best_line", []) if review.get("best_line", []) is Array else []
        if not line.is_empty():
            best_move = String(line[0])
    if not _is_uci_move(best_move):
        return
    host._show_best_move = not host._show_best_move
    if host._show_best_move:
        # La mejor jugada se calcula desde la posición ANTERIOR a la jugada
        # revisada; mostrar el tablero posterior produciría un resaltado engañoso.
        if _index > 0 and _index - 1 < _states.size():
            _board.set_state(_states[_index - 1])
        _board.set_highlight(best_move.substr(0, 2), best_move.substr(2, 2), "Mejor jugada")
    else:
        if _index >= 0 and _index < _states.size():
            _board.set_state(_states[_index])
        _refresh_board_highlight()
    _best_move_button.text = "OCULTAR" if host._show_best_move else "VER MEJOR"

func _current_review() -> Dictionary:
    if _index > 0 and _index - 1 < _engine_analysis.size() and _engine_analysis[_index - 1] is Dictionary:
        return _engine_analysis[_index - 1]
    return {}

func _is_uci_move(value: String) -> bool:
    if value.length() < 4 or value.length() > 5:
        return false
    return value.substr(0, 1) >= "a" and value.substr(0, 1) <= "h" and value.substr(1, 1) >= "1" and value.substr(1, 1) <= "8" and value.substr(2, 1) >= "a" and value.substr(2, 1) <= "h" and value.substr(3, 1) >= "1" and value.substr(3, 1) <= "8"

func _refresh_board_highlight() -> void:
    if not is_instance_valid(_board):
        return
    var review: Dictionary = {}
    if _index > 0 and _index - 1 < _engine_analysis.size() and _engine_analysis[_index - 1] is Dictionary:
        review = _engine_analysis[_index - 1]
    if host._show_best_move:
        var best_move := str(review.get("best_move", ""))
        if _is_uci_move(best_move):
            _board.set_highlight(best_move.substr(0, 2), best_move.substr(2, 2), "Mejor jugada")
            return
    if host._review_mode == "analysis":
        _board.set_highlight(String(review.get("highlight_from", "")), String(review.get("highlight_to", "")), String(review.get("classification", "")))
    else:
        _board.set_highlight("", "", "")

func _refresh_move_selection() -> void:
    var groups: Array = []
    if is_instance_valid(_move_list):
        groups.append(_move_list)
    if is_instance_valid(host._move_grid):
        groups.append(host._move_grid)
    for group in groups:
        for child in group.find_children("*", "Button", true, false):
            var state_index := int(child.get_meta("state_index", -1))
            child.button_pressed = state_index == _index
            child.modulate = Color(1.08, 0.94, 0.68, 1.0) if state_index == _index else Color(1, 1, 1, 1)
    if host._review_mode == "analysis":
        call_deferred("_ensure_selected_move_visible")

func _ensure_selected_move_visible() -> void:
    if not is_instance_valid(_move_scroll) or not is_instance_valid(_move_list):
        return
    for child in _move_list.get_children():
        if child is Button and int(child.get_meta("state_index", -1)) == _index:
            _move_scroll.ensure_control_visible(child)
            return
