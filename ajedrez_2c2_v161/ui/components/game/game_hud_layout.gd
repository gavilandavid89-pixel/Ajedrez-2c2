extends RefCounted
class_name GameHudLayout

const LayoutMetrics = preload("res://core/layout/layout_metrics.gd")

const MODE_2C2 := 0
const MODE_VS_BOT := 2

var host: Control

var game: Variant:
    get: return host.game
    set(value): host.game = value

var mode_label: Variant:
    get: return host.mode_label
    set(value): host.mode_label = value

var turn_label: Variant:
    get: return host.turn_label
    set(value): host.turn_label = value

var status_label: Variant:
    get: return host.status_label
    set(value): host.status_label = value

var selected_label: Variant:
    get: return host.selected_label
    set(value): host.selected_label = value

var moves_label: Variant:
    get: return host.moves_label
    set(value): host.moves_label = value

var online_status_label: Variant:
    get: return host.online_status_label
    set(value): host.online_status_label = value

var time_control_label: Variant:
    get: return host.time_control_label
    set(value): host.time_control_label = value

var compact_back: Variant:
    get: return host.compact_back
    set(value): host.compact_back = value

var compact_reset: Variant:
    get: return host.compact_reset
    set(value): host.compact_reset = value

var game_menu_button: Variant:
    get: return host.game_menu_button
    set(value): host.game_menu_button = value

var game_action_menu: Variant:
    get: return host.game_action_menu
    set(value): host.game_action_menu = value

var black_info: Variant:
    get: return host.black_info
    set(value): host.black_info = value

var white_info: Variant:
    get: return host.white_info
    set(value): host.white_info = value

var black_players: Variant:
    get: return host.black_players
    set(value): host.black_players = value

var white_players: Variant:
    get: return host.white_players
    set(value): host.white_players = value

var black_title: Variant:
    get: return host.black_title
    set(value): host.black_title = value

var white_title: Variant:
    get: return host.white_title
    set(value): host.white_title = value

var black_team_clock: Variant:
    get: return host.black_team_clock
    set(value): host.black_team_clock = value

var white_team_clock: Variant:
    get: return host.white_team_clock
    set(value): host.white_team_clock = value

var action_row: Variant:
    get: return host.action_row
    set(value): host.action_row = value

var result_panel: Variant:
    get: return host.result_panel
    set(value): host.result_panel = value

var result_label: Variant:
    get: return host.result_label
    set(value): host.result_label = value

var result_entry: Variant:
    get: return host.result_entry
    set(value): host.result_entry = value

var result_screen: Variant:
    get: return host.result_screen
    set(value): host.result_screen = value

var mini_panel: Variant:
    get: return host.mini_panel
    set(value): host.mini_panel = value

var mini_title: Variant:
    get: return host.mini_title
    set(value): host.mini_title = value

var mini_body: Variant:
    get: return host.mini_body
    set(value): host.mini_body = value

var mini_cooldown: Variant:
    get: return host.mini_cooldown
    set(value): host.mini_cooldown = value

var mini_actions: Variant:
    get: return host.mini_actions
    set(value): host.mini_actions = value

var chat_panel: Variant:
    get: return host.chat_panel
    set(value): host.chat_panel = value

var chat_messages: Variant:
    get: return host.chat_messages
    set(value): host.chat_messages = value

var chat_input: Variant:
    get: return host.chat_input
    set(value): host.chat_input = value

var history_panel: Variant:
    get: return host.history_panel
    set(value): host.history_panel = value

var history_lines: Variant:
    get: return host.history_lines
    set(value): host.history_lines = value

var black_signature: Variant:
    get: return host.black_signature
    set(value): host.black_signature = value

var white_signature: Variant:
    get: return host.white_signature
    set(value): host.white_signature = value

var emote_picker: Variant:
    get: return host.emote_picker
    set(value): host.emote_picker = value

var emote_serial_seen: Variant:
    get: return host.emote_serial_seen
    set(value): host.emote_serial_seen = value

var cards_by_slot: Variant:
    get: return host.cards_by_slot
    set(value): host.cards_by_slot = value

var _connected_viewport: Variant:
    get: return host._connected_viewport
    set(value): host._connected_viewport = value

var _connected_game: Variant:
    get: return host._connected_game
    set(value): host._connected_game = value

var chat_component: Variant:
    get: return host.chat_component
    set(value): host.chat_component = value

var overlay_controller: Variant:
    get: return host.overlay_controller
    set(value): host.overlay_controller = value

var _last_layout_viewport: Variant:
    get: return host._last_layout_viewport
    set(value): host._last_layout_viewport = value

var _layout_dirty: Variant:
    get: return host._layout_dirty
    set(value): host._layout_dirty = value

var _layout_queued: Variant:
    get: return host._layout_queued
    set(value): host._layout_queued = value

var _dynamic_refresh_accumulator: Variant:
    get: return host._dynamic_refresh_accumulator
    set(value): host._dynamic_refresh_accumulator = value

var _mobile_scale: Variant:
    get: return host._mobile_scale
    set(value): host._mobile_scale = value

var _result_transition_started: Variant:
    get: return host._result_transition_started
    set(value): host._result_transition_started = value

var _mini_dragging: Variant:
    get: return host._mini_dragging
    set(value): host._mini_dragging = value

var _mini_drag_offset: Variant:
    get: return host._mini_drag_offset
    set(value): host._mini_drag_offset = value

func _init(p_host: Control) -> void:
    host = p_host

func is_inside_tree() -> bool:
    return host.is_inside_tree()

func get_viewport_rect() -> Rect2:
    return host.get_viewport_rect()

func get_node(path: NodePath):
    return host.get_node(path)

func _move_suggestion_panel(target: Vector2) -> void:
    host._move_suggestion_panel(target)

func _mobile_ui_scale() -> float:
    if not is_inside_tree():
        return 1.0
    var viewport_size := get_viewport_rect().size
    var short_side := minf(float(viewport_size.x), float(viewport_size.y))
    if short_side <= 0.0:
        return 1.0
    return clampf(820.0 / short_side, 1.0, 1.55)


func _scaled_font(base_size: float, cap: float = 22.0) -> int:
    return int(round(clampf(base_size * _mobile_scale * 1.12, base_size + 1.0, cap)))


func _set_local_rect(control: Control, rect: Rect2) -> void:
    control.anchor_left = 0.0
    control.anchor_top = 0.0
    control.anchor_right = 0.0
    control.anchor_bottom = 0.0
    control.position = rect.position
    control.size = rect.size


func _place(control: Control, rect: Rect2) -> void:
    _set_local_rect(control, rect)


func _style_team_clock(clock_label: Label, active: bool, accent: Color) -> void:
    var style := StyleBoxFlat.new()
    style.set_corner_radius_all(9)
    style.content_margin_left = 7.0
    style.content_margin_right = 7.0
    style.content_margin_top = 4.0
    style.content_margin_bottom = 4.0
    if active:
        style.bg_color = Color(accent.r * 0.22, accent.g * 0.18, accent.b * 0.13, 0.92)
        style.border_color = accent
        style.set_border_width_all(2)
        clock_label.modulate = Color("#FFF1D0")
    else:
        style.bg_color = Color(0.0, 0.0, 0.0, 0.10)
        style.border_color = Color("#3B342A")
        style.set_border_width_all(1)
        clock_label.modulate = Color("#C8BAA2")
    clock_label.add_theme_stylebox_override("normal", style)


func _set_team_panel_layout(panel: Panel, title_label: Label, clock_label: Label, players: GridContainer, rect: Rect2, columns: int, align_right: bool = false) -> void:
    _place(panel, rect)
    # El jugador no vive dentro de una tarjeta/barra: solo avatar + nombre.
    panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    # En la partida el nombre del equipo ya se entiende por color/posición.
    # Reservamos ese espacio para las fichas y el reloj independiente.
    title_label.visible = false
    var clock_w: float = 92.0 if rect.size.x >= 290.0 else 84.0
    var clock_h: float = minf(48.0, maxf(40.0, rect.size.y - 6.0))
    var portrait_layout := LayoutMetrics.is_portrait(get_viewport_rect().size)
    players.columns = columns
    if not portrait_layout:
        # Landscape has little side-rail width. Stack a full-width clock above
        # horizontal player cards instead of squeezing avatar, name and clock
        # into one narrow row (the previous layout clipped names and avatars).
        var landscape_players_rect := Rect2(Vector2(5.0, 48.0), Vector2(maxf(0.0, rect.size.x - 10.0), maxf(0.0, rect.size.y - 52.0)))
        _set_local_rect(players, landscape_players_rect)
        _set_local_rect(clock_label, Rect2(Vector2(5.0, 3.0), Vector2(maxf(0.0, rect.size.x - 10.0), 40.0)))
        clock_label.add_theme_font_size_override("font_size", _scaled_font(21.0, 26.0))
        players.columns = 1
        var child_count := maxi(1, players.get_child_count())
        var card_height := maxf(58.0, (landscape_players_rect.size.y - float(maxi(0, child_count - 1)) * 3.0) / float(child_count))
        for child in players.get_children():
            if child is Panel and child.has_method("update_state"):
                child.custom_minimum_size = Vector2(landscape_players_rect.size.x, card_height)
        return

    var players_width: float = maxf(0.0, rect.size.x - clock_w - 20.0)
    var players_x: float = 5.0 if not align_right else clock_w + 10.0
    # Portrait top team: keep the first avatar clear of the floating back
    # button. The wider team rail gives two 92px player cards enough room,
    # while the clock remains attached to the same visual group at the edge.
    if not align_right:
        players_x = 40.0
        players_width = maxf(0.0, rect.size.x - clock_w - 56.0)
    var clock_x: float = maxf(0.0, rect.size.x - clock_w - 5.0) if not align_right else 5.0
    var players_rect := Rect2(Vector2(players_x, 2.0), Vector2(players_width, maxf(0.0, rect.size.y - 4.0)))
    _set_local_rect(players, players_rect)
    _set_local_rect(clock_label, Rect2(Vector2(clock_x, (rect.size.y - clock_h) * 0.5), Vector2(clock_w, clock_h)))
    clock_label.add_theme_font_size_override("font_size", _scaled_font(21.0, 26.0))
    var card_height: float = clampf(players_rect.size.y, 60.0, 72.0)
    for child in players.get_children():
        if child is Panel and child.has_method("update_state"):
            child.custom_minimum_size = Vector2(0.0, card_height)


func _default_button_width(full_text: String) -> float:
    match full_text:
        "Sugerir":
            return 84.0
        "Cambiar":
            return 80.0
        "Rendirse":
            return 86.0
        "Tablas":
            return 72.0
    return 64.0


func _visible_button_width(button: Button) -> float:
    return max(button.custom_minimum_size.x, 52.0)


func _layout_bottom_controls(compact: bool) -> void:
    var bottom: Control = get_node("Bottom")
    var width := bottom.size.x
    var gap := 6.0
    var utility_buttons: Array[Button] = [get_node("Bottom/Emotes"), get_node("Bottom/Chat"), get_node("Bottom/GameMenu")]
    var visible_utils: Array[Button] = []
    for button in utility_buttons:
        if button.visible:
            visible_utils.append(button)

    var action_buttons: Array[Button] = []
    for child in action_row.get_children():
        if child is Button and child.visible:
            action_buttons.append(child)
            if not child.has_meta("_full_text"):
                child.set_meta("_full_text", child.text)

    var is_narrow := width < 370.0
    # Game controls use one compact row: 2c2 keeps cooperative actions at left;
    # both modes reserve the right side for reaction, chat and the two-action menu.
    var action_w := 0.0
    if not action_buttons.is_empty():
        var total_gap := gap * float(max(0, action_buttons.size() - 1))
        action_w = minf(width * 0.52, maxf(0.0, (width - total_gap - 152.0) * 0.58))
        action_w = maxf(0.0, action_w)

    var utility_total := gap * float(max(0, visible_utils.size() - 1))
    var utility_w_each := 0.0
    if not visible_utils.is_empty():
        utility_w_each = clampf((minf(178.0, width * 0.50) - utility_total) / float(visible_utils.size()), 38.0, 62.0)

    var height := 64.0
    bottom.size.y = height
    _set_local_rect(action_row, Rect2(Vector2(6.0, 6.0), Vector2(maxf(0.0, width - 12.0), 48.0)))

    if action_buttons.is_empty():
        action_row.visible = false
    else:
        action_row.visible = true
        var x := 0.0
        var gaps_count := float(max(0, action_buttons.size() - 1))
        var each_action := maxf(52.0, (maxf(100.0, width - 12.0 - utility_w_each * float(visible_utils.size()) - utility_total - gap) - gap * gaps_count) / float(action_buttons.size()))
        each_action = minf(each_action, 92.0)
        for b in action_buttons:
            b.custom_minimum_size = Vector2(each_action, 48.0)
            if is_narrow:
                b.text = String({"Suggest": "Sug.", "Swap": "Cambio"}.get(b.name, b.get_meta("_full_text", b.text)))
            else:
                b.text = String(b.get_meta("_full_text", b.text))
            b.add_theme_font_size_override("font_size", _scaled_font(15.0, 21.0))
            _set_local_rect(b, Rect2(Vector2(x, 0.0), Vector2(each_action, 48.0)))
            x += each_action + gap

    var utility_group_width := utility_w_each * float(visible_utils.size()) + utility_total
    var cursor := (width - utility_group_width) * 0.5 if action_buttons.is_empty() else width - 6.0
    for button in visible_utils:
        var bw := utility_w_each
        if not action_buttons.is_empty():
            cursor -= bw
        var label: String = String(button.get_meta("_full_text", button.text))
        match button.name:
            "Emotes":
                label = "🙂"
            "Chat":
                label = "💬"
            "GameMenu":
                label = "⋮"
        button.text = String(label)
        button.custom_minimum_size = Vector2(bw, 48.0)
        button.add_theme_font_size_override("font_size", _scaled_font(17.0, 22.0))
        _set_local_rect(button, Rect2(Vector2(cursor, 8.0), Vector2(bw, 48.0)))
        cursor += bw + gap if action_buttons.is_empty() else -gap


func _layout_landscape_side_controls(width: float, available_height: float) -> void:
    var bottom: Control = get_node("Bottom")
    var gap := 5.0
    var margin := 5.0
    var action_buttons: Array[Button] = []
    for child in action_row.get_children():
        if child is Button and child.visible:
            action_buttons.append(child)
            if not child.has_meta("_full_text"):
                child.set_meta("_full_text", child.text)
    var utility_buttons: Array[Button] = []
    for path in ["Bottom/Emotes", "Bottom/Chat", "Bottom/GameMenu"]:
        var b := get_node(path) as Button
        if b != null and b.visible:
            utility_buttons.append(b)

    var action_h := 48.0
    _set_local_rect(action_row, Rect2(Vector2(margin, 5.0), Vector2(maxf(0.0, width - margin * 2.0), action_h)))
    action_row.visible = not action_buttons.is_empty()
    if not action_buttons.is_empty():
        var each_action: float = maxf(52.0, (width - margin * 2.0 - gap * float(action_buttons.size() - 1)) / float(action_buttons.size()))
        each_action = minf(each_action, 104.0)
        for i in range(action_buttons.size()):
            var b := action_buttons[i]
            var full_text := String(b.get_meta("_full_text", b.text))
            b.text = String({"Suggest": "Sugerir", "Swap": "Cambiar", "Resign": "Rendirse", "Draw": "Tablas"}.get(b.name, full_text))
            b.custom_minimum_size = Vector2(each_action, action_h)
            b.add_theme_font_size_override("font_size", int(round(clampf(width * 0.072, 12.0, 17.0))))
            _set_local_rect(b, Rect2(Vector2(float(i) * (each_action + gap), 0.0), Vector2(each_action, action_h)))

    var utility_y := 59.0 if not action_buttons.is_empty() else 7.0
    var utility_h := 42.0
    var utility_gap := 4.0
    if not utility_buttons.is_empty():
        var each_utility: float = maxf(40.0, (width - margin * 2.0 - utility_gap * float(utility_buttons.size() - 1)) / float(utility_buttons.size()))
        each_utility = minf(each_utility, 66.0)
        var labels := {"Emotes": "🙂", "Chat": "💬", "GameMenu": "⋮"}
        for i in range(utility_buttons.size()):
            var b := utility_buttons[i]
            b.text = String(labels.get(b.name, b.text))
            b.custom_minimum_size = Vector2(each_utility, utility_h)
            b.add_theme_font_size_override("font_size", 19)
            _set_local_rect(b, Rect2(Vector2(margin + float(i) * (each_utility + utility_gap), utility_y), Vector2(each_utility, utility_h)))
    bottom.size.y = minf(maxf(104.0, utility_y + utility_h + 6.0), maxf(104.0, available_height))


func _resize_for_viewport() -> void:
    if not is_inside_tree():
        return
    _mobile_scale = _mobile_ui_scale()
    var vp: Vector2 = get_viewport_rect().size
    var portrait: bool = LayoutMetrics.is_portrait(vp)
    var result_overlay_visible: bool = host.get_node_or_null("MatchResultScreen") != null and host.get_node("MatchResultScreen").visible
    var result_mode: bool = (game != null and not game.running) or result_overlay_visible
    var board_rect: Rect2 = LayoutMetrics.board_rect(vp, result_mode)
    var board_bottom: float = board_rect.end.y
    var is_2c2: bool = game != null and game.mode == MODE_2C2
    var reset_allowed: bool = game != null and (game.mode == host.MODE_1C1_LOCAL or game.mode == host.MODE_VS_BOT)
    var compact_portrait: bool = portrait and LayoutMetrics.is_compact_portrait(vp)
    var suggestion_popup: bool = mini_panel.visible and mini_panel.get_meta("suggestion_mode", false)

    # En partida no existe una barra superior de modo/online/tiempo total.
    # Menú y reinicio sobreviven como botones flotantes discretos.
    get_node("Top").visible = false
    compact_back.visible = not result_mode
    compact_reset.visible = not result_mode and reset_allowed
    if not result_mode:
        var utility_size := 38.0 if compact_portrait else 40.0
        _set_local_rect(compact_back, Rect2(Vector2(6.0, 6.0), Vector2(utility_size, utility_size)))
        _set_local_rect(compact_reset, Rect2(Vector2(vp.x - utility_size - 6.0, 6.0), Vector2(utility_size, utility_size)))
        compact_back.text = "‹"
        compact_reset.text = "↻"
        compact_back.add_theme_font_size_override("font_size", _scaled_font(20.0, 24.0))
        compact_reset.add_theme_font_size_override("font_size", _scaled_font(18.0, 23.0))
    else:
        compact_back.visible = false
        compact_reset.visible = false

    # Los textos de turno/estado dejan de competir con el tablero. El reloj
    # activo es ahora el único indicador persistente del turno.
    turn_label.visible = false
    status_label.visible = false
    selected_label.visible = false

    if portrait:
        var team_height: float = LayoutMetrics.portrait_team_header_height(vp)
        # Fichas y reloj se acercan a esquinas opuestas del móvil; el tablero
        # conserva su espacio central y no absorbe los márgenes del HUD.
        var side_pad := 8.0
        var panel_width := minf(maxf(0.0, vp.x - side_pad * 2.0), 344.0)
        var local_is_black: bool = game != null and game.local_team() == game.TEAM_BLACK
        var top_team_y: float = 4.0 if result_mode else LayoutMetrics.portrait_team_top(vp)
        var top_team := Rect2(Vector2(side_pad, top_team_y), Vector2(panel_width, team_height))
        if local_is_black:
            _set_team_panel_layout(white_info, white_title, white_team_clock, white_players, top_team, 2 if is_2c2 else 1)
        else:
            _set_team_panel_layout(black_info, black_title, black_team_clock, black_players, top_team, 2 if is_2c2 else 1)

        # El tablero queda centrado en horizontal y la holgura vertical se reparte
        # entre el bloque superior y los controles inferiores para evitar una zona
        # vacía excesiva debajo en teléfonos altos.
        board_rect = LayoutMetrics.board_rect(vp, result_mode)

        # Movimientos: una sola línea compacta bajo el tablero. Cuando llega
        # una sugerencia, el popup ocupa primero ese espacio sobrante y el resto
        # del HUD se desplaza hacia abajo sin tocar el tablero.
        var suggestion_h: float = 50.0 if suggestion_popup else 0.0
        var moves_h: float = 16.0 if compact_portrait else 18.0
        var moves_y: float = board_bottom + LayoutMetrics.PORTRAIT_MOVE_STATUS_GAP + suggestion_h + (2.0 if suggestion_popup else 0.0)
        _set_local_rect(moves_label, Rect2(Vector2(8.0, moves_y), Vector2(maxf(0.0, vp.x - 16.0), moves_h)))
        moves_label.visible = true
        moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        moves_label.clip_text = true
        moves_label.add_theme_font_size_override("font_size", _scaled_font(15.0, 20.0))

        var bottom_team_y: float = moves_y + moves_h + LayoutMetrics.PORTRAIT_PLAYER_BLOCK_GAP
        var bottom_team_extra: float = 18.0 if vp.y > 900.0 else 8.0
        var bottom_team := Rect2(Vector2(maxf(side_pad, vp.x - panel_width - side_pad), bottom_team_y), Vector2(panel_width, team_height + bottom_team_extra))
        if local_is_black:
            _set_team_panel_layout(black_info, black_title, black_team_clock, black_players, bottom_team, 2 if is_2c2 else 1, true)
        else:
            _set_team_panel_layout(white_info, white_title, white_team_clock, white_players, bottom_team, 2 if is_2c2 else 1, true)

        var bottom_y := bottom_team.end.y + LayoutMetrics.PORTRAIT_ACTIONS_GAP
        var bottom_height := LayoutMetrics.BOTTOM_HEIGHT_COMPACT
        _place(get_node("Bottom"), Rect2(Vector2(8.0, bottom_y), Vector2(maxf(0.0, vp.x - 16.0), bottom_height)))
        get_node("Bottom").visible = not result_mode
        _layout_bottom_controls(true)
    else:
        # En horizontal el ancho suele sobrar: el tablero usa el máximo cuadrado
        # que permite la altura, mientras las fichas ocupan los laterales.
        var side_height: float = LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_2C2 if is_2c2 else LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_1C1
        var local_is_black: bool = game != null and game.local_team() == game.TEAM_BLACK
        var left_side: Rect2 = LayoutMetrics.landscape_side_rect(vp, false, side_height)
        var right_side: Rect2 = LayoutMetrics.landscape_side_rect(vp, true, side_height)
        left_side.position.y = 48.0
        right_side.position.y = 48.0
        left_side.size.y = maxf(0.0, minf(side_height, vp.y - 48.0 - 8.0))
        right_side.size.y = left_side.size.y
        if local_is_black:
            _set_team_panel_layout(white_info, white_title, white_team_clock, white_players, left_side, 1)
            _set_team_panel_layout(black_info, black_title, black_team_clock, black_players, right_side, 1)
        else:
            _set_team_panel_layout(black_info, black_title, black_team_clock, black_players, left_side, 1)
            _set_team_panel_layout(white_info, white_title, white_team_clock, white_players, right_side, 1)
        # En horizontal, las acciones ocupan el rail izquierdo y el estado de
        # movimientos el rail derecho; el tablero se amplía sin un footer global.
        moves_label.visible = true
        var moves_y: float = right_side.position.y + side_height + 4.0
        _set_local_rect(moves_label, Rect2(Vector2(right_side.position.x, moves_y), Vector2(right_side.size.x, 20.0)))
        moves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
        moves_label.clip_text = true
        moves_label.add_theme_font_size_override("font_size", _scaled_font(13.0, 16.0))
        var bottom_y: float = left_side.position.y + side_height + 8.0
        var bottom_h: float = maxf(104.0, vp.y - bottom_y - 8.0)
        var side_controls := Rect2(Vector2(left_side.position.x, bottom_y), Vector2(left_side.size.x, bottom_h))
        _place(get_node("Bottom"), side_controls)
        get_node("Bottom").visible = not result_mode
        _layout_landscape_side_controls(side_controls.size.x, side_controls.size.y)

    # Los elementos de partida que ya no tienen utilidad visual permanente.
    mode_label.visible = false
    online_status_label.visible = false
    time_control_label.visible = false

    # Paneles contextuales: las sugerencias recibidas son compactas y usan el
    # espacio sobrante fuera del tablero; en horizontal comparten la columna
    # lateral con el chat sin superponerse al tablero.
    var mobile_overlay: bool = _mobile_scale > 1.30
    var is_suggestion_popup: bool = bool(mini_panel.get_meta("suggestion_mode", false))
    var panel_w: float = minf(316.0, maxf(224.0, vp.x - 24.0))
    var mini_h := 158.0
    if is_suggestion_popup:
        mini_h = 50.0
        panel_w = minf(308.0, maxf(252.0, vp.x - 16.0))
        mini_title.add_theme_font_size_override("font_size", 17)
        mini_body.add_theme_font_size_override("font_size", 17)
        mini_cooldown.visible = false
    elif mobile_overlay:
        panel_w = minf(316.0, maxf(224.0, vp.x - 24.0))
        mini_h = 176.0
        mini_title.add_theme_font_size_override("font_size", _scaled_font(14.0, 20.0))
        mini_body.add_theme_font_size_override("font_size", _scaled_font(14.0, 20.0))
        mini_cooldown.add_theme_font_size_override("font_size", _scaled_font(12.0, 16.0))
        chat_messages.add_theme_font_size_override("normal_font_size", _scaled_font(11.0, 16.0))
        chat_input.add_theme_font_size_override("font_size", _scaled_font(15.0, 21.0))
        history_lines.add_theme_font_size_override("normal_font_size", _scaled_font(11.0, 16.0))
        get_node("HistoryPanel/Title").add_theme_font_size_override("font_size", _scaled_font(14.0, 20.0))
        for close_name in ["MiniPanel/Close", "ChatPanel/Close", "HistoryPanel/Close"]:
            var close_button: Button = get_node(close_name)
            close_button.custom_minimum_size = Vector2(40.0, 40.0)
            close_button.add_theme_font_size_override("font_size", _scaled_font(14.0, 20.0))
    if portrait:
        var x: float = (vp.x - panel_w) * 0.5 if mobile_overlay else maxf(8.0, vp.x - panel_w - 8.0)
        if is_suggestion_popup:
            # El popup ocupa el espacio sobrante, justo debajo del tablero y
            # antes del jugador inferior: cero píxeles de tablero tapados.
            var suggestion_y: float = board_bottom + LayoutMetrics.PORTRAIT_MOVE_STATUS_GAP
            mini_panel.position = Vector2((vp.x - panel_w) * 0.5, suggestion_y)
            mini_panel.size = Vector2(panel_w, mini_h)
            _set_local_rect(mini_title, Rect2(Vector2(10.0, 8.0), Vector2(mini_panel.size.x * 0.30, 34.0)))
            _set_local_rect(mini_body, Rect2(Vector2(mini_panel.size.x * 0.33, 8.0), Vector2(mini_panel.size.x * 0.21, 34.0)))
            _set_local_rect(mini_actions, Rect2(Vector2(mini_panel.size.x * 0.56, 8.0), Vector2(mini_panel.size.x * 0.40, 34.0)))
            _set_local_rect(get_node("MiniPanel/Close"), Rect2(Vector2(mini_panel.size.x - 44.0, 8.0), Vector2(36.0, 36.0)))
            if mini_panel.get_meta("manual_position", false):
                _move_suggestion_panel(mini_panel.global_position)
        else:
            var y: float = maxf(72.0, board_rect.position.y + 8.0)
            mini_panel.position = Vector2(x, y)
            mini_panel.size = Vector2(panel_w, minf(mini_h, maxf(132.0, vp.y - 84.0)))
            _set_local_rect(mini_title, Rect2(Vector2(12.0, 10.0), Vector2(maxf(120.0, mini_panel.size.x - 60.0), 30.0)))
            _set_local_rect(mini_body, Rect2(Vector2(12.0, 46.0), Vector2(maxf(120.0, mini_panel.size.x - 24.0), 50.0)))
            _set_local_rect(mini_cooldown, Rect2(Vector2(12.0, 98.0), Vector2(maxf(120.0, mini_panel.size.x - 24.0), 22.0)))
            _set_local_rect(mini_actions, Rect2(Vector2(12.0, maxf(120.0, mini_panel.size.y - 52.0)), Vector2(maxf(120.0, mini_panel.size.x - 54.0), 44.0)))
            _set_local_rect(get_node("MiniPanel/Close"), Rect2(Vector2(mini_panel.size.x - 44.0, 8.0), Vector2(36.0, 36.0)))
        # El chat nunca tapa el tablero: se convierte en una hoja inferior.
        if not is_suggestion_popup:
            chat_panel.position = Vector2(x, board_rect.end.y + 4.0)
            chat_panel.size = Vector2(panel_w, minf(238.0 if not mobile_overlay else 270.0, maxf(150.0, vp.y - board_rect.end.y - 8.0)))
            _set_local_rect(chat_messages, Rect2(Vector2(12.0, 46.0), Vector2(maxf(120.0, chat_panel.size.x - 24.0), maxf(70.0, chat_panel.size.y - 96.0))))
            _set_local_rect(chat_input, Rect2(Vector2(12.0, maxf(52.0, chat_panel.size.y - 46.0)), Vector2(maxf(120.0, chat_panel.size.x - 24.0), 34.0)))
        history_panel.position = Vector2(x, board_rect.end.y + 4.0)
        history_panel.size = Vector2(panel_w, minf(238.0 if not mobile_overlay else 270.0, maxf(150.0, vp.y - board_rect.end.y - 8.0)))
    else:
        var right_side: Rect2 = LayoutMetrics.landscape_side_rect(vp, true, LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_2C2 if is_2c2 else LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_1C1)
        var y: float = right_side.end.y + 10.0
        var max_h: float = maxf(0.0, vp.y - y - 10.0)
        var chat_y: float = y
        if is_suggestion_popup:
            mini_panel.position = Vector2(right_side.position.x, y)
            mini_panel.size = Vector2(right_side.size.x, minf(72.0, max_h))
            _set_local_rect(mini_title, Rect2(Vector2(8.0, 5.0), Vector2(maxf(80.0, mini_panel.size.x - 16.0), 22.0)))
            _set_local_rect(mini_body, Rect2(Vector2(8.0, 25.0), Vector2(maxf(80.0, mini_panel.size.x - 16.0), 18.0)))
            _set_local_rect(mini_actions, Rect2(Vector2(6.0, 43.0), Vector2(maxf(100.0, mini_panel.size.x - 12.0), 34.0)))
            mini_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            mini_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
            if mini_panel.get_meta("manual_position", false):
                _move_suggestion_panel(mini_panel.global_position)
            chat_y = y + mini_panel.size.y + 8.0
        else:
            mini_panel.position = Vector2(right_side.position.x, y)
            mini_panel.size = Vector2(right_side.size.x, min(190.0, max_h))
            chat_y = y
            _set_local_rect(mini_title, Rect2(Vector2(12.0, 10.0), Vector2(maxf(80.0, mini_panel.size.x - 60.0), 30.0)))
            _set_local_rect(mini_body, Rect2(Vector2(12.0, 46.0), Vector2(maxf(80.0, mini_panel.size.x - 24.0), 50.0)))
            _set_local_rect(mini_cooldown, Rect2(Vector2(12.0, 98.0), Vector2(maxf(80.0, mini_panel.size.x - 24.0), 22.0)))
            _set_local_rect(mini_actions, Rect2(Vector2(12.0, maxf(120.0, mini_panel.size.y - 52.0)), Vector2(maxf(80.0, mini_panel.size.x - 54.0), 44.0)))
            _set_local_rect(get_node("MiniPanel/Close"), Rect2(Vector2(mini_panel.size.x - 44.0, 8.0), Vector2(36.0, 36.0)))
        # En horizontal el chat vive debajo del jugador, y debajo de la
        # sugerencia si esta se encuentra visible.
        chat_panel.position = Vector2(right_side.position.x, chat_y)
        chat_panel.size = Vector2(right_side.size.x, min(330.0, maxf(0.0, vp.y - chat_y - 10.0)))
        _set_local_rect(chat_messages, Rect2(Vector2(12.0, 46.0), Vector2(maxf(80.0, chat_panel.size.x - 24.0), maxf(60.0, chat_panel.size.y - 96.0))))
        _set_local_rect(chat_input, Rect2(Vector2(12.0, maxf(52.0, chat_panel.size.y - 46.0)), Vector2(maxf(80.0, chat_panel.size.x - 24.0), 34.0)) )
        history_panel.position = Vector2(right_side.position.x, y)
        history_panel.size = Vector2(right_side.size.x, min(290.0, max_h))

    if emote_picker:
        emote_picker.resize_for_viewport(vp, board_rect)
        if game.mode == MODE_VS_BOT:
            emote_picker.visible = false

    # Resultado: modal responsive, especialmente importante en móviles estrechos.
    if host.get_node_or_null("FinishedResultButton") != null:
        var result_btn: Button = host.get_node("FinishedResultButton")
        result_btn.visible = game != null and not game.running and (result_screen == null or not result_screen.visible)
        result_btn.add_theme_font_size_override("font_size", _scaled_font(12.0, 16.0))

    if result_panel.visible:
        var compact_result: bool = portrait and vp.x < 420.0
        var result_w: float
        var result_h: float
        if portrait:
            result_w = maxf(280.0, vp.x - 24.0)
            result_h = minf(174.0, maxf(166.0, vp.y - board_bottom - 10.0))
            result_panel.position = Vector2((vp.x - result_w) * 0.5, board_bottom + 10.0)
        else:
            var right_side: Rect2 = LayoutMetrics.landscape_side_rect(vp, true, LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_2C2 if is_2c2 else LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_1C1)
            result_w = right_side.size.x
            result_h = minf(300.0, maxf(190.0, vp.y - 88.0))
            result_panel.position = Vector2(right_side.position.x, right_side.position.y)
        result_panel.size = Vector2(result_w, result_h)
        result_panel.pivot_offset = result_panel.size * 0.5

        var margin_x: float = 10.0 if compact_result else 14.0
        var buttons_h: float = 40.0
        var button_y: float = result_h - buttons_h - 10.0
        var gap: float = 5.0
        var button_w: float = maxf(0.0, (result_w - margin_x * 2.0 - gap * 2.0) / 3.0)
        _set_local_rect(result_label, Rect2(Vector2(margin_x, 8.0), Vector2(maxf(0.0, result_w - margin_x * 2.0), maxf(90.0, button_y - 14.0))))
        _set_local_rect(get_node("Result/Analyze"), Rect2(Vector2(margin_x, button_y), Vector2(button_w, buttons_h)))
        _set_local_rect(get_node("Result/Rematch"), Rect2(Vector2(margin_x + button_w + gap, button_y), Vector2(button_w, buttons_h)))
        _set_local_rect(get_node("Result/ToMenu"), Rect2(Vector2(margin_x + (button_w + gap) * 2.0, button_y), Vector2(button_w, buttons_h)))
        result_label.add_theme_font_size_override("font_size", 16 if compact_result else 21)
        get_node("Result/Analyze").add_theme_font_size_override("font_size", _scaled_font(12.0, 17.0))
        get_node("Result/Rematch").add_theme_font_size_override("font_size", _scaled_font(12.0, 17.0))
        get_node("Result/ToMenu").add_theme_font_size_override("font_size", _scaled_font(12.0, 17.0))
        get_node("Result/ToMenu").text = "Menú" if compact_result else "Volver al menú"

        # El resultado sustituye los controles, pero no tapa el tablero.
        get_node("Bottom").visible = false
        turn_label.visible = false
        moves_label.visible = false
        status_label.visible = false
        white_info.visible = false
    else:
        get_node("Bottom").visible = true

