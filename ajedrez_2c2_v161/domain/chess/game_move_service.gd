extends RefCounted
class_name ChessGameMoveService

const ChessRules = preload("res://domain/chess/rules.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var rules: ChessRules:
    get: return host.rules
var board: Array:
    get: return host.board
    set(value): host.board = value
var mode: int:
    get: return int(host.mode)
var running: bool:
    get: return bool(host.running)
var current_slot: int:
    get: return int(host.current_slot)
    set(value): host.current_slot = value
var slot_colors: Variant:
    get: return host.slot_colors
var pending_promotion: Vector2i:
    get: return host.pending_promotion
    set(value): host.pending_promotion = value
var pending_move_index: int:
    get: return int(host.pending_move_index)
    set(value): host.pending_move_index = value
var move_history: Array[Dictionary]:
    get: return host.move_history
var castling_rights: Dictionary:
    get: return host.castling_rights
    set(value): host.castling_rights = value
var en_passant_target: Vector2i:
    get: return host.en_passant_target
    set(value): host.en_passant_target = value
var selected: Vector2i:
    get: return host.selected
    set(value): host.selected = value
var suggestion: Dictionary:
    get: return host.suggestion
    set(value): host.suggestion = value
var surrender_request: Dictionary:
    get: return host.surrender_request
    set(value): host.surrender_request = value
var draw_state: Dictionary:
    get: return host.draw_state
    set(value): host.draw_state = value

const NO_SQUARE := Vector2i(-1, -1)
const TEAM_WHITE := 0
const TEAM_BLACK := 1
const MODE_VS_BOT := 2

func get_piece(pos: Vector2i) -> String:
    if not rules.inside(pos) or not rules.board_valid(board):
        return ""
    return board[pos.y][pos.x]

func current_piece_allowed(piece: String) -> bool:
    if piece == "" or pending_promotion != NO_SQUARE or not running:
        return false
    if mode == MODE_VS_BOT and current_slot == 1:
        return false
    var team: int = host.current_team()
    return (team == TEAM_WHITE and rules.is_white(piece)) or (team == TEAM_BLACK and rules.is_black(piece))

func attempt_move(from: Vector2i, to: Vector2i, promotion_piece: String = "dama", by_bot: bool = false) -> bool:
    if not running or pending_promotion != NO_SQUARE:
        return false
    var actor: int = host.current_actor_slot()
    if actor < 0:
        _emit_log("El equipo no tiene representante activo.")
        return false
    var piece: String = get_piece(from)
    if by_bot:
        if not host.is_bot_turn():
            return false
        var bot_white: bool = slot_colors[current_slot] == TEAM_WHITE
        if rules.is_white(piece) != bot_white:
            return false
    elif not current_piece_allowed(piece):
        _emit_log("Ese turno pertenece a %s." % host.current_owner())
        return false
    if not rules.valid(board, from, to, piece, castling_rights, en_passant_target):
        _emit_log("Movimiento inválido: %s → %s" % [square_name(from), square_name(to)])
        return false
    host.mark_seen(actor)
    var captured: String = get_piece(to)
    var was_castle: bool = piece.begins_with("rey_") and abs(to.x - from.x) == 2
    var was_en_passant: bool = piece.begins_with("peon_") and to == en_passant_target and captured == "" and from.x != to.x
    var old_en_passant: Vector2i = en_passant_target
    # FIDE halfmove clock resets on every pawn move or capture, including en passant.
    if piece.begins_with("peon_") or captured != "" or was_en_passant:
        host.halfmove_clock = 0
    else:
        host.halfmove_clock += 1

    _apply_move(from, to, piece, was_castle, was_en_passant)
    _update_special_rights(from, to, piece, captured)
    _update_en_passant(from, to, piece)

    if piece.begins_with("peon_") and (to.y == 0 or to.y == 7):
        move_history.append({
            "slot": current_slot,
            "actor": host.current_owner(),
            "from": square_name(from),
            "to": square_name(to),
            "piece": piece,
            "captured": captured,
            "castle": was_castle,
            "en_passant": was_en_passant,
            "promotion": "pending"
        })
        pending_move_index = move_history.size() - 1
        pending_promotion = to
        if by_bot:
            choose_promotion("dama")
            return true
        host.promotion_required.emit(to)
        _emit_log("Promoción requerida en %s." % square_name(to))
    else:
        _finish_move(from, to, piece, captured, was_castle, was_en_passant, old_en_passant)
    return true

func _apply_move(from: Vector2i, to: Vector2i, piece: String, was_castle: bool, was_en_passant: bool) -> void:
    board[from.y][from.x] = ""
    board[to.y][to.x] = piece
    if was_en_passant:
        var dir: int = -1 if rules.is_white(piece) else 1
        board[to.y - dir][to.x] = ""
    if was_castle:
        var rook_from_x: int = 7 if to.x > from.x else 0
        var rook_to_x: int = 5 if to.x > from.x else 3
        board[from.y][rook_to_x] = board[from.y][rook_from_x]
        board[from.y][rook_from_x] = ""

func _update_special_rights(from: Vector2i, to: Vector2i, piece: String, captured: String) -> void:
    if piece == "rey_blanca":
        castling_rights["WK"] = false
        castling_rights["WQ"] = false
    elif piece == "rey_negro":
        castling_rights["BK"] = false
        castling_rights["BQ"] = false
    elif piece == "torre_blanca":
        if from == Vector2i(0, 7): castling_rights["WQ"] = false
        if from == Vector2i(7, 7): castling_rights["WK"] = false
    elif piece == "torre_negro":
        if from == Vector2i(0, 0): castling_rights["BQ"] = false
        if from == Vector2i(7, 0): castling_rights["BK"] = false
    if captured == "torre_blanca":
        if to == Vector2i(0, 7): castling_rights["WQ"] = false
        if to == Vector2i(7, 7): castling_rights["WK"] = false
    elif captured == "torre_negro":
        if to == Vector2i(0, 0): castling_rights["BQ"] = false
        if to == Vector2i(7, 0): castling_rights["BK"] = false

func _update_en_passant(from: Vector2i, to: Vector2i, piece: String) -> void:
    en_passant_target = NO_SQUARE
    if piece.begins_with("peon_") and abs(to.y - from.y) == 2:
        en_passant_target = Vector2i(from.x, (from.y + to.y) / 2)

func _finish_move(from: Vector2i, to: Vector2i, piece: String, captured: String, was_castle: bool, was_en_passant: bool, old_en_passant: Vector2i) -> void:
    move_history.append({
        "slot": current_slot,
        "actor": host.current_owner(),
        "from": square_name(from),
        "to": square_name(to),
        "piece": piece,
        "captured": captured,
        "castle": was_castle,
        "en_passant": was_en_passant,
        "promotion": false
    })
    _emit_log("%s mueve %s de %s a %s%s" % [host.current_owner(), piece_label(piece), square_name(from), square_name(to), " y captura %s" % piece_label(captured) if captured != "" else ""])
    _after_move_resolution()

func choose_promotion(kind: String) -> bool:
    if pending_promotion == NO_SQUARE or not running:
        return false
    var y: int = pending_promotion.y
    var white: bool = rules.is_white(board[y][pending_promotion.x])
    var allowed: Array[String] = ["dama", "torre", "alfil", "caballo"]
    if not allowed.has(kind):
        return false
    var piece: String = "%s_%s" % [kind, "blanca" if white else "negro"]
    board[y][pending_promotion.x] = piece
    var square: Vector2i = pending_promotion
    if pending_move_index >= 0 and pending_move_index < move_history.size():
        move_history[pending_move_index]["promotion"] = kind
    pending_move_index = -1
    pending_promotion = NO_SQUARE
    _emit_log("Promoción en %s a %s." % [square_name(square), piece_label(piece)])
    _after_move_resolution()
    return true

func _after_move_resolution() -> void:
    selected = NO_SQUARE
    suggestion = {}
    surrender_request = {}
    draw_state = {"stage": 0, "by_slot": -1, "target_team": -1, "accepted_by": []}
    var next_team: int = 1 - host.current_team()
    if rules.is_checkmate(board, next_team == TEAM_WHITE, castling_rights, en_passant_target):
        host.finish(host.current_team(), "Jaque mate")
        host._capture_replay_state()
        return
    if rules.is_stalemate(board, next_team == TEAM_WHITE, castling_rights, en_passant_target):
        host.finish(-1, "Tablas por ahogado")
        host._capture_replay_state()
        return
    if rules.in_check(board, next_team == TEAM_WHITE):
        _emit_log("⚠️ Jaque a las %s." % ("blancas" if next_team == TEAM_WHITE else "negras"))
    host._advance_turn()
    host._capture_replay_state()
    host.check_automatic_draw_rules()

func advance_turn() -> void:
    host._advance_turn()

func square_name(pos: Vector2i) -> String:
    return String.chr(97 + pos.x) + str(8 - pos.y)

func piece_label(piece: String) -> String:
    if piece.is_empty():
        return "vacío"
    var p: String = piece.get_slice("_", 0)
    var names: Dictionary = {"peon":"Peón","torre":"Torre","caballo":"Caballo","alfil":"Alfil","dama":"Dama","rey":"Rey"}
    return names.get(p, p).capitalize()

func _emit_log(text: String) -> void:
    host._emit_log(text)
