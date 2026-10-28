extends Control
class_name ChessBoardView

const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const BoardPieceAgentScript = preload("res://domain/supervision/board_piece_supervisor_agent.gd")

const LayoutMetrics = preload("res://core/layout/layout_metrics.gd")
const PieceMoveAnimatorScript = preload("res://ui/components/game/piece_move_animator.gd")
const BoardVisualContractScript = preload("res://core/visual/board_visual_contract.gd")
const BoardPieceRendererScript = preload("res://core/visual/board_piece_renderer.gd")
const BoardVisualEventsHighlightLastMove := "last_move"

signal square_pressed(pos: Vector2i)

const BOARD_THEMES := {
    # "classic" conserva el tablero original del proyecto.
    "classic": {"light": Color("#F0D9B5"), "dark": Color("#B58863")},
    # Skin opcional: grafito + gris metal + detalles dorados.
    "graphite_gold": {"light": Color("#68707A"), "dark": Color("#30363E")},
}
const LIGHT := Color("#F0D9B5")
const DARK := Color("#B58863")
const SELECTED := Color(0.12, 0.86, 0.33, 0.28)
const MOVE_DOT := Color(0.10, 0.80, 0.28, 0.80)
const MOVE_CAPTURE := Color(0.92, 0.18, 0.18, 0.72)
const SUGGESTION := BoardVisualContractScript.HIGHLIGHT_SUGGESTION
const CHECK := Color(1.0, 0.18, 0.18, 0.82)
const MATE_FILL := Color(0.95, 0.08, 0.08, 0.30)
const MATE_GLOW := Color(1.0, 0.12, 0.12, 0.98)
const BORDER := Color(0.05, 0.06, 0.08, 0.92)
const FRAME := Color("#13171D")
const FRAME_GOLD := Color("#E6AD32")
const PIECE_DRAW_RATIO := BoardVisualContractScript.PIECE_DRAW_RATIO
const PIECE_TEXTURES: Dictionary = {
    # Conjunto clásico original. No se reemplaza ni se modifica.
    "torre_blanca": preload("res://assets/pieces/white_rook.png"),
    "caballo_blanca": preload("res://assets/pieces/white_knight.png"),
    "alfil_blanca": preload("res://assets/pieces/white_bishop.png"),
    "dama_blanca": preload("res://assets/pieces/white_queen.png"),
    "rey_blanca": preload("res://assets/pieces/white_king.png"),
    "peon_blanca": preload("res://assets/pieces/white_pawn.png"),
    "torre_negro": preload("res://assets/pieces/black_rook.png"),
    "caballo_negro": preload("res://assets/pieces/black_knight.png"),
    "alfil_negro": preload("res://assets/pieces/black_bishop.png"),
    "dama_negro": preload("res://assets/pieces/black_queen.png"),
    "rey_negro": preload("res://assets/pieces/black_king.png"),
    "peon_negro": preload("res://assets/pieces/black_pawn.png"),
}

const PIECE_TEXTURES_GRAPHITE_GOLD: Dictionary = {
    "torre_blanca": preload("res://assets/pieces/skin_graphite_gold/white_rook.png"),
    "caballo_blanca": preload("res://assets/pieces/skin_graphite_gold/white_knight.png"),
    "alfil_blanca": preload("res://assets/pieces/skin_graphite_gold/white_bishop.png"),
    "dama_blanca": preload("res://assets/pieces/skin_graphite_gold/white_queen.png"),
    "rey_blanca": preload("res://assets/pieces/skin_graphite_gold/white_king.png"),
    "peon_blanca": preload("res://assets/pieces/skin_graphite_gold/white_pawn.png"),
    "torre_negro": preload("res://assets/pieces/skin_graphite_gold/black_rook.png"),
    "caballo_negro": preload("res://assets/pieces/skin_graphite_gold/black_knight.png"),
    "alfil_negro": preload("res://assets/pieces/skin_graphite_gold/black_bishop.png"),
    "dama_negro": preload("res://assets/pieces/skin_graphite_gold/black_queen.png"),
    "rey_negro": preload("res://assets/pieces/skin_graphite_gold/black_king.png"),
    "peon_negro": preload("res://assets/pieces/skin_graphite_gold/black_pawn.png"),
}

# Cada conjunto puede evolucionar de forma independiente sin tocar la lógica del ajedrez.
const PIECE_TEXTURE_SETS: Dictionary = {
    "classic": PIECE_TEXTURES,
    "graphite_gold": PIECE_TEXTURES_GRAPHITE_GOLD,
}

var game
var board_rect := Rect2()
var selected := Vector2i(-1, -1)
var last_viewport := Vector2(-1, -1)
var font: Font
var flipped: bool = false
var show_coordinates: bool = true
var board_theme: String = "classic"
var piece_set: String = "classic"
var last_move_highlight: Dictionary = {}
var _connected_player_data: Node = null
var _connected_viewport: Viewport = null
var move_animator: PieceMoveAnimator
var _board_piece_agent: BoardPieceSupervisorAgent
var _last_board_issue_capture_key := ""

func _ready() -> void:
    var hub = RuntimeServicesScript.get_autoload("SupervisorHub")
    if hub != null and hub.get("board_piece_agent") != null:
        _board_piece_agent = hub.board_piece_agent
    else:
        _board_piece_agent = BoardPieceAgentScript.new()
    var player_data = RuntimeServicesScript.get_autoload("PlayerData")
    if player_data != null:
        show_coordinates = player_data.get_setting("show_coordinates", true)
        board_theme = player_data.get_appearance("board_theme", "classic")
        piece_set = player_data.get_appearance("piece_set", "classic")
        _connected_player_data = player_data
        if not player_data.data_changed.is_connected(_on_player_data_changed):
            player_data.data_changed.connect(_on_player_data_changed)
    move_animator = PieceMoveAnimatorScript.new()
    move_animator.name = "PieceMoveAnimator"
    add_child(move_animator)
    move_animator.bind_board(self)
    mouse_filter = Control.MOUSE_FILTER_STOP
    font = ThemeDB.fallback_font
    _connected_viewport = get_viewport()
    if _connected_viewport != null and not _connected_viewport.size_changed.is_connected(_on_viewport_changed):
        _connected_viewport.size_changed.connect(_on_viewport_changed)
    _refresh_layout()

func _exit_tree() -> void:
    if _connected_player_data != null and is_instance_valid(_connected_player_data):
        if _connected_player_data.has_signal("data_changed") and _connected_player_data.data_changed.is_connected(_on_player_data_changed):
            _connected_player_data.data_changed.disconnect(_on_player_data_changed)
    _connected_player_data = null
    if _connected_viewport != null and is_instance_valid(_connected_viewport):
        if _connected_viewport.size_changed.is_connected(_on_viewport_changed):
            _connected_viewport.size_changed.disconnect(_on_viewport_changed)
    _connected_viewport = null

func set_game(state) -> void:
    if move_animator != null:
        move_animator.stop_animation(false)
    game = state
    last_move_highlight.clear()
    _audit_board_piece_state()
    _publish_visual_state()
    queue_redraw()

func set_selected(pos: Vector2i) -> void:
    selected = pos
    var visual_events := get_node_or_null("/root/BoardVisualEvents")
    if visual_events != null:
        if pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8:
            visual_events.publish_selection("match", String.chr(97 + pos.x) + str(8 - pos.y))
        else:
            visual_events.publish_selection("match", "")
        var legal_squares: Array[String] = []
        if game != null and pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8 and game.get("rules") != null:
            for target in game.rules.legal_moves(game.board, pos, game.castling_rights, game.en_passant_target):
                legal_squares.append(_pos_to_square(target))
        visual_events.publish_interaction("match", _pos_to_square(pos), legal_squares)
    queue_redraw()

func _publish_visual_state() -> void:
    var visual_events := get_node_or_null("/root/BoardVisualEvents")
    if visual_events == null:
        return
    var snapshot: Dictionary = {"selected": _pos_to_square(selected), "flipped": flipped, "board_theme": board_theme, "piece_set": piece_set}
    if game != null:
        snapshot["board"] = game.board.duplicate(true) if game.get("board") is Array else []
        snapshot["running"] = bool(game.get("running"))
        snapshot["current_slot"] = int(game.current_slot)
    visual_events.publish_state("match", snapshot)

func _pos_to_square(pos: Vector2i) -> String:
    if pos.x < 0 or pos.x >= 8 or pos.y < 0 or pos.y >= 8:
        return ""
    return String.chr(97 + pos.x) + str(8 - pos.y)

func set_flipped(value: bool) -> void:
    flipped = value
    var visual_events := get_node_or_null("/root/BoardVisualEvents")
    if visual_events != null:
        visual_events.publish_presentation("match", flipped, board_theme, piece_set)
    _publish_visual_state()
    queue_redraw()

func animate_move(move: Dictionary) -> void:
    if move_animator != null:
        last_move_highlight = move.duplicate(true)
        var visual_events := get_node_or_null("/root/BoardVisualEvents")
        if visual_events != null:
            visual_events.publish_highlight("match", String(move.get("from", "")), String(move.get("to", "")), BoardVisualEventsHighlightLastMove)
            visual_events.publish_move_committed("match", move)
        move_animator.animate_move(move)
        _publish_visual_state()
        queue_redraw()

func is_move_animation_active() -> bool:
    return move_animator != null and move_animator.is_animating()

func get_piece_texture(piece: String) -> Texture2D:
    var texture_set: Dictionary = PIECE_TEXTURE_SETS.get(piece_set, PIECE_TEXTURES)
    return texture_set.get(piece) as Texture2D

func piece_draw_size(piece: String, cell: float) -> Vector2:
    var texture := get_piece_texture(piece)
    if texture == null:
        return Vector2.ZERO
    return BoardPieceRendererScript.piece_size(texture, cell)

func _on_player_data_changed() -> void:
    var player_data = RuntimeServicesScript.get_autoload("PlayerData")
    if player_data != null:
        show_coordinates = player_data.get_setting("show_coordinates", true)
        board_theme = player_data.get_appearance("board_theme", "classic")
        piece_set = player_data.get_appearance("piece_set", "classic")
        _audit_board_piece_state()
        queue_redraw()

func _screen_pos(logical: Vector2i) -> Vector2i:
    if flipped:
        return Vector2i(7 - logical.x, 7 - logical.y)
    return logical

func layout_for_viewport(viewport: Vector2) -> Rect2:
    var result_mode: bool = game != null and not game.running
    return LayoutMetrics.board_rect(viewport, result_mode)

func _refresh_layout() -> void:
    last_viewport = get_viewport_rect().size
    board_rect = layout_for_viewport(last_viewport)
    _audit_board_piece_state()
    queue_redraw()

func refresh_layout() -> void:
    # Permite recalcular el tablero cuando cambia el estado de la partida
    # (por ejemplo, al entrar en la pantalla de resultado).
    if not is_inside_tree():
        return
    _refresh_layout()

func _on_viewport_changed() -> void:
    if not is_inside_tree():
        return
    var vp: Vector2 = get_viewport_rect().size
    if vp != last_viewport:
        last_viewport = vp
        board_rect = layout_for_viewport(vp)
        _audit_board_piece_state()
        queue_redraw()

func _audit_board_piece_state() -> void:
    if _board_piece_agent == null:
        return
    var board_state: Variant = game.board if game != null and game.get("board") != null else null
    var texture_set: Dictionary = PIECE_TEXTURE_SETS.get(piece_set, PIECE_TEXTURES)
    var hub := RuntimeServicesScript.get_autoload("SupervisorHub")
    var audit: Dictionary
    if hub != null and hub.has_method("audit_board"):
        audit = hub.audit_board(board_state, texture_set.keys(), board_theme, piece_set, board_rect, get_viewport_rect().size)
    else:
        audit = _board_piece_agent.inspect_board(board_state, texture_set.keys(), board_theme, piece_set, board_rect, get_viewport_rect().size)
    if not bool(audit.get("ok", false)):
        var issues: Array = audit.get("issues", [])
        var issue_key := "%s|%s|%s" % [str(issues), board_theme, piece_set]
        if issue_key != _last_board_issue_capture_key:
            _last_board_issue_capture_key = issue_key
            if hub != null and hub.has_method("capture_screen") and not OS.has_feature("headless"):
                call_deferred("_capture_board_issue", issues.duplicate(), board_theme, piece_set)

func _capture_board_issue(issues: Array, theme_id: String, piece_set_id: String) -> void:
    var hub := RuntimeServicesScript.get_autoload("SupervisorHub")
    if hub == null or not hub.has_method("capture_screen"):
        return
    var result: Dictionary = hub.capture_screen("board_issue", {"issues": ",".join(PackedStringArray(issues)), "theme": theme_id, "piece_set": piece_set_id, "capture_reason": "board_audit_failed"})
    if not bool(result.get("ok", false)) and hub.has_method("record_runtime_error"):
        hub.record_runtime_error("board_view", "Could not capture board audit failure", {"code": result.get("code", "unknown")})

func _input(_event: InputEvent) -> void:
    # Toda la entrada de partida se centraliza en Game._input para que
    # mouse, touch directo y touch-emulado recorran exactamente el mismo camino.
    pass

func _gui_input(_event: InputEvent) -> void:
    # Game procesa la entrada antes del sistema GUI. Mantener este método vacío
    # evita dobles movimientos cuando Android entrega Touch + Mouse emulado.
    pass

func _emit_square(point: Vector2) -> void:
    if not board_rect.has_point(point):
        return
    if game == null or not game.running:
        return
    if game.pending_promotion != game.NO_SQUARE:
        return

    var cell: float = board_rect.size.x / 8.0
    var screen_x: int = int(floor((point.x - board_rect.position.x) / cell))
    var screen_y: int = int(floor((point.y - board_rect.position.y) / cell))
    if screen_x < 0 or screen_x >= 8 or screen_y < 0 or screen_y >= 8:
        return

    var pos: Vector2i = Vector2i(screen_x, screen_y)
    if flipped:
        pos = Vector2i(7 - screen_x, 7 - screen_y)
    if game.rules.inside(pos):
        square_pressed.emit(pos)

func _draw() -> void:
    if board_rect.size.x <= 0.0:
        return
    if game != null:
        _audit_board_piece_state()

    var cell: float = board_rect.size.x / 8.0

    if board_theme == "graphite_gold":
        # Marco propio de la skin opcional.
        draw_rect(board_rect.grow(8.0), FRAME, true)
        draw_rect(board_rect.grow(7.0), FRAME_GOLD, false, 2.0)
        draw_rect(board_rect.grow(3.0), BORDER, false, 2.0)
    else:
        # El tablero clásico conserva exactamente su borde original.
        draw_rect(board_rect.grow(2.0), BORDER, true)

    for y in range(8):
        for x in range(8):
            var logical: Vector2i = Vector2i(x, y)
            var screen: Vector2i = _screen_pos(logical)
            var rect: Rect2 = Rect2(
                board_rect.position + Vector2(screen.x * cell, screen.y * cell),
                Vector2(cell, cell)
            )
            var theme_data: Dictionary = BOARD_THEMES.get(board_theme, BOARD_THEMES["classic"])
            draw_rect(rect, theme_data["light"] if (x + y) % 2 == 0 else theme_data["dark"])
            _draw_coordinates(rect, logical, screen, cell)

    if game == null:
        return

    # Última jugada: resalta tanto el origen como el destino, como en Chess.com.
    # Se dibuja encima de las casillas y debajo de piezas, selección y jaque.
    if not last_move_highlight.is_empty():
        var from_square := _parse_square(String(last_move_highlight.get("from", "")))
        var to_square := _parse_square(String(last_move_highlight.get("to", "")))
        for logical in [from_square, to_square]:
            if game.rules.inside(logical):
                var screen := _screen_pos(logical)
                var highlight_rect := Rect2(
                    board_rect.position + Vector2(screen.x * cell, screen.y * cell),
                    Vector2(cell, cell)
                )
                draw_rect(highlight_rect, Color(0.94, 0.83, 0.28, 0.40), true)

    if selected != Vector2i(-1, -1):
        var sel_screen: Vector2i = _screen_pos(selected)
        var sel_rect: Rect2 = Rect2(
            board_rect.position + Vector2(sel_screen.x * cell, sel_screen.y * cell),
            Vector2(cell, cell)
        )
        draw_rect(sel_rect, SELECTED, true)
        draw_rect(sel_rect, Color(0.10, 0.92, 0.32, 0.95), false, max(4.0, cell * 0.05))

        for move in game.rules.legal_moves(
            game.board,
            selected,
            game.castling_rights,
            game.en_passant_target
        ):
            var target: String = game.get_piece(move)
            var move_screen: Vector2i = _screen_pos(move)
            var center: Vector2 = board_rect.position + Vector2(
                (move_screen.x + 0.5) * cell,
                (move_screen.y + 0.5) * cell
            )
            if target == "":
                draw_circle(center, cell * 0.09, MOVE_DOT)
            else:
                draw_circle(center, cell * 0.28, MOVE_CAPTURE, false, max(4.0, cell * 0.04))

    # La flecha es privada del receptor: quien la envía no debe verla como
    # si fuera una jugada propia. En el cliente local el jugador es slot 0.
    if not game.suggestion.is_empty() and int(game.suggestion.get("recipient_slot", -1)) == 0:
        var sf: Vector2i = game.suggestion["from"]
        var st: Vector2i = game.suggestion["to"]
        var sf_screen: Vector2i = _screen_pos(sf)
        var st_screen: Vector2i = _screen_pos(st)
        var a: Vector2 = board_rect.position + Vector2((sf_screen.x + 0.5) * cell, (sf_screen.y + 0.5) * cell)
        var b: Vector2 = board_rect.position + Vector2((st_screen.x + 0.5) * cell, (st_screen.y + 0.5) * cell)
        draw_line(a, b, SUGGESTION, max(5.0, cell * 0.04))
        draw_circle(b, cell * 0.09, SUGGESTION)

    for white in [true, false]:
        if game.running and game.rules.in_check(game.board, white):
            var king: Vector2i = game.rules.find_king(game.board, white)
            if game.rules.inside(king):
                var king_screen: Vector2i = _screen_pos(king)
                var king_rect: Rect2 = Rect2(
                    board_rect.position + Vector2(king_screen.x * cell, king_screen.y * cell),
                    Vector2(cell, cell)
                )
                draw_rect(king_rect, CHECK, false, max(5.0, cell * 0.055))

    # Final de partida: en mate el rey perdedor recibe una marca mucho más
    # evidente que el simple borde de jaque. El tablero sigue visible durante
    # la transición de resultado para que el jugador entienda qué ocurrió.
    if not game.running and String(game.winner_reason).to_lower().contains("mate") and game.winner_team >= 0:
        var losing_white: bool = game.winner_team == game.TEAM_BLACK
        var mate_king: Vector2i = game.rules.find_king(game.board, losing_white)
        if game.rules.inside(mate_king):
            var mate_screen: Vector2i = _screen_pos(mate_king)
            var mate_rect := Rect2(
                board_rect.position + Vector2(mate_screen.x * cell, mate_screen.y * cell),
                Vector2(cell, cell)
            )
            # El resaltado pertenece a la casilla: no debe crecer fuera de ella,
            # porque un borde exterior hace que el escaque parezca más grande.
            draw_rect(mate_rect, MATE_FILL, true)
            var mate_inner := mate_rect.grow(-cell * 0.045)
            draw_rect(mate_inner, MATE_GLOW, false, max(4.0, cell * 0.055))

    for y in range(8):
        for x in range(8):
            var piece: String = game.board[y][x]
            if not piece.is_empty():
                var logical := Vector2i(x, y)
                if move_animator == null or not move_animator.should_hide_piece_at(logical):
                    _draw_piece(piece, logical, cell)

func _parse_square(value: String) -> Vector2i:
    var square := value.strip_edges().to_lower()
    if square.length() != 2:
        return Vector2i(-1, -1)
    var file_index := square.unicode_at(0) - 97
    var rank_index := square.unicode_at(1) - 49
    if file_index < 0 or file_index > 7 or rank_index < 0 or rank_index > 7:
        return Vector2i(-1, -1)
    return Vector2i(file_index, 7 - rank_index)

func _draw_coordinates(rect: Rect2, logical: Vector2i, screen: Vector2i, cell: float) -> void:
    if not show_coordinates:
        return
    var edge_color: Color = Color(0.18, 0.18, 0.19, 0.80) if (logical.x + logical.y) % 2 == 0 else Color(0.95, 0.94, 0.90, 0.82)

    if screen.x == 0:
        var rank: String = str(8 - logical.y)
        draw_string(
            font,
            rect.position + Vector2(4, 14),
            rank,
            HORIZONTAL_ALIGNMENT_LEFT,
            20,
            12,
            edge_color
        )

    if screen.y == 7:
        var file: String = String.chr(97 + logical.x)
        draw_string(
            font,
            rect.position + Vector2(cell - 16, cell - 4),
            file,
            HORIZONTAL_ALIGNMENT_LEFT,
            16,
            12,
            edge_color
        )

func _draw_piece(piece: String, logical: Vector2i, cell: float) -> void:
    var texture := get_piece_texture(piece)
    if texture == null:
        return
    var screen: Vector2i = _screen_pos(logical)
    var cell_rect := Rect2(
        board_rect.position + Vector2(screen.x * cell, screen.y * cell),
        Vector2(cell, cell)
    )
    BoardPieceRendererScript.draw_piece(self, texture, cell_rect, cell)
