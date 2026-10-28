extends RefCounted
class_name ChessRules

const EMPTY := ""
const NO_SQUARE := Vector2i(-1, -1)

func inside(pos: Vector2i) -> bool:
    return pos.x >= 0 and pos.x < 8 and pos.y >= 0 and pos.y < 8

func board_valid(board: Array) -> bool:
    if board.size() != 8:
        return false
    for row in board:
        if not (row is Array) or row.size() != 8:
            return false
    return true

func is_white(piece: String) -> bool:
    return piece.ends_with("_blanca")

func is_black(piece: String) -> bool:
    return piece.ends_with("_negro")

func same_team(a: String, b: String) -> bool:
    if a == EMPTY or b == EMPTY:
        return false
    return is_white(a) == is_white(b)

func is_king(piece: String) -> bool:
    return piece.begins_with("rey_")

func enemy_at(board: Array, from: Vector2i, to: Vector2i) -> bool:
    if not board_valid(board) or not inside(from) or not inside(to):
        return false
    var a: String = board[from.y][from.x]
    var b: String = board[to.y][to.x]
    return b != EMPTY and not same_team(a, b) and not is_king(b)

func clear_path(board: Array, from: Vector2i, to: Vector2i) -> bool:
    var sx: int = int(sign(to.x - from.x))
    var sy: int = int(sign(to.y - from.y))
    var p: Vector2i = from + Vector2i(sx, sy)
    while p != to:
        if not inside(p):
            return false
        if board[p.y][p.x] != EMPTY:
            return false
        p += Vector2i(sx, sy)
    return true

func find_king(board: Array, white: bool) -> Vector2i:
    if not board_valid(board):
        return NO_SQUARE
    var wanted: String = "rey_blanca" if white else "rey_negro"
    for y in range(8):
        for x in range(8):
            if board[y][x] == wanted:
                return Vector2i(x, y)
    return NO_SQUARE

func is_square_attacked(board: Array, square: Vector2i, by_white: bool) -> bool:
    if not board_valid(board) or not inside(square):
        return false
    for y in range(8):
        for x in range(8):
            var from: Vector2i = Vector2i(x, y)
            var piece: String = board[y][x]
            if piece == EMPTY:
                continue
            if is_white(piece) != by_white:
                continue
            if piece.begins_with("peon_"):
                var dir: int = -1 if by_white else 1
                var d: Vector2i = square - from
                if abs(d.x) == 1 and d.y == dir:
                    return true
                continue
            if piece.begins_with("caballo_"):
                var d: Vector2i = square - from
                if (abs(d.x) == 1 and abs(d.y) == 2) or (abs(d.x) == 2 and abs(d.y) == 1):
                    return true
                continue
            if piece.begins_with("rey_"):
                var d: Vector2i = square - from
                if abs(d.x) <= 1 and abs(d.y) <= 1 and d != Vector2i.ZERO:
                    return true
                continue
            if piece.begins_with("torre_"):
                if (square.x == from.x or square.y == from.y) and clear_path(board, from, square):
                    return true
                continue
            if piece.begins_with("alfil_"):
                if abs(square.x - from.x) == abs(square.y - from.y) and clear_path(board, from, square):
                    return true
                continue
            if piece.begins_with("dama_"):
                var straight: bool = square.x == from.x or square.y == from.y
                var diagonal: bool = abs(square.x - from.x) == abs(square.y - from.y)
                if (straight or diagonal) and clear_path(board, from, square):
                    return true
    return false

func in_check(board: Array, white: bool) -> bool:
    var king: Vector2i = find_king(board, white)
    if king == NO_SQUARE:
        return true
    return is_square_attacked(board, king, not white)

func _castling_allowed(castling_rights: Dictionary, white: bool, king_side: bool) -> bool:
    var key: String = "WK" if white and king_side else "WQ" if white else "BK" if king_side else "BQ"
    return bool(castling_rights.get(key, false))

func _would_be_in_check_after_move(board: Array, from: Vector2i, to: Vector2i, white: bool, en_passant_target := NO_SQUARE) -> bool:
    var copy: Array = board.duplicate(true)
    var piece: String = copy[from.y][from.x]
    copy[from.y][from.x] = EMPTY
    copy[to.y][to.x] = piece
    if piece.begins_with("peon_") and to == en_passant_target and copy[to.y][to.x] != EMPTY:
        var dir: int = -1 if white else 1
        var captured_y: int = to.y - dir
        if inside(Vector2i(to.x, captured_y)) and copy[captured_y][to.x].begins_with("peon_"):
            copy[captured_y][to.x] = EMPTY
    return in_check(copy, white)

func _valid_pawn(board: Array, from: Vector2i, to: Vector2i, piece: String, en_passant_target: Vector2i) -> bool:
    var white: bool = is_white(piece)
    var dir: int = -1 if white else 1
    var start_row: int = 6 if white else 1
    var target: String = board[to.y][to.x]
    var d: Vector2i = to - from
    if d.x == 0 and d.y == dir and target == EMPTY:
        return true
    if d.x == 0 and d.y == dir * 2 and from.y == start_row and target == EMPTY:
        var mid: Vector2i = from + Vector2i(0, dir)
        return board[mid.y][mid.x] == EMPTY
    if abs(d.x) == 1 and d.y == dir:
        if target != EMPTY:
            return enemy_at(board, from, to)
        if to != en_passant_target:
            return false
        var captured_y := to.y - dir
        if not inside(Vector2i(to.x, captured_y)):
            return false
        var captured_piece := String(board[captured_y][to.x])
        return captured_piece == ("peon_negro" if white else "peon_blanca")
    return false

func _valid_castle(board: Array, from: Vector2i, to: Vector2i, piece: String, castling_rights: Dictionary) -> bool:
    var white: bool = is_white(piece)
    var home_y: int = 7 if white else 0
    if from != Vector2i(4, home_y) or to.y != home_y or abs(to.x - from.x) != 2:
        return false
    var king_side: bool = to.x > from.x
    if not _castling_allowed(castling_rights, white, king_side):
        return false
    var rook_x: int = 7 if king_side else 0
    var rook_piece: String = "torre_blanca" if white else "torre_negro"
    if board[home_y][rook_x] != rook_piece:
        return false
    var between: Array[int] = [5, 6]
    if not king_side:
        between = [1, 2, 3]
    for x in between:
        if board[home_y][x] != EMPTY:
            return false
    if in_check(board, white):
        return false
    var transit_x: int = 5 if king_side else 3
    if _would_be_in_check_after_move(board, from, Vector2i(transit_x, home_y), white):
        return false
    if _would_be_in_check_after_move(board, from, to, white):
        return false
    return true

func pseudo_valid(board: Array, from: Vector2i, to: Vector2i, piece: String, castling_rights: Dictionary = {}, en_passant_target: Vector2i = NO_SQUARE) -> bool:
    if not board_valid(board) or not inside(from) or not inside(to):
        return false
    if piece == EMPTY or from == to or board[from.y][from.x] != piece:
        return false
    var target: String = board[to.y][to.x]
    if target != EMPTY and same_team(piece, target):
        return false
    if target != EMPTY and is_king(target):
        return false
    var d: Vector2i = to - from
    var ax: int = abs(d.x)
    var ay: int = abs(d.y)

    if piece.begins_with("caballo_"):
        return (ax == 1 and ay == 2) or (ax == 2 and ay == 1)
    if piece.begins_with("rey_"):
        if ax <= 1 and ay <= 1:
            return true
        return _valid_castle(board, from, to, piece, castling_rights)
    if piece.begins_with("torre_"):
        return (d.x == 0 or d.y == 0) and clear_path(board, from, to)
    if piece.begins_with("alfil_"):
        return ax == ay and clear_path(board, from, to)
    if piece.begins_with("dama_"):
        var straight: bool = d.x == 0 or d.y == 0
        var diagonal := ax == ay
        return (straight or diagonal) and clear_path(board, from, to)
    if piece.begins_with("peon_"):
        return _valid_pawn(board, from, to, piece, en_passant_target)
    return false

func _apply_basic_move(board: Array, from: Vector2i, to: Vector2i, piece: String, en_passant_target: Vector2i) -> Array:
    var copy: Array = board.duplicate(true)
    copy[from.y][from.x] = EMPTY
    copy[to.y][to.x] = piece
    if piece.begins_with("peon_") and to == en_passant_target and board[to.y][to.x] == EMPTY and from.x != to.x:
        var dir := -1 if is_white(piece) else 1
        var captured_y: int = to.y - dir
        if inside(Vector2i(to.x, captured_y)):
            copy[captured_y][to.x] = EMPTY
    return copy

func _apply_castle(board: Array, from: Vector2i, to: Vector2i, piece: String) -> Array:
    var copy: Array = board.duplicate(true)
    copy[from.y][from.x] = EMPTY
    copy[to.y][to.x] = piece
    var king_side: bool = to.x > from.x
    var rook_from_x := 7 if king_side else 0
    var rook_to_x := 5 if king_side else 3
    copy[from.y][rook_to_x] = copy[from.y][rook_from_x]
    copy[from.y][rook_from_x] = EMPTY
    return copy

func _apply_for_legality(board: Array, from: Vector2i, to: Vector2i, piece: String, castling_rights: Dictionary, en_passant_target: Vector2i) -> Array:
    if piece.begins_with("rey_") and abs(to.x - from.x) == 2:
        return _apply_castle(board, from, to, piece)
    return _apply_basic_move(board, from, to, piece, en_passant_target)

func valid(board: Array, from: Vector2i, to: Vector2i, piece: String, castling_rights: Dictionary = {}, en_passant_target: Vector2i = NO_SQUARE) -> bool:
    if not pseudo_valid(board, from, to, piece, castling_rights, en_passant_target):
        return false
    var white: bool = is_white(piece)
    var next: Array = _apply_for_legality(board, from, to, piece, castling_rights, en_passant_target)
    return not in_check(next, white)

func legal_moves(board: Array, from: Vector2i, castling_rights: Dictionary = {}, en_passant_target: Vector2i = NO_SQUARE) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    if not board_valid(board) or not inside(from):
        return result
    var piece: String = board[from.y][from.x]
    if piece == EMPTY:
        return result
    for y in range(8):
        for x in range(8):
            var to: Vector2i = Vector2i(x, y)
            if valid(board, from, to, piece, castling_rights, en_passant_target):
                result.append(to)
    return result

func has_any_legal_move(board: Array, white: bool, castling_rights: Dictionary = {}, en_passant_target: Vector2i = NO_SQUARE) -> bool:
    for y in range(8):
        for x in range(8):
            var piece: String = board[y][x]
            if piece == EMPTY or is_white(piece) != white:
                continue
            if not legal_moves(board, Vector2i(x, y), castling_rights, en_passant_target).is_empty():
                return true
    return false

func is_checkmate(board: Array, white: bool, castling_rights: Dictionary = {}, en_passant_target: Vector2i = NO_SQUARE) -> bool:
    return in_check(board, white) and not has_any_legal_move(board, white, castling_rights, en_passant_target)

func is_stalemate(board: Array, white: bool, castling_rights: Dictionary = {}, en_passant_target: Vector2i = NO_SQUARE) -> bool:
    return not in_check(board, white) and not has_any_legal_move(board, white, castling_rights, en_passant_target)
