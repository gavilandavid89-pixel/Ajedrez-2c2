extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")
const ProfileDataScript = preload("res://domain/player/profile_data.gd")

var app: Node
var friends: Node
var profile_id := ""
var profile_name := "Jugador"
var add_friend_button: Button

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    app = RuntimeServicesScript.get_autoload("App")
    friends = RuntimeServicesScript.get_autoload("FriendsService")
    if app != null:
        profile_id = String(app.target_profile_id)
        profile_name = String(app.target_profile_name)
        app.target_profile_id = ""
        app.target_profile_name = ""
    if profile_name.is_empty():
        profile_name = "Jugador"

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.configure_main_content_margin(self, margin, 14.0, 120.0, 16.0, 16.0, 174.0, 16.0, 16.0)
    add_child(margin)

    var scroll := ScrollContainer.new()
    scroll.name = "ProfileScroll"
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    margin.add_child(scroll)

    var box := VBoxContainer.new()
    box.name = "ProfileContent"
    box.add_theme_constant_override("separation", 10)
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(box)

    var top := Factory.make_top_bar("Perfil", box, func(): Navigation.go(ScreenCatalog.MAIN_MENU))
    top.name = "TopBar"
    _build_profile(box)
    Factory.attach_main_nav(self, "friends", _on_nav)

func _profile_public_data() -> Dictionary:
    var presets := {
        "mica": {
            "title": "Promesa",
            "nexus": 1248, "games_2c2": 143, "wins_2c2": 98, "losses_2c2": 38, "draws_2c2": 7, "cups_2c2": 24,
            "nexus_1c1": 1176, "games_1c1": 86, "wins_1c1": 52, "losses_1c1": 29, "draws_1c1": 5, "cups_1c1": 13,
            "club": "Los Caballos", "online": true,
            "partner": "Alex", "partner_nexus": 1320, "partner_games": 34, "partner_wins": 25, "partner_losses": 7, "partner_draws": 2,
            "recent": [["2c2", "Victoria", "Alex + Luna"], ["1c1", "Victoria", "Noah"], ["2c2", "Derrota", "Alex + Leo"], ["1c1", "Victoria", "Sofia"], ["2c2", "Victoria", "Alex + Ana"]]
        },
        "alex": {
            "title": "Dedicado",
            "nexus": 1320, "games_2c2": 118, "wins_2c2": 79, "losses_2c2": 33, "draws_2c2": 6, "cups_2c2": 19,
            "nexus_1c1": 1410, "games_1c1": 151, "wins_1c1": 96, "losses_1c1": 46, "draws_1c1": 9, "cups_1c1": 28,
            "club": "Los Caballos", "online": false,
            "partner": "Mica", "partner_nexus": 1310, "partner_games": 34, "partner_wins": 25, "partner_losses": 7, "partner_draws": 2,
            "recent": [["1c1", "Victoria", "Noah"], ["2c2", "Victoria", "Mica + Luna"], ["1c1", "Derrota", "Sofia"], ["2c2", "Victoria", "Mica + Leo"], ["1c1", "Victoria", "Luna"]]
        },
        "rival1": {
            "title": "Luchador",
            "nexus": 846, "games_2c2": 67, "wins_2c2": 35, "losses_2c2": 28, "draws_2c2": 4, "cups_2c2": 8,
            "nexus_1c1": 902, "games_1c1": 74, "wins_1c1": 39, "losses_1c1": 31, "draws_1c1": 4, "cups_1c1": 7,
            "club": "Torre Norte", "online": false,
            "partner": "Luna", "partner_nexus": 930, "partner_games": 8, "partner_wins": 5, "partner_losses": 3, "partner_draws": 0,
            "recent": [["2c2", "Victoria", "Luna + Noah"], ["1c1", "Derrota", "Mica"], ["2c2", "Derrota", "Alex + Mica"], ["1c1", "Victoria", "Leo"], ["2c2", "Victoria", "Luna + Sofia"]]
        }
    }
    if presets.has(profile_id):
        return presets[profile_id].duplicate(true)
    return {
        "title": "Jugador", "nexus": 1000, "games_2c2": 24, "wins_2c2": 13, "losses_2c2": 10, "draws_2c2": 1, "cups_2c2": 3,
        "nexus_1c1": 1000, "games_1c1": 24, "wins_1c1": 13, "losses_1c1": 10, "draws_1c1": 1, "cups_1c1": 3,
        "club": "Sin club", "online": false, "partner": "", "partner_nexus": 0, "partner_games": 0, "partner_wins": 0, "partner_losses": 0, "partner_draws": 0,
        "recent": [["2c2", "Victoria", "Rival + Rival"], ["1c1", "Derrota", "Jugador"]]
    }

func _build_profile(box: VBoxContainer) -> void:
    var data := _profile_public_data()
    var known_profile := ProfileDataScript.get_profile(profile_id)
    var avatar := String(known_profile.get("avatar", "res://assets/avatars/avatar_you.svg"))
    var title := String(data.get("title", known_profile.get("title", "Jugador")))
    var is_friend: bool = friends != null and friends.is_friend(profile_id)

    var header := PanelContainer.new()
    header.name = "PublicHeader"
    header.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 14))
    box.add_child(header)
    var header_box := HBoxContainer.new()
    header_box.add_theme_constant_override("separation", 12)
    header.add_child(header_box)

    var avatar_label := Label.new()
    avatar_label.custom_minimum_size = Vector2(78, 78)
    avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    avatar_label.add_theme_font_size_override("font_size", 50)
    header_box.add_child(avatar_label)

    var identity := VBoxContainer.new()
    identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    identity.add_theme_constant_override("separation", 1)
    header_box.add_child(identity)

    var name := Label.new()
    name.text = profile_name
    name.add_theme_font_size_override("font_size", 27)
    name.add_theme_color_override("font_color", Factory.colors()["text"])
    identity.add_child(name)

    var title_label := Label.new()
    title_label.text = title
    title_label.add_theme_color_override("font_color", Factory.colors()["gold"])
    identity.add_child(title_label)

    var status := Label.new()
    status.text = ("● En línea" if bool(data.get("online", false)) else "○ Desconectado")
    status.add_theme_color_override("font_color", Factory.colors()["green"] if bool(data.get("online", false)) else Factory.colors()["muted"])
    identity.add_child(status)

    var nexus := Label.new()
    nexus.text = "NEXUS  %d" % int(data.get("nexus", 1000))
    nexus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    nexus.add_theme_font_size_override("font_size", 27)
    nexus.add_theme_color_override("font_color", Factory.colors()["gold"])
    header_box.add_child(nexus)

    add_friend_button = Factory.make_primary("AMIGOS" if is_friend else "AÑADIR AMIGO", 56)
    add_friend_button.name = "AddFriend"
    add_friend_button.disabled = profile_id.is_empty() or is_friend
    add_friend_button.pressed.connect(_send_friend_request)
    box.add_child(add_friend_button)

    if not String(data.get("club", "Sin club")).is_empty() and String(data.get("club", "Sin club")) != "Sin club":
        var club_line := _make_info_line("♜", "Club", String(data["club"]))
        box.add_child(club_line)

    _add_section_title(box, "COMPETITIVO")
    var competitive := _make_competitive_card(data)
    box.add_child(competitive)

    _add_section_title(box, "PAREJA 2c2")
    box.add_child(_make_pair_card(data))

    _add_section_title(box, "🏆 PROGRESIÓN")
    box.add_child(_make_progression_card(data))

    _add_section_title(box, "ÚLTIMAS PARTIDAS")
    box.add_child(_make_recent_matches_card(data))

func _add_section_title(box: VBoxContainer, text_value: String) -> void:
    var title := Factory.section_title(text_value)
    title.add_theme_font_size_override("font_size", 22)
    title.add_theme_color_override("font_color", Factory.colors()["muted"])
    box.add_child(title)

func _make_competitive_card(data: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style())
    var rows := VBoxContainer.new()
    rows.add_theme_constant_override("separation", 8)
    card.add_child(rows)
    var head := HBoxContainer.new()
    rows.add_child(head)
    _add_stat_label(head, "", "1c1", true)
    _add_stat_label(head, "", "2c2", true)
    var values := HBoxContainer.new()
    rows.add_child(values)
    _add_stat_label(values, "NEXUS", "%d" % int(data.get("nexus_1c1", 1000)), false)
    _add_stat_label(values, "NEXUS", "%d" % int(data.get("nexus", 1000)), false)
    _add_stat_label(values, "Partidas", "%d" % int(data.get("games_1c1", 0)), false)
    _add_stat_label(values, "Partidas", "%d" % int(data.get("games_2c2", 0)), false)
    var win_row := HBoxContainer.new()
    rows.add_child(win_row)
    _add_stat_label(win_row, "Victorias", "%d%%" % _win_rate(int(data.get("wins_1c1", 0)), int(data.get("games_1c1", 0))), false)
    _add_stat_label(win_row, "Victorias", "%d%%" % _win_rate(int(data.get("wins_2c2", 0)), int(data.get("games_2c2", 0))), false)
    return card

func _add_stat_label(row: HBoxContainer, label_text: String, value: String, header: bool) -> void:
    var box := VBoxContainer.new()
    box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    box.add_theme_constant_override("separation", 1)
    row.add_child(box)
    var label := Label.new()
    label.text = value if header else label_text
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_color_override("font_color", Factory.colors()["text"] if header else Factory.colors()["muted"])
    label.add_theme_font_size_override("font_size", 24 if header else 22)
    box.add_child(label)
    if not header:
        var value_label := Label.new()
        value_label.text = value
        value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        value_label.add_theme_color_override("font_color", Factory.colors()["text"])
        box.add_child(value_label)

func _make_pair_card(data: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style())
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 4)
    card.add_child(box)
    var partner := String(data.get("partner", ""))
    if partner.is_empty() or int(data.get("partner_games", 0)) < 1:
        var empty := Label.new()
        empty.text = "Sin pareja 2c2 actual"
        empty.add_theme_color_override("font_color", Factory.colors()["muted"])
        box.add_child(empty)
        return card
    var name := Label.new()
    name.text = "%s + %s" % [profile_name, partner]
    name.add_theme_font_size_override("font_size", 25)
    box.add_child(name)
    var meta := Label.new()
    meta.text = "NEXUS %d  ·  %d partidas  ·  %d%% victorias" % [int(data.get("partner_nexus", 0)), int(data.get("partner_games", 0)), _win_rate(int(data.get("partner_wins", 0)), int(data.get("partner_games", 0)))]
    meta.add_theme_color_override("font_color", Factory.colors()["muted"])
    box.add_child(meta)
    return card

func _make_progression_card(data: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style())
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 20)
    card.add_child(row)
    _add_progress_item(row, "1c1", int(data.get("cups_1c1", 0)))
    _add_progress_item(row, "2c2", int(data.get("cups_2c2", 0)))
    return card

func _add_progress_item(row: HBoxContainer, mode: String, cups: int) -> void:
    var item := VBoxContainer.new()
    item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(item)
    var mode_label := Label.new()
    mode_label.text = mode
    mode_label.add_theme_color_override("font_color", Factory.colors()["muted"])
    item.add_child(mode_label)
    var cup_label := Label.new()
    cup_label.text = "🏆 %d" % cups
    cup_label.add_theme_font_size_override("font_size", 28)
    cup_label.add_theme_color_override("font_color", Factory.colors()["gold"])
    item.add_child(cup_label)

func _make_recent_matches_card(data: Dictionary) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style())
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 3)
    card.add_child(box)
    for item in data.get("recent", []):
        if not item is Array or item.size() < 3:
            continue
        var row := HBoxContainer.new()
        row.custom_minimum_size.y = 34
        box.add_child(row)
        var mode := Label.new()
        mode.text = String(item[0])
        mode.custom_minimum_size.x = 42
        mode.add_theme_color_override("font_color", Factory.colors()["gold"])
        row.add_child(mode)
        var result := Label.new()
        result.text = "✓" if String(item[1]) == "Victoria" else "✕"
        result.custom_minimum_size.x = 28
        result.add_theme_color_override("font_color", Factory.colors()["green"] if String(item[1]) == "Victoria" else Factory.colors()["red"])
        row.add_child(result)
        var opponent := Label.new()
        opponent.text = "vs %s" % String(item[2])
        opponent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        opponent.add_theme_color_override("font_color", Factory.colors()["text"])
        row.add_child(opponent)
    var more := Label.new()
    more.text = "Ver más  ›"
    more.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    more.add_theme_color_override("font_color", Factory.colors()["muted"])
    box.add_child(more)
    return card

func _make_info_line(icon: String, label_text: String, value: String) -> PanelContainer:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel"], Factory.colors()["border"], 10))
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    card.add_child(row)
    var icon_label := Label.new()
    icon_label.text = icon
    icon_label.add_theme_font_size_override("font_size", 26)
    row.add_child(icon_label)
    var label := Label.new()
    label.text = label_text
    label.add_theme_color_override("font_color", Factory.colors()["muted"])
    row.add_child(label)
    var value_label := Label.new()
    value_label.text = value
    value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    value_label.add_theme_color_override("font_color", Factory.colors()["text"])
    row.add_child(value_label)
    return card

func _win_rate(wins: int, games: int) -> int:
    if games <= 0:
        return 0
    return roundi(float(wins) * 100.0 / float(games))

func _send_friend_request() -> void:
    if friends == null or profile_id.is_empty() or add_friend_button == null:
        return
    if friends.send_request(profile_id, profile_name, "♟", int(_profile_public_data().get("nexus", 1000)), "profile"):
        add_friend_button.text = "SOLICITUD ENVIADA"
        add_friend_button.disabled = true

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club": Navigation.go(ScreenCatalog.CLUBS)
        "friends": Navigation.go(ScreenCatalog.FRIENDS)
        "more": Navigation.go(ScreenCatalog.MORE)
