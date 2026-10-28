extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")

var clubs: Node
var club: Dictionary
var content: VBoxContainer

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(margin)
    Factory.configure_main_content_margin(self, margin, 14.0, 16.0, 16.0, 16.0, 16.0, 16.0, 16.0)
    margin.custom_minimum_size.x = 0.0
    var scroll := ScrollContainer.new()
    scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.custom_minimum_size.x = 0.0
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    margin.add_child(scroll)
    content = VBoxContainer.new()
    content.add_theme_constant_override("separation", 10)
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.custom_minimum_size.x = 0.0
    scroll.add_child(content)
    clubs = get_node_or_null("/root/ClubsService")
    club = {} if clubs == null else clubs.get_selected_club()
    if club.is_empty() and clubs != null:
        club = clubs.get_active_club()
    if club.is_empty():
        Navigation.go(ScreenCatalog.CLUBS)
        return
    if clubs != null:
        clubs.mark_detail_seen(String(club.get("id", "")))
    Factory.make_top_bar(String(club.get("name", "Club")), content, func(): Navigation.go(ScreenCatalog.CLUBS))
    _build_detail()

func _build_detail() -> void:
    var hero := PanelContainer.new()
    hero.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 14))
    content.add_child(hero)
    var v := VBoxContainer.new()
    v.alignment = BoxContainer.ALIGNMENT_CENTER
    v.add_theme_constant_override("separation", 6)
    hero.add_child(v)
    var icon := Label.new()
    icon.text = String(club.get("icon", "♟"))
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 42)
    v.add_child(icon)
    var name := Label.new()
    name.text = String(club.get("name", "Club"))
    name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name.add_theme_font_size_override("font_size", 22)
    name.add_theme_color_override("font_color", Factory.colors()["text"])
    v.add_child(name)
    var desc := Label.new()
    desc.text = String(club.get("description", ""))
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    desc.custom_minimum_size.x = 0.0
    desc.add_theme_font_size_override("font_size", 16 if get_viewport_rect().size.x < 560.0 else 18)
    desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    desc.add_theme_color_override("font_color", Factory.colors()["muted"])
    v.add_child(desc)

    var meta := PanelContainer.new()
    meta.add_theme_stylebox_override("panel", Factory.panel_style())
    content.add_child(meta)
    var meta_box := VBoxContainer.new()
    meta_box.add_theme_constant_override("separation", 6)
    meta.add_child(meta_box)
    var members_link := Factory.make_secondary("MIEMBROS · %d →" % int(club.get("members", 0)), 46)
    members_link.name = "MembersLink"
    members_link.custom_minimum_size = Vector2(0.0, 48.0)
    members_link.add_theme_font_size_override("font_size", 18 if get_viewport_rect().size.x < 560.0 else 22)
    members_link.autowrap_mode = TextServer.AUTOWRAP_OFF
    members_link.clip_text = true
    members_link.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    members_link.pressed.connect(func(): Navigation.go(ScreenCatalog.CLUB_MEMBERS))
    meta_box.add_child(members_link)
    meta_box.add_child(_info("Fundador", String(club.get("founder", "Jugador"))))
    meta_box.add_child(_info("Acceso", _access_text()))

    content.add_child(Factory.section_title("JERARQUÍA"))
    var hierarchy := Label.new()
    hierarchy.text = "♚ Rey 1 · ♛ Dama 2 · ♜ Torre 3 · ♝ Alfil 5 · ♞ Caballo 9 · ♟ Peón · máximo 50"
    hierarchy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hierarchy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    hierarchy.custom_minimum_size.x = 0.0
    hierarchy.add_theme_font_size_override("font_size", 17 if get_viewport_rect().size.x < 560.0 else 20)
    hierarchy.add_theme_color_override("font_color", Factory.colors()["muted"])
    content.add_child(hierarchy)

    _build_join_requests()

    content.add_child(Factory.section_title("MIEMBROS DESTACADOS"))
    var members := _mock_members()
    for member in members:
        var row := HBoxContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.custom_minimum_size = Vector2(0.0, 56.0)
        row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
        row.clip_contents = true
        row.add_theme_constant_override("separation", 8)
        content.add_child(row)
        var avatar := Label.new()
        avatar.text = String(member.get("icon", "♟"))
        avatar.custom_minimum_size.x = 42
        avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        avatar.add_theme_font_size_override("font_size", 22)
        row.add_child(avatar)
        var n := Label.new()
        n.text = "%s  ·  %s" % [String(member.get("name", "Jugador")), String(clubs.role_label(String(member.get("role", "peon"))) if clubs != null and clubs.has_method("role_label") else "Peón · Miembro")]
        n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        n.custom_minimum_size.x = 0.0
        n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        n.autowrap_mode = TextServer.AUTOWRAP_OFF
        n.clip_text = true
        n.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        n.add_theme_font_size_override("font_size", 15 if get_viewport_rect().size.x < 560.0 else 18)
        n.add_theme_color_override("font_color", Factory.colors()["text"])
        row.add_child(n)
        var profile := Factory.make_secondary("PERFIL", 42)
        profile.custom_minimum_size = Vector2(68.0, 48.0)
        profile.autowrap_mode = TextServer.AUTOWRAP_OFF
        profile.clip_text = true
        profile.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        profile.add_theme_font_size_override("font_size", 12 if get_viewport_rect().size.x < 560.0 else 15)
        profile.pressed.connect(func(): _show_member(member))
        row.add_child(profile)

    if clubs != null and clubs.is_joined(String(club.get("id", ""))):
        var chat := Factory.make_primary("ABRIR CHAT DEL CLUB", 52)
        chat.pressed.connect(func(): Navigation.go(ScreenCatalog.CLUB_CHAT))
        content.add_child(chat)
    else:
        var access := String(club.get("access_type", "public"))
        var action_text := "UNIRME AL CLUB" if access == "public" else ("SOLICITAR INGRESO" if access == "nexus" else "ACEPTAR INVITACIÓN")
        var join := Factory.make_primary(action_text, 52)
        join.pressed.connect(_join_club)
        if access == "invite":
            var local_id := String(clubs.local_id()) if clubs != null and clubs.has_method("local_id") else "local_player"
            join.disabled = clubs == null or not clubs.has_invitation(String(club.get("id", "")), local_id)
        content.add_child(join)


func _build_join_requests() -> void:
    if clubs == null or not clubs.has_method("can_approve_requests"):
        return
    var club_id := String(club.get("id", ""))
    if not clubs.can_approve_requests(club_id):
        return
    var requests: Array = clubs.get_join_requests(club_id) if clubs.has_method("get_join_requests") else []
    if requests.is_empty():
        return
    content.add_child(Factory.section_title("SOLICITUDES"))
    for request in requests:
        var row := PanelContainer.new()
        row.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["border"], 10))
        content.add_child(row)
        var h := HBoxContainer.new()
        h.add_theme_constant_override("separation", 6)
        row.add_child(h)
        var label := Label.new()
        label.text = "%s · NEXUS %d" % [String(request.get("name", "Jugador")), int(request.get("nexus", 0))]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        h.add_child(label)
        var approve := Factory.make_secondary("ACEPTAR", 42)
        approve.pressed.connect(func():
            clubs.approve_join_request(club_id, String(request.get("id", "")))
            _rebuild()
        )
        h.add_child(approve)
        var reject := Factory.make_secondary("RECHAZAR", 42)
        reject.pressed.connect(func():
            clubs.reject_join_request(club_id, String(request.get("id", "")))
            _rebuild()
        )
        h.add_child(reject)

func _rebuild() -> void:
    for child in content.get_children():
        child.queue_free()
    await get_tree().process_frame
    _build_detail()
func _info(label_text: String, value_text: String) -> Label:
    var label := Label.new()
    label.text = "%s: %s" % [label_text, value_text]
    label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    label.custom_minimum_size.x = 0.0
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 17 if get_viewport_rect().size.x < 560.0 else 19)
    label.add_theme_color_override("font_color", Factory.colors()["text"])
    return label

func _access_text() -> String:
    var access := String(club.get("access_type", "public"))
    if access == "public":
        return "Público · entrada directa"
    if access == "nexus":
        return "Privado · NEXUS %d + aprobación" % int(club.get("min_nexus", 0))
    return "Privado · solo invitación"

func _mock_members() -> Array[Dictionary]:
    if clubs != null and clubs.has_method("get_members"):
        return clubs.get_members(String(club.get("id", "")))
    return []

func _join_club() -> void:
    if clubs == null:
        return
    var result: Dictionary = clubs.request_join(String(club.get("id", "")))
    if bool(result.get("ok", false)) and String(result.get("status", "")) == "joined":
        Navigation.go(ScreenCatalog.CLUB_CHAT)

func _show_member(member: Dictionary) -> void:
    var popup := ConfirmationDialog.new()
    popup.title = String(member.get("name", "Perfil"))
    popup.dialog_text = "NEXUS: %d\n\n¿Enviar solicitud de amistad?" % int(member.get("nexus", 0))
    popup.ok_button_text = "ENVIAR SOLICITUD"
    popup.cancel_button_text = "CANCELAR"
    add_child(popup)
    var friends := get_node_or_null("/root/FriendsService")
    popup.confirmed.connect(func():
        if friends != null:
            friends.send_request(String(member.get("id", "")), String(member.get("name", "Jugador")), String(member.get("icon", "♟")), int(member.get("nexus", 0)), "club")
        popup.queue_free()
    )
    popup.canceled.connect(func(): popup.queue_free())
    popup.popup_centered()
