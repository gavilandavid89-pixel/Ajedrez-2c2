extends SceneTree

const RulesScript = preload("res://domain/chess/rules.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var rules = RulesScript.new()
    var rights := {"WK":true,"WQ":true,"BK":true,"BQ":true}

    # Castling cannot pass through an attacked transit square.
    var board := _empty_board()
    board[7][4] = "rey_blanca"
    board[7][7] = "torre_blanca"
    board[0][4] = "rey_negro"
    board[0][5] = "torre_negro"
    _check(not rules.valid(board, Vector2i(4,7), Vector2i(6,7), "rey_blanca", rights), "Castling rejected when transit square is attacked")

    # A castling right alone is not enough if the rook is missing.
    board = _empty_board()
    board[7][4] = "rey_blanca"
    board[0][4] = "rey_negro"
    _check(not rules.valid(board, Vector2i(4,7), Vector2i(6,7), "rey_blanca", rights), "Castling rejected when rook is absent")

    # A king may not capture a defended enemy piece.
    board = _empty_board()
    board[7][4] = "rey_blanca"
    board[5][4] = "torre_negro"
    board[3][4] = "rey_negro"
    _check(not rules.valid(board, Vector2i(4,7), Vector2i(4,5), "rey_blanca", rights), "King cannot capture a piece protected by enemy king")

    # A pinned rook cannot expose its king to a rook attack.
    board = _empty_board()
    board[7][4] = "rey_blanca"
    board[6][4] = "torre_blanca"
    board[0][4] = "torre_negro"
    board[0][0] = "rey_negro"
    _check(not rules.valid(board, Vector2i(4,6), Vector2i(3,6), "torre_blanca", rights), "Pinned rook cannot move off the king file")

    # En passant that opens a rook line to the moving side's king is illegal.
    board = _empty_board()
    board[3][4] = "rey_blanca"
    board[3][7] = "torre_negro"
    board[3][5] = "peon_blanca"
    board[3][6] = "peon_negro"
    board[0][0] = "rey_negro"
    _check(not rules.valid(board, Vector2i(5,3), Vector2i(6,2), "peon_blanca", {}, Vector2i(6,2)), "En passant rejected if it exposes own king to rook check")

    # Pawns attack diagonally even when the target square is empty.
    board = _empty_board()
    board[4][4] = "peon_negro"
    board[3][3] = "rey_blanca"
    board[7][7] = "rey_negro"
    _check(rules.is_square_attacked(board, Vector2i(3,5), false), "Pawn attacks are recognized on an empty diagonal square")

    # No legal move while in check is checkmate, not stalemate.
    board = _empty_board()
    board[0][0] = "rey_negro"
    board[1][1] = "dama_blanca"
    board[2][2] = "rey_blanca"
    _check(rules.is_checkmate(board, false), "Checkmate correctly detected in a constrained king position")

    # A blocked king with no check is stalemate.
    board = _empty_board()
    board[0][0] = "rey_negro"
    board[2][1] = "dama_blanca"
    board[2][2] = "rey_blanca"
    _check(rules.is_stalemate(board, false), "Stalemate correctly detected when king is not in check")

    print("V113 CHESS EDGE: %d OK / %d FAILED" % [passed, failed])
    for failure in failures:
        push_error(failure)
    quit(0 if failed == 0 else 1)

func _empty_board() -> Array:
    var board: Array = []
    for y in range(8):
        var row: Array[String] = []
        for x in range(8):
            row.append("")
        board.append(row)
    return board

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        failures.append(label)
        print("[FAIL] ", label)
