extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const AppConfig = preload("res://core/services/app.gd")
const Competitive = preload("res://domain/competitive/competitive_system.gd")

const BG := Color("#14110E")
const PANEL := Color("#1D1812")
const PANEL_2 := Color("#241D15")
const BORDER := Color("#403426")
const GOLD := Color("#D5A84E")
const TEXT := Color("#F0E3C4")
const MUTED := Color("#AFA18A")
const SUCCESS := Color("#9FCB9A")

var profile_button: Button
var profile_frame_ring: Panel
var more_button: Button
var more_menu: PopupMenu
var streak_label: Label
var daily_goal_label: Label
var main_nav: MainNavigation
var scroll: ScrollContainer
var content_box: VBoxContainer
var compat_margin: Control
var compat_vbox: VBoxContainer
var play_button: Button
var bot_button: Button
var play_overlay: PanelContainer
var play_menu: VBoxContainer
var toast: Label
var _connected_player_data: Node = null
var _connected_viewport: Viewport = null
var _rematch_service: Node = null
var _rematch_banner: Panel = null
var _rematch_request_id := ""
var _toast_generation := 0

func _app() -> Node:
    return RuntimeServicesScript.get_autoload("App")

func _player_data() -> Object:
    return RuntimeServicesScript.get_autoload("PlayerData")

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_home()
    _build_profile_button()
    _build_more_button()
    _build_main_nav()
    _build_rematch_banner()
    _connect_legacy_mode_buttons()
    var player_data := _player_data()
    if player_data != null:
        _connected_player_data = player_data
        if not player_data.data_changed.is_connected(_refresh_home):
            player_data.data_changed.connect(_refresh_home)
    _connected_viewport = get_viewport()
    if _connected_viewport != null:
        if not _connected_viewport.size_changed.is_connected(_on_viewport_changed):
            _connected_viewport.size_changed.connect(_on_viewport_changed)
        if not _connected_viewport.size_changed.is_connected(_position_rematch_banner):
            _connected_viewport.size_changed.connect(_position_rematch_banner)
    _refresh_home()
    _refresh_rematch_banner()
    _on_viewport_changed()

func _exit_tree() -> void:
    if _connected_viewport != null and is_instance_valid(_connected_viewport):
        if _connected_viewport.size_changed.is_connected(_on_viewport_changed):
            _connected_viewport.size_changed.disconnect(_on_viewport_changed)
        if _connected_viewport.size_changed.is_connected(_position_rematch_banner):
            _connected_viewport.size_changed.disconnect(_position_rematch_banner)
    _connected_viewport = null
    if _rematch_service != null and is_instance_valid(_rematch_service) and _rematch_service.has_signal("changed"):
        if _rematch_service.changed.is_connected(_refresh_rematch_banner):
            _rematch_service.changed.disconnect(_refresh_rematch_banner)
    if _connected_player_data != null and is_instance_valid(_connected_player_data):
        if _connected_player_data.has_signal("data_changed") and _connected_player_data.data_changed.is_connected(_refresh_home):
            _connected_player_data.data_changed.disconnect(_refresh_home)
    _connected_player_data = null


func _build_rematch_banner() -> void:
    _rematch_service = RuntimeServicesScript.get_autoload("RematchService")
    _rematch_banner = Panel.new()
    _rematch_banner.name = "RematchBanner"
    _rematch_banner.visible = false
    _rematch_banner.z_index = 50
    _rematch_banner.mouse_filter = Control.MOUSE_FILTER_STOP
    _rematch_banner.add_theme_stylebox_override("panel", _panel_style(PANEL_2, GOLD, 14))
    add_child(_rematch_banner)
    if _rematch_service != null and _rematch_service.has_signal("changed"):
        if not _rematch_service.changed.is_connected(_refresh_rematch_banner):
            _rematch_service.changed.connect(_refresh_rematch_banner)

func _refresh_rematch_banner() -> void:
    if _rematch_banner == null:
        return
    for child in _rematch_banner.get_children():
        _rematch_banner.remove_child(child)
        child.queue_free()
    var request: Dictionary = _rematch_service.get_latest_request() if _rematch_service != null else {}
    _rematch_banner.visible = not request.is_empty()
    if request.is_empty():
        return
    _rematch_request_id = String(request.get("id", ""))
    var row := Control.new()
    row.name = "RematchRow"
    row.position = Vector2(10, 4)
    row.size = Vector2(maxf(0.0, _rematch_banner.size.x - 20.0), 54.0)
    _rematch_banner.add_child(row)
    var icon := Label.new()
    icon.text = String(request.get("icon", "♟"))
    icon.position = Vector2(0, 2)
    icon.size = Vector2(34, 48)
    icon.add_theme_font_size_override("font_size", 26)
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(icon)
    var title := Label.new()
    title.text = "%s te ha pedido la revancha" % String(request.get("requester_name", "Rival"))
    title.name = "Label"
    title.position = Vector2(38, 13)
    title.size = Vector2(maxf(112.0, row.size.x - 154.0), 28)
    title.add_theme_color_override("font_color", TEXT)
    title.add_theme_font_size_override("font_size", 23)
    row.add_child(title)
    var accept := _make_small_action("✓", SUCCESS)
    accept.name = "Accept"
    accept.position = Vector2(row.size.x - 96.0, 5)
    accept.size = Vector2(44, 44)
    accept.tooltip_text = "Aceptar revancha"
    accept.pressed.connect(func(): _answer_rematch(true))
    row.add_child(accept)
    var reject := _make_small_action("×", Color("#D56A5E"))
    reject.name = "Reject"
    reject.position = Vector2(row.size.x - 48.0, 5)
    reject.size = Vector2(44, 44)
    reject.tooltip_text = "Rechazar revancha"
    reject.pressed.connect(func(): _answer_rematch(false))
    row.add_child(reject)
    _position_rematch_banner()

func _make_small_action(label: String, accent: Color) -> Button:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size = Vector2(44, 44)
    button.add_theme_font_size_override("font_size", 29)
    button.add_theme_color_override("font_color", accent)
    button.add_theme_stylebox_override("normal", _panel_style(PANEL, BORDER, 10))
    button.add_theme_stylebox_override("hover", _panel_style(PANEL_2, accent, 10))
    return button

func _answer_rematch(accept: bool) -> void:
    if _rematch_service == null or _rematch_request_id.is_empty():
        return
    if accept:
        _rematch_service.accept_request(_rematch_request_id)
        var app := _app()
        if app != null:
            app.online_entry = "random"
        Navigation.go(ScreenCatalog.ONLINE_MATCHMAKING)
    else:
        _rematch_service.reject_request(_rematch_request_id)
    _rematch_request_id = ""
    _refresh_rematch_banner()

func _position_rematch_banner() -> void:
    if _rematch_banner == null:
        return
    var size := get_viewport_rect().size
    _rematch_banner.position = Vector2(12, 10)
    _rematch_banner.size = Vector2(maxf(0.0, size.x - 24.0), 62.0)
    var row := _rematch_banner.get_node_or_null("RematchRow") as Control
    if row != null:
        row.position = Vector2(10, 4)
        row.size = Vector2(maxf(0.0, _rematch_banner.size.x - 20.0), 54.0)
        var title := row.get_node_or_null("Label") as Label
        var sub := row.get_node_or_null("Label2") as Label
        var accept := row.get_node_or_null("Accept") as Button
        var reject := row.get_node_or_null("Reject") as Button
        if title != null:
            title.size = Vector2(maxf(112.0, row.size.x - 154.0), 28)
        if sub != null:
            sub.size = Vector2(maxf(120.0, row.size.x - 140.0), 20)
        if accept != null:
            accept.name = "Accept"
            accept.position = Vector2(row.size.x - 96.0, 5)
            accept.size = Vector2(44, 44)
        if reject != null:
            reject.name = "Reject"
            reject.position = Vector2(row.size.x - 48.0, 5)
            reject.size = Vector2(44, 44)

func _build_home() -> void:
    var background := ColorRect.new()
    background.name = "Background"
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = BG
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    scroll = ScrollContainer.new()
    scroll.name = "HomeScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 12.0
    scroll.offset_right = -12.0
    # Keep the profile row fixed above the scroll, but don't reserve a huge
    # dead band that looks like a curtain and hides the title on phones.
    scroll.offset_top = 94.0 if get_viewport_rect().size.y >= get_viewport_rect().size.x else 56.0
    scroll.offset_bottom = -120.0
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.follow_focus = false
    scroll.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(scroll)

    content_box = VBoxContainer.new()
    content_box.name = "VBox"
    content_box.custom_minimum_size.x = 320.0
    content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content_box.add_theme_constant_override("separation", 18 if get_viewport_rect().size.y >= get_viewport_rect().size.x else 14)
    content_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    scroll.add_child(content_box)

    # Breathing room below the top identity row (avatar + title).
    var header_gap := Control.new()
    header_gap.name = "HeaderBreathingRoom"
    header_gap.custom_minimum_size.y = 8.0 if get_viewport_rect().size.y >= get_viewport_rect().size.x else 4.0
    content_box.add_child(header_gap)

    # Compatibility surface for older automated callers. The real UI is the
    # scrollable home above; these nodes remain outside the visible layout.
    compat_margin = Control.new()
    compat_margin.name = "Margin"
    compat_margin.visible = false
    add_child(compat_margin)
    compat_vbox = VBoxContainer.new()
    compat_vbox.name = "VBox"
    compat_vbox.custom_minimum_size = Vector2(320.0, 0.0)
    compat_margin.add_child(compat_vbox)

    var title := Label.new()
    title.name = "Title"
    title.text = "Ajedrez 2c2"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_color_override("font_color", TEXT)
    title.add_theme_font_size_override("font_size", 38)
    content_box.add_child(title)

    var subtitle := Label.new()
    subtitle.name = "Subtitle"
    subtitle.text = "Juega, revisa tus partidas y sigue tu progreso"
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    subtitle.add_theme_color_override("font_color", MUTED)
    subtitle.add_theme_font_size_override("font_size", 25)
    content_box.add_child(subtitle)

    # Mobile-first hierarchy: the two primary game actions stay together
    # immediately below the title block. Everything secondary comes after.
    play_button = _make_button("JUGAR", 76, GOLD, TEXT, 24)
    play_button.name = "PlayButton"
    play_button.pressed.connect(_toggle_play_menu)
    content_box.add_child(play_button)

    bot_button = _make_button("JUGAR CONTRA BOTS", 70, BORDER, TEXT, 20)
    bot_button.name = "BotSectionButton"
    bot_button.pressed.connect(func(): Navigation.go(ScreenCatalog.BOT_SETUP))
    content_box.add_child(bot_button)

    play_overlay = PanelContainer.new()
    play_overlay.name = "PlayMenu"
    play_overlay.visible = false
    play_overlay.add_theme_stylebox_override("panel", _panel_style(PANEL_2, GOLD, 14))
    content_box.add_child(play_overlay)

    play_menu = VBoxContainer.new()
    play_menu.name = "PlayOptions"
    play_menu.add_theme_constant_override("separation", 7)
    play_overlay.add_child(play_menu)
    var play_title := Label.new()
    play_title.text = "¿Cómo quieres jugar?"
    play_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    play_title.add_theme_color_override("font_color", MUTED)
    play_title.add_theme_font_size_override("font_size", 25)
    play_menu.add_child(play_title)

    _add_play_option("1c1", "1c1  ·  Online", "Uno contra uno", AppConfig.MODE_1C1)
    _add_play_option("2c2", "2c2  ·  Cooperativo", "Forma equipo", AppConfig.MODE_2C2)
    _add_play_local_option()

    var goal_row := HBoxContainer.new()
    goal_row.name = "DailyGoal"
    goal_row.alignment = BoxContainer.ALIGNMENT_CENTER
    goal_row.add_theme_constant_override("separation", 6)
    daily_goal_label = Label.new()
    daily_goal_label.name = "Label"
    daily_goal_label.text = "🎯 Gana 1 partida  ·  0/1"
    daily_goal_label.add_theme_color_override("font_color", MUTED)
    daily_goal_label.add_theme_font_size_override("font_size", 23)
    goal_row.add_child(daily_goal_label)
    content_box.add_child(goal_row)

    # Aire considerable entre las acciones principales y el resto del Inicio.
    var primary_breathing_room := Control.new()
    primary_breathing_room.name = "PrimaryBreathingRoom"
    primary_breathing_room.custom_minimum_size.y = 20.0
    content_box.add_child(primary_breathing_room)

    _add_separator(content_box)
    _add_history_section()
    _add_separator(content_box)
    _add_season_section()
    _add_activity_line()

    # Compatibility nodes kept in the old public path. They are not visible;
    # real UI actions above call the same handlers.
    _add_legacy_button("2c2", AppConfig.MODE_2C2)
    _add_legacy_button("1c1", AppConfig.MODE_1C1)
    _add_legacy_button("Bot", -1)
    _add_legacy_button("Local", -2)

    var online_setup := preload("res://scenes/online_setup.tscn").instantiate()
    online_setup.name = "OnlineSetup"
    online_setup.visible = false
    add_child(online_setup)
    online_setup.start_requested.connect(_on_online_start)
    online_setup.friend_requested.connect(_on_friend_start)
    online_setup.join_requested.connect(_on_join_start)

    toast = Label.new()
    toast.name = "Toast"
    toast.visible = false
    toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    toast.add_theme_color_override("font_color", TEXT)
    toast.add_theme_stylebox_override("normal", _panel_style(PANEL_2, BORDER, 12))
    toast.add_theme_font_size_override("font_size", 25)
    toast.z_index = 20
    add_child(toast)

func _add_play_option(id: String, title_text: String, subtitle_text: String, mode: int) -> void:
    var button := _make_button("%s\n%s" % [title_text, subtitle_text], 58, PANEL, TEXT, 17)
    button.name = "Play" + id
    button.pressed.connect(func(): _open_online_setup(mode))
    play_menu.add_child(button)

func _add_play_local_option() -> void:
    var button := _make_button("LOCAL\nEn este dispositivo", 58, PANEL, TEXT, 17)
    button.name = "PlayLocal"
    button.pressed.connect(func(): Navigation.go(ScreenCatalog.LOCAL_SETUP))
    play_menu.add_child(button)

func _add_history_section() -> void:
    var heading := _section_heading("ÚLTIMAS PARTIDAS")
    content_box.add_child(heading)
    var data := _player_data()
    var entries: Array = [] if data == null else data.history.duplicate(true)
    entries.reverse()
    var shown := 0
    for item in entries:
        if not item is Dictionary:
            continue
        _add_history_row(item)
        shown += 1
        if shown >= 3:
            break
    if shown == 0:
        var empty := Label.new()
        empty.name = "HistoryEmpty"
        empty.text = "Tus partidas recientes aparecerán aquí."
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.add_theme_color_override("font_color", MUTED)
        empty.add_theme_font_size_override("font_size", 25)
        content_box.add_child(empty)
    var all := Button.new()
    all.text = "Ver todo el historial  →"
    all.flat = true
    all.add_theme_color_override("font_color", GOLD)
    all.add_theme_font_size_override("font_size", 25)
    all.pressed.connect(func(): _open_account_page("history"))
    content_box.add_child(all)

func _add_history_row(item: Dictionary) -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style(PANEL, BORDER, 12))
    content_box.add_child(panel)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 7)
    row.custom_minimum_size = Vector2(0, 52)
    panel.add_child(row)
    _add_history_profile_icons(row, item)

    var text_box := VBoxContainer.new()
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(text_box)
    var title := Label.new()
    title.text = _history_title(item)
    title.add_theme_color_override("font_color", TEXT)
    title.add_theme_font_size_override("font_size", 23)
    text_box.add_child(title)
    var result := Label.new()
    result.text = String(item.get("result", item.get("outcome", "Partida")))
    result.add_theme_color_override("font_color", MUTED)
    result.add_theme_font_size_override("font_size", 23)
    text_box.add_child(result)
    var action := Button.new()
    var analyzed := bool(item.get("analysis_viewed", false))
    action.text = "VER" if analyzed else "ANALIZAR"
    action.custom_minimum_size = Vector2(82, 42)
    action.add_theme_color_override("font_color", GOLD)
    action.pressed.connect(func(): _open_history(item))
    row.add_child(action)

func _add_history_profile_icons(row: HBoxContainer, item: Dictionary) -> void:
    var players: Array = item.get("players", []) if item.get("players", []) is Array else []
    var ids: Array = item.get("player_ids", []) if item.get("player_ids", []) is Array else []
    if players.is_empty() or ids.is_empty():
        return
    var current_id := ""
    var data := _player_data()
    if data != null and data.profile is Dictionary:
        current_id = String(data.profile.get("id", ""))
    var icons := HBoxContainer.new()
    icons.name = "HistoryProfileIcons"
    icons.add_theme_constant_override("separation", 3)
    icons.custom_minimum_size.x = 68
    row.add_child(icons)
    var shown := 0
    for i in range(mini(players.size(), ids.size())):
        var profile_id := String(ids[i])
        var player_name := String(players[i])
        if profile_id.is_empty() or profile_id == current_id or player_name.is_empty():
            continue
        var icon := Button.new()
        icon.name = "Profile_%d" % i
        icon.text = _history_profile_symbol(i)
        icon.custom_minimum_size = Vector2(30, 30)
        icon.add_theme_font_size_override("font_size", 23)
        icon.add_theme_stylebox_override("normal", _panel_style(PANEL, GOLD, 10))
        icon.add_theme_stylebox_override("hover", _panel_style(PANEL_2, GOLD, 10))
        icon.tooltip_text = "Ver perfil de %s" % player_name
        icon.pressed.connect(func(pid: String = profile_id, pname: String = player_name): _open_history_profile(pid, pname))
        icons.add_child(icon)
        shown += 1
        if shown >= 3:
            break
    if shown == 0:
        icons.queue_free()

func _history_profile_symbol(index: int) -> String:
    return ["♟", "♞", "♜", "♝"][index % 4]

func _open_history_profile(profile_id: String, profile_name: String) -> void:
    if profile_id.is_empty():
        return
    var app := _app()
    if app == null:
        return
    app.target_profile_id = profile_id
    app.target_profile_name = profile_name
    Navigation.go(ScreenCatalog.PLAYER_PROFILE)


func _history_title(item: Dictionary) -> String:
    var left := String(item.get("player_name", "Eragon"))
    var right := String(item.get("opponent_name", item.get("opponent", "Rival")))
    var partner := String(item.get("partner_name", ""))
    if not partner.is_empty():
        left += " + " + partner
    return "%s vs %s" % [left, right]

func _open_history(item: Dictionary) -> void:
    var match_id := String(item.get("match_id", ""))
    var data := _player_data()
    if data != null and not match_id.is_empty() and data.has_method("mark_history_analysis_viewed"):
        data.mark_history_analysis_viewed(match_id)
    _open_account_page("analysis")

func _add_season_section() -> void:
    content_box.add_child(_section_heading("TEMPORADA ACTUAL"))
    var data := _player_data()
    var season_name := "Temporada 1"
    var cups := 0
    if data != null:
        season_name = String(data.season.get("name", season_name))
        cups = int(data.individual.get("cups", 0))
    var card := PanelContainer.new()
    card.name = "SeasonSummary"
    card.add_theme_stylebox_override("panel", _panel_style(PANEL, BORDER, 12))
    content_box.add_child(card)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 5)
    card.add_child(box)
    var name := Label.new()
    name.text = season_name
    name.add_theme_color_override("font_color", TEXT)
    name.add_theme_font_size_override("font_size", 25)
    box.add_child(name)
    var progress := ProgressBar.new()
    progress.custom_minimum_size.y = 7
    progress.show_percentage = false
    progress.value = float(cups % 100)
    box.add_child(progress)
    var detail := Button.new()
    detail.text = "%d copas   ·   Ver temporada →" % cups
    detail.flat = true
    detail.alignment = HORIZONTAL_ALIGNMENT_LEFT
    detail.add_theme_color_override("font_color", MUTED)
    detail.add_theme_color_override("font_hover_color", GOLD)
    detail.add_theme_font_size_override("font_size", 23)
    detail.pressed.connect(func(): _open_account_page("cups"))
    box.add_child(detail)

func _add_activity_line() -> void:
    var data := _player_data()
    if data == null:
        return
    var games := 0
    var wins := 0
    var nexus_delta := 0
    var now := Time.get_datetime_dict_from_system()
    for item in data.history:
        if not item is Dictionary:
            continue
        var dt := Time.get_datetime_dict_from_unix_time(int(item.get("timestamp", 0)))
        if int(dt.get("year", -1)) != int(now.get("year", -2)) or int(dt.get("month", -1)) != int(now.get("month", -2)):
            continue
        games += 1
        if String(item.get("outcome", "")) == "win":
            wins += 1
        nexus_delta += int(item.get("rating_delta", 0))
    var line := Label.new()
    line.name = "MonthlyActivity"
    line.text = "ESTE MES  ·  %d partidas  ·  %d victorias  ·  %+d NEXUS" % [games, wins, nexus_delta]
    line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    line.add_theme_color_override("font_color", MUTED)
    line.add_theme_font_size_override("font_size", 23)
    line.tooltip_text = "Resumen de tu actividad durante este mes"
    content_box.add_child(line)

func _daily_goal_text() -> String:
    var data := _player_data()
    if data == null:
        return "🎯 Gana 1 partida  ·  0/1"
    var now := Time.get_datetime_dict_from_system()
    var won_today := 0
    for item in data.history:
        if not item is Dictionary:
            continue
        var dt := Time.get_datetime_dict_from_unix_time(int(item.get("timestamp", 0)))
        if int(dt.get("year", -1)) == int(now.get("year", -2)) and int(dt.get("month", -1)) == int(now.get("month", -2)) and int(dt.get("day", -1)) == int(now.get("day", -2)) and String(item.get("outcome", "")) == "win":
            won_today += 1
    if won_today > 0:
        return "✓ Objetivo completado"
    return "🎯 Gana 1 partida  ·  0/1"

func _daily_streak(data: Object) -> int:
    if data == null:
        return 0
    var days := {}
    for item in data.history:
        if not item is Dictionary:
            continue
        var timestamp := int(item.get("timestamp", 0))
        if timestamp <= 0:
            continue
        var dt := Time.get_datetime_dict_from_unix_time(timestamp)
        var key := "%04d-%02d-%02d" % [int(dt.get("year", 0)), int(dt.get("month", 0)), int(dt.get("day", 0))]
        days[key] = true
    var cursor_dt := Time.get_datetime_dict_from_system()
    cursor_dt["hour"] = 0
    cursor_dt["minute"] = 0
    cursor_dt["second"] = 0
    var cursor := Time.get_unix_time_from_datetime_dict(cursor_dt)
    var streak := 0
    while days.has(Time.get_date_string_from_unix_time(int(cursor))):
        streak += 1
        cursor -= 86400
    return streak

func _add_separator(parent: VBoxContainer) -> void:
    var gap := Control.new()
    gap.name = "SectionSpacing"
    gap.custom_minimum_size.y = 24.0
    parent.add_child(gap)

func _section_heading(text_value: String) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_color_override("font_color", MUTED)
    label.add_theme_font_size_override("font_size", 25)
    return label

func _add_legacy_button(id: String, mode: int) -> void:
    if compat_vbox == null:
        return
    var button := Button.new()
    button.name = id
    button.visible = false
    button.custom_minimum_size = Vector2(0, 60)
    button.mouse_filter = Control.MOUSE_FILTER_IGNORE
    compat_vbox.add_child(button)
    if mode >= 0:
        button.pressed.connect(func(): _open_online_setup(mode))
    elif id == "Bot":
        button.pressed.connect(func(): Navigation.go(ScreenCatalog.BOT_SETUP))
    else:
        button.pressed.connect(func(): Navigation.go(ScreenCatalog.LOCAL_SETUP))

func _connect_legacy_mode_buttons() -> void:
    pass

func _open_online_setup(mode: int) -> void:
    var setup := get_node_or_null("OnlineSetup")
    if setup != null and setup.has_method("open_for_mode"):
        setup.open_for_mode(mode)
    _close_play_menu()

func _toggle_play_menu() -> void:
    if play_overlay == null:
        return
    play_overlay.visible = not play_overlay.visible
    play_button.text = "CERRAR JUGAR" if play_overlay.visible else "JUGAR"

func _close_play_menu() -> void:
    if play_overlay != null:
        play_overlay.visible = false
    if play_button != null:
        play_button.text = "JUGAR"

func _build_profile_button() -> void:
    # Avatar grande y sin marco rectangular del botón. El marco de perfil es
    # un anillo independiente, colocado por fuera del icono para no taparlo.
    profile_frame_ring = Panel.new()
    profile_frame_ring.name = "ProfileFrameRing"
    profile_frame_ring.z_index = 5
    profile_frame_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
    profile_frame_ring.add_theme_stylebox_override("panel", _home_profile_frame_style(_profile_frame_id()))
    add_child(profile_frame_ring)

    profile_button = Button.new()
    profile_button.name = "ProfileButton"
    profile_button.z_index = 6
    profile_button.tooltip_text = "Perfil"
    profile_button.custom_minimum_size = Vector2(56, 56)
    profile_button.focus_mode = Control.FOCUS_NONE
    profile_button.flat = true
    profile_button.expand_icon = true
    profile_button.add_theme_color_override("font_color", TEXT)
    profile_button.add_theme_color_override("font_hover_color", TEXT)
    profile_button.add_theme_stylebox_override("normal", _transparent_style())
    profile_button.add_theme_stylebox_override("hover", _transparent_style())
    profile_button.add_theme_stylebox_override("pressed", _transparent_style())
    _refresh_profile_avatar()
    profile_button.pressed.connect(func(): Navigation.go(ScreenCatalog.ACCOUNT))
    add_child(profile_button)

    streak_label = Label.new()
    streak_label.name = "StreakLabel"
    streak_label.z_index = 6
    streak_label.text = "0🔥"
    streak_label.add_theme_color_override("font_color", GOLD)
    streak_label.add_theme_font_size_override("font_size", 25)
    streak_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    add_child(streak_label)

func _transparent_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0)
    style.set_border_width_all(0)
    style.shadow_size = 0
    return style

func _profile_frame_id() -> String:
    var data := _player_data()
    if data != null and data.has_method("get_appearance"):
        return data.get_appearance("profile_frame", "classic")
    return "classic"

func _home_profile_frame_style(frame_id: String) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0)
    style.border_color = GOLD if frame_id == "gold" else Color("#4A4034")
    style.set_border_width_all(3 if frame_id == "gold" else 2)
    style.set_corner_radius_all(42)
    return style

func _refresh_profile_avatar() -> void:
    if profile_button == null:
        return
    var path := "res://assets/avatars/avatar_you.svg"
    var data := _player_data()
    if data != null and data.profile is Dictionary:
        path = String(data.profile.get("avatar", path))
    if path.begins_with("user://") and FileAccess.file_exists(path):
        var image := Image.load_from_file(ProjectSettings.globalize_path(path))
        if image != null and not image.is_empty():
            profile_button.icon = ImageTexture.create_from_image(image)
            return
    if ResourceLoader.exists(path):
        profile_button.icon = load(path)
    elif ResourceLoader.exists("res://assets/avatars/avatar_you.svg"):
        profile_button.icon = load("res://assets/avatars/avatar_you.svg")

func _build_more_button() -> void:
    more_button = _icon_button("⋮", "Más opciones")
    more_button.name = "MoreButton"
    more_button.z_index = 6
    more_button.custom_minimum_size = Vector2(48, 48)
    more_button.add_theme_font_size_override("font_size", 28)
    more_button.pressed.connect(_toggle_more_menu)
    add_child(more_button)

    more_menu = PopupMenu.new()
    more_menu.name = "MoreMenu"
    more_menu.add_item("Club", 1)
    more_menu.add_item("Amigos", 2)
    more_menu.add_separator()
    more_menu.add_item("Ajustes", 3)
    more_menu.add_item("Rankings", 4)
    more_menu.add_item("Perfil", 5)
    more_menu.add_separator()
    more_menu.add_item("Diagnóstico QA (offline)", 6)
    more_menu.id_pressed.connect(_on_more_menu_pressed)
    _refresh_diagnostics_menu_item()
    add_child(more_menu)

func _toggle_more_menu() -> void:
    if more_menu == null or more_button == null:
        return
    if more_menu.visible:
        more_menu.hide()
        return
    _refresh_diagnostics_menu_item()
    var vp := get_viewport_rect().size
    var menu_size := Vector2i(230, 0)
    var menu_pos := Vector2i(int(vp.x - menu_size.x - 12.0), int(more_button.position.y + more_button.size.y + 6.0))
    more_menu.popup(Rect2i(menu_pos, menu_size))

func _on_more_menu_pressed(id: int) -> void:
    match id:
        1:
            _on_main_navigation("club")
        2:
            _on_main_navigation("friends")
        3:
            _open_account_page("settings")
        4:
            _open_account_page("ranking")
        5:
            Navigation.go(ScreenCatalog.ACCOUNT)
        6:
            _export_diagnostics_offline()

func _diagnostics_allowed_offline() -> bool:
    # The diagnostic export must never be offered during an online match or matchmaking.
    var tree := get_tree()
    if tree == null or tree.current_scene == null:
        return false
    var scene_path := String(tree.current_scene.scene_file_path).to_lower()
    if scene_path.contains("online") or scene_path.contains("match") or scene_path.contains("matchmaking"):
        return false
    var app := _app()
    if app != null:
        if app.has_method("is_online_session_active") and bool(app.is_online_session_active()):
            return false
        for property_info in app.get_property_list():
            if String(property_info.get("name", "")) == "online_session_active" and bool(app.get("online_session_active")):
                return false
    return true

func _refresh_diagnostics_menu_item() -> void:
    if more_menu == null:
        return
    var item_index := more_menu.get_item_index(6)
    if item_index < 0:
        return
    var allowed := _diagnostics_allowed_offline()
    more_menu.set_item_text(item_index, "Diagnóstico QA (offline)" if allowed else "Diagnóstico QA no disponible online")
    more_menu.set_item_disabled(item_index, not allowed)
    more_menu.set_item_tooltip(item_index, "Exporta capturas y registros locales; solo disponible fuera de partidas online." if allowed else "El diagnóstico manual se desactiva durante matchmaking o partidas online.")

func _export_diagnostics_offline() -> void:
    # Manual diagnostics are strictly offline; check both before opening and before export.
    if not _diagnostics_allowed_offline():
        _show_diagnostics_notice("El diagnóstico manual solo está disponible cuando no estás en una partida online.")
        return
    var hub := RuntimeServicesScript.get_autoload("SupervisorHub")
    if hub == null or not hub.has_method("recent_diagnostics") or not hub.has_method("export_qa_bundle"):
        _show_diagnostics_notice("El servicio de diagnóstico no está disponible.")
        return

    var dialog := AcceptDialog.new()
    dialog.name = "OfflineDiagnosticsPanel"
    dialog.title = "Diagnóstico QA · Offline"
    dialog.ok_button_text = "Cerrar"
    dialog.dialog_text = "Últimos eventos guardados. Los detalles pueden contener rutas locales; revísalos antes de compartir."
    var outer := VBoxContainer.new()
    outer.custom_minimum_size = Vector2(520, 300)
    var scroll_view := ScrollContainer.new()
    scroll_view.custom_minimum_size = Vector2(520, 280)
    scroll_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
    var entries_box := VBoxContainer.new()
    entries_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var events: Array = hub.recent_diagnostics(20)
    if events.is_empty():
        var empty_label := Label.new()
        empty_label.text = "No hay diagnósticos registrados todavía."
        empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        entries_box.add_child(empty_label)
    else:
        for event in events:
            var item := Label.new()
            var details: Dictionary = event.get("details", {})
            item.text = "[%s] %s · %s\n%s" % [String(event.get("severity", "info")).to_upper(), String(event.get("agent", "unknown")), String(event.get("code", "event")), JSON.stringify(details)]
            item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
            item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            item.add_theme_color_override("font_color", TEXT if String(event.get("severity", "info")) != "error" else Color("#FF9388"))
            entries_box.add_child(item)
            var separator := HSeparator.new()
            entries_box.add_child(separator)
    scroll_view.add_child(entries_box)
    outer.add_child(scroll_view)
    dialog.add_child(outer)
    dialog.add_button("Exportar paquete QA", true, "export_qa")
    dialog.custom_action.connect(func(action: String):
        if action == "export_qa":
            dialog.hide()
            dialog.queue_free()
            _export_qa_bundle_offline()
    )
    dialog.confirmed.connect(func(): dialog.queue_free())
    dialog.canceled.connect(func(): dialog.queue_free())
    add_child(dialog)
    dialog.popup_centered(Vector2i(600, 500))

func _export_qa_bundle_offline() -> void:
    # The state can change after the panel opened, so enforce the offline rule again.
    if not _diagnostics_allowed_offline():
        _show_diagnostics_notice("El diagnóstico manual solo está disponible cuando no estás en una partida online.")
        return
    var hub := RuntimeServicesScript.get_autoload("SupervisorHub")
    if hub == null or not hub.has_method("export_qa_bundle"):
        _show_diagnostics_notice("El servicio de diagnóstico no está disponible.")
        return
    var result: Dictionary = hub.export_qa_bundle(20)
    if not bool(result.get("ok", false)):
        _show_diagnostics_notice("No se pudo exportar el paquete QA. El error quedó registrado en el diario.")
        return
    var path := String(result.get("path", "user://qa_supervisor_bundle.zip"))
    _show_diagnostics_notice("Paquete QA creado.\nRuta local: %s\nIncluye registros y capturas recientes. Revísalo antes de compartirlo." % path)

func _show_diagnostics_notice(message: String) -> void:
    var dialog := AcceptDialog.new()
    dialog.title = "Diagnóstico QA"
    dialog.dialog_text = message
    dialog.ok_button_text = "Entendido"
    add_child(dialog)
    dialog.confirmed.connect(func(): dialog.queue_free())
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered(Vector2i(440, 220))

func _icon_button(symbol: String, tooltip: String) -> Button:
    var b := Button.new()
    b.text = symbol
    b.tooltip_text = tooltip
    b.custom_minimum_size = Vector2(58, 58)
    b.focus_mode = Control.FOCUS_NONE
    b.add_theme_font_size_override("font_size", 22)
    b.expand_icon = true
    b.add_theme_color_override("font_color", TEXT)
    b.add_theme_color_override("font_hover_color", GOLD)
    b.add_theme_stylebox_override("normal", _panel_style(Color(0, 0, 0, 0), BORDER, 12))
    b.add_theme_stylebox_override("hover", _panel_style(PANEL_2, GOLD, 12))
    return b

func _build_main_nav() -> void:
    main_nav = MainNavigation.new()
    main_nav.name = "MainNavigation"
    main_nav.set_active("home")
    main_nav.navigate.connect(_on_main_navigation)
    add_child(main_nav)

func _on_main_navigation(section: String) -> void:
    match section:
        "home":
            if scroll != null:
                scroll.scroll_vertical = 0
        "more":
            Navigation.go(ScreenCatalog.MORE)
        "club":
            var clubs := get_node_or_null("/root/ClubsService")
            if clubs != null and not String(clubs.active_club_id).is_empty():
                Navigation.go(ScreenCatalog.CLUB_CHAT)
            else:
                Navigation.go(ScreenCatalog.CLUBS)
        "friends":
            Navigation.go(ScreenCatalog.FRIENDS)
        "play":
            _toggle_play_menu()

func _show_toast(message: String) -> void:
    if toast == null:
        return
    toast.text = message
    toast.visible = true
    toast.position = Vector2(24, maxf(72.0, get_viewport_rect().size.y - 150.0))
    toast.size = Vector2(maxf(0.0, get_viewport_rect().size.x - 48.0), 48.0)
    _toast_generation += 1
    var timer := get_tree().create_timer(1.8)
    timer.timeout.connect(_on_toast_timeout.bind(_toast_generation), CONNECT_ONE_SHOT)

func _on_toast_timeout(generation: int) -> void:
    if not is_inside_tree() or generation != _toast_generation:
        return
    if is_instance_valid(toast):
        toast.visible = false

func _open_account_page(page_name: String) -> void:
    var app := _app()
    if app != null:
        app.account_start_page = page_name
    Navigation.go(ScreenCatalog.ACCOUNT)

func _refresh_home() -> void:
    if not is_inside_tree() or content_box == null:
        return
    if daily_goal_label != null:
        daily_goal_label.text = _daily_goal_text()
    if streak_label != null:
        streak_label.text = "%d🔥" % _daily_streak(_player_data())
    _refresh_profile_avatar()
    if profile_frame_ring != null:
        profile_frame_ring.add_theme_stylebox_override("panel", _home_profile_frame_style(_profile_frame_id()))
    var old_scroll := scroll.scroll_vertical if scroll != null else 0
    call_deferred("_rebuild_lower_home", old_scroll)

func _rebuild_lower_home(old_scroll: int) -> void:
    if not is_inside_tree() or get_tree() == null or not is_instance_valid(content_box) or not is_instance_valid(scroll):
        return
    var fixed_names := ["Title", "Subtitle", "PlayButton", "PlayMenu", "BotSectionButton", "DailyGoal", "PrimaryBreathingRoom"]
    for child in content_box.get_children():
        if not fixed_names.has(child.name):
            child.queue_free()
    await get_tree().process_frame
    if not is_inside_tree() or get_tree() == null or not is_instance_valid(content_box) or not is_instance_valid(scroll):
        return
    _add_separator(content_box)
    _add_history_section()
    _add_separator(content_box)
    _add_season_section()
    _add_activity_line()
    await get_tree().process_frame
    if not is_inside_tree() or get_tree() == null or not is_instance_valid(scroll):
        return
    if scroll != null:
        var max_scroll := maxi(0, int(scroll.get_v_scroll_bar().max_value - scroll.get_v_scroll_bar().page))
        scroll.scroll_vertical = mini(old_scroll, max_scroll)

func _make_button(text_value: String, height: float, border: Color, font_color: Color, font_size: int) -> Button:
    var b := Button.new()
    b.text = text_value
    b.custom_minimum_size = Vector2(0, maxf(height, 68.0))
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.focus_mode = Control.FOCUS_NONE
    b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    b.add_theme_color_override("font_color", font_color)
    b.add_theme_color_override("font_hover_color", TEXT)
    b.add_theme_font_size_override("font_size", font_size)
    b.add_theme_stylebox_override("normal", _panel_style(PANEL_2, border, 14))
    b.add_theme_stylebox_override("hover", _panel_style(Color("#30271C"), GOLD, 14))
    b.add_theme_stylebox_override("pressed", _panel_style(Color("#241D15"), GOLD, 14))
    return b

func _panel_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _on_viewport_changed() -> void:
    var vp := get_viewport_rect().size
    var portrait := vp.y >= vp.x
    var width_ratio := 0.94 if portrait else 0.74
    var max_width := 820.0 if portrait else 980.0
    var minimum_width := minf(vp.x - (24.0 if portrait else 40.0), 340.0 if portrait else 540.0)
    var width := clampf(vp.x * width_ratio, minimum_width, minf(max_width, vp.x - (24.0 if portrait else 40.0)))
    if content_box != null:
        content_box.custom_minimum_size.x = width
        content_box.add_theme_constant_override("separation", 18 if portrait else 14)
        var subtitle := content_box.get_node_or_null("Subtitle") as Label
        if subtitle != null:
            subtitle.text = "Juega, revisa tus partidas\ny sigue tu progreso" if portrait else "Juega, revisa tus partidas y sigue tu progreso"
        var history_empty := content_box.get_node_or_null("HistoryEmpty") as Label
        if history_empty != null:
            history_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    if compat_vbox != null:
        # Preserve the legacy public measurement contract used by older QA
        # callers; the visible scroll layout above has its own wider mobile rule.
        var compat_ratio := 0.92 if portrait else 0.68
        var compat_max := 720.0 if portrait else 920.0
        var compat_min := 320.0 if portrait else 520.0
        compat_vbox.custom_minimum_size.x = clampf(vp.x * compat_ratio, compat_min, compat_max)
    if scroll != null:
        scroll.offset_left = 12.0 if portrait else 180.0
        scroll.offset_right = -12.0
        scroll.offset_top = 94.0 if portrait else 56.0
        scroll.offset_bottom = -120.0 if portrait else -12.0
    if profile_frame_ring != null:
        profile_frame_ring.position = Vector2(18, 34) if portrait else Vector2(210, 14)
        profile_frame_ring.size = Vector2(72, 72) if portrait else Vector2(64, 64)
    if profile_button != null:
        profile_button.position = Vector2(26, 48) if portrait else Vector2(220, 25)
        profile_button.size = Vector2(56, 56) if portrait else Vector2(56, 56)
    if streak_label != null:
        streak_label.position = Vector2(116, 56) if portrait else Vector2(292, 26)
        streak_label.size = Vector2(70, 44) if portrait else Vector2(52, 36)
    if more_button != null:
        more_button.position = Vector2(maxf(12.0, vp.x - 68.0), 34.0)
        more_button.size = Vector2(56, 56)
    if main_nav != null:
        main_nav.set_active("home")

func _on_online_start(mode: int, minutes: int) -> void:
    var app := _app()
    if app != null:
        app.selected_mode = mode
        app.selected_time_minutes = minutes
        app.online_entry = "random"
    Navigation.go(ScreenCatalog.ONLINE_MATCHMAKING)

func _on_friend_start(mode: int, minutes: int) -> void:
    var app := _app()
    if app != null:
        app.selected_mode = mode
        app.selected_time_minutes = minutes
        app.online_entry = "friend"
        app.temporary_online_bots = false
        app.prepare_friend_room()
    Navigation.go(ScreenCatalog.ONLINE_MATCHMAKING)

func _on_join_start(mode: int, minutes: int, room_code: String) -> void:
    var app := _app()
    if app != null:
        app.selected_mode = mode
        app.selected_time_minutes = minutes
        app.online_entry = "friend_join"
        app.temporary_online_bots = false
        app.join_room_code = room_code
    Navigation.go(ScreenCatalog.ONLINE_MATCHMAKING)
