extends Control

const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const Factory = preload("res://ui/components/social/social_ui_factory.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const EmoteDataScript = preload("res://domain/player/emote_data.gd")

var clubs: Node
var chat: Node
var body: VBoxContainer
var message_list: VBoxContainer
var members_panel: PanelContainer
var input: LineEdit
var club: Dictionary
var emote_popup: PopupPanel

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    clubs = get_node_or_null("/root/ClubsService")
    chat = get_node_or_null("/root/ClubChatService")
    club = {} if clubs == null else clubs.get_active_club()
    if club.is_empty():
        Navigation.go(ScreenCatalog.CLUBS)
        return
    Factory.add_background(self)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    Factory.configure_main_content_margin(self, margin, 14.0, 120.0, 12.0, 12.0, 174.0, 16.0, 16.0)
    add_child(margin)
    var compact := Factory.is_landscape(self)
    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 6 if compact else 10)
    margin.add_child(root)
    _build_header(root)
    var scroll := ScrollContainer.new()
    scroll.name = "ChatScroll"
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.mouse_filter = Control.MOUSE_FILTER_PASS
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    root.add_child(scroll)
    message_list = VBoxContainer.new()
    message_list.add_theme_constant_override("separation", 10)
    message_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    message_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.add_child(message_list)
    _build_composer(root)
    if chat != null and not chat.changed.is_connected(_refresh_chat):
        chat.changed.connect(_refresh_chat)
    _refresh_chat()
    Factory.attach_main_nav(self, "club", _on_nav)

func _build_header(root: VBoxContainer) -> void:
    var compact := Factory.is_landscape(self)
    var top := HBoxContainer.new()
    top.custom_minimum_size.y = 54 if compact else 68
    top.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
    top.add_theme_constant_override("separation", 6)
    root.add_child(top)
    var back := Button.new()
    back.text = "‹"
    back.custom_minimum_size = Vector2(48, 48)
    back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    back.mouse_filter = Control.MOUSE_FILTER_STOP
    back.add_theme_font_size_override("font_size", 34)
    back.pressed.connect(func(): Navigation.go(ScreenCatalog.CLUBS))
    top.add_child(back)
    var icon := Label.new()
    icon.text = String(club.get("icon", "♟"))
    icon.custom_minimum_size = Vector2(40, 40) if compact else Vector2(48, 48)
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 34)
    top.add_child(icon)
    var name_box := VBoxContainer.new()
    name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(name_box)
    var name := Label.new()
    name.text = String(club.get("name", "Club"))
    name.add_theme_color_override("font_color", Factory.colors()["text"])
    var header_font_size := 22 if get_viewport_rect().size.x < 420.0 else 28
    if name.text.length() > 20:
        header_font_size = mini(header_font_size, 20)
    name.add_theme_font_size_override("font_size", header_font_size)
    name.clip_text = true
    name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    name_box.add_child(name)
    var count := Label.new()
    count.text = "%d miembros" % int(club.get("members", 0))
    count.add_theme_color_override("font_color", Factory.colors()["muted"])
    count.add_theme_font_size_override("font_size", 18)
    name_box.add_child(count)
    var members := Factory.make_secondary("MIEMBROS", 48)
    members.name = "MembersButton"
    members.custom_minimum_size = Vector2(112 if compact else 108, 48)
    members.autowrap_mode = TextServer.AUTOWRAP_OFF
    members.clip_text = true
    members.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    members.add_theme_font_size_override("font_size", 13 if compact else 16)
    members.size_flags_horizontal = Control.SIZE_SHRINK_END
    members.pressed.connect(_toggle_members)
    top.add_child(members)
    var challenge := Factory.make_secondary("DESAFIAR", 48)
    challenge.custom_minimum_size.x = 88 if compact else 0
    challenge.autowrap_mode = TextServer.AUTOWRAP_OFF
    challenge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    challenge.add_theme_font_size_override("font_size", 13 if compact else 18)
    challenge.pressed.connect(_open_challenge_menu)
    if compact:
        top.add_child(challenge)
    else:
        root.add_child(challenge)

func _build_composer(root: VBoxContainer) -> void:
    var row := HBoxContainer.new()
    row.name = "ChatComposer"
    row.custom_minimum_size.y = 52 if Factory.is_landscape(self) else 58
    row.size_flags_vertical = Control.SIZE_SHRINK_END
    row.add_theme_constant_override("separation", 6)
    root.add_child(row)
    var emotes := Factory.make_secondary("🙂", 48 if Factory.is_landscape(self) else 52)
    emotes.name = "ChatEmotes"
    emotes.tooltip_text = "Emoticonos"
    emotes.custom_minimum_size = Vector2(48, 48) if Factory.is_landscape(self) else Vector2(52, 52)
    emotes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    emotes.pressed.connect(_toggle_emotes)
    row.add_child(emotes)
    input = LineEdit.new()
    input.name = "ChatInput"
    input.placeholder_text = "Escribe en el chat..."
    input.custom_minimum_size.y = 48 if Factory.is_landscape(self) else 52
    input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    input.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    row.add_child(input)
    var send := Factory.make_secondary("➤", 48 if Factory.is_landscape(self) else 52)
    send.name = "SendMessage"
    send.tooltip_text = "Enviar mensaje"
    send.custom_minimum_size = Vector2(48, 48) if Factory.is_landscape(self) else Vector2(52, 52)
    send.add_theme_font_size_override("font_size", 26)
    send.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    send.pressed.connect(_send)
    row.add_child(send)

func _send() -> void:
    var player_data := RuntimeServicesScript.get_autoload("PlayerData")
    var author := "Jugador" if player_data == null else String(player_data.profile.get("name", "Jugador"))
    if chat != null and chat.send_message(String(club.get("id", "")), author, input.text, "♟"):
        input.text = ""

func _refresh_chat() -> void:
    if message_list == null:
        return
    for child in message_list.get_children():
        child.queue_free()
    var messages: Array = [] if chat == null else chat.get_messages(String(club.get("id", "")))
    if messages.is_empty():
        var empty_state := CenterContainer.new()
        empty_state.name = "EmptyChatState"
        empty_state.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        empty_state.size_flags_vertical = Control.SIZE_EXPAND_FILL
        empty_state.custom_minimum_size.y = 120.0 if Factory.is_landscape(self) else 220.0
        message_list.add_child(empty_state)
        var empty := Label.new()
        empty.text = "Todavía no hay mensajes\n\nEste es el chat de %s.\nSaluda al club o lanza un desafío amistoso." % String(club.get("name", "Club"))
        empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.custom_minimum_size.x = 280.0
        empty.add_theme_font_size_override("font_size", 16 if Factory.is_landscape(self) else 18)
        empty.add_theme_color_override("font_color", Factory.colors()["muted"])
        empty_state.add_child(empty)
    for message in messages:
        if String(message.get("kind", "")) == "club_match":
            _add_match_message(message)
        else:
            _add_message(message)
    var pending: Array = [] if chat == null else chat.get_active_challenges(String(club.get("id", "")))
    for challenge_data in pending:
        _add_challenge_card(challenge_data)

func _add_match_message(message: Dictionary) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 10))
    message_list.add_child(card)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 8)
    card.add_child(row)
    var text_box := VBoxContainer.new()
    text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(text_box)
    var title := Label.new()
    title.text = "👁  Partida amistosa en curso..." if String(message.get("text", "")).find("en curso") >= 0 else "🏆  Partida amistosa finalizada"
    title.add_theme_color_override("font_color", Factory.colors()["text"])
    text_box.add_child(title)
    var detail := Label.new()
    detail.text = "No afecta rating, copas ni NEXUS."
    detail.add_theme_color_override("font_color", Factory.colors()["muted"])
    detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_box.add_child(detail)
    var watch := Factory.make_secondary("VER", 40)
    watch.pressed.connect(func(): _open_club_match(String(message.get("match_id", ""))))
    row.add_child(watch)

func _add_message(message: Dictionary) -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel"], Factory.colors()["border"], 10))
    message_list.add_child(panel)
    var box := VBoxContainer.new()
    panel.add_child(box)
    var author := Label.new()
    author.text = "%s  %s" % [String(message.get("icon", "♟")), String(message.get("author", "Jugador"))]
    author.add_theme_color_override("font_color", Factory.colors()["gold"])
    author.add_theme_font_size_override("font_size", 22)
    box.add_child(author)
    if String(message.get("kind", "message")) == "emote":
        var emote := EmoteDataScript.get_emote(String(message.get("emote_id", "")))
        if not emote.is_empty():
            var texture := TextureRect.new()
            texture.texture = load(String(emote.get("path", "")))
            texture.custom_minimum_size = Vector2(64, 64)
            texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            texture.tooltip_text = String(emote.get("label", "Reacción"))
            box.add_child(texture)
            return
    var text := Label.new()
    text.text = String(message.get("text", ""))
    text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text.add_theme_color_override("font_color", Factory.colors()["text"])
    box.add_child(text)

func _toggle_emotes() -> void:
    if emote_popup != null and is_instance_valid(emote_popup):
        emote_popup.queue_free()
        emote_popup = null
        return
    emote_popup = PopupPanel.new()
    emote_popup.name = "ClubEmotePopup"
    var viewport_size := get_viewport_rect().size
    emote_popup.size = Vector2(minf(360.0, maxf(200.0, viewport_size.x - 20.0)), minf(320.0, maxf(220.0, viewport_size.y - 160.0)))
    var outer := VBoxContainer.new()
    outer.add_theme_constant_override("separation", 8)
    emote_popup.add_child(outer)
    var header := HBoxContainer.new()
    outer.add_child(header)
    var title := Label.new()
    title.text = "🙂  Reacciones"
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    title.add_theme_font_size_override("font_size", 22)
    header.add_child(title)
    var close := Button.new()
    close.text = "×"
    close.custom_minimum_size = Vector2(48, 48)
    close.pressed.connect(func():
        if is_instance_valid(emote_popup):
            emote_popup.queue_free()
            emote_popup = null
    )
    header.add_child(close)
    var grid := GridContainer.new()
    grid.columns = 4 if emote_popup.size.x >= 330.0 else (3 if emote_popup.size.x >= 270.0 else 2)
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    outer.add_child(grid)
    var player_data := RuntimeServicesScript.get_autoload("PlayerData")
    var allowed: Array = player_data.get_equipped_emotes() if player_data != null else []
    for item in EmoteDataScript.all():
        var id := String(item.get("id", ""))
        if not allowed.has(id):
            continue
        var button := Button.new()
        button.name = "Emote_%s" % id
        var emote_side := 72.0 if emote_popup.size.x >= 330.0 else (64.0 if emote_popup.size.x >= 270.0 else 56.0)
        button.custom_minimum_size = Vector2(emote_side, emote_side)
        button.icon = load(String(item.get("path", "")))
        button.expand_icon = true
        button.tooltip_text = String(item.get("label", id))
        button.pressed.connect(func(emote_id: String = id): _send_emote(emote_id))
        grid.add_child(button)
    var hint := Label.new()
    hint.text = "Toca una reacción para enviarla al club."
    hint.add_theme_color_override("font_color", Factory.colors()["muted"])
    outer.add_child(hint)
    add_child(emote_popup)
    var button := get_node_or_null("MainNavigation")
    var center := get_viewport_rect().size * 0.5
    emote_popup.position = Vector2(clampf(center.x - emote_popup.size.x * 0.5, 10.0, get_viewport_rect().size.x - emote_popup.size.x - 10.0), clampf(center.y - emote_popup.size.y * 0.5, 70.0, get_viewport_rect().size.y - emote_popup.size.y - 90.0))
    emote_popup.popup()

func _send_emote(emote_id: String) -> void:
    var player_data := RuntimeServicesScript.get_autoload("PlayerData")
    var author := "Jugador" if player_data == null else String(player_data.profile.get("name", "Jugador"))
    if chat != null and chat.has_method("send_emote"):
        chat.send_emote(String(club.get("id", "")), author, emote_id, "♟")
    if emote_popup != null and is_instance_valid(emote_popup):
        emote_popup.queue_free()
        emote_popup = null

func _add_challenge_card(data: Dictionary) -> void:
    var card := PanelContainer.new()
    card.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 12))
    message_list.add_child(card)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    card.add_child(box)

    var title := Label.new()
    title.text = "♟ Desafío amistoso · %s" % String(data.get("mode", "")).to_upper()
    title.add_theme_color_override("font_color", Factory.colors()["text"])
    box.add_child(title)

    var roster := Label.new()
    roster.text = "Jugadores: %s" % String(chat.roster_text(data) if chat != null and chat.has_method("roster_text") else "(🔍/🔍/🔍/🔍)")
    roster.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    roster.add_theme_color_override("font_color", Factory.colors()["text"])
    box.add_child(roster)

    var count := Label.new()
    count.text = "Jugadores unidos: %d / %d · No afecta copas, rating ni NEXUS." % [int(data.get("accepted", 0)) + 1, int(data.get("players_required", 2))]
    count.add_theme_color_override("font_color", Factory.colors()["muted"])
    count.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(count)

    var actions := HBoxContainer.new()
    actions.add_theme_constant_override("separation", 6)
    box.add_child(actions)

    var player_data := RuntimeServicesScript.get_autoload("PlayerData")
    var local_id := "local_player" if player_data == null else String(player_data.profile.get("id", "local_player"))
    var sender_id := String(data.get("sender_id", ""))
    var slots: Array = data.get("slots", []) if data.get("slots", []) is Array else []
    var local_slot := -1
    for i in range(slots.size()):
        if String(slots[i]) == local_id:
            local_slot = i
            break

    if sender_id == local_id and String(data.get("status", "")) != "accepted":
        var cancel := Factory.make_secondary("CANCELAR", 44)
        cancel.pressed.connect(func(): chat.cancel_challenge(String(club.get("id", "")), String(data.get("id", ""))))
        actions.add_child(cancel)
    elif local_slot < 0 and int(data.get("accepted", 0)) < int(data.get("required", 1)):
        var accept := Factory.make_primary("UNIRME", 44)
        accept.pressed.connect(func():
            if chat.accept_challenge(String(club.get("id", "")), String(data.get("id", ""))):
                if String(data.get("mode", "")) == "2c2":
                    _show_side_choice(String(data.get("id", "")))
        )
        actions.add_child(accept)
    elif String(data.get("mode", "")) == "2c2" and local_slot >= 0 and String(data.get("status", "")) != "accepted":
        var teams: Array = data.get("slot_teams", [-1,-1,-1,-1]) if data.get("slot_teams", []) is Array else [-1,-1,-1,-1]
        var current_team := int(teams[local_slot]) if local_slot < teams.size() else -1
        var team_text := "ELEGIR COLOR" if current_team < 0 else ("BLANCAS" if current_team == 0 else "NEGRAS")
        var side := Factory.make_primary(team_text, 44)
        side.pressed.connect(func(): _show_side_choice(String(data.get("id", ""))))
        actions.add_child(side)

    var help := Label.new()
    help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    help.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    if String(data.get("mode", "")) == "2c2":
        var available: Dictionary = chat.available_team_slots(data) if chat != null and chat.has_method("available_team_slots") else {"white":2,"black":2}
        help.text = "♔ %d libres · ♚ %d libres" % [int(available.get("white",2)), int(available.get("black",2))]
    else:
        help.text = "Esperando jugador..." if local_slot < 0 else "Listo"
    help.add_theme_color_override("font_color", Factory.colors()["muted"])
    actions.add_child(help)

func _show_side_choice(challenge_id: String) -> void:
    if chat == null:
        return
    var challenge: Dictionary = {}
    for item in chat.get_active_challenges(String(club.get("id", ""))):
        if String(item.get("id", "")) == challenge_id:
            challenge = item
            break
    if challenge.is_empty():
        return
    var available: Dictionary = chat.available_team_slots(challenge)
    var popup := PopupMenu.new()
    popup.name = "SideChoice"
    popup.add_item("♔ Blancas", 0, 0)
    popup.add_item("♚ Negras", 1, 0)
    popup.set_item_disabled(0, int(available.get("white",0)) <= 0)
    popup.set_item_disabled(1, int(available.get("black",0)) <= 0)
    popup.id_pressed.connect(func(team: int):
        chat.choose_challenge_side(String(club.get("id", "")), challenge_id, team)
        popup.queue_free()
    )
    add_child(popup)
    popup.position = Vector2(18, maxf(90.0, get_viewport_rect().size.y * 0.42))
    popup.popup()

func _open_challenge_menu() -> void:
    var popup := PopupMenu.new()
    popup.add_item("1c1 · amistosa", 1)
    popup.add_item("2c2 · amistosa", 2)
    popup.id_pressed.connect(func(id: int):
        if chat != null:
            chat.create_challenge(String(club.get("id", "")), "1c1" if id == 1 else "2c2")
        popup.queue_free()
    )
    add_child(popup)
    popup.position = Vector2(16, 120)
    popup.popup()

func _toggle_members() -> void:
    Navigation.go(ScreenCatalog.CLUB_MEMBERS)
    return
    if members_panel != null and is_instance_valid(members_panel):
        members_panel.queue_free()
        members_panel = null
        return
    members_panel = PanelContainer.new()
    members_panel.name = "MembersPanel"
    members_panel.position = Vector2(16, 88)
    members_panel.size = Vector2(maxf(280.0, get_viewport_rect().size.x - 32.0), 260.0)
    members_panel.z_index = 10
    members_panel.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 12))
    add_child(members_panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 6)
    members_panel.add_child(box)
    var heading := Label.new()
    heading.text = "MIEMBROS"
    heading.add_theme_color_override("font_color", Factory.colors()["text"])
    box.add_child(heading)
    var member_data: Array[Dictionary] = [
        {"id":"founder","name":String(club.get("founder","Fundador")),"icon":"♚","nexus":800},
        {"id":"mica","name":"Mica","icon":"♟","nexus":520},
        {"id":"alex","name":"Alex","icon":"♞","nexus":640},
        {"id":"luna","name":"Luna","icon":"♝","nexus":410},
    ]
    for member in member_data:
        var row := HBoxContainer.new()
        row.custom_minimum_size.y = 42
        box.add_child(row)
        var label := Label.new()
        label.text = "%s  %s" % [String(member.get("icon","♟")), String(member.get("name","Jugador"))]
        label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        row.add_child(label)
        var profile := Factory.make_secondary("PERFIL", 38)
        profile.pressed.connect(func(): _show_member_profile(member))
        row.add_child(profile)
        var friend := Factory.make_secondary("AMIGO", 38)
        friend.pressed.connect(func(): _send_friend_request(member))
        row.add_child(friend)


func _show_member_profile(member: Dictionary) -> void:
    var popup := ConfirmationDialog.new()
    popup.title = String(member.get("name", "Perfil"))
    popup.dialog_text = "NEXUS: %d\n\n¿Enviar solicitud de amistad?" % int(member.get("nexus", 0))
    popup.ok_button_text = "ENVIAR SOLICITUD"
    popup.cancel_button_text = "CANCELAR"
    add_child(popup)
    popup.confirmed.connect(func():
        _send_friend_request(member)
        popup.queue_free()
    )
    popup.canceled.connect(func(): popup.queue_free())
    popup.popup_centered()

func _send_friend_request(member: Dictionary) -> void:
    var friends := get_node_or_null("/root/FriendsService")
    if friends != null:
        friends.send_request(String(member.get("id","")), String(member.get("name","Jugador")), String(member.get("icon","♟")), int(member.get("nexus",0)), "club")

func _open_club_match(match_id: String) -> void:
    var app := RuntimeServicesScript.get_autoload("App")
    if app != null:
        app.club_match_view_id = match_id
        app.club_match_view_club_id = String(club.get("id", ""))
    Navigation.go(ScreenCatalog.CLUB_MATCH_VIEWER)

func _on_nav(section: String) -> void:
    match section:
        "home": Navigation.go(ScreenCatalog.MAIN_MENU)
        "club": pass
        "friends": Navigation.go(ScreenCatalog.FRIENDS)
        "more": Navigation.go(ScreenCatalog.MORE)
