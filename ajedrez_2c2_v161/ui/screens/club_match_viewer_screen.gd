extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    var app := RuntimeServicesScript.get_autoload("App")
    var chat := RuntimeServicesScript.get_autoload("ClubChatService")
    var club_id := "" if app == null else String(app.club_match_view_club_id)
    var match_id := "" if app == null else String(app.club_match_view_id)
    var match_data: Dictionary = {}
    if chat != null:
        match_data = chat.get_match(club_id, match_id)
    if app != null:
        app.club_match_view_id = ""
        app.club_match_view_club_id = ""
    if match_data.is_empty():
        Navigation.go(ScreenCatalog.CLUB_CHAT)
        return
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.configure_main_content_margin(self, margin, 14.0, 120.0, 16.0, 16.0, 174.0, 16.0, 16.0)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 10)
    margin.add_child(root)
    var club_back := Factory.make_top_bar("Partida amistosa", root, func(): Navigation.go(ScreenCatalog.CLUB_CHAT))
    club_back.name = "TopBar"
    var status := Label.new()
    status.text = "👁  OBSERVANDO" if String(match_data.get("status", "")) == "live" else "🏆  FINALIZADA"
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 25)
    status.add_theme_color_override("font_color", Factory.colors()["gold"])
    root.add_child(status)
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 14))
    root.add_child(card)
    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 7)
    card.add_child(box)
    var mode := Label.new()
    mode.text = "AJEDREZ %s · AMISTOSA" % String(match_data.get("mode", "1c1")).to_upper()
    mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    mode.add_theme_color_override("font_color", Factory.colors()["muted"])
    box.add_child(mode)
    var players := Label.new()
    var names: Array[String] = []
    for item in match_data.get("players", []):
        names.append(String(item))
    players.text = "  vs  ".join(names) if not names.is_empty() else "Jugadores del club"
    players.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    players.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    players.add_theme_font_size_override("font_size", 28)
    players.add_theme_color_override("font_color", Factory.colors()["text"])
    box.add_child(players)
    var board := GridContainer.new()
    board.columns = 8
    board.name = "SpectatorBoard"
    board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
    board.custom_minimum_size = Vector2(288, 288)
    root.add_child(board)
    _build_board(board)
    var note := Label.new()
    if String(match_data.get("status", "")) == "live":
        note.text = "Los miembros del club pueden observar esta amistosa."
    else:
        note.text = "La partida permanece en el chat hasta que los mensajes la desplacen."
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    note.add_theme_color_override("font_color", Factory.colors()["muted"])
    root.add_child(note)
    var back := Factory.make_secondary("VOLVER AL CHAT", 48)
    back.pressed.connect(func(): Navigation.go(ScreenCatalog.CLUB_CHAT))
    root.add_child(back)
    Factory.attach_main_nav(self, "club", _on_nav)

func _build_board(board: GridContainer) -> void:
    for i in range(64):
        var square := PanelContainer.new()
        var box := StyleBoxFlat.new()
        box.bg_color = Color("#D5A84E") if ((i / 8 + i % 8) % 2 == 0) else Color("#241D15")
        box.set_border_width_all(0)
        square.add_theme_stylebox_override("panel", box)
        square.custom_minimum_size = Vector2(36, 36)
        board.add_child(square)

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club": Navigation.go(ScreenCatalog.CLUB_CHAT)
        "friends": Navigation.go(ScreenCatalog.FRIENDS)
        "more": Navigation.go(ScreenCatalog.MORE)
