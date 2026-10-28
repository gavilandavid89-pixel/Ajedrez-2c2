extends RefCounted
class_name ReviewTacticalCommentary

# Capa de explicaciones deterministas. No ejecuta Stockfish ni depende de UI;
# interpreta únicamente datos que ya produjo el análisis.
const PIECE_NAMES := {
    "peon_blanca": "peón blanco", "torre_blanca": "torre blanca",
    "caballo_blanca": "caballo blanco", "alfil_blanca": "alfil blanco",
    "dama_blanca": "dama blanca", "rey_blanca": "rey blanco",
    "peon_negro": "peón negro", "torre_negro": "torre negra",
    "caballo_negro": "caballo negro", "alfil_negro": "alfil negro",
    "dama_negro": "dama negra", "rey_negro": "rey negro"
}

func build_commentary(before: Dictionary, move: Dictionary, best: Dictionary, played: Dictionary, alternatives: Array, loss_cp: float) -> Dictionary:
    var notes: Array[String] = []
    var board: Array = before.get("board", [])
    var from_sq := String(move.get("from", ""))
    var to_sq := String(move.get("to", ""))
    var from_pos := _square_to_pos(from_sq)
    var to_pos := _square_to_pos(to_sq)
    var best_move := String(best.get("bestmove", ""))
    var played_line: Array = played.get("pv", []) if played.get("pv", []) is Array else []

    if _valid_board(board) and to_pos != Vector2i(-1, -1):
        var target := String(board[to_pos.y][to_pos.x])
        if not target.is_empty():
            notes.append("La jugada captura una %s." % String(PIECE_NAMES.get(target, "pieza rival")))
        elif from_pos != Vector2i(-1, -1):
            var moving_piece := String(board[from_pos.y][from_pos.x])
            if moving_piece.begins_with("peon_") and from_pos.x != to_pos.x:
                notes.append("Parece una captura al paso; verifica que el estado del replay registre correctamente esa regla especial.")

    if not best_move.is_empty() and best_move != from_sq + to_sq and loss_cp >= 45.0:
        notes.append("Stockfish prefiere %s; la diferencia estimada es de %.0f centipeones." % [best_move, loss_cp])

    # No afirma que exista una recaptura sin que la PV de la búsqueda de la
    # jugada la muestre. Se informa como continuación principal, no como verdad táctica absoluta.
    if played_line.size() >= 2:
        var reply := String(played_line[1])
        if _is_uci(reply):
            notes.append("Tras tu jugada, la continuación principal calculada por el motor incluye %s." % reply)

    var gap := 0.0
    if alternatives.size() >= 2:
        gap = absf(float(alternatives[0].get("score", 0.0)) - float(alternatives[1].get("score", 0.0))) * 100.0
    if gap >= 150.0:
        notes.append("La primera alternativa destaca claramente frente a la segunda a esta profundidad; conviene revisar la variante completa antes de atribuirle un motivo táctico.")

    return {"notes": notes, "played_reply": String(played_line[1]) if played_line.size() >= 2 else "", "best_move": best_move, "loss_cp": loss_cp, "confidence": "engine_line" if not played_line.is_empty() else "evaluation_only"}

func _valid_board(board: Array) -> bool:
    if board.size() != 8:
        return false
    for row in board:
        if not row is Array or row.size() != 8:
            return false
    return true

func _square_to_pos(square: String) -> Vector2i:
    if square.length() != 2:
        return Vector2i(-1, -1)
    var x := square.unicode_at(0) - 97
    var y := 8 - (square.unicode_at(1) - 48)
    return Vector2i(x, y) if x >= 0 and x < 8 and y >= 0 and y < 8 else Vector2i(-1, -1)

func _is_uci(value: String) -> bool:
    return value.length() >= 4 and value.length() <= 5 and value.substr(0, 1) >= "a" and value.substr(0, 1) <= "h" and value.substr(1, 1) >= "1" and value.substr(1, 1) <= "8" and value.substr(2, 1) >= "a" and value.substr(2, 1) <= "h" and value.substr(3, 1) >= "1" and value.substr(3, 1) <= "8"
