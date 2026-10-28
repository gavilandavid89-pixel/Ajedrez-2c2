extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")

var clubs: Node
var club: Dictionary

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.add_background(self)
    clubs = RuntimeServicesScript.get_autoload("ClubsService")
    club = {} if clubs == null else clubs.get_active_club()
    if club.is_empty():
        Navigation.go(ScreenCatalog.CLUBS)
        return
    var compact := Factory.is_landscape(self)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.configure_main_content_margin(self, margin, 10.0, 120.0, 12.0, 12.0, 174.0, 12.0, 12.0)
    add_child(margin)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 6 if compact else 10)
    margin.add_child(root)
    Factory.make_top_bar("Miembros", root, func(): Navigation.go(ScreenCatalog.CLUB_CHAT)).name = "TopBar"
    var heading := Label.new()
    heading.text = "%s · %d / 50 miembros" % [String(club.get("name", "Club")), int(club.get("members", 0))]
    heading.add_theme_color_override("font_color", Factory.colors()["muted"])
    heading.add_theme_font_size_override("font_size", 15 if compact else 17)
    root.add_child(heading)
    var role_hint := Label.new()
    if clubs != null and clubs.can_manage_roles(String(club.get("id", ""))):
        role_hint.text = "Puedes cambiar roles por debajo de tu propia jerarquía."
    else:
        role_hint.text = "Jerarquía: ♚ Rey > ♛ Dama > ♜ Torre > ♝ Alfil > ♞ Caballo > ♟ Peón"
    role_hint.add_theme_color_override("font_color", Factory.colors()["muted"])
    role_hint.add_theme_font_size_override("font_size", 13 if compact else 15)
    role_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    root.add_child(role_hint)
    var scroll := ScrollContainer.new()
    scroll.name = "MembersScroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.mouse_filter = Control.MOUSE_FILTER_PASS
    root.add_child(scroll)
    var list := VBoxContainer.new()
    list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    list.add_theme_constant_override("separation", 7)
    scroll.add_child(list)
    for member in _members(club):
        var row := PanelContainer.new()
        row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel"], Factory.colors()["border"], 10))
        list.add_child(row)
        var member_content := VBoxContainer.new()
        member_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        member_content.add_theme_constant_override("separation", 6)
        row.add_child(member_content)

        var r := HBoxContainer.new()
        r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        r.custom_minimum_size = Vector2(0.0, 54.0 if compact else 64.0)
        r.clip_contents = true
        r.add_theme_constant_override("separation", 8)
        member_content.add_child(r)
        var avatar := Label.new()
        avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
        avatar.text = String(member.get("icon", "♟"))
        avatar.custom_minimum_size = Vector2(42, 42) if compact else Vector2(56, 56)
        avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        avatar.add_theme_font_size_override("font_size", 24 if compact else 30)
        r.add_child(avatar)
        var role := String(member.get("role", "peon"))
        var role_label := String(clubs.role_label(role)) if clubs != null and clubs.has_method("role_label") else "Peón · Miembro"
        var identity := VBoxContainer.new()
        identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        identity.custom_minimum_size = Vector2(0.0, 42.0 if not compact else 38.0)
        identity.alignment = BoxContainer.ALIGNMENT_CENTER
        identity.add_theme_constant_override("separation", 0)
        r.add_child(identity)

        var name_label := Label.new()
        name_label.text = String(member.get("name", "Jugador"))
        name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        name_label.custom_minimum_size = Vector2(0.0, 22.0)
        name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        name_label.add_theme_color_override("font_color", Factory.colors()["text"])
        name_label.add_theme_font_size_override("font_size", 15 if compact else 17)
        name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
        name_label.clip_text = true
        name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        identity.add_child(name_label)

        var member_role_hint := Label.new()
        member_role_hint.text = role_label
        member_role_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        member_role_hint.custom_minimum_size = Vector2(0.0, 18.0)
        member_role_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        member_role_hint.add_theme_color_override("font_color", Factory.colors()["muted"])
        member_role_hint.add_theme_font_size_override("font_size", 12 if compact else 14)
        member_role_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
        member_role_hint.clip_text = true
        member_role_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
        member_role_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
        identity.add_child(member_role_hint)

        var actions := HBoxContainer.new()
        actions.size_flags_horizontal = Control.SIZE_SHRINK_END if compact else Control.SIZE_EXPAND_FILL
        actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
        actions.alignment = BoxContainer.ALIGNMENT_END
        actions.add_theme_constant_override("separation", 5 if compact else 6)
        var club_id := String(club.get("id", ""))
        var target_id := String(member.get("id", ""))
        if clubs != null and clubs.can_manage_roles(club_id) and clubs.can_manage_member(club_id, target_id):
            var role_button := Factory.make_secondary("ROL", 42)
            role_button.custom_minimum_size = Vector2(48 if compact else 64, 48)
            role_button.autowrap_mode = TextServer.AUTOWRAP_OFF
            role_button.add_theme_font_size_override("font_size", 13 if compact else 18)
            role_button.tooltip_text = "Asignar rol"
            role_button.pressed.connect(_on_role_button_pressed.bind(member, weakref(role_button)))
            actions.add_child(role_button)
            var kick_button := Factory.make_secondary("EXPULSAR", 42)
            kick_button.custom_minimum_size = Vector2(70 if compact else 88, 48)
            kick_button.autowrap_mode = TextServer.AUTOWRAP_OFF
            kick_button.add_theme_font_size_override("font_size", 12 if compact else 17)
            kick_button.tooltip_text = "Expulsar del club"
            kick_button.pressed.connect(_on_kick_button_pressed.bind(member))
            actions.add_child(kick_button)
        var profile := Factory.make_secondary("PERFIL", 42)
        profile.custom_minimum_size = Vector2(64 if compact else 78, 48)
        profile.autowrap_mode = TextServer.AUTOWRAP_OFF
        profile.add_theme_font_size_override("font_size", 12 if compact else 17)
        profile.pressed.connect(_on_profile_button_pressed.bind(member))
        actions.add_child(profile)
        if compact:
            r.add_child(actions)
        else:
            member_content.add_child(actions)
    Factory.attach_main_nav(self, "club", _on_nav)

func _on_role_button_pressed(member_data: Dictionary, button_ref: WeakRef) -> void:
    var button := button_ref.get_ref() as Control if button_ref != null else null
    if button == null or not is_instance_valid(button) or not is_inside_tree():
        return
    _open_role_menu(member_data, button)

func _on_kick_button_pressed(member_data: Dictionary) -> void:
    if is_inside_tree():
        _confirm_remove(member_data)

func _on_profile_button_pressed(member_data: Dictionary) -> void:
    if is_inside_tree():
        _open_profile(member_data)

func _members(_club: Dictionary) -> Array[Dictionary]:
    if clubs != null and clubs.has_method("get_members"):
        return clubs.get_members(String(_club.get("id", "")))
    return []

func _open_role_menu(member: Dictionary, anchor: Control) -> void:
    if clubs == null:
        return
    var popup := PopupMenu.new()
    popup.name = "RoleMenu"
    var club_id := String(club.get("id", ""))
    var target_id := String(member.get("id", ""))
    var actor_role: String = clubs.member_role(club_id)
    var actor_power: int = clubs.role_power(actor_role)
    var roles: Array[String] = [clubs.ROLE_FOUNDER, clubs.ROLE_QUEEN, clubs.ROLE_ROOK, clubs.ROLE_BISHOP, clubs.ROLE_KNIGHT, clubs.ROLE_PAWN]
    for role in roles:
        if clubs.role_power(role) > actor_power:
            continue
        popup.add_item(clubs.role_label(role), clubs.role_power(role))
        var index := popup.item_count - 1
        popup.set_item_disabled(index, not clubs.can_assign_role(club_id, target_id, role))
    popup.id_pressed.connect(func(role_id: int):
        for role in roles:
            if clubs.role_power(role) == role_id and clubs.can_assign_role(club_id, target_id, role):
                clubs.set_member_role(club_id, target_id, role)
                popup.queue_free()
                get_tree().reload_current_scene()
                return
        popup.queue_free()
    )
    add_child(popup)
    var pos := anchor.global_position + Vector2(0, anchor.size.y + 4)
    popup.position = Vector2i(int(pos.x), int(pos.y))
    popup.popup()

func _confirm_remove(member: Dictionary) -> void:
    if clubs == null:
        return
    var club_id := String(club.get("id", ""))
    var target_id := String(member.get("id", ""))
    if not clubs.can_remove_member(club_id, target_id):
        return
    var dialog := ConfirmationDialog.new()
    dialog.title = "Expulsar jugador"
    dialog.dialog_text = "¿Expulsar a %s del club?" % String(member.get("name", "Jugador"))
    dialog.ok_button_text = "EXPULSAR"
    dialog.cancel_button_text = "CANCELAR"
    add_child(dialog)
    dialog.confirmed.connect(func():
        clubs.remove_member(club_id, target_id)
        dialog.queue_free()
        get_tree().reload_current_scene()
    )
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered()

func _open_profile(member: Dictionary) -> void:
    var app := RuntimeServicesScript.get_autoload("App")
    if app != null:
        app.target_profile_id = String(member.get("id", ""))
        app.target_profile_name = String(member.get("name", "Jugador"))
    Navigation.go(ScreenCatalog.PLAYER_PROFILE)

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club": Navigation.go(ScreenCatalog.CLUB_CHAT)
        "friends": Navigation.go(ScreenCatalog.FRIENDS)
        "more": Navigation.go(ScreenCatalog.MORE)
