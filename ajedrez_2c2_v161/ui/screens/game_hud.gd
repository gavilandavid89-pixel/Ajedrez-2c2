extends Control
const GameChatPanelScript = preload("res://ui/components/game/game_chat_panel.gd")
const GameOverlayControllerScript = preload("res://ui/components/game/game_overlay_controller.gd")
const GameHudLayoutScript = preload("res://ui/components/game/game_hud_layout.gd")
const ThemePalette = preload("res://core/theme/theme_tokens.gd")

const MODE_2C2 := 0
const MODE_1C1 := 1
const MODE_VS_BOT := 2
const MODE_1C1_LOCAL := 3

const ProfileDataScript = preload("res://domain/player/profile_data.gd")
const PlayerCardScene = preload("res://scenes/player_card.tscn")
const EmotePickerScene = preload("res://scenes/emote_picker.tscn")
const GameActionMenuScene = preload("res://scenes/game_action_menu.tscn")
const MatchResultScreenScene = preload("res://scenes/game_match_result_screen.tscn")
const EmoteDataScript = preload("res://domain/player/emote_data.gd")
const LayoutMetrics = preload("res://core/layout/layout_metrics.gd")

signal back_requested
signal reset_requested
signal rematch_requested
signal analysis_requested
signal action_requested(action: String)

var game

var mode_label: Label
var turn_label: Label
var status_label: Label
var selected_label: Label
var moves_label: Label
var online_status_label: Label
var time_control_label: Label
var compact_back: Button
var compact_reset: Button
var game_menu_button: Button
var game_action_menu

var black_info: Panel
var white_info: Panel
var black_players: GridContainer
var white_players: GridContainer
var black_title: Label
var white_title: Label
var black_team_clock: Label
var white_team_clock: Label

var action_row: HBoxContainer
var result_panel: Panel
var result_label: Label
var result_entry: Dictionary = {}
var result_screen: Control = null
var finished_result_button: Button = null

var mini_panel: Panel
var mini_title: Label
var mini_body: Label
var mini_cooldown: Label
var mini_actions: HBoxContainer
var chat_panel: Panel
var chat_messages: RichTextLabel
var chat_input: LineEdit
var history_panel: Panel
var history_lines: RichTextLabel
var black_signature: String = ""
var white_signature: String = ""
var emote_picker
var emote_serial_seen: int = -1
var cards_by_slot: Dictionary = {}
var _connected_viewport: Viewport = null
var _connected_game = null
var chat_component: Node = null
var overlay_controller = null
var _last_layout_viewport := Vector2(-1, -1)
var _layout_dirty := true
var _layout_queued := false
var _dynamic_refresh_accumulator := 0.0
static var _emote_texture_cache: Dictionary = {}
var _mobile_scale: float = 1.0
var _result_transition_started := false
var _mini_dragging := false
var _mini_drag_offset := Vector2.ZERO
var hud_layout: RefCounted

func _mobile_ui_scale() -> float:
    return hud_layout._mobile_ui_scale()

func _scaled_font(base_size: float, cap: float = 22.0) -> int:
    return hud_layout._scaled_font(base_size, cap)

func _ready() -> void:
    hud_layout = GameHudLayoutScript.new(self)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _build()
    set_process(true)

func _exit_tree() -> void:
    if _connected_viewport != null and is_instance_valid(_connected_viewport):
        if _connected_viewport.size_changed.is_connected(_on_layout_viewport_changed):
            _connected_viewport.size_changed.disconnect(_on_layout_viewport_changed)
    if _connected_game != null and is_instance_valid(_connected_game):
        if _connected_game.state_changed.is_connected(_on_game_state_changed):
            _connected_game.state_changed.disconnect(_on_game_state_changed)
    _connected_viewport = null
    _connected_game = null

func _on_game_state_changed() -> void:
    if is_inside_tree() and game != null:
        refresh()

func _on_layout_viewport_changed() -> void:
    _queue_layout_refresh()

func _queue_layout_refresh() -> void:
    if not is_inside_tree():
        return
    _layout_dirty = true
    if _layout_queued:
        return
    _layout_queued = true
    call_deferred("_apply_queued_layout")

func _apply_queued_layout() -> void:
    _layout_queued = false
    if not is_inside_tree() or not _layout_dirty:
        return
    _layout_dirty = false
    _last_layout_viewport = get_viewport_rect().size
    _resize_for_viewport()
    if game != null and not game.running:
        get_node("Bottom").visible = false

func set_game(state) -> void:
    if _connected_game != null and is_instance_valid(_connected_game):
        if _connected_game.state_changed.is_connected(_on_game_state_changed):
            _connected_game.state_changed.disconnect(_on_game_state_changed)
    game = state
    _connected_game = state
    if _connected_game != null and _connected_game.has_signal("state_changed"):
        if not _connected_game.state_changed.is_connected(_on_game_state_changed):
            _connected_game.state_changed.connect(_on_game_state_changed)
    black_signature = ""
    white_signature = ""
    emote_serial_seen = -1
    refresh()

func _build() -> void:
    mode_label = get_node("Top/Mode")
    turn_label = get_node("Turn")
    status_label = get_node("Status")
    selected_label = get_node("Selected")
    moves_label = get_node("Moves")
    online_status_label = get_node("Top/OnlineStatus")
    time_control_label = get_node("Top/TimeControl")
    compact_back = get_node("CompactBack")
    compact_reset = get_node("CompactReset")

    black_info = get_node("BlackInfo")
    white_info = get_node("WhiteInfo")
    black_players = get_node("BlackInfo/Players")
    white_players = get_node("WhiteInfo/Players")
    black_title = get_node("BlackInfo/Title")
    white_title = get_node("WhiteInfo/Title")
    black_team_clock = get_node("BlackInfo/TeamClock")
    white_team_clock = get_node("WhiteInfo/TeamClock")

    action_row = get_node("Bottom/Actions")
    mini_panel = get_node("MiniPanel")
    mini_title = get_node("MiniPanel/Title")
    mini_body = get_node("MiniPanel/Body")
    mini_cooldown = get_node("MiniPanel/Cooldown")
    mini_actions = get_node("MiniPanel/Actions")
    overlay_controller = GameOverlayControllerScript.new()
    overlay_controller.attach(self, mini_panel, mini_title, mini_body, mini_cooldown, mini_actions, Callable(self, "_scaled_font"))
    overlay_controller.action_requested.connect(_on_overlay_action)
    chat_panel = get_node("ChatPanel")
    chat_component = chat_panel
    chat_messages = get_node("ChatPanel/Messages")
    chat_input = get_node("ChatPanel/Input")
    history_panel = get_node("HistoryPanel")
    history_lines = get_node("HistoryPanel/Lines")
    result_panel = get_node("Result")
    result_label = get_node("Result/Label")
    finished_result_button = get_node("FinishedResultButton")
    result_screen = MatchResultScreenScene.instantiate()
    result_screen.name = "MatchResultScreen"
    add_child(result_screen)
    result_screen.z_index = 250
    result_screen.close_requested.connect(_close_result_screen)
    result_screen.analyze_requested.connect(func(): analysis_requested.emit())
    result_screen.rematch_requested.connect(func(): rematch_requested.emit())
    result_screen.new_game_requested.connect(_new_game_from_result)
    result_screen.home_requested.connect(_return_home_from_result)
    finished_result_button.pressed.connect(_reopen_result_screen)
    emote_picker = get_node("EmotePicker")
    game_menu_button = get_node("Bottom/GameMenu")
    game_action_menu = get_node("GameActionMenu")
    emote_picker.emote_selected.connect(_on_emote_selected)
    _apply_overlay_priorities()
    emote_picker.closed.connect(_close_emote_picker)

    get_node("Top/Back").pressed.connect(func(): back_requested.emit())
    get_node("Top/Reset").pressed.connect(func(): reset_requested.emit())
    compact_back.pressed.connect(func(): back_requested.emit())
    compact_reset.pressed.connect(func(): reset_requested.emit())
    get_node("Result/ToMenu").pressed.connect(func(): back_requested.emit())
    get_node("Result/Rematch").pressed.connect(func(): rematch_requested.emit())
    get_node("Result/Analyze").pressed.connect(func(): analysis_requested.emit())
    get_node("Bottom/Chat").pressed.connect(_toggle_chat)
    get_node("Bottom/Emotes").pressed.connect(_toggle_emotes)
    game_menu_button.pressed.connect(_toggle_game_menu)
    game_action_menu.action_selected.connect(_on_game_menu_action)
    game_action_menu.dismissed.connect(_close_game_menu)
    get_node("MiniPanel/Close").pressed.connect(_close_mini)
    mini_title.gui_input.connect(_on_mini_title_gui_input)
    mini_title.mouse_filter = Control.MOUSE_FILTER_STOP
    mini_title.mouse_default_cursor_shape = Control.CURSOR_MOVE
    if chat_component != null and chat_component.has_signal("message_submitted"):
        if not chat_component.is_connected("message_submitted", _send_chat):
            chat_component.connect("message_submitted", _send_chat)
    if chat_component != null and chat_component.has_signal("close_requested"):
        if not chat_component.is_connected("close_requested", _on_chat_component_closed):
            chat_component.connect("close_requested", _on_chat_component_closed)
    get_node("HistoryPanel/Close").pressed.connect(_close_history)

    for child in action_row.get_children():
        if child is Button:
            var action_id := String(child.get_meta("_action", child.name))
            child.pressed.connect(_emit_action_id.bind(action_id))

func _send_chat(text: String) -> void:
    if game and game.running and (game.mode == MODE_2C2 or game.mode == MODE_1C1):
        game.chat(text)
    if chat_component != null:
        chat_component.call("clear_input")
    else:
        chat_input.clear()
    refresh()

func set_result_entry(entry: Dictionary) -> void:
    result_entry = entry.duplicate(true) if entry is Dictionary else {}
    if game != null and not game.running:
        result_label.text = _result_text()
        if result_screen != null and is_instance_valid(result_screen):
            result_screen.configure(game, result_entry)

func set_selected_text(pos: Vector2i) -> void:
    if game == null or pos == game.NO_SQUARE:
        selected_label.text = ""
    else:
        selected_label.text = "Seleccionada · %s" % game.square_name(pos)

func set_suggestion_mode(active: bool) -> void:
    var button: Button = action_row.get_node("Suggest")
    if button == null:
        return
    button.text = "Cancelar" if active else "Sugerir"
    button.add_theme_font_size_override("font_size", _scaled_font(14.0, 20.0))

func flash_message(text: String) -> void:
    status_label.text = text

func refresh() -> void:
    if game == null:
        return

    var is_2c2: bool = game.mode == MODE_2C2

    mode_label.text = _game_mode_title(game.mode)
    time_control_label.text = "%d'" % game.match_minutes
    status_label.text = _status_text()
    moves_label.text = _moves_text()

    _refresh_team_panel(game.TEAM_BLACK, black_info, black_players, black_title)
    _refresh_team_panel(game.TEAM_WHITE, white_info, white_players, white_title)

    var team_name: String = "BLANCAS" if game.current_team() == game.TEAM_WHITE else "NEGRAS"
    turn_label.text = "Turno %s · %s · %s" % [game.current_slot_name(), team_name, _display_owner(game.current_actor_slot())]

    # Separar las acciones que mueven el tablero de las herramientas sociales.
    # Chat, sugerencias, cambio de posiciones y reacciones deben seguir activos
    # durante el turno rival o durante el pensamiento de un bot.
    var user_can_move: bool = game.running and not game.is_bot_turn()
    var chat_enabled: bool = game.mode == MODE_2C2 or game.mode == MODE_1C1
    action_row.get_node("Suggest").visible = is_2c2
    action_row.get_node("Swap").visible = is_2c2
    action_row.get_node("Suggest").disabled = not game.running
    action_row.get_node("Swap").disabled = not game.running
    get_node("Bottom/Chat").visible = chat_enabled and game.running
    get_node("Bottom/Chat").disabled = not game.running
    get_node("Bottom/Emotes").visible = game.mode != MODE_VS_BOT and game.running
    get_node("Bottom/Emotes").disabled = not game.running
    game_menu_button.visible = game.running
    game_menu_button.disabled = not user_can_move
    # En 1c1 competitivo no existe reinicio durante una partida activa.
    # El reinicio queda reservado para partidas locales/bot.
    get_node("Top/Reset").visible = game.mode == MODE_1C1_LOCAL or game.mode == MODE_VS_BOT
    compact_reset.visible = game.mode == MODE_1C1_LOCAL or game.mode == MODE_VS_BOT
    if not user_can_move:
        _close_game_menu()

    # Los movimientos viven directamente bajo el tablero; no necesitamos un
    # segundo panel de "Historial" durante una partida.
    get_node("Bottom/History").visible = false

    if not is_2c2:
        _close_mini()
    if game.mode == MODE_VS_BOT:
        _close_emote_picker()

    _refresh_popups()
    _refresh_emote_event()

    var match_finished: bool = not game.running
    white_info.visible = true
    if not match_finished:
        _result_transition_started = false
        result_panel.visible = false
        if finished_result_button != null:
            finished_result_button.visible = false
        if result_screen != null and is_instance_valid(result_screen):
            result_screen.hide_screen()
        get_node("Bottom").visible = true
    else:
        result_label.text = _result_text()
        result_panel.visible = false
        get_node("Result/ToMenu").visible = true
        get_node("Bottom").visible = false
        turn_label.visible = false
        status_label.visible = false
        if finished_result_button != null:
            finished_result_button.visible = true
        _close_mini()
        _close_chat()
        _close_history()
        _close_emote_picker()
        _close_game_menu()
        if not _result_transition_started:
            _result_transition_started = true
            if result_screen != null and is_instance_valid(result_screen):
                result_screen.configure(game, result_entry)
                result_screen.show_screen()

    _apply_overlay_priorities()
    _queue_layout_refresh()

func _apply_overlay_priorities() -> void:
    # Jerarquía explícita: resultado > confirmaciones > utilidad > controles base.
    get_node("Top").z_index = 10
    get_node("BlackInfo").z_index = 10
    get_node("WhiteInfo").z_index = 10
    get_node("Turn").z_index = 10
    get_node("Selected").z_index = 10
    get_node("Moves").z_index = 10
    get_node("Status").z_index = 10
    get_node("Bottom").z_index = 20
    get_node("EmotePicker").z_index = 30
    get_node("ChatPanel").z_index = 30
    get_node("HistoryPanel").z_index = 30
    get_node("MiniPanel").z_index = 40
    get_node("GameActionMenu").z_index = 45
    get_node("Result").z_index = 100
    if result_panel.visible:
        _close_mini()
        _close_chat()
        _close_history()
        _close_emote_picker()
        _close_game_menu()
        _close_game_menu()

func is_board_input_blocked() -> bool:
    if get_node_or_null("Result") != null and get_node("Result").visible:
        return true
    if get_node_or_null("MiniPanel") != null and get_node("MiniPanel").visible:
        return true
    if get_node_or_null("ChatPanel") != null and get_node("ChatPanel").visible:
        return true
    if get_node_or_null("HistoryPanel") != null and get_node("HistoryPanel").visible:
        return true
    if get_node_or_null("EmotePicker") != null and get_node("EmotePicker").visible:
        return true
    if get_node_or_null("GameActionMenu") != null and get_node("GameActionMenu").visible:
        return true
    return false

func _process(delta: float) -> void:
    if game == null:
        return
    _dynamic_refresh_accumulator += delta
    if _dynamic_refresh_accumulator < 0.10:
        return
    _dynamic_refresh_accumulator = 0.0
    refresh_dynamic_only()

func refresh_dynamic_only() -> void:
    if game == null:
        return
    # Los paneles de jugadores se actualizan por state_changed; este ciclo queda
    # reservado para relojes, cooldowns, overlays y cambios de viewport.
    black_team_clock.text = _clock(game.team_time[game.TEAM_BLACK])
    white_team_clock.text = _clock(game.team_time[game.TEAM_WHITE])
    var match_context = get_node_or_null("/root/MatchContext")
    if match_context != null and match_context.has_method("set_clocks"):
        match_context.set_clocks(float(game.team_time[game.TEAM_WHITE]), float(game.team_time[game.TEAM_BLACK]), "white" if game.current_team() == game.TEAM_WHITE else "black")
    var black_accent := Color("#A85A49")
    var white_accent := Color("#D4A548")
    black_team_clock.modulate = black_accent if game.current_team() == game.TEAM_BLACK else Color("#E6D7BC")
    white_team_clock.modulate = white_accent if game.current_team() == game.TEAM_WHITE else Color("#E6D7BC")
    _refresh_popups()
    var vp := get_viewport_rect().size
    if vp != _last_layout_viewport:
        _queue_layout_refresh()
    if emote_picker and emote_picker.visible:
        emote_picker.refresh()

func _team_signature(team: int) -> String:
    var parts: Array[String] = []
    for slot in range(game.SLOTS):
        if game.slot_colors[slot] != team:
            continue
        parts.append("%d:%s:%s:%s" % [slot, game.slot_profile_ids[slot], game.slot_owners[slot], str(game.slot_active[slot])])
    parts.append("turn=" + str(game.current_slot))
    return "|".join(parts)

func _profile_for_slot(profile_id: String) -> Dictionary:
    var profile: Dictionary = ProfileDataScript.get_profile(profile_id)
    # El jugador local debe reflejar su identidad real, no la ficha de prueba "you".
    if profile_id == "you":
        var player_data = get_node_or_null("/root/PlayerData")
        if player_data != null:
            profile["id"] = String(player_data.profile.get("id", profile.get("id", "USR_LOCAL_PLAYER")))
            profile["name"] = String(player_data.profile.get("name", profile.get("name", "Tú")))
            profile["avatar"] = String(player_data.profile.get("avatar", profile.get("avatar", "")))
            profile["frame"] = player_data.get_appearance("profile_frame", "classic")
            profile["title"] = _player_title_label(player_data.get_appearance("player_title", "jugador"))
            profile["name_color"] = player_data.get_appearance("name_color", "cream")
    return profile

func _player_title_label(title_id: String) -> String:
    match title_id:
        "jugador": return "Jugador"
        "estratega": return "Estratega"
        "veterano": return "Veterano"
    return "Jugador"

func _refresh_team_panel(team: int, panel: Panel, container: GridContainer, title_label: Label) -> void:
    var signature := _team_signature(team)
    var previous := black_signature if team == game.TEAM_BLACK else white_signature
    var accent := Color("#A85A49") if team == game.TEAM_BLACK else Color("#D4A548")
    var team_clock: Label = black_team_clock if team == game.TEAM_BLACK else white_team_clock
    if game.mode == MODE_2C2:
        title_label.text = "Equipo Negro" if team == game.TEAM_BLACK else "Equipo Blanco"
    elif game.mode == MODE_1C1:
        title_label.text = "Rival" if team == game.TEAM_BLACK else "Tú"
    else:
        title_label.text = "Negras" if team == game.TEAM_BLACK else "Blancas"
    title_label.modulate = accent
    team_clock.text = _clock(game.team_time[team])
    _style_team_clock(team_clock, game.current_team() == team, accent)
    var match_context = get_node_or_null("/root/MatchContext")
    if match_context != null and match_context.has_method("update_player"):
        var player_color := "white" if team == game.TEAM_WHITE else "black"
        for slot in range(game.SLOTS):
            if game.slot_colors[slot] != team:
                continue
            var player_profile := _profile_for_slot(String(game.slot_profile_ids[slot]))
            match_context.update_player(player_color, {"id": String(player_profile.get("id", game.slot_profile_ids[slot])), "name": String(player_profile.get("name", "Jugador")), "avatar": String(player_profile.get("avatar", "")), "rating": int(player_profile.get("rating", 0)), "team": player_color, "status": "active" if bool(game.slot_active[slot]) else "inactive"})

    if signature != previous:
        # Evita referencias antiguas al reconstruir las tarjetas.
        for slot in range(game.SLOTS):
            if game.slot_colors[slot] == team:
                cards_by_slot.erase(slot)
        for child in container.get_children():
            child.queue_free()
        for slot in range(game.SLOTS):
            if game.slot_colors[slot] != team:
                continue
            if game.slot_profile_ids[slot].is_empty():
                continue
            var card = PlayerCardScene.instantiate()
            card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            card.custom_minimum_size = Vector2(0.0, 58.0)
            container.add_child(card)
            card.set_meta("slot", slot)
            cards_by_slot[slot] = card
            var profile: Dictionary = _profile_for_slot(game.slot_profile_ids[slot])
            var role: String = String.chr(65 + slot) if game.mode == MODE_2C2 else ("Tú" if slot == 0 else ("IA" if game.mode == MODE_VS_BOT else "Rival"))
            # En 1c1 evitamos que el nombre "Rival" se repita también como título
            # cuando el perfil online todavía no aporta uno real.
            if game.mode == MODE_1C1 and slot != 0:
                var profile_title := String(profile.get("title", profile.get("tag", "")))
                if profile_title.is_empty() or profile_title == String(profile.get("name", "")) or profile_title == "Rival":
                    profile["title"] = "Oponente"
            card.set_profile(profile, role, bool(game.slot_active[slot]), slot == game.current_slot or slot == game.current_actor_slot(), accent)

        if team == game.TEAM_BLACK:
            black_signature = signature
        else:
            white_signature = signature

    for child in container.get_children():
        if not child is Panel or not child.has_method("update_state"):
            continue
        var slot: int = int(child.get_meta("slot", -1))
        if slot < 0:
            continue
        child.update_state(
            bool(game.slot_active[slot]),
            slot == game.current_slot or slot == game.current_actor_slot(),
            accent
        )

func _refresh_emote_event() -> void:
    if game == null:
        return
    var serial := int(game.emote_serial)
    if serial == emote_serial_seen:
        return
    emote_serial_seen = serial
    if serial <= 0:
        return
    var slot := int(game.last_emote_slot)
    var emote_id := String(game.last_emote_id)
    if slot < 0 or emote_id.is_empty():
        return
    var item := EmoteDataScript.get_emote(emote_id)
    if item.is_empty():
        return
    var card = cards_by_slot.get(slot, null)
    if card == null or not is_instance_valid(card):
        return
    var path := String(item.get("path", ""))
    var texture: Texture2D = _emote_texture_cache.get(path, null)
    if texture == null and not path.is_empty():
        texture = load(path) as Texture2D
        if texture != null:
            _emote_texture_cache[path] = texture
    if texture != null:
        card.show_emote(texture)

func show_single_surrender_confirmation() -> void:
    _show_mini_panel(
        "Rendirse",
        "La partida terminará inmediatamente y contará como derrota.",
        "Puedes desactivar esta confirmación en Ajustes.",
        [
            ["Rendirse", "confirm_single_surrender", "#B64B3E"],
            ["Cancelar", "cancel_single_surrender", "#4F6B56"],
        ]
    )

func _on_emote_selected(emote_id: String) -> void:
    if game == null or game.mode == MODE_VS_BOT:
        return
    if game.emote(emote_id):
        _close_emote_picker()
    else:
        if game.emote_cooldown_until > game.now():
            flash_message("Emote en enfriamiento")

func _toggle_emotes() -> void:
    if game == null or game.mode == MODE_VS_BOT or not game.running:
        return
    if emote_picker.visible:
        _close_emote_picker()
        return
    _close_chat()
    _close_history()
    _close_mini()
    emote_picker.visible = true
    emote_picker.set_process(true)
    emote_picker.refresh()
    _resize_for_viewport()

func _close_emote_picker() -> void:
    if emote_picker == null:
        return
    emote_picker.visible = false
    emote_picker.set_process(false)

func _refresh_popups() -> void:
    if game == null or not game.running:
        _close_mini()
        return

    var local_slot: int = game.local_player_slot

    if game.mode == MODE_2C2 and not game.surrender_request.is_empty():
        var waiting := int(game.surrender_request.get("waiting", -1))
        if local_slot == waiting:
            _show_mini_panel(
                "Rendición del compañero",
                "%s propone rendirse. La decisión afecta a todo el equipo." % game.slot_owners[int(game.surrender_request.get("from", 0))],
                "",
                [
                    ["Aceptar", "accept_surrender", "#B64B3E"],
                    ["Rechazar", "reject_surrender", "#4F6B56"],
                ]
            )
            return

    if game.mode == MODE_2C2 and not game.swap_request.is_empty():
        var target := int(game.swap_request.get("to", -1))
        if local_slot == target:
            _show_mini_panel(
                "Cambio de posición",
                "%s quiere intercambiar su posición contigo." % game.slot_owners[int(game.swap_request.get("from", 0))],
                "Intercambio básico · sin costo",
                [
                    ["Aceptar", "accept_swap", "#B48A36"],
                    ["Rechazar", "reject_swap", "#51473A"],
                ]
            )
            return

    if game.mode == MODE_2C2 and int(game.draw_state.get("stage", 0)) == 1:
        var by: int = int(game.draw_state.get("by_slot", -1))
        if local_slot == game.active_teammate(by):
            _show_mini_panel(
                "Oferta de tablas",
                "%s propone tablas. Primero necesitan estar de acuerdo como equipo." % game.slot_owners[by],
                "",
                [
                    ["Aceptar", "accept_draw", "#4F6B56"],
                    ["Rechazar", "reject_draw", "#B64B3E"],
                ]
            )
            return

    if game.mode == MODE_2C2 and int(game.draw_state.get("stage", 0)) == 2:
        var voters: Array[int] = game.required_draw_voters()
        if voters.has(local_slot):
            _show_mini_panel(
                "Tablas solicitadas",
                "El otro equipo aceptó internamente. ¿Aceptas las tablas?",
                "Se requiere acuerdo de los jugadores activos.",
                [
                    ["Aceptar", "accept_draw", "#4F6B56"],
                    ["Rechazar", "reject_draw", "#B64B3E"],
                ]
            )
            return

    if game.mode == MODE_2C2 and not game.suggestion.is_empty():
        var recipient := int(game.suggestion.get("recipient_slot", -1))
        var proposer := int(game.suggestion.get("by_slot", -1))
        var suggestion_status := String(game.suggestion.get("status", "pending"))
        if local_slot == recipient and suggestion_status == "pending":
            _show_suggestion_panel(proposer, Vector2i(game.suggestion["to"]))
            return

    if not mini_panel.visible or mini_panel.get_meta("manual_open", false) != true:
        if mini_panel.visible:
            _close_mini()

func _show_suggestion_panel(proposer: int, target_square: Vector2i) -> void:
    if overlay_controller == null or game == null:
        return
    overlay_controller.show_suggestion(_display_owner(proposer), game.square_name(target_square))

func _show_mini_panel(title: String, body: String, cooldown: String, actions: Array) -> void:
    if overlay_controller == null:
        return
    overlay_controller.show_panel(title, body, cooldown, actions, _mobile_scale)

func _on_mini_title_gui_input(event: InputEvent) -> void:
    if overlay_controller != null:
        overlay_controller.handle_title_input(event)

func _move_suggestion_panel(target: Vector2) -> void:
    if overlay_controller != null:
        overlay_controller.move_to(target)

func _on_overlay_action(action: String) -> void:
    action_requested.emit(action)
    _close_mini()

func _toggle_game_menu() -> void:
    if game == null or not game.running or game_menu_button == null:
        return
    if game_action_menu.visible:
        _close_game_menu()
        return
    _close_mini()
    _close_chat()
    _close_history()
    _close_emote_picker()
    var anchor := game_menu_button.get_global_rect()
    var board_rect := LayoutMetrics.board_rect(get_viewport_rect().size, false)
    game_action_menu.show_menu(anchor, get_viewport_rect().size, board_rect.end.y + 4.0)

func _close_game_menu() -> void:
    if game_action_menu != null:
        game_action_menu.hide_menu()

func _on_game_menu_action(action: String) -> void:
    _close_game_menu()
    action_requested.emit(action)

func _toggle_history() -> void:
    if history_panel.visible:
        _close_history()
    else:
        _close_chat()
        _close_mini()
        history_panel.visible = true

func _refresh_history() -> void:
    if game == null:
        return
    var lines: Array[String] = []
    var count: int = game.move_history.size()
    var start: int = max(0, count - 16)
    # Planilla tradicional: cada fila agrupa la jugada blanca y la negra.
    # Se mantiene el panel dentro del HUD actual y el historial más reciente.
    start -= start % 2
    for i in range(start, count, 2):
        var white_move: Dictionary = game.move_history[i] if i < count else {}
        var black_move: Dictionary = game.move_history[i + 1] if i + 1 < count else {}
        var white_text := "%s→%s" % [String(white_move.get("from", "")), String(white_move.get("to", ""))] if not white_move.is_empty() else "—"
        var black_text := "%s→%s" % [String(black_move.get("from", "")), String(black_move.get("to", ""))] if not black_move.is_empty() else "—"
        lines.append("%-3d  %-12s  %s" % [int(i / 2) + 1, white_text, black_text])
    history_lines.text = "1. Blancas           Negras\n" + "\n".join(lines) if not lines.is_empty() else "Todavía no hay movimientos."

func _toggle_chat() -> void:
    if game == null or not game.running or not (game.mode == MODE_2C2 or game.mode == MODE_1C1):
        return
    if chat_panel.visible:
        _close_chat()
    else:
        _close_history()
        _close_mini()
        _close_emote_picker()
        _close_game_menu()
        _refresh_chat()
        if chat_component != null:
            chat_component.call("open_chat")
        else:
            chat_panel.visible = true
            chat_input.grab_focus()
        _queue_layout_refresh()

func _refresh_chat() -> void:
    if game == null:
        return
    var content := "\n".join(game.chat_history)
    if chat_component != null:
        chat_component.call("set_messages", content)
    else:
        chat_messages.text = content
    chat_input.placeholder_text = "Escribir"

func _close_mini() -> void:
    if overlay_controller != null:
        overlay_controller.close()
    else:
        mini_panel.visible = false
    _mini_dragging = false

func _close_chat() -> void:
    if chat_component != null:
        chat_component.call("close_chat")
    else:
        chat_panel.visible = false

func _on_chat_component_closed() -> void:
    _queue_layout_refresh()

func _close_history() -> void:
    history_panel.visible = false

func _game_mode_title(mode_value: int) -> String:
    match mode_value:
        MODE_2C2:
            return "AJEDREZ 2c2  ·  COOPERATIVO"
        MODE_1C1:
            return "AJEDREZ 1c1  ·  ONLINE"
        MODE_VS_BOT:
            return "AJEDREZ  ·  VS IA"
        MODE_1C1_LOCAL:
            return "AJEDREZ 1c1  ·  LOCAL"
    return "AJEDREZ"

func _display_owner(slot: int) -> String:
    if slot < 0 or slot >= game.SLOTS:
        return "Sin representante"
    var profile_id: String = game.slot_profile_ids[slot]
    if not profile_id.is_empty():
        return String(ProfileDataScript.get_profile(profile_id).get("name", game.slot_owners[slot]))
    return game.slot_owners[slot]

func _clock(seconds: float) -> String:
    var total: int = max(0, int(ceil(seconds)))
    return "%02d:%02d" % [int(total / 60), total % 60]

func _moves_text() -> String:
    var count: int = game.move_history.size()
    if count == 0:
        return "Movimientos"
    var start: int = max(0, count - 12)
    start -= start % 2
    var parts: Array[String] = []
    for i in range(start, count, 2):
        var white_move: Dictionary = game.move_history[i] if i < count else {}
        var black_move: Dictionary = game.move_history[i + 1] if i + 1 < count else {}
        var white_text := "%s→%s" % [String(white_move.get("from", "")), String(white_move.get("to", ""))] if not white_move.is_empty() else "—"
        var black_text := "%s→%s" % [String(black_move.get("from", "")), String(black_move.get("to", ""))] if not black_move.is_empty() else ""
        parts.append("%d. %s%s" % [int(i / 2) + 1, white_text, "   " + black_text if not black_text.is_empty() else ""])
    return "   ·   ".join(parts)

func _status_text() -> String:
    if not game.running:
        return "Partida terminada"
    if game.pending_promotion != game.NO_SQUARE:
        return "Elige la promoción de tu peón"
    if game.mode == MODE_2C2:
        if not game.suggestion.is_empty():
            return "Hay una sugerencia de tu compañero."
        if not game.swap_request.is_empty():
            return "Tu compañero propuso un cambio de posición."
    var team := "blancas" if game.current_team() == game.TEAM_WHITE else "negras"
    return "Turno de las %s" % team.capitalize()

func _signed_value(value: int) -> String:
    return "+%d" % value if value > 0 else str(value)

func _result_text() -> String:
    var lines: Array[String] = []
    if game.winner_team < 0:
        lines.append("TABLAS")
    else:
        var local_team: int = int(game.slot_colors[0]) if game.slot_colors.size() > 0 else -1
        var personal := "VICTORIA" if local_team == game.winner_team else "DERROTA"
        var is_mate := String(game.winner_reason).to_lower().contains("mate")
        lines.append("JAQUE MATE" if is_mate else personal)
        if is_mate:
            lines.append(personal)
        # En 1c1 el resultado personal ya comunica el desenlace; evitamos
        # una línea redundante para reservar espacio al progreso competitivo.
        if game.mode != MODE_1C1:
            lines.append("Ganan las blancas" if game.winner_team == game.TEAM_WHITE else "Ganan las negras")
    if game.winner_team < 0:
        lines.append(String(game.winner_reason))
    if not result_entry.is_empty() and bool(result_entry.get("competitive", game.mode == MODE_2C2 or game.mode == MODE_1C1)):
        var rating_delta := int(result_entry.get("rating_delta", 0))
        var cup_delta := int(result_entry.get("cup_delta", 0))
        # El 1c1 muestra su progreso propio en el resultado; 2c2 conserva
        # exactamente su presentación actual.
        lines.append("Rating %s · Copas %s" % [_signed_value(rating_delta), _signed_value(cup_delta)])
        if game.mode == MODE_1C1:
            var rating_after := int(result_entry.get("rating_after", 0))
            var cups_after := int(result_entry.get("cups_after", 0))
            var league_after := String(result_entry.get("league_after", "Bronce"))
            var streak_after := int(result_entry.get("streak_after", 0))
            lines.append("%d · 🏆%d · %s · Racha %d" % [rating_after, cups_after, league_after, streak_after])
    else:
        lines.append("%d jugadas · partida guardada" % game.move_history.size())
    return "\n".join(lines)

func _animate_result_transition() -> void:
    # Compatibilidad con la implementación anterior: el resultado ahora es
    # un menú independiente animado por GameMatchResultScreen.
    pass

func _emit_action_id(action_id: String) -> void:
    action_requested.emit(action_id)

func _return_home_from_result() -> void:
    back_requested.emit()

func _new_game_from_result() -> void:
    # El flujo de nueva partida pertenece al controlador principal.
    # Reutilizamos la misma señal para no duplicar lógica de navegación/reset.
    rematch_requested.emit()

func _close_result_screen() -> void:
    if result_screen != null and is_instance_valid(result_screen):
        result_screen.hide_screen()
    if finished_result_button != null:
        finished_result_button.visible = true
    _queue_layout_refresh()

func _reopen_result_screen() -> void:
    if game == null or game.running or result_screen == null or not is_instance_valid(result_screen):
        return
    result_screen.configure(game, result_entry)
    result_screen.show_screen()
    if finished_result_button != null:
        finished_result_button.visible = false

func show_result_screen_after_reconnect() -> void:
    # A reconnect after a completed match returns to the final-result overlay.
    # It intentionally does not change match state or start another transition.
    if game == null or game.running or result_screen == null or not is_instance_valid(result_screen):
        return
    result_screen.configure(game, result_entry)
    result_screen.show_screen()
    if finished_result_button != null:
        finished_result_button.visible = false

func _set_local_rect(control: Control, rect: Rect2) -> void:
    hud_layout._set_local_rect(control, rect)

func _place(control: Control, rect: Rect2) -> void:
    hud_layout._place(control, rect)

func _style_team_clock(clock_label: Label, active: bool, accent: Color) -> void:
    hud_layout._style_team_clock(clock_label, active, accent)

func _set_team_panel_layout(panel: Panel, title_label: Label, clock_label: Label, players: GridContainer, rect: Rect2, columns: int) -> void:
    hud_layout._set_team_panel_layout(panel, title_label, clock_label, players, rect, columns)

func _default_button_width(full_text: String) -> float:
    return hud_layout._default_button_width(full_text)

func _visible_button_width(button: Button) -> float:
    return hud_layout._visible_button_width(button)

func _layout_bottom_controls(compact: bool) -> void:
    hud_layout._layout_bottom_controls(compact)

func _resize_for_viewport() -> void:
    hud_layout._resize_for_viewport()
