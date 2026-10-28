extends Control

signal close_requested
signal analyze_requested
signal rematch_requested
signal new_game_requested
signal home_requested

const Factory = preload("res://ui/components/social/social_ui_factory.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const ProfileDataScript = preload("res://domain/player/profile_data.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")
const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")

var game
var entry: Dictionary = {}
var scroll: ScrollContainer
var content: VBoxContainer
var assembly_parts: Array[Control] = []
var assembled := false

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    visible = false
    _build()

func _build() -> void:
    var bg := ColorRect.new()
    bg.name = "Background"
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("#14110E")
    bg.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(bg)
    bg.z_index = -1
    var close := Button.new()
    close.name = "Close"
    close.text = "×"
    close.custom_minimum_size = Vector2(56,56)
    close.position = Vector2(8,8)
    close.add_theme_font_size_override("font_size", 36)
    close.add_theme_stylebox_override("normal", Factory.button_style(Color(0,0,0,0), Color("#4A3B2A"), 12))
    close.add_theme_stylebox_override("hover", Factory.button_style(Color("#251E17"), Color("#D5A84E"), 12))
    close.tooltip_text = "Volver al tablero"
    close.pressed.connect(func(): close_requested.emit())
    add_child(close)
    scroll = ScrollContainer.new()
    scroll.name = "ResultScroll"
    scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    scroll.offset_left = 14
    scroll.offset_right = -14
    scroll.offset_top = 72
    scroll.offset_bottom = -82
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    add_child(scroll)
    content = VBoxContainer.new()
    content.name = "ResultContent"
    content.add_theme_constant_override("separation", 12)
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(content)
    scroll.get_v_scroll_bar().modulate.a = 0.45
    var home_fixed := Factory.make_secondary("⌂  VOLVER AL INICIO", 58)
    home_fixed.name = "HomeFixed"
    home_fixed.anchor_left = 0.0
    home_fixed.anchor_right = 1.0
    home_fixed.anchor_top = 1.0
    home_fixed.anchor_bottom = 1.0
    home_fixed.offset_left = 14.0
    home_fixed.offset_right = -14.0
    home_fixed.offset_top = -70.0
    home_fixed.offset_bottom = -12.0
    home_fixed.add_theme_font_size_override("font_size", 23)
    home_fixed.z_index = 10
    home_fixed.pressed.connect(_on_home_pressed)
    add_child(home_fixed)
    var hint := Label.new()
    hint.text = "RESULTADO DE LA PARTIDA"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", Factory.colors()["muted"])
    hint.add_theme_font_size_override("font_size", 19)
    content.add_child(hint)

func configure(state, result_entry: Dictionary) -> void:
    game = state
    entry = result_entry.duplicate(true)
    if not is_inside_tree():
        return
    _rebuild_content()
    call_deferred("_play_assembly")

func show_screen() -> void:
    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP
    call_deferred("_play_assembly")

func hide_screen() -> void:
    visible = false

func set_rematch_requested(requested: bool) -> void:
    if content == null:
        return
    var button := content.get_node_or_null("Rematch") as Button
    if button == null:
        return
    var outcome := _outcome_text()
    if outcome == "Derrota":
        return
    button.disabled = not requested
    button.modulate.a = 1.0 if requested else 0.45
    button.tooltip_text = "El rival pidió revancha." if requested else "Se activará cuando el rival pida la revancha."
    var hint := content.get_node_or_null("RematchHint") as Label
    if hint != null:
        hint.text = "El rival pidió revancha. Puedes aceptar." if requested else "El rival puede pedir una revancha."

func _rebuild_content() -> void:
    if content == null:
        return
    for child in content.get_children():
        if child.name == "ResultScroll" or child.name == "ResultContent":
            continue
        child.queue_free()
    assembly_parts.clear()
    assembled = false
    var team := _winner_team()
    var hero := PanelContainer.new()
    hero.name = "WinnerHero"
    hero.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel2"], Factory.colors()["gold"], 18))
    content.add_child(hero)
    assembly_parts.append(hero)
    var hero_box := VBoxContainer.new()
    hero_box.alignment = BoxContainer.ALIGNMENT_CENTER
    hero_box.add_theme_constant_override("separation", 6)
    hero.add_child(hero_box)
    var result_label := Label.new()
    result_label.text = "VICTORIA" if team >= 0 else "TABLAS"
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.add_theme_font_size_override("font_size", 34)
    result_label.add_theme_color_override("font_color", Factory.colors()["gold"])
    hero_box.add_child(result_label)
    var reason := Label.new()
    reason.text = String(game.winner_reason) if game != null else "Partida terminada"
    reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reason.add_theme_color_override("font_color", Factory.colors()["muted"])
    hero_box.add_child(reason)

    var team_title := Label.new()
    team_title.text = "EQUIPO GANADOR" if team >= 0 else "PARTIDA TERMINADA"
    team_title.add_theme_color_override("font_color", Factory.colors()["muted"])
    content.add_child(team_title)
    assembly_parts.append(team_title)
    var crown := Label.new()
    crown.name = "SharedCrown"
    crown.text = "👑" if team >= 0 else ""
    crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crown.add_theme_font_size_override("font_size", 58)
    crown.custom_minimum_size = Vector2(0, 66)
    crown.add_theme_color_override("font_color", Factory.colors()["gold"])
    content.add_child(crown)
    assembly_parts.append(crown)

    var players := HBoxContainer.new()
    players.name = "WinningTeam"
    players.alignment = BoxContainer.ALIGNMENT_CENTER
    players.add_theme_constant_override("separation", 22)
    content.add_child(players)
    assembly_parts.append(players)
    if team >= 0:
        for slot in range(game.SLOTS):
            if slot >= game.slot_colors.size() or int(game.slot_colors[slot]) != team:
                continue
            if not bool(game.slot_active[slot]):
                continue
            players.add_child(_player_card(slot))

    var cups := int(entry.get("cup_delta", 0))
    var progress := PanelContainer.new()
    progress.add_theme_stylebox_override("panel", Factory.panel_style(Factory.colors()["panel"], Factory.colors()["border"], 12))
    content.add_child(progress)
    assembly_parts.append(progress)
    var progress_box := VBoxContainer.new()
    progress.add_child(progress_box)
    var p1 := Label.new()
    p1.name = "CupReward"
    p1.text = "🏆 %s" % _signed(cups) if cups != 0 else "🏆 0"
    p1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    p1.add_theme_color_override("font_color", Factory.colors()["text"])
    p1.add_theme_font_size_override("font_size", 27)
    progress_box.add_child(p1)

    var action := Factory.make_primary("ANALIZAR PARTIDA", 60)
    action.name = "Analyze"
    action.pressed.connect(func(): analyze_requested.emit())
    content.add_child(action)
    assembly_parts.append(action)

    var outcome := _outcome_text()
    var again := Factory.make_secondary("REVANCHA", 56) if outcome == "Derrota" else Factory.make_secondary("ACEPTAR", 56)
    again.name = "Rematch"
    if outcome != "Derrota":
        again.disabled = true
        again.modulate.a = 0.45
        again.tooltip_text = "Se activará cuando el rival pida la revancha."
    again.pressed.connect(func(): rematch_requested.emit())
    content.add_child(again)

    var hint := Label.new()
    hint.name = "RematchHint"
    hint.text = "El rival puede pedir una revancha." if outcome != "Derrota" else "Puedes pedir una revancha a tus rivales."
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.add_theme_color_override("font_color", Factory.colors()["muted"])
    hint.add_theme_font_size_override("font_size", 16)
    content.add_child(hint)

    var new_game := Factory.make_primary("NUEVA PARTIDA", 58)
    new_game.name = "NewGame"
    new_game.pressed.connect(func(): new_game_requested.emit())
    content.add_child(new_game)
    assembly_parts.append(new_game)

    var finish := Label.new()
    finish.text = "La partida quedó guardada en tu historial."
    finish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    finish.add_theme_color_override("font_color", Factory.colors()["muted"])
    finish.add_theme_font_size_override("font_size", 16)
    content.add_child(finish)

func _player_card(slot: int) -> Control:
    var box := VBoxContainer.new()
    box.name = "Player%d" % slot
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 3)
    var avatar := Control.new()
    avatar.custom_minimum_size = Vector2(58, 58)
    var icon := Label.new()
    icon.text = _avatar_symbol(slot)
    icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 42)
    avatar.add_child(icon)
    if slot != 0:
        var add := Button.new()
        add.name = "AddFriend"
        add.text = "+"
        add.custom_minimum_size = Vector2(26, 26)
        add.position = Vector2(35, 31)
        add.add_theme_font_size_override("font_size", 26)
        add.add_theme_stylebox_override("normal", Factory.button_style(Factory.colors()["gold"], Factory.colors()["gold"], 13))
        add.add_theme_color_override("font_color", Color("#14110E"))
        add.tooltip_text = "Añadir amigo"
        add.pressed.connect(_on_add_friend_pressed.bind(slot, weakref(add)))
        avatar.add_child(add)
        if _friend_request_already_sent(slot):
            add.queue_free()
    box.add_child(avatar)
    var name := Label.new()
    name.text = _player_name(slot)
    name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name.add_theme_color_override("font_color", Factory.colors()["text"])
    name.add_theme_font_size_override("font_size", 19)
    box.add_child(name)
    return box

func _on_home_pressed() -> void:
    home_requested.emit()

func _winner_team() -> int:
    return int(game.winner_team) if game != null else -1

func _outcome_text() -> String:
    var local_team := int(game.slot_colors[0]) if game != null and game.slot_colors.size() > 0 else -1
    if _winner_team() < 0:
        return "Tablas"
    return "Victoria" if local_team == _winner_team() else "Derrota"

func _player_name(slot: int) -> String:
    if game == null or slot < 0 or slot >= game.slot_owners.size():
        return "Jugador"
    return String(game.slot_owners[slot])

func _avatar_symbol(slot: int) -> String:
    if game == null:
        return "♟"
    if slot == 0:
        return "♔"
    if slot == 1:
        return "♚"
    if slot == 2:
        return "♟"
    return "♞"

func _on_add_friend_pressed(slot: int, button_ref: WeakRef) -> void:
    var button := button_ref.get_ref() as Button if button_ref != null else null
    if button == null or not is_instance_valid(button):
        return
    _send_friend(slot, button)

func _send_friend(slot: int, button: Button) -> void:
    if not is_instance_valid(button) or game == null or slot <= 0 or slot >= game.slot_profile_ids.size():
        return
    var friends := RuntimeServicesScript.get_autoload("FriendsService")
    if friends == null or not is_instance_valid(button):
        return
    var id := String(game.slot_profile_ids[slot])
    var name := _player_name(slot)
    if not friends.send_request(id, name, _avatar_symbol(slot), 0, "match_result"):
        return
    button.disabled = true
    button.text = "✔"
    button.tooltip_text = "Solicitud enviada"
    button.add_theme_font_size_override("font_size", 23)
    button.pivot_offset = button.size * 0.5
    var tween := create_tween()
    tween.tween_property(button, "scale", Vector2(1.22, 1.22), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.tween_property(button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.tween_interval(0.28)
    tween.tween_property(button, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
    tween.tween_callback(button.queue_free)

func _friend_request_already_sent(slot: int) -> bool:
    if game == null or slot <= 0 or slot >= game.slot_profile_ids.size():
        return false
    var friends := RuntimeServicesScript.get_autoload("FriendsService")
    if friends == null:
        return false
    var id := String(game.slot_profile_ids[slot])
    if friends.is_friend(id):
        return true
    for request in friends.get_pending_requests():
        if String(request.get("id", "")) == id:
            return true
    return false

func _open_profile(slot: int) -> void:
    if game == null or slot < 0 or slot >= game.slot_profile_ids.size():
        return
    var app := RuntimeServicesScript.get_autoload("App")
    if app != null:
        app.target_profile_id = String(game.slot_profile_ids[slot])
        app.target_profile_name = _player_name(slot)
    Navigation.go(ScreenCatalog.PLAYER_PROFILE)

func _signed(value: int) -> String:
    return "+%d" % value if value > 0 else str(value)

func _play_assembly() -> void:
    if not visible or assembled or assembly_parts.is_empty():
        return
    assembled = true
    # Esperar al layout real del VBox/ScrollContainer antes de capturar las
    # posiciones destino; evita que la animación arranque con posiciones 0,0.
    await get_tree().process_frame
    if not visible:
        return
    var viewport_size := get_viewport_rect().size
    var center := viewport_size * 0.5
    var i := 0
    for part in assembly_parts:
        if not is_instance_valid(part):
            continue
        part.modulate.a = 0.0
        part.pivot_offset = part.size * 0.5
        var target := part.position
        var dx := (-1.0 if i % 2 == 0 else 1.0) * (140.0 + float(i % 3) * 55.0)
        var dy := (-1.0 if i % 3 == 0 else 1.0) * (100.0 + float(i % 4) * 22.0)
        part.position = target + Vector2(dx, dy) + (center - target) * 0.08
        var tween := create_tween()
        tween.tween_interval(0.035 * float(i))
        tween.tween_property(part, "position", target, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        tween.parallel().tween_property(part, "modulate:a", 1.0, 0.24)
        i += 1
