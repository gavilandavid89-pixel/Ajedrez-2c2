extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

var list_box: VBoxContainer
var friends_service: Node

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.configure_main_content_margin(self, margin, 14.0, 120.0, 16.0, 16.0, 174.0, 16.0, 16.0)
    add_child(margin)
    var compact := Factory.is_landscape(self)
    var scroll := ScrollContainer.new()
    scroll.name = "FriendsScroll"
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    margin.add_child(scroll)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 8 if compact else 12)
    body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(body)
    Factory.make_top_bar("Amigos", body, func(): Navigation.go(ScreenCatalog.MAIN_MENU))
    list_box = body
    friends_service = get_node_or_null("/root/FriendsService")
    if friends_service != null and friends_service.has_signal("changed"):
        friends_service.changed.connect(_refresh)
    _refresh()
    Factory.attach_main_nav(self, "friends", _on_nav)

func _refresh() -> void:
    if list_box == null:
        return
    for child in list_box.get_children():
        if child.name != "TopBar":
            child.queue_free()
    var pending: Array = [] if friends_service == null else friends_service.get_pending_requests()
    if not pending.is_empty():
        list_box.add_child(Factory.section_title("SOLICITUDES PENDIENTES"))
        for request in pending:
            _add_request_card(request)
    list_box.add_child(Factory.section_title("TUS AMIGOS"))
    var rows: Array = [] if friends_service == null else friends_service.get_friends()
    if rows.is_empty():
        var empty := Label.new()
        empty.text = "Todavía no tienes amigos aceptados.\nDespués de una partida podrás enviar una solicitud."
        empty.add_theme_color_override("font_color", Factory.colors()["muted"])
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        list_box.add_child(empty)
        return
    var compact := Factory.is_landscape(self)
    for friend in rows:
        var card := Button.new()
        card.custom_minimum_size.y = 76 if compact else 100
        card.alignment = HORIZONTAL_ALIGNMENT_LEFT
        card.add_theme_stylebox_override("normal", Factory.panel_style())
        card.add_theme_stylebox_override("hover", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 12))
        card.add_theme_stylebox_override("pressed", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 12))
        card.pressed.connect(func(): _open_profile(friend))
        list_box.add_child(card)
        var row := HBoxContainer.new()
        row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        row.offset_left = 10
        row.offset_right = -10
        row.offset_top = 4
        row.offset_bottom = -4
        row.mouse_filter = Control.MOUSE_FILTER_IGNORE
        row.add_theme_constant_override("separation", 10)
        card.add_child(row)
        var icon := Label.new()
        icon.text = String(friend.get("icon", "♟"))
        icon.custom_minimum_size = Vector2(52, 52) if compact else Vector2(68, 68)
        icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        icon.add_theme_font_size_override("font_size", 28 if compact else 34)
        row.add_child(icon)
        var info := VBoxContainer.new()
        info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(info)
        var name := Label.new()
        name.text = String(friend.get("name", "Jugador"))
        name.add_theme_color_override("font_color", Factory.colors()["text"])
        name.add_theme_font_size_override("font_size", 22 if compact else 28)
        name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        info.add_child(name)
        var status := Label.new()
        status.text = ("En línea" if bool(friend.get("online", false)) else "NEXUS %d" % int(friend.get("nexus", 0)))
        status.add_theme_color_override("font_color", Factory.colors()["muted"])
        status.add_theme_font_size_override("font_size", 17 if compact else 21)
        status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        info.add_child(status)


func _add_request_card(request: Dictionary) -> void:
    var compact := Factory.is_landscape(self)
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 10))
    list_box.add_child(panel)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 6)
    panel.add_child(row)
    var info := VBoxContainer.new()
    info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(info)
    var name := Label.new()
    name.text = "%s  %s" % [String(request.get("icon", "♟")), String(request.get("name", "Jugador"))]
    name.add_theme_font_size_override("font_size", 22 if compact else 28)
    info.add_child(name)
    var source := Label.new()
    source.text = "Solicitud · NEXUS %d" % int(request.get("nexus", 0))
    source.add_theme_color_override("font_color", Factory.colors()["muted"])
    source.add_theme_font_size_override("font_size", 17 if compact else 21)
    info.add_child(source)
    var accept := Factory.make_secondary("ACEPTAR", 48)
    accept.pressed.connect(func():
        if friends_service != null:
            friends_service.accept_request(String(request.get("id", "")))
    )
    row.add_child(accept)
    var reject := Factory.make_secondary("RECHAZAR", 48)
    reject.pressed.connect(func():
        if friends_service != null:
            friends_service.reject_request(String(request.get("id", "")))
    )
    row.add_child(reject)

func _open_profile(friend: Dictionary) -> void:
    var app := RuntimeServicesScript.get_autoload("App")
    if app != null:
        app.target_profile_id = String(friend.get("id", ""))
        app.target_profile_name = String(friend.get("name", "Jugador"))
    Navigation.go(ScreenCatalog.PLAYER_PROFILE)

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club":
            var clubs := get_node_or_null("/root/ClubsService")
            Navigation.go(ScreenCatalog.CLUB_CHAT if clubs != null and not String(clubs.active_club_id).is_empty() else ScreenCatalog.CLUBS)
        "friends": pass
        "more": Navigation.go(ScreenCatalog.MORE)
