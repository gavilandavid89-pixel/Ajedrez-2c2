extends RefCounted
class_name ChessGameMatchLifecycleService

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var mode: int:
    get: return int(host.mode)
    set(value): host.mode = value
var board: Array:
    get: return host.board
    set(value): host.board = value
var slot_owners: Variant:
    get: return host.slot_owners
    set(value): host.slot_owners = value
var slot_colors: Variant:
    get: return host.slot_colors
    set(value): host.slot_colors = value
var slot_active: Variant:
    get: return host.slot_active
    set(value): host.slot_active = value
var slot_profile_ids: Variant:
    get: return host.slot_profile_ids
    set(value): host.slot_profile_ids = value
var current_slot: int:
    get: return int(host.current_slot)
    set(value): host.current_slot = value
var local_player_slot: int:
    get: return int(host.local_player_slot)
    set(value): host.local_player_slot = value
var selected: Vector2i:
    get: return host.selected
    set(value): host.selected = value
var running: bool:
    get: return bool(host.running)
    set(value): host.running = value
var winner_team: int:
    get: return int(host.winner_team)
    set(value): host.winner_team = value
var winner_reason: String:
    get: return String(host.winner_reason)
    set(value): host.winner_reason = value
var strategic_mode: bool:
    get: return bool(host.strategic_mode)
    set(value): host.strategic_mode = value
var suggestion: Dictionary:
    get: return host.suggestion
    set(value): host.suggestion = value
var suggestion_cooldown_until: float:
    get: return float(host.suggestion_cooldown_until)
    set(value): host.suggestion_cooldown_until = value
var question_cooldown_until: float:
    get: return float(host.question_cooldown_until)
    set(value): host.question_cooldown_until = value
var emote_cooldown_until: float:
    get: return float(host.emote_cooldown_until)
    set(value): host.emote_cooldown_until = value
var last_emote_id: String:
    get: return String(host.last_emote_id)
    set(value): host.last_emote_id = value
var last_emote_slot: int:
    get: return int(host.last_emote_slot)
    set(value): host.last_emote_slot = value
var emote_serial: int:
    get: return int(host.emote_serial)
    set(value): host.emote_serial = value
var surrender_request: Dictionary:
    get: return host.surrender_request
    set(value): host.surrender_request = value
var draw_state: Dictionary:
    get: return host.draw_state
    set(value): host.draw_state = value
var swap_request: Dictionary:
    get: return host.swap_request
    set(value): host.swap_request = value
var last_seen: Variant:
    get: return host.last_seen
    set(value): host.last_seen = value
var match_minutes: int:
    get: return int(host.match_minutes)
    set(value): host.match_minutes = value
var match_seconds: float:
    get: return float(host.match_seconds)
    set(value): host.match_seconds = value
var team_time: Variant:
    get: return host.team_time
    set(value): host.team_time = value
var castling_rights: Dictionary:
    get: return host.castling_rights
    set(value): host.castling_rights = value
var en_passant_target: Vector2i:
    get: return host.en_passant_target
    set(value): host.en_passant_target = value
var pending_promotion: Vector2i:
    get: return host.pending_promotion
    set(value): host.pending_promotion = value
var pending_move_index: int:
    get: return int(host.pending_move_index)
    set(value): host.pending_move_index = value
var move_history: Array[Dictionary]:
    get: return host.move_history
    set(value): host.move_history = value
var chat_history: Array[String]:
    get: return host.chat_history
    set(value): host.chat_history = value
var emote_history: Array[String]:
    get: return host.emote_history
    set(value): host.emote_history = value
var replay_states: Array[Dictionary]:
    get: return host.replay_states
    set(value): host.replay_states = value
var pair_stats: Dictionary:
    get: return host.pair_stats
    set(value): host.pair_stats = value

const TEAM_WHITE := 0
const TEAM_BLACK := 1
const SLOTS := 4
const ABSENCE_SECONDS := 60.0
const MATCH_SECONDS := 600.0
const DEFAULT_MATCH_MINUTES := 10
const NO_SQUARE := Vector2i(-1, -1)
const MODE_2C2 := 0
const MODE_1C1 := 1
const MODE_VS_BOT := 2
const MODE_1C1_LOCAL := 3

func now() -> float:
    return Time.get_ticks_msec() / 1000.0

func reset_match(new_mode: int = MODE_2C2, new_time_minutes: int = -1) -> void:
    mode = clamp(new_mode, MODE_2C2, MODE_1C1_LOCAL)
    var configured_minutes := new_time_minutes
    var app = _app()
    configured_minutes = int(app.selected_time_minutes) if configured_minutes <= 0 and app != null else (DEFAULT_MATCH_MINUTES if configured_minutes <= 0 else configured_minutes)
    match_minutes = clampi(configured_minutes, 1, 60)
    match_seconds = float(match_minutes) * 60.0
    board = [
        ["torre_negro","caballo_negro","alfil_negro","dama_negro","rey_negro","alfil_negro","caballo_negro","torre_negro"],
        ["peon_negro","peon_negro","peon_negro","peon_negro","peon_negro","peon_negro","peon_negro","peon_negro"],
        ["","","","","","","",""],
        ["","","","","","","",""],
        ["","","","","","","",""],
        ["","","","","","","",""],
        ["peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca"],
        ["torre_blanca","caballo_blanca","alfil_blanca","dama_blanca","rey_blanca","alfil_blanca","caballo_blanca","torre_blanca"]
    ]

    if mode == MODE_2C2:
        slot_owners = ["Jugador A", "Jugador B", "Jugador C", "Jugador D"]
        slot_active = [true, true, true, true]
        slot_profile_ids = ["you", "rival1", "mate", "rival2"]
        strategic_mode = true
        _emit_log("Nueva partida 2c2: roles listos")
    elif mode == MODE_1C1:
        slot_owners = ["Tú", "Rival", "", ""]
        slot_active = [true, true, false, false]
        slot_profile_ids = ["you", "rival", "", ""]
        strategic_mode = false
        _emit_log("Nueva partida 1c1 online: roles listos")
    elif mode == MODE_VS_BOT:
        slot_owners = ["Jugador", "Bot", "", ""]
        slot_active = [true, true, false, false]
        slot_profile_ids = ["you", "bot", "", ""]
        strategic_mode = false
        _emit_log("Nueva partida contra Bot: roles listos")
    else:
        slot_owners = ["Jugador 1", "Jugador 2", "", ""]
        slot_active = [true, true, false, false]
        slot_profile_ids = ["local1", "local2", "", ""]
        strategic_mode = false
        _emit_log("Nueva partida 1c1 local: roles listos")

    slot_colors = [TEAM_WHITE, TEAM_BLACK, TEAM_WHITE, TEAM_BLACK] if mode == MODE_2C2 else [TEAM_WHITE, TEAM_BLACK, -1, -1]
    current_slot = 0
    host.delegated_turn_actor.clear()
    selected = NO_SQUARE
    running = true
    winner_team = -1
    winner_reason = ""
    suggestion = {}
    suggestion_cooldown_until = 0.0
    question_cooldown_until = 0.0
    emote_cooldown_until = 0.0
    last_emote_id = ""
    last_emote_slot = -1
    emote_serial = 0
    surrender_request = {}
    draw_state = {"stage": 0, "by_slot": -1, "target_team": -1, "accepted_by": []}
    swap_request = {}
    var t: float = now()
    last_seen = [t, t, t, t]
    team_time = [match_seconds, match_seconds]
    castling_rights = {"WK": true, "WQ": true, "BK": true, "BQ": true}
    en_passant_target = NO_SQUARE
    host.halfmove_clock = 0
    host.position_repetition_counts.clear()
    host.match_uid = "%d-%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), randi()]
    pending_promotion = NO_SQUARE
    pending_move_index = -1
    move_history.clear()
    chat_history.clear()
    emote_history.clear()
    replay_states.clear()
    pair_stats = {}
    host.bot_slots.clear()
    if mode == MODE_VS_BOT:
        if app != null:
            host.bot_id = String(app.selected_bot_id)
            host.bot_target_elo = int(app.selected_bot_elo)
            host.bot_target_nexus = int(app.selected_bot_nexus)
        host.bot_slots[1] = host.bot_id
    if mode == MODE_2C2:
        ensure_pair_stats()
        if app != null and bool(app.temporary_online_bots):
            host.set_temporary_bot(1, "nora")
            host.set_temporary_bot(2, "tactico")
            host.set_temporary_bot(3, "estratega")
    elif mode == MODE_1C1:
        if app != null and bool(app.temporary_online_bots):
            host.set_temporary_bot(1, "nora")
    host.refresh_team_delegation_policy()
    host._capture_replay_state()
    host.state_changed.emit()

func process(delta: float) -> void:
    if not running or pending_promotion != NO_SQUARE:
        return
    var team: int = current_team()
    team_time[team] = max(0.0, team_time[team] - delta)
    if team_time[team] <= 0.0:
        finish(1 - team, "Tiempo agotado")
        return
    _check_absence()

func _check_absence() -> void:
    if mode != MODE_2C2:
        return
    var slot: int = current_slot
    if slot < 0 or slot >= SLOTS or not slot_active[slot]:
        return
    var t: float = now()
    if t - last_seen[slot] < ABSENCE_SECONDS:
        return
    slot_active[slot] = false
    if host.team_delegation_policy != null:
        host.team_delegation_policy.set_player_status(String(slot_profile_ids[slot]), "disconnected")
    _emit_log("%s quedó AUSENTE." % slot_owners[slot])
    var team: int = slot_colors[slot]
    if not any_active_on_team(team):
        finish(1 - team, "Equipo completo ausente")
        return
    _normalize_current_turn()
    host.state_changed.emit()

func ensure_pair_stats() -> void:
    # Estado transitorio del ciclo de partida para compatibilidad con la UX
    # antigua. No es fuente competitiva: NEXUS-TEAM persistente se actualiza
    # después mediante GameMatchResultService/PlayerData.
    for team in range(2):
        var key: String = pair_key_for_team(team)
        if not pair_stats.has(key):
            pair_stats[key] = {"rating": 1000, "best_rating": 1000, "games": 0, "wins": 0, "losses": 0, "draws": 0, "streak": 0}

func pair_key_for_team(team: int) -> String:
    var names: Array[String] = []
    for i in range(SLOTS):
        if slot_colors[i] == team:
            names.append(slot_owners[i])
    names.sort()
    return "%s & %s" % [names[0], names[1]]

func any_active_on_team(team: int) -> bool:
    for i in range(SLOTS):
        if slot_colors[i] == team and slot_active[i]:
            return true
    return false

func active_teammate(slot: int) -> int:
    if slot < 0 or slot >= SLOTS:
        return -1
    var team: int = slot_colors[slot]
    for i in range(SLOTS):
        if i != slot and slot_colors[i] == team:
            return i
    return -1

func current_team() -> int:
    return slot_colors[current_slot]

func current_actor_slot() -> int:
    if current_slot < 0 or current_slot >= SLOTS:
        return -1
    # Once a delegated turn has started, reconnecting the original owner does
    # not steal that turn back. The lock is cleared only by advance_turn().
    if host.delegated_turn_actor.has(current_slot):
        var locked_actor := int(host.delegated_turn_actor[current_slot])
        return locked_actor if locked_actor >= 0 and locked_actor < SLOTS and bool(slot_active[locked_actor]) else -1
    if bool(slot_active[current_slot]):
        return current_slot
    var mate := _covering_teammate(current_slot)
    if mate >= 0:
        host.delegated_turn_actor[current_slot] = mate
    return mate

func _covering_teammate(slot: int) -> int:
    var mate := active_teammate(slot)
    if mate < 0 or not bool(slot_active[mate]):
        return -1
    if host.team_delegation_policy != null and mode == MODE_2C2:
        var actor_id := String(slot_profile_ids[mate])
        var owner_id := String(slot_profile_ids[slot])
        # Keep compatibility with existing local absence flows/tests that set
        # slot_active directly: inactive slot is the authoritative local signal.
        if String(host.team_delegation_policy.player_status.get(owner_id, "")) == "connected":
            host.team_delegation_policy.set_player_status(owner_id, "disconnected")
        return mate if host.team_delegation_policy.can_control_seat(actor_id, owner_id, String(host.match_uid)) else -1
    return mate

func _normalize_current_turn() -> void:
    return

func current_owner() -> String:
    var actor: int = current_actor_slot()
    return "Sin representante" if actor < 0 else slot_owners[actor]

func current_slot_name() -> String:
    return String.chr(65 + current_slot)


func randomize_roles() -> void:
    # El rol de juego es independiente de la apariencia equipada.
    # El slot local (0) puede ser Blancas o Negras; en 2c2 su compañero
    # ocupa el mismo bando y los dos rivales el contrario.
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var local_team: int = TEAM_WHITE if rng.randi_range(0, 1) == 0 else TEAM_BLACK
    assign_roles_for_local_team(local_team)

func assign_roles_for_local_team(local_team: int) -> void:
    # Método determinista para pruebas/reconexión: permite fijar el rol local
    # sin tocar la lógica de apariencia ni las reglas del tablero.
    var normalized: int = TEAM_BLACK if local_team == TEAM_BLACK else TEAM_WHITE
    var rival_team: int = TEAM_BLACK if normalized == TEAM_WHITE else TEAM_WHITE
    if mode == MODE_2C2:
        slot_colors = [normalized, rival_team, normalized, rival_team]
    else:
        slot_colors = [normalized, rival_team, -1, -1]
    # Siempre comienza el bando de Blancas, pero el jugador local puede ser
    # ese bando o el rival. Esto evita que el primer turno dependa del slot 0.
    var active_count := SLOTS if mode == MODE_2C2 else 2
    current_slot = -1
    for i in range(active_count):
        if slot_colors[i] == TEAM_WHITE:
            current_slot = i
            break
    if current_slot < 0:
        current_slot = 0

func local_team() -> int:
    if local_player_slot < 0 or local_player_slot >= slot_colors.size():
        return -1
    return int(slot_colors[local_player_slot])

func set_local_player_slot(slot: int) -> bool:
    if slot < 0 or slot >= SLOTS:
        return false
    local_player_slot = slot
    host.state_changed.emit()
    return true

func is_2c2() -> bool:
    return mode == MODE_2C2

func set_slot_profile(slot: int, profile_id: String, display_name: String = "") -> bool:
    if slot < 0 or slot >= SLOTS or profile_id.strip_edges().is_empty():
        return false
    slot_profile_ids[slot] = profile_id.strip_edges()
    if not display_name.strip_edges().is_empty():
        slot_owners[slot] = display_name.strip_edges()
    host.refresh_team_delegation_policy()
    host.state_changed.emit()
    return true

func mark_seen(slot: int) -> void:
    if slot < 0 or slot >= SLOTS:
        return
    last_seen[slot] = now()
    slot_active[slot] = true

func advance_turn() -> void:
    var previous_slot := current_slot
    host.delegated_turn_actor.erase(previous_slot)
    var count := SLOTS if mode == MODE_2C2 else 2
    for step in range(1, count + 1):
        var candidate: int = (current_slot + step) % count
        if mode != MODE_2C2 or slot_active[candidate] or any_active_on_team(slot_colors[candidate]):
            current_slot = candidate
            break
    # A seat that is already disconnected when its turn begins is delegated
    # immediately. If it reconnects during this turn, the lock remains until
    # the next advance_turn call.
    if mode == MODE_2C2 and not bool(slot_active[current_slot]):
        var mate := active_teammate(current_slot)
        if mate >= 0 and bool(slot_active[mate]):
            host.delegated_turn_actor[current_slot] = mate
    host.state_changed.emit()

func mark_current_absent() -> void:
    if mode != MODE_2C2 or not running:
        return
    var team := current_team()
    slot_active[current_slot] = false
    if host.team_delegation_policy != null:
        host.team_delegation_policy.set_player_status(String(slot_profile_ids[current_slot]), "disconnected")
    _emit_log("🟡 %s quedó AUSENTE." % slot_owners[current_slot])
    if not any_active_on_team(team):
        finish(1 - team, "Equipo completo ausente")
        return
    host.state_changed.emit()

func force_slot_absent(slot: int) -> void:
    if mode != MODE_2C2 or slot < 0 or slot >= SLOTS or not running:
        return
    slot_active[slot] = false
    if host.team_delegation_policy != null:
        host.team_delegation_policy.set_player_status(String(slot_profile_ids[slot]), "disconnected")
    last_seen[slot] = now() - ABSENCE_SECONDS - 1.0
    _emit_log("🟡 %s quedó AUSENTE." % slot_owners[slot])
    if not any_active_on_team(slot_colors[slot]):
        finish(1 - slot_colors[slot], "Equipo completo ausente")
    host.state_changed.emit()

func return_player(slot: int) -> bool:
    if mode != MODE_2C2 or slot < 0 or slot >= SLOTS or not running:
        return false
    slot_active[slot] = true
    last_seen[slot] = now()
    if host.team_delegation_policy != null:
        host.team_delegation_policy.set_player_status(String(slot_profile_ids[slot]), "connected")
    _emit_log("🟢 %s regresó a la partida." % slot_owners[slot])
    host.state_changed.emit()
    return true

func return_current_player() -> bool:
    return return_player(current_slot)

func finish(winning_team: int, reason: String) -> void:
    if not running:
        return
    running = false
    if host.team_delegation_policy != null:
        host.team_delegation_policy.set_match_terminal(String(host.match_uid))
    winner_team = winning_team
    winner_reason = reason
    if mode == MODE_2C2:
        ensure_pair_stats()
        for team in range(2):
            var key: String = pair_key_for_team(team)
            var stats: Dictionary = pair_stats[key]
            stats["games"] = int(stats["games"]) + 1
            if winning_team == team:
                stats["wins"] = int(stats["wins"]) + 1
                stats["streak"] = int(stats["streak"]) + 1
                stats["rating"] = int(stats["rating"]) + 15
                stats["best_rating"] = max(int(stats.get("best_rating", 1000)), int(stats["rating"]))
            elif winning_team >= 0:
                stats["losses"] = int(stats.get("losses", 0)) + 1
                stats["streak"] = 0
                stats["rating"] = max(0, int(stats["rating"]) - 10)
            else:
                # A draw is a completed game, but neither a win nor a loss.
                # Reset streaks and leave the transient rating unchanged.
                stats["draws"] = int(stats.get("draws", 0)) + 1
                stats["streak"] = 0
            pair_stats[key] = stats
    _emit_log("FIN: %s — %s" % ["Tablas" if winning_team < 0 else ("Blancas ganan" if winning_team == TEAM_WHITE else "Negras ganan"), reason])
    host.match_finished.emit(winning_team, reason)
    host.state_changed.emit()

func _app() -> Node:
    return RuntimeServicesScript_get_autoload("App")

func RuntimeServicesScript_get_autoload(name: String) -> Node:
    var services_script := load("res://core/services/runtime_services.gd")
    return services_script.get_autoload(name)

func _emit_log(text: String) -> void:
    host._emit_log(text)
