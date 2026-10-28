extends RefCounted
class_name GameInputController

const AppConfig = preload("res://core/services/app.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var game: Variant:
    get: return host.game
var board_view: Variant:
    get: return host.board_view
var hud: Variant:
    get: return host.hud
var suggestion_mode: bool:
    get: return bool(host.suggestion_mode)
    set(value): host.suggestion_mode = value
var _pointer_down: bool:
    get: return bool(host._pointer_down)
    set(value): host._pointer_down = value
var _pointer_down_square: Vector2i:
    get: return host._pointer_down_square
    set(value): host._pointer_down_square = value

func _input(event: InputEvent) -> void:
    # QA observation runs before gameplay guards so it can reveal taps ignored
    # by overlays, animation locks, bot turns, or a stopped match. It never
    # consumes input and never changes the match.
    var touch_event := event as InputEventScreenTouch
    var observed_square := Vector2i(-1, -1)
    var selected_before := Vector2i(-1, -1)
    var moves_before := 0
    if touch_event != null:
        if board_view != null:
            observed_square = _logical_square_at(touch_event.position)
            selected_before = board_view.selected
        if game != null:
            moves_before = game.move_history.size()
        var hub = RuntimeServicesScript.get_autoload("SupervisorHub")
        if hub != null and hub.has_method("observe_touch"):
            var blocked_reason := ""
            if game == null or board_view == null:
                blocked_reason = "game_or_board_unavailable"
            elif not game.running:
                blocked_reason = "match_not_running"
            elif game.pending_promotion != game.NO_SQUARE:
                blocked_reason = "promotion_pending"
            elif game.is_bot_turn() and not suggestion_mode:
                blocked_reason = "bot_turn"
            elif hud != null and hud.has_method("is_board_input_blocked") and hud.is_board_input_blocked():
                blocked_reason = "hud_blocks_board_input"
            elif board_view.has_method("is_move_animation_active") and board_view.is_move_animation_active():
                blocked_reason = "move_animation_active"
            hub.observe_touch(touch_event.pressed, touch_event.position, observed_square, selected_before, game != null and game.running, blocked_reason, touch_event.index)
    if game == null or board_view == null or not game.running:
        return
    if game.pending_promotion != game.NO_SQUARE:
        return
    # El turno del bot bloquea movimientos reales, no la selección de una
    # sugerencia cooperativa: sugerir debe estar disponible en todo momento.
    if game.is_bot_turn() and not suggestion_mode:
        return
    if hud != null and hud.has_method("is_board_input_blocked") and hud.is_board_input_blocked():
        return
    if board_view.has_method("is_move_animation_active") and board_view.is_move_animation_active():
        return

    if touch_event == null:
        return

    var point: Vector2 = touch_event.position
    if touch_event.pressed:
        # Track one active pointer. A second finger must not replace the origin
        # square or let its release complete another finger's move.
        if _pointer_down:
            if touch_event.index != int(host._active_pointer_index):
                _observe_touch_result("secondary_pointer_ignored", selected_before, moves_before)
            return

        var logical := _logical_square_at(point)
        _pointer_down = logical != Vector2i(-1, -1)
        _pointer_down_square = logical
        host._active_pointer_index = touch_event.index if _pointer_down else -1
        # Select immediately on the first tap; suggestion mode must not require
        # a double-tap or a release/repress cycle to register the origin piece.
        if _pointer_down:
            _on_board_square(logical)
            host.get_viewport().set_input_as_handled()
        _observe_touch_result("press_processed" if _pointer_down else "press_outside_board", selected_before, moves_before)
        return

    # Only the pointer that began on the board may complete its tap or drag.
    # HUD taps, outside touches, and other fingers must never leak into a move.
    if not _pointer_down or touch_event.index != int(host._active_pointer_index):
        _observe_touch_result("release_without_matching_board_press", selected_before, moves_before)
        return
    var press_square := _pointer_down_square
    _pointer_down = false
    _pointer_down_square = Vector2i(-1, -1)
    host._active_pointer_index = -1
    if press_square != Vector2i(-1, -1) and board_view.selected != Vector2i(-1, -1):
        var release_square := _logical_square_at(point)
        if release_square != Vector2i(-1, -1) and release_square != press_square and release_square != board_view.selected:
            _on_board_square(release_square)
            host.get_viewport().set_input_as_handled()
    _observe_touch_result("release_processed", selected_before, moves_before)

func _observe_touch_result(code: String, selected_before: Vector2i, moves_before: int) -> void:
    var hub = RuntimeServicesScript.get_autoload("SupervisorHub")
    if hub == null or not hub.has_method("observe_touch_result") or game == null or board_view == null:
        return
    hub.observe_touch_result(code, selected_before, board_view.selected, moves_before, game.move_history.size(), suggestion_mode)

func _logical_square_at(point: Vector2) -> Vector2i:
    if board_view == null:
        return Vector2i(-1, -1)
    var local_point: Vector2 = board_view.get_global_transform_with_canvas().affine_inverse() * point
    if not board_view.board_rect.has_point(local_point):
        return Vector2i(-1, -1)
    var cell: float = board_view.board_rect.size.x / 8.0
    if cell <= 0.0:
        return Vector2i(-1, -1)
    var sx := int(floor((local_point.x - board_view.board_rect.position.x) / cell))
    var sy := int(floor((local_point.y - board_view.board_rect.position.y) / cell))
    if sx < 0 or sx >= 8 or sy < 0 or sy >= 8:
        return Vector2i(-1, -1)
    var logical := Vector2i(sx, sy)
    if board_view.flipped:
        logical = Vector2i(7 - sx, 7 - sy)
    return logical if game != null and game.rules.inside(logical) else Vector2i(-1, -1)

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") and game != null and (game.mode == AppConfig.MODE_2C2 or game.mode == AppConfig.MODE_1C1) and game.running:
        host.get_viewport().set_input_as_handled()

func _on_board_square(pos: Vector2i) -> void:
    if not game.running or game.pending_promotion != game.NO_SQUARE:
        return

    if game.is_bot_turn() and not suggestion_mode:
        return

    var piece: Variant = game.get_piece(pos)

    # Modo Sugerir: no ejecuta movimientos. Solo registra la intención
    # origen -> destino para que el compañero la vea como flecha fantasma.
    if suggestion_mode:
        if board_view.selected == Vector2i(-1, -1):
            if piece != "" and _local_team_piece_allowed(String(piece)):
                board_view.set_selected(pos)
                hud.set_selected_text(pos)
                hud.flash_message("Ahora toca la casilla donde quieres que vaya")
            return

        if pos == board_view.selected:
            board_view.set_selected(Vector2i(-1, -1))
            hud.set_selected_text(game.NO_SQUARE)
            hud.flash_message("Sugerencia cancelada")
            suggestion_mode = false
            hud.set_suggestion_mode(false)
            return

        if piece != "" and _local_team_piece_allowed(String(piece)):
            board_view.set_selected(pos)
            hud.set_selected_text(pos)
            return

        var sent: bool = bool(game.propose_suggestion(board_view.selected, pos))
        board_view.set_selected(Vector2i(-1, -1))
        hud.set_selected_text(game.NO_SQUARE)
        suggestion_mode = false
        hud.set_suggestion_mode(false)
        if sent:
            hud.flash_message("Sugerencia enviada al compañero")
        else:
            hud.flash_message("No se puede sugerir ese movimiento")
        host._on_state_changed()
        return

    if board_view.selected == Vector2i(-1, -1):
        if piece != "" and game.current_piece_allowed(piece):
            board_view.set_selected(pos)
            hud.set_selected_text(pos)
        return

    if pos == board_view.selected:
        board_view.set_selected(Vector2i(-1, -1))
        hud.set_selected_text(game.NO_SQUARE)
        return

    if piece != "" and game.current_piece_allowed(piece):
        board_view.set_selected(pos)
        hud.set_selected_text(pos)
        return

    var moved: bool = bool(game.attempt_move(board_view.selected, pos))
    board_view.set_selected(Vector2i(-1, -1))
    hud.set_selected_text(game.NO_SQUARE)
    suggestion_mode = false
    hud.set_suggestion_mode(false)

    if not moved:
        hud.flash_message("Movimiento inválido")

    host._on_state_changed()

func _local_team_piece_allowed(piece: String) -> bool:
    if game == null or piece.is_empty() or game.local_player_slot < 0 or game.local_player_slot >= game.SLOTS:
        return false
    if not game.slot_active[game.local_player_slot]:
        return false
    var team: int = int(game.slot_colors[game.local_player_slot])
    return (team == game.TEAM_WHITE and game.rules.is_white(piece)) or (team == game.TEAM_BLACK and game.rules.is_black(piece))

func _on_action(action: String) -> void:
    match action:
        "suggest":
            # Sugerir activa un modo de intención: el jugador elige origen y
            # destino, pero la pieza NUNCA se mueve. El compañero recibe la
            # flecha fantasma y decide si seguirla.
            suggestion_mode = not suggestion_mode
            hud.set_suggestion_mode(suggestion_mode)
            if suggestion_mode:
                if board_view.selected == Vector2i(-1, -1):
                    hud.flash_message("Sugerir: selecciona la pieza que propones")
                else:
                    hud.flash_message("Sugerir: ahora selecciona la casilla destino")
            else:
                hud.flash_message("Sugerencia cancelada")
        "challenge":
            game.question_suggestion(game.local_player_slot)
        "swap":
            game.request_swap()
        "surrender":
            if game.mode == AppConfig.MODE_1C1 and _confirm_surrender_enabled():
                hud.show_single_surrender_confirmation()
            else:
                game.request_surrender()
        "confirm_single_surrender":
            game.request_surrender()
        "cancel_single_surrender":
            pass
        "draw":
            game.request_draw()
        "accept_suggestion":
            game.answer_suggestion(true, game.local_player_slot)
        "reject_suggestion":
            game.answer_suggestion(false, game.local_player_slot)
        "accept_swap":
            game.answer_swap(true)
        "reject_swap":
            game.answer_swap(false)
        "accept_surrender":
            game.answer_surrender(true)
        "reject_surrender":
            game.answer_surrender(false)
        "accept_draw":
            game.answer_draw(true, game.local_player_slot)
        "reject_draw":
            game.answer_draw(false, game.local_player_slot)
        "promotion_queen":
            game.choose_promotion("dama")
        "promotion_rook":
            game.choose_promotion("torre")
        "promotion_bishop":
            game.choose_promotion("alfil")
        "promotion_knight":
            game.choose_promotion("caballo")

    host._on_state_changed()

func _confirm_surrender_enabled() -> bool:
    var player_data = RuntimeServicesScript.get_autoload("PlayerData")
    return player_data == null or player_data.get_setting("confirm_surrender", true)
