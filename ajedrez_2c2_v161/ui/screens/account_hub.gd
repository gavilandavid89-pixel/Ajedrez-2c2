extends Control
const ThemePalette = preload("res://core/theme/theme_tokens.gd")
const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")

const AppConfig = preload("res://core/services/app.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")
const Competitive = preload("res://domain/competitive/competitive_system.gd")
const NexusTeam = preload("res://domain/competitive/nexus_team.gd")
const EmoteDataScript = preload("res://domain/player/emote_data.gd")
const ReplayViewScript = preload("res://domain/replay/match_replay_view.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const GameReviewServiceScript = preload("res://domain/replay/game_review_service.gd")
const AccountPageRendererScript = preload("res://ui/components/account_page_renderer.gd")

var _fallback_player_data: Node = null
var _connected_player_data: Node = null
var _connected_viewport: Viewport = null

var page := "profile"
var ranking_mode := "1c1"
var viewport_size := Vector2.ZERO
var main_margin: MarginContainer
var main_nav: MainNavigation
var content: Panel
var title: Label
var tabs: GridContainer
var body: VBoxContainer
var status: Label
var compact_hint: Label
var history_action: Button
var stat_grid: GridContainer
var selected_history_index := -1
var _refresh_in_progress := false
static var _avatar_texture_cache: Dictionary = {}
static var _preview_texture_cache: Dictionary = {}
var _analysis_thread: Thread = null
var _analysis_service: RefCounted = null
var _analysis_status_label: Label = null
var _analysis_item: Dictionary = {}
var _analysis_moves: Array = []
var _analysis_viewer: Control = null
var page_renderer: RefCounted

const BG := ThemePalette.BG
const PANEL := ThemePalette.PANEL
const PANEL_2 := ThemePalette.PANEL_2
const TEXT := ThemePalette.TEXT
const MUTED := ThemePalette.MUTED
const GOLD := ThemePalette.GOLD
const GREEN := ThemePalette.GREEN
const RED := ThemePalette.RED

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var app = RuntimeServicesScript.get_autoload("App")
    if app != null:
        var requested := String(app.account_start_page)
        if ["profile", "profile_edit", "ranking", "history", "analysis", "replay", "appearance", "reactions", "settings", "more", "cups", "help"].has(requested):
            page = requested
        app.account_start_page = "profile"
    _build()
    page_renderer = AccountPageRendererScript.new(self)
    var data := _data()
    if data != null and page in ["analysis", "replay"] and selected_history_index < 0 and not data.history.is_empty():
        selected_history_index = data.history.size() - 1
    if data != null and data.has_signal("data_changed"):
        _connected_player_data = data
        if not data.data_changed.is_connected(_refresh):
            data.data_changed.connect(_refresh)
    _connected_viewport = get_viewport()
    if _connected_viewport != null and not _connected_viewport.size_changed.is_connected(_resize):
        _connected_viewport.size_changed.connect(_resize)
    _resize()
    _refresh()

func _exit_tree() -> void:
    if _analysis_thread != null and _analysis_thread.is_started():
        _analysis_thread.wait_to_finish()
    _analysis_thread = null
    _analysis_status_label = null
    _analysis_item = {}
    _analysis_moves = []
    _analysis_viewer = null
    if _connected_player_data != null and is_instance_valid(_connected_player_data):
        if _connected_player_data.has_signal("data_changed") and _connected_player_data.data_changed.is_connected(_refresh):
            _connected_player_data.data_changed.disconnect(_refresh)
    if _connected_viewport != null and is_instance_valid(_connected_viewport):
        if _connected_viewport.size_changed.is_connected(_resize):
            _connected_viewport.size_changed.disconnect(_resize)
    _connected_player_data = null
    _connected_viewport = null

func _on_back_pressed() -> void:
    match page:
        "profile":
            Navigation.go(ScreenCatalog.MAIN_MENU)
        "analysis":
            var app = RuntimeServicesScript.get_autoload("App")
            if app != null and app.analysis_return_to_home:
                app.analysis_return_to_home = false
                Navigation.go(ScreenCatalog.MAIN_MENU)
            else:
                page = "history"
                _refresh()
        "replay":
            page = "history"
            _refresh()
        "cups":
            page = "ranking"
            _refresh()
        "ranking", "history", "more":
            Navigation.go(ScreenCatalog.MAIN_MENU)
        "help":
            page = "more"
            _refresh()
        _: # Apariencia, Edición de perfil, Reacciones y Ajustes pertenecen al Perfil.
            page = "profile"
            _refresh()

func _build() -> void:
    var bg := ColorRect.new()
    bg.color = BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    main_margin = MarginContainer.new()
    var margin := main_margin
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 16)
    margin.add_theme_constant_override("margin_right", 16)
    margin.add_theme_constant_override("margin_top", 50)
    margin.add_theme_constant_override("margin_bottom", 16)
    add_child(margin)

    var root_box := VBoxContainer.new()
    root_box.add_theme_constant_override("separation", 10)
    margin.add_child(root_box)

    var top := HBoxContainer.new()
    top.custom_minimum_size.y = 64
    root_box.add_child(top)

    var back := Button.new()
    back.text = "‹"
    back.tooltip_text = "Volver"
    back.custom_minimum_size = Vector2(62, 58)
    back.add_theme_font_size_override("font_size", 34)
    back.add_theme_color_override("font_color", TEXT)
    back.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
    back.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
    back.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
    back.pressed.connect(_on_back_pressed)
    top.add_child(back)

    title = Label.new()
    title.text = "Perfil"
    title.add_theme_color_override("font_color", TEXT)
    title.add_theme_font_size_override("font_size", 25)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top.add_child(title)

    # Perfil es una pantalla de información, no una barra de navegación.
    # Las secciones secundarias se abren desde el menú principal.
    compact_hint = Label.new()
    compact_hint.name = "Hint"
    compact_hint.visible = false
    compact_hint.text = "Base local · online real pendiente"
    compact_hint.add_theme_color_override("font_color", MUTED)
    compact_hint.add_theme_font_size_override("font_size", 18)
    compact_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    compact_hint.custom_minimum_size.x = 0.0
    compact_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
    compact_hint.clip_text = true
    compact_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    compact_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    compact_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    top.add_child(compact_hint)

    # Las antiguas pestañas quedan fuera de la navegación visible.
    # Perfil es una pantalla única; Historial y Ajustes tienen accesos de icono.
    tabs = GridContainer.new()
    tabs.name = "LegacyTabs"
    tabs.visible = false
    tabs.mouse_filter = Control.MOUSE_FILTER_IGNORE
    root_box.add_child(tabs)

    content = Panel.new()
    content.add_theme_stylebox_override("panel", _panel_style(PANEL))
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root_box.add_child(content)

    var scroll := ScrollContainer.new()
    scroll.name = "Scroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 10
    scroll.offset_right = -10
    scroll.offset_top = 10
    scroll.offset_bottom = -10
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.follow_focus = false
    scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    content.add_child(scroll)

    body = VBoxContainer.new()
    body.mouse_filter = Control.MOUSE_FILTER_IGNORE
    body.add_theme_constant_override("separation", 10)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    body.custom_minimum_size.x = 0
    scroll.add_child(body)

    status = Label.new()
    status.add_theme_color_override("font_color", MUTED)
    status.add_theme_font_size_override("font_size", 18)
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    status.clip_text = false
    root_box.add_child(status)

    _build_header_actions()

func _build_header_actions() -> void:
    # Acciones contextuales del perfil: no usamos una barra global aquí.
    # Historial y Ajustes tienen accesos persistentes, claros y aislados.
    history_action = _top_icon_button("◷", "Historial de partidas")
    history_action.name = "HistoryAction"
    history_action.pressed.connect(func(): page = "history"; _refresh())
    add_child(history_action)


func _on_main_navigation(section: String) -> void:
    # Compatibilidad con pruebas/llamadas antiguas. La navegación global
    # pertenece al menú principal, no a Perfil.
    match section:
        "play", "ranking", "history", "more":
            Navigation.go(ScreenCatalog.MAIN_MENU)

func _sync_main_nav() -> void:
    # El Perfil no muestra la barra principal; conserva el método como
    # delegador de compatibilidad para no romper código existente.
    if main_nav != null:
        main_nav.visible = false
    _resize()

func _refresh() -> void:
    if body == null or not is_inside_tree() or _refresh_in_progress:
        return
    _refresh_in_progress = true
    if tabs:
        tabs.visible = false
    if compact_hint:
        compact_hint.visible = false
    for child in body.get_children():
        child.queue_free()
    if page_renderer != null:
        page_renderer.render(page)
    var titles := {
        "profile": "Perfil",
        "profile_edit": "Editar perfil",
        "ranking": "Ranking",
        "cups": "Copas",
        "history": "Historial",
        "analysis": "Análisis",
        "replay": "Replay",
        "appearance": "Apariencia",
        "reactions": "Experiencia",
        "settings": "Ajustes",
        "more": "Más",
        "help": "Ayuda",
    }
    title.text = String(titles.get(page, "Perfil"))
    _update_status()
    _sync_main_nav()
    _refresh_in_progress = false

func _refresh_tabs() -> void:
    # Se conserva por compatibilidad con pruebas antiguas; la navegación visual ya no usa pestañas.
    if tabs:
        tabs.visible = false

func _top_icon_button(symbol: String, tooltip: String) -> Button:
    var b := Button.new()
    b.text = symbol
    b.tooltip_text = tooltip
    b.custom_minimum_size = Vector2(50, 50)
    b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    b.add_theme_font_size_override("font_size", 28)
    b.add_theme_color_override("font_color", TEXT)
    b.add_theme_color_override("font_hover_color", GOLD)
    b.add_theme_stylebox_override("normal", _button_style(PANEL_2, 12, 1, Color("#3D3428")))
    b.add_theme_stylebox_override("hover", _button_style(Color("#30271C"), 12, 1, GOLD))
    b.add_theme_stylebox_override("pressed", _button_style(Color("#241D15"), 12, 1, GOLD))
    return b

func _layout_viewport() -> Vector2:
    # Layout breakpoints must use the real window size, not the 720px virtual
    # canvas. Otherwise a 412px phone is mistaken for a wide tablet and grids
    # stay at four columns, clipping profile statistics horizontally.
    if is_inside_tree() and get_window() != null:
        return Vector2(get_window().size)
    if viewport_size.x > 1.0 and viewport_size.y > 1.0:
        return viewport_size
    return Vector2(
        float(ProjectSettings.get_setting("display/window/size/viewport_width", 720)),
        float(ProjectSettings.get_setting("display/window/size/viewport_height", 720))
    )

func _build_profile() -> void:
    page_renderer.render("profile")

func _build_profile_edit() -> void:
    page_renderer.render("profile_edit")

func _build_more() -> void:
    page_renderer.render("more")

func _build_help() -> void:
    page_renderer.render("help")

func _build_ranking() -> void:
    page_renderer.render("ranking")

func _build_history() -> void:
    page_renderer.render("history")

func _open_history_primary(record_id: String) -> void:
    # Historial entra directo al estudio. No hay una pantalla intermedia
    # ni un segundo botón "Analizar" antes de poder ver el tablero.
    _open_history_analysis(record_id)

func _open_history_analysis(record_id: String) -> void:
    selected_history_index = _find_history_index(record_id)
    if selected_history_index < 0:
        return
    var player := _data()
    if player != null and player.has_method("mark_history_analysis_viewed"):
        player.mark_history_analysis_viewed(record_id, false)
    page = "analysis"
    _refresh()

func _open_history_replay(record_id: String) -> void:
    selected_history_index = _find_history_index(record_id)
    if selected_history_index < 0:
        return
    page = "replay"
    _refresh()

func _find_history_index(match_id: String) -> int:
    var entries: Array = _data().history
    for i in range(entries.size()):
        if String(entries[i].get("match_id", "")) == match_id:
            return i
    return -1

func _build_analysis() -> void:
    page_renderer.render("analysis")

func _start_engine_review(item: Dictionary, moves: Array, replay_data: Dictionary, status_label: Label, viewer: Control) -> void:
    if not is_instance_valid(status_label) or page != "analysis":
        return
    if moves.is_empty():
        status_label.text = "Motor: no hay jugadas para analizar."
        return
    var service := GameReviewServiceScript.new()
    if not service.engine.is_available():
        status_label.text = "Motor: falta el binario oficial de Stockfish 19 ARM64"
        return
    if _analysis_thread != null and _analysis_thread.is_started():
        return
    _analysis_status_label = status_label
    _analysis_item = item
    _analysis_moves = moves
    _analysis_viewer = viewer
    # Observe the replay on the main thread before starting the engine worker.
    var supervisor := RuntimeServicesScript.get_autoload("SupervisorHub")
    if supervisor != null and supervisor.replay_agent != null:
        supervisor.replay_agent.inspect_replay(replay_data, moves)
    _analysis_thread = Thread.new()
    _analysis_service = service
    # Use a bound method instead of a lambda closure. The old closure captured
    # locals owned by this screen; navigating away while Stockfish was running
    # could free those captures and produce "Lambda capture ... was freed".
    var task := Callable(service, "analyze_replay").bind(replay_data.duplicate(true), moves.duplicate(true), 10)
    var start_error: Error = _analysis_thread.start(task)
    if start_error != OK:
        _analysis_thread = null
        status_label.text = "Motor: no se pudo iniciar el análisis en segundo plano."
        return
    _poll_engine_review()

func _poll_engine_review() -> void:
    if _analysis_thread == null:
        return
    if _analysis_thread.is_alive():
        if is_instance_valid(_analysis_status_label):
            _analysis_status_label.text = "Motor: analizando %d jugadas…" % _analysis_moves.size()
        # Use a bound instance method instead of a lambda capturing this screen.
        # If navigation destroys the screen while the timer is pending, Godot
        # disconnects the freed target cleanly instead of invoking stale captures.
        get_tree().create_timer(0.25).timeout.connect(_on_engine_review_poll_timeout, CONNECT_ONE_SHOT)
        return
    var result: Variant = _analysis_thread.wait_to_finish()
    _analysis_thread = null
    _analysis_service = null
    if not is_instance_valid(_analysis_status_label):
        return
    if result is Dictionary and bool(result.get("ok", false)):
        _analysis_status_label.text = "Motor: Stockfish 19 · profundidad 10 · análisis completado"
        _apply_engine_review(_analysis_item, result, _analysis_viewer)
    else:
        _analysis_status_label.text = "Motor: %s" % String(result.get("error", "no disponible")) if result is Dictionary else "Motor: no disponible"

func _on_engine_review_poll_timeout() -> void:
    if is_inside_tree():
        _poll_engine_review()

func _apply_engine_review(item: Dictionary, result: Dictionary, viewer: Control) -> void:
    var report := result.duplicate(true)
    var player := _data()
    if player == null:
        return
    var target_match_id := String(item.get("match_id", ""))
    var target_index := -1
    if not target_match_id.is_empty():
        target_index = _find_history_index(target_match_id)
    elif selected_history_index >= 0 and selected_history_index < player.history.size():
        target_index = selected_history_index
    if target_index < 0 or target_index >= player.history.size():
        return
    player.history[target_index]["engine_analysis"] = report
    player.history[target_index]["analysis_viewed"] = true
    if is_instance_valid(viewer) and viewer.has_method("set_engine_analysis"):
        viewer.set_engine_analysis(report)
    if player.has_method("save_data"):
        player.save_data()
    elif player.has_signal("data_changed"):
        player.data_changed.emit()

func _build_replay() -> void:
    page_renderer.render("replay")

func _build_cups() -> void:
    page_renderer.render("cups")

func _build_reactions() -> void:
    page_renderer.render("reactions")

func _build_settings() -> void:
    page_renderer.render("settings")

func _build_appearance() -> void:
    page_renderer.render("appearance")

func _edit_name() -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "Cambiar nombre"
    var line := LineEdit.new()
    line.text = String(_data().profile.get("name", "Tú"))
    line.placeholder_text = "Nombre (1-10 caracteres)"
    line.max_length = PlayerDataScript.MAX_DISPLAY_NAME_LENGTH
    dialog.add_child(line)
    add_child(dialog)
    dialog.confirmed.connect(func():
        if not _data().set_display_name(line.text):
            line.grab_focus()
            return
        dialog.queue_free()
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered_ratio(0.82)
    line.grab_focus()

func _data() -> Object:
    var existing := RuntimeServicesScript.get_autoload("PlayerData")
    if existing != null:
        return existing
    if _fallback_player_data == null or not is_instance_valid(_fallback_player_data):
        _fallback_player_data = PlayerDataScript.new()
        _fallback_player_data.name = "PlayerData_Fallback"
    return _fallback_player_data

func _card() -> PanelContainer:
    var p := PanelContainer.new()
    p.add_theme_stylebox_override("panel", _panel_style(PANEL_2))
    var content_box := VBoxContainer.new()
    content_box.name = "Content"
    content_box.add_theme_constant_override("separation", 8)
    p.add_child(content_box)
    return p

func _card_content(card: PanelContainer) -> VBoxContainer:
    return card.get_node("Content") as VBoxContainer

func _stat_card(label_text: String, value: String) -> PanelContainer:
    var p := _card()
    p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    p.custom_minimum_size.y = 84.0
    var box := _card_content(p)
    box.add_theme_constant_override("separation", 3)
    var v := Label.new()
    v.text = value
    v.add_theme_color_override("font_color", GOLD)
    v.add_theme_font_size_override("font_size", 22)
    v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(v)
    var l := Label.new()
    l.text = label_text
    l.add_theme_color_override("font_color", MUTED)
    l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    l.custom_minimum_size.y = 32.0
    l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.clip_text = true
    l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    box.add_child(l)
    return p

func _muted(text_value: String) -> Label:
    var l := Label.new()
    l.text = text_value
    l.add_theme_color_override("font_color", MUTED)
    l.add_theme_font_size_override("font_size", 20)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    return l

func _button_style(fill: Color, radius: int, border_width: int, border: Color) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.set_corner_radius_all(radius)
    s.set_border_width_all(border_width)
    s.border_color = border
    s.content_margin_left = 8
    s.content_margin_right = 8
    return s

func _panel_style(fill: Color) -> StyleBoxFlat:
    return _button_style(fill, 14, 1, Color("#3D3428"))

func _update_status() -> void:
    status.text = "%d copas · %d rating · datos locales" % [int(_data().individual.get("cups", 0)), int(_data().individual.get("rating", Competitive.DEFAULT_RATING))]

func _mobile_ui_scale() -> float:
    var window_width := float(get_window().size.x) if is_inside_tree() else viewport_size.x
    # canvas_items already scales the virtual canvas to phone pixels; keep only a small optical lift.
    return clampf(720.0 / maxf(1.0, window_width), 1.0, 1.15)

func _is_in_main_navigation(node: Node) -> bool:
    var cursor := node.get_parent() if node != null else null
    while cursor != null:
        if cursor.name == "MainNavigation":
            return true
        cursor = cursor.get_parent()
    return false

func _apply_mobile_typography(node: Node) -> void:
    if node == null:
        return
    # El estudio de ajedrez ya aplica su propia escala para móvil.
    if node.name == "GameReviewStudy":
        return
    var scale := _mobile_ui_scale()
    if node is Label or node is Button or node is LineEdit:
        var base := float(node.get_meta("_mobile_base_font", -1.0))
        if base <= 0.0:
            base = float(node.get_theme_font_size("font_size"))
            node.set_meta("_mobile_base_font", base)
        if base > 0.0:
            node.add_theme_font_size_override("font_size", max(18, roundi(base * scale)))
    elif node is RichTextLabel:
        var rich_base := float(node.get_meta("_mobile_base_font", -1.0))
        if rich_base <= 0.0:
            rich_base = float(node.get_theme_font_size("normal_font_size"))
            node.set_meta("_mobile_base_font", rich_base)
        if rich_base > 0.0:
            node.add_theme_font_size_override("normal_font_size", max(14, roundi(rich_base * scale)))
    if node is Button and not _is_in_main_navigation(node):
        var base_size: Vector2 = node.get_meta("_mobile_base_size", Vector2.ZERO)
        if base_size == Vector2.ZERO:
            base_size = node.custom_minimum_size
            if base_size.x > 0.0 or base_size.y > 0.0:
                node.set_meta("_mobile_base_size", base_size)
        if base_size != Vector2.ZERO:
            node.custom_minimum_size = base_size * scale
    for child in node.get_children():
        _apply_mobile_typography(child)

func _resize() -> void:
    if not is_inside_tree():
        return
    viewport_size = get_viewport_rect().size
    var portrait := viewport_size.y >= viewport_size.x
    var focused_study_page := page in ["analysis", "replay"]
    if main_margin != null:
        # Las pantallas de estudio usan ancho completo, igual que la pantalla
        # de partida. El resto del perfil conserva sus márgenes habituales.
        # Account is a standalone destination (no side navigation); do not
        # reserve the 160px rail used by social screens in landscape.
        main_margin.add_theme_constant_override("margin_left", 0 if focused_study_page else (16 if portrait else 24))
        # History is a floating icon in the top-right corner. Reserve its area
        # so the landscape status hint and content never sit underneath it.
        main_margin.add_theme_constant_override("margin_right", 0 if focused_study_page else (16 if portrait else 84))
        main_margin.add_theme_constant_override("margin_top", 0 if focused_study_page else (50 if portrait else 28))
        main_margin.add_theme_constant_override("margin_bottom", 0 if focused_study_page else 16)
    if title:
        title.add_theme_font_size_override("font_size", 24 if portrait else 25)
    if history_action != null:
        history_action.position = Vector2(maxf(0.0, viewport_size.x - (60.0 if portrait else 64.0)), 14.0)
    if compact_hint:
        compact_hint.visible = not portrait or (get_window().size.x >= 700 if is_inside_tree() else viewport_size.x >= 700)
    if tabs:
        tabs.columns = 3 if portrait else 6
        for child in tabs.get_children():
            child.custom_minimum_size.x = 0
    if stat_grid:
        stat_grid.columns = 2 if portrait else 4
    if body:
        body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        body.add_theme_constant_override("separation", 0 if focused_study_page else 10)
        # En Replay/Análisis no añadimos un ancho artificial: el tablero debe
        # poder llegar al borde del viewport, como en partida.
        body.custom_minimum_size.x = viewport_size.x if focused_study_page else 0.0
    var scroll := content.get_node_or_null("Scroll") if content != null else null
    if scroll != null:
        scroll.offset_left = 0 if focused_study_page else 10
        scroll.offset_right = 0 if focused_study_page else -10
        scroll.offset_top = 0 if focused_study_page else (34 if portrait else 18)
        scroll.offset_bottom = 0 if focused_study_page else -10
        scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    if content != null:
        content.add_theme_stylebox_override("panel", StyleBoxEmpty.new() if focused_study_page else _panel_style(PANEL))
    if status != null:
        status.visible = not focused_study_page
    _apply_mobile_typography(self)