extends RefCounted
class_name ReplayViewLayoutService

const ReplayBoardScript = preload("res://domain/replay/replay_board.gd")
const PlayerHeaderScript = preload("res://ui/components/player/player_header.gd")
const LayoutMetrics = preload("res://core/layout/layout_metrics.gd")

var host: Node
var _built := false

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

func build() -> void:
    if _built or host == null:
        return
    _built = true
    host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host.size_flags_vertical = Control.SIZE_EXPAND_FILL
    host.custom_minimum_size.x = 0.0

    # Fondo de tema explícito: la vista puede vivir fuera del contenedor que
    # aplica el tema general, así que nunca debe transparentar el gris del SO.
    var background := ColorRect.new()
    background.name = "ReplayThemeBackground"
    background.color = Color("#07111F")
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    background.size_flags_vertical = Control.SIZE_EXPAND_FILL
    host.add_child(background)
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

    var root := VBoxContainer.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.name = "ReplayLayout"
    root.add_theme_constant_override("separation", 0)
    root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    root.size_flags_vertical = Control.SIZE_EXPAND_FILL
    host.add_child(root)

    # Replay y análisis son experiencias distintas. El acceso al análisis es explícito
    # y no activa el motor por sí solo.
    var mode_bar := HBoxContainer.new()
    mode_bar.name = "ReplayActions"
    mode_bar.alignment = BoxContainer.ALIGNMENT_BEGIN
    mode_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    mode_bar.add_theme_constant_override("separation", 8)
    root.add_child(mode_bar)
    host._result_label = Label.new()
    host._result_label.name = "MatchResultLabel"
    host._result_label.text = "REPLAY"
    host._result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    host._result_label.add_theme_color_override("font_color", host.GOLD)
    host._result_label.add_theme_font_size_override("font_size", 14)
    mode_bar.add_child(host._result_label)
    host._analysis_entry_button = Button.new()
    host._analysis_entry_button.name = "AnalyzeGameButton"
    host._analysis_entry_button.text = "✦  Analizar partida"
    host._analysis_entry_button.tooltip_text = "Abrir el análisis de esta partida; el replay seguirá limpio"
    host._analysis_entry_button.custom_minimum_size = Vector2(0, 42)
    host._analysis_entry_button.pressed.connect(host.request_analysis)
    var analysis_style := StyleBoxFlat.new()
    analysis_style.bg_color = Color("#332815")
    analysis_style.border_color = host.GOLD
    analysis_style.set_border_width_all(1)
    analysis_style.set_corner_radius_all(11)
    analysis_style.content_margin_left = 12
    analysis_style.content_margin_right = 12
    host._analysis_entry_button.add_theme_stylebox_override("normal", analysis_style)
    var analysis_hover := analysis_style.duplicate()
    analysis_hover.bg_color = Color("#463619")
    host._analysis_entry_button.add_theme_stylebox_override("hover", analysis_hover)
    mode_bar.add_child(host._analysis_entry_button)

    # La identidad de los jugadores pertenece al contexto de la partida y se conserva en replay.
    host._black_player_header = PlayerHeaderScript.new()
    host._black_player_header.name = "BlackPlayerHeader"
    host._black_player_header.player_color = "black"
    root.add_child(host._black_player_header)

    # El tablero es el protagonista. La navegación va debajo, como en una app
    # de ajedrez: primero ves la posición, luego controlas el movimiento.
    host._workspace = Control.new()
    host._workspace.name = "BoardArea"
    host._workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
    host._workspace.clip_contents = false
    root.add_child(host._workspace)

    host._board = ReplayBoardScript.new()
    host._board.name = "ReplayBoard"
    host._board.attach_owner(host)
    host._board.custom_minimum_size = Vector2(280, 280)
    host._board.mouse_filter = Control.MOUSE_FILTER_IGNORE
    host._workspace.add_child(host._board)

    host._white_player_header = PlayerHeaderScript.new()
    host._white_player_header.name = "WhitePlayerHeader"
    host._white_player_header.player_color = "white"
    root.add_child(host._white_player_header)

    var navigation := HBoxContainer.new()
    navigation.name = "MoveNavigation"
    navigation.alignment = BoxContainer.ALIGNMENT_CENTER
    navigation.add_theme_constant_override("separation", 7)
    navigation.custom_minimum_size.y = host.NAV_HEIGHT
    root.add_child(navigation)

    host._previous_button = make_nav_button("◂", "Jugada anterior")
    host._previous_button.pressed.connect(func():
        host.stop_auto_review()
        host.set_replay_position(host._index - 1)
    )
    navigation.add_child(host._previous_button)

    host._auto_button = make_auto_button()
    host._auto_button.pressed.connect(host.toggle_auto_review)
    navigation.add_child(host._auto_button)

    host._next_button = make_nav_button("▸", "Siguiente jugada")
    host._next_button.pressed.connect(func():
        host.stop_auto_review()
        host.set_replay_position(host._index + 1)
    )
    navigation.add_child(host._next_button)

    host._move_label = Label.new()
    host._move_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    host._move_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    host._move_label.custom_minimum_size = Vector2(124, 44)
    host._move_label.add_theme_color_override("font_color", host.TEXT)
    host._move_label.add_theme_font_size_override("font_size", 22)
    navigation.add_child(host._move_label)
    navigation.move_child(host._move_label, 2)

    # La planilla queda debajo del tablero. Sin panel ni marco: solo jugadas.
    host._move_scroll = ScrollContainer.new()
    host._move_scroll.name = "MoveStripScroll"
    host._move_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    host._move_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    host._move_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._move_scroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    host._move_scroll.custom_minimum_size.y = host.MOVE_STRIP_HEIGHT
    root.add_child(host._move_scroll)

    host._move_list = HBoxContainer.new()
    host._move_list.alignment = BoxContainer.ALIGNMENT_CENTER
    host._move_list.add_theme_constant_override("separation", 6)
    host._move_list.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    host._move_scroll.add_child(host._move_list)

    # En replay, la planilla tradicional muestra cada número con blancas y
    # negras en columnas. El análisis conserva la barra compacta y desplazable.
    host._move_grid_scroll = ScrollContainer.new()
    host._move_grid_scroll.name = "ReplayMoveSheetScroll"
    host._move_grid_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    host._move_grid_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    host._move_grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._move_grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    host._move_grid_scroll.custom_minimum_size = Vector2(0, 112)
    host._move_grid_scroll.visible = true
    root.add_child(host._move_grid_scroll)
    host._move_grid = VBoxContainer.new()
    host._move_grid.name = "ReplayMoveSheet"
    host._move_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._move_grid.add_theme_constant_override("separation", 2)
    host._move_grid_scroll.add_child(host._move_grid)

    host._position_label = Label.new()
    host._position_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    host._position_label.add_theme_color_override("font_color", host.MUTED)
    host._position_label.add_theme_font_size_override("font_size", 19)
    host._position_label.custom_minimum_size.y = 22
    root.add_child(host._position_label)

    # Coach: burbuja contextual, no tarjeta de estadísticas.
    host._coach_panel = PanelContainer.new()
    host._coach_panel.name = "CoachBubble"
    host._coach_panel.visible = false
    host._coach_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._coach_panel.custom_minimum_size = Vector2(0, host.COACH_HEIGHT)
    var coach_style := StyleBoxFlat.new()
    coach_style.bg_color = Color("#1D211A")
    coach_style.border_color = Color("#4A4034")
    coach_style.set_border_width_all(1)
    coach_style.border_color = Color("#6F5930")
    coach_style.border_width_left = 4
    coach_style.set_corner_radius_all(16)
    coach_style.content_margin_left = 14.0
    coach_style.content_margin_right = 14.0
    coach_style.content_margin_top = 8.0
    coach_style.content_margin_bottom = 8.0
    host._coach_panel.add_theme_stylebox_override("panel", coach_style)
    host._workspace.add_child(host._coach_panel)

    var coach_box := VBoxContainer.new()
    coach_box.add_theme_constant_override("separation", 2)
    host._coach_panel.add_child(coach_box)
    host._coach_title = Label.new()
    host._coach_title.add_theme_font_size_override("font_size", 23)
    host._coach_title.add_theme_color_override("font_color", Color("#E6C77B"))
    host._coach_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    host._coach_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    coach_box.add_child(host._coach_title)
    host._coach_text = Label.new()
    host._coach_text.add_theme_font_size_override("font_size", 19)
    host._coach_text.add_theme_color_override("font_color", Color("#F0E9DA"))
    host._coach_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    host._coach_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    host._coach_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    host._coach_text.max_lines_visible = 3
    coach_box.add_child(host._coach_text)

    var coach_footer := HBoxContainer.new()
    coach_footer.add_theme_constant_override("separation", 8)
    coach_box.add_child(coach_footer)
    host._coach_line = Label.new()
    host._coach_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    host._coach_line.add_theme_color_override("font_color", Color("#D5C7A7"))
    host._coach_line.add_theme_font_size_override("font_size", 14)
    host._coach_line.text = "Variante del motor"
    host._coach_line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    coach_footer.add_child(host._coach_line)

    host._best_move_button = Button.new()
    host._best_move_button.text = "VER MEJOR"
    host._best_move_button.tooltip_text = "Resaltar la mejor jugada calculada por Stockfish"
    host._best_move_button.custom_minimum_size = Vector2(92, 30)
    host._best_move_button.add_theme_font_size_override("font_size", 12)
    var best_style := StyleBoxFlat.new()
    best_style.bg_color = Color("#332815")
    best_style.border_color = host.GOLD
    best_style.set_border_width_all(1)
    best_style.set_corner_radius_all(9)
    best_style.content_margin_left = 8
    best_style.content_margin_right = 8
    best_style.content_margin_top = 4
    best_style.content_margin_bottom = 4
    host._best_move_button.add_theme_stylebox_override("normal", best_style)
    var best_hover := best_style.duplicate()
    best_hover.bg_color = Color("#463619")
    host._best_move_button.add_theme_stylebox_override("hover", best_hover)
    host._best_move_button.pressed.connect(host.toggle_best_move)
    coach_footer.add_child(host._best_move_button)

    # The board stage owns board centering and responsive coach placement.
    # Player rails and move strip remain shared with the replay presentation.
    root.move_child(host._move_scroll, 3)
    root.move_child(host._white_player_header, 4)

    if not host.resized.is_connected(resize):
        host.resized.connect(resize)
    if not host._workspace.resized.is_connected(resize):
        host._workspace.resized.connect(resize)
    if host.is_inside_tree():
        resize()
    else:
        host.call_deferred("_resize")

func make_nav_button(symbol: String, tooltip: String) -> Button:
    var b := Button.new()
    b.text = symbol
    b.tooltip_text = tooltip
    b.custom_minimum_size = Vector2(46, 44)
    b.add_theme_font_size_override("font_size", 22)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#211C17")
    style.set_corner_radius_all(13)
    style.set_border_width_all(1)
    style.border_color = Color("#4A4034")
    b.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate()
    hover.bg_color = Color("#2A2219")
    hover.border_color = host.GOLD
    b.add_theme_stylebox_override("hover", hover)
    return b

func make_auto_button() -> Button:
    var b := Button.new()
    b.text = "AUTO"
    b.tooltip_text = "Avanzar automáticamente hasta una jugada importante"
    b.custom_minimum_size = Vector2(72, 44)
    b.add_theme_font_size_override("font_size", 19)
    var style := StyleBoxFlat.new()
    style.bg_color = Color("#332815")
    style.set_corner_radius_all(13)
    style.set_border_width_all(1)
    style.border_color = host.GOLD
    b.add_theme_stylebox_override("normal", style)
    var hover := style.duplicate()
    hover.bg_color = Color("#463619")
    b.add_theme_stylebox_override("hover", hover)
    return b

func mobile_ui_scale(viewport_size: Vector2) -> float:
    # La UI vive en la base lógica de Godot, mientras que un teléfono puede
    # tener una ventana física mucho más estrecha. Usamos la ventana real para
    # compensar tipografía y objetivos táctiles; el tablero no recibe esta escala.
    var window_width := float(host.get_window().size.x) if host.is_inside_tree() else viewport_size.x
    return clampf(480.0 / maxf(1.0, window_width), 1.0, 1.20)

func resize() -> void:
    var viewport_size: Vector2 = host.get_viewport_rect().size
    var ui_scale := mobile_ui_scale(viewport_size)
    var wide: bool = viewport_size.x > viewport_size.y * 1.08
    var available_width := minf(maxf(0.0, host.size.x), viewport_size.x)
    var coach_height: float = host.COACH_HEIGHT if host._review_mode == "analysis" and not wide else 0.0
    var entry_height: float = 46.0 if host._review_mode == "replay" else 0.0
    var player_rails: float = (144.0 if host._review_mode == "replay" else 0.0) * ui_scale
    var nav_and_strip: float = (host.NAV_HEIGHT + host.MOVE_STRIP_HEIGHT + 22.0 + coach_height + entry_height + player_rails) * ui_scale
    var host_height := float(host.size.y) if host.size.y > 1.0 else viewport_size.y
    var available_height := maxf(220.0, minf(viewport_size.y, host_height) - nav_and_strip)
    if wide:
        host._board_side = minf(available_width, available_height)
    else:
        # Replay may be embedded in the history screen, whose own title and
        # result card consume vertical space. Fit to the actual view height so
        # player rails and controls remain reachable instead of overflowing.
        var width_limit := available_width if available_width > 1.0 else viewport_size.x
        var shared_board_side := LayoutMetrics.board_rect(viewport_size, false).size.x
        host._board_side = minf(minf(width_limit, available_height), shared_board_side)
        if host.get_parent() != null and host.get_parent().name == "Body":
            host._board_side = minf(host._board_side, viewport_size.x * 0.78)
    host._board_side = maxf(180.0 if not wide else 220.0, host._board_side)

    host.custom_minimum_size = Vector2(0.0, host._board_side + nav_and_strip)
    if is_instance_valid(host._workspace):
        host._workspace.custom_minimum_size = Vector2(0.0, host._board_side + ((host.COACH_HEIGHT + 10.0) * ui_scale if host._review_mode == "analysis" and not wide else 0.0))
        host._workspace.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        host._workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
    host._workspace.clip_contents = false
    if is_instance_valid(host._board):
        var stage_size: Vector2 = host._workspace.size
        var coach_visible: bool = host._review_mode == "analysis" and host._coach_panel.visible
        var top_rail: float = (host.COACH_HEIGHT + 10.0) * ui_scale if coach_visible and not wide else 0.0
        var actual_board_side: float = minf(minf(host._board_side, stage_size.x), maxf(1.0, stage_size.y - top_rail))
        if actual_board_side < 1.0:
            actual_board_side = host._board_side
        host._board.custom_minimum_size = Vector2(actual_board_side, actual_board_side)
        host._board.size = Vector2(actual_board_side, actual_board_side)
        var side_coach: bool = wide and coach_visible and stage_size.x >= actual_board_side + 260.0
        host._coach_panel.visible = coach_visible
        if side_coach:
            # Center the board relative to the entire stage, not the leftover space
            # after the coach. The coach floats at the upper-right without shifting it.
            host._board.position = Vector2((stage_size.x - actual_board_side) * 0.5, maxf(0.0, (stage_size.y - actual_board_side) * 0.5))
            var coach_width := minf(280.0 * ui_scale, maxf(220.0, stage_size.x - actual_board_side - 18.0))
            host._coach_panel.position = Vector2(stage_size.x - coach_width, 4.0)
            host._coach_panel.size = Vector2(coach_width, host.COACH_HEIGHT * ui_scale)
        elif coach_visible:
            # Portrait/narrow layouts: keep the dialogue in a dedicated rail above
            # the board, never over legal squares or touch controls.
            host._coach_panel.position = Vector2(4.0, 2.0)
            host._coach_panel.size = Vector2(maxf(0.0, stage_size.x - 8.0), host.COACH_HEIGHT * ui_scale)
            var board_y: float = host.COACH_HEIGHT * ui_scale + 10.0 * ui_scale + maxf(0.0, (stage_size.y - host.COACH_HEIGHT * ui_scale - 10.0 * ui_scale - host._board_side) * 0.5)
            host._board.position = Vector2((stage_size.x - actual_board_side) * 0.5, board_y)
        else:
            host._board.position = Vector2((stage_size.x - actual_board_side) * 0.5, maxf(0.0, (stage_size.y - actual_board_side) * 0.5))
            host._coach_panel.position = Vector2.ZERO
            host._coach_panel.size = Vector2.ZERO

    if is_instance_valid(host._previous_button):
        host._previous_button.custom_minimum_size = Vector2(46.0, 44.0) * ui_scale
        host._previous_button.add_theme_font_size_override("font_size", roundi(22.0 * ui_scale))
    if is_instance_valid(host._auto_button):
        host._auto_button.custom_minimum_size = Vector2(72.0, 44.0) * ui_scale
        host._auto_button.add_theme_font_size_override("font_size", roundi(13.0 * ui_scale))
    if is_instance_valid(host._next_button):
        host._next_button.custom_minimum_size = Vector2(46.0, 44.0) * ui_scale
        host._next_button.add_theme_font_size_override("font_size", roundi(22.0 * ui_scale))

    if is_instance_valid(host._move_label):
        host._move_label.custom_minimum_size = Vector2(124.0, 44.0) * ui_scale
        host._move_label.add_theme_font_size_override("font_size", roundi(15.0 * ui_scale))

    if is_instance_valid(host._move_scroll):
        host._move_scroll.custom_minimum_size.y = host.MOVE_STRIP_HEIGHT * ui_scale
    if is_instance_valid(host._move_grid_scroll):
        host._move_grid_scroll.custom_minimum_size.y = (112.0 if not wide else 84.0) * ui_scale
    if is_instance_valid(host._move_list):
        host._move_list.add_theme_constant_override("separation", roundi(14.0 * ui_scale))
        for child in host._move_list.get_children():
            if child is Button:
                var state_index := int(child.get_meta("state_index", -1))
                child.custom_minimum_size = Vector2(62.0 if state_index == 0 else 88.0, host.MOVE_STRIP_HEIGHT) * ui_scale
                child.add_theme_font_size_override("font_size", roundi(15.0 * ui_scale))

    if is_instance_valid(host._position_label):
        host._position_label.custom_minimum_size.y = 22.0 * ui_scale
        host._position_label.add_theme_font_size_override("font_size", roundi(13.0 * ui_scale))

    if is_instance_valid(host._analysis_entry_button):
        host._analysis_entry_button.custom_minimum_size.y = 42.0 * ui_scale
    if is_instance_valid(host._black_player_header):
        host._black_player_header.custom_minimum_size.y = 72.0 * ui_scale
    if is_instance_valid(host._white_player_header):
        host._white_player_header.custom_minimum_size.y = 72.0 * ui_scale
        host._analysis_entry_button.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
    if is_instance_valid(host._coach_panel):
        host._coach_panel.custom_minimum_size.y = host.COACH_HEIGHT * ui_scale
        host._coach_title.add_theme_font_size_override("font_size", roundi(14.0 * ui_scale))
        host._coach_text.add_theme_font_size_override("font_size", roundi(12.0 * ui_scale))
        host._coach_line.add_theme_font_size_override("font_size", roundi(12.0 * ui_scale))
        host._best_move_button.custom_minimum_size = Vector2(92.0, 30.0) * ui_scale
        host._best_move_button.add_theme_font_size_override("font_size", roundi(11.0 * ui_scale))
