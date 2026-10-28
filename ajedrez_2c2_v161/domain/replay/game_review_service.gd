extends RefCounted
class_name GameReviewService

const EngineScript = preload("res://domain/bots/stockfish_engine.gd")
const RulesScript = preload("res://domain/chess/rules.gd")
const TacticalCommentaryScript = preload("res://domain/replay/review_tactical_commentary.gd")

var engine := EngineScript.new()
var rules := RulesScript.new()
var tactical_commentary := TacticalCommentaryScript.new()

const CP_EXCELLENT := 20.0
const CP_VERY_GOOD := 45.0
const CP_GOOD := 80.0
const CP_INACCURACY := 120.0
const CP_MISTAKE := 200.0
const GREAT_GAP := 90.0
const BRILLIANT_MAX_LOSS := 35.0
const BRILLIANT_MIN_PIECE := 3.0
const BRILLIANT_MIN_COMPENSATION := -0.35

func analyze_replay(replay: Dictionary, moves: Array, depth: int = 12) -> Dictionary:
    # This service can run on a worker thread. SceneTree/Node access belongs on the main thread.
    if replay.is_empty() or moves.is_empty():
        return {"ok": false, "error": "No hay una partida analizable.", "moves": []}
    var raw_states: Variant = replay.get("states", [])
    if not (raw_states is Array) or raw_states.size() < moves.size() + 1:
        return {"ok": false, "error": "El replay no contiene todas las posiciones necesarias.", "moves": []}

    var fens: Array[String] = []
    var uci_moves: Array[String] = []
    var decoded_states: Array = []
    for i in range(moves.size()):
        var before := _decode_state(raw_states[i], i)
        if before.is_empty():
            return {"ok": false, "error": "Posición %d inválida." % (i + 1), "moves": []}
        var move: Dictionary = moves[i] if moves[i] is Dictionary else {}
        var uci := _move_to_uci(move)
        if uci.is_empty():
            return {"ok": false, "error": "No se pudo convertir la jugada %d a UCI." % (i + 1), "moves": []}
        fens.append(_state_to_fen(before, i))
        uci_moves.append(uci)
        decoded_states.append(before)

    var result := engine.analyze_positions(fens, uci_moves, depth, 3)
    if not bool(result.get("ok", false)):
        return result

    var analyzed: Array = []
    var raw_results: Array = result.get("moves", [])
    for i in range(raw_results.size()):
        var item: Dictionary = raw_results[i]
        var best: Dictionary = item.get("best", {})
        var played: Dictionary = item.get("played", {})
        var alternatives: Array = item.get("alternatives", []) if item.get("alternatives", []) is Array else []
        var loss := _centipawn_loss(best, played, i)
        var before: Dictionary = decoded_states[i]
        var move: Dictionary = moves[i] if moves[i] is Dictionary else {}
        var previous_loss := float(analyzed[i - 1].get("loss", 0.0)) if i > 0 and not analyzed.is_empty() else 0.0
        var classification_data := _classify_move(before, move, best, played, alternatives, loss, previous_loss)
        var coach_text := String(classification_data["coach_text"])
        if not coach_text.is_empty() and not String(best.get("bestmove", "")).is_empty() and not coach_text.contains(String(best.get("bestmove", ""))):
            coach_text += " Mejor alternativa del motor: %s." % String(best.get("bestmove", ""))
        var best_line: Array = best.get("pv", []) if best.get("pv", []) is Array else []
        var tactical_report: Dictionary = tactical_commentary.build_commentary(before, move, best, played, alternatives, loss)
        var tactical_notes: Array = tactical_report.get("notes", [])
        if not tactical_notes.is_empty():
            coach_text += " " + " ".join(tactical_notes)
        analyzed.append({
            "move_index": i,
            "best_move": String(best.get("bestmove", "")),
            "best_score": float(best.get("score", 0.0)),
            "played_score": float(played.get("score", 0.0)),
            "loss": loss,
            "classification": classification_data["classification"],
            "coach_text": coach_text,
            "best_line": best_line,
            "tactical_report": tactical_report,
            "highlight_from": String(move.get("from", "")),
            "highlight_to": String(move.get("to", "")),
            "special": classification_data["special"],
            "sacrifice_candidate": classification_data["sacrifice_candidate"],
            "critical": classification_data["critical"],
            "alternative_gap": classification_data["alternative_gap"],
            "depth": depth,
            "engine": "Stockfish 19",
        })
    return {"ok": true, "error": "", "moves": analyzed, "engine": "Stockfish 19", "depth": depth, "multi_pv": 3}

func _classify_move(before: Dictionary, move: Dictionary, best: Dictionary, played: Dictionary, alternatives: Array, loss: float, previous_loss: float = 0.0) -> Dictionary:
    var best_score := float(best.get("score", 0.0))
    var played_score := float(played.get("score", 0.0))
    var alternative_gap := 0.0
    if alternatives.size() >= 2:
        alternative_gap = absf(float(alternatives[0].get("score", 0.0)) - float(alternatives[1].get("score", 0.0))) * 100.0

    var critical := alternative_gap >= GREAT_GAP and loss <= BRILLIANT_MAX_LOSS
    var sacrifice_candidate := _is_piece_sacrifice_candidate(before, move)
    var after_score := played_score
    var not_bad_after := after_score >= BRILLIANT_MIN_COMPENSATION
    var near_best := loss <= BRILLIANT_MAX_LOSS
    var not_already_winning := best_score < 2.50

    # A Miss belongs to the position created by the opponent's mistake: the
    # player had a clearly winning opportunity but failed to capitalize.
    if previous_loss >= CP_MISTAKE and best_score >= 1.50 and played_score < 0.75 and loss >= CP_GOOD:
        return _classification("Oportunidad perdida", _miss_coach_text(best, played, loss), "miss", false, false, alternative_gap)

    # Special categories take precedence over ordinary loss buckets.
    # Brilliant follows the current public Chess.com definition: a good/nearly
    # best move that sacrifices a piece, does not leave a bad position, and is
    # not simply a move made from an already completely winning position.
    if sacrifice_candidate and near_best and not_bad_after and not_already_winning:
        return _classification("Brillante", _brilliant_coach_text(move, played_score, alternative_gap), "brilliant", true, critical, alternative_gap)

    # Great/Genial is reserved for a critical move: the best/near-best option
    # is clearly separated from the alternatives or is the only practical way
    # to preserve/improve the position.
    if critical and _is_near_best(loss):
        return _classification("Genial", _critical_coach_text(best_score, played_score, alternative_gap), "great", false, true, alternative_gap)

    if loss < CP_EXCELLENT:
        return _classification("Excelente", "¡EXCELENTE! La jugada mantiene prácticamente intacta la evaluación.", "", false, false, alternative_gap)
    if loss < CP_VERY_GOOD:
        return _classification("Muy bien", "¡MUY BIEN! Es una continuación muy cercana a la mejor.", "", false, false, alternative_gap)
    if loss < CP_GOOD:
        return _classification("Bien", "Bien jugado. La posición se mantiene sólida.", "", false, false, alternative_gap)
    if loss < CP_INACCURACY:
        return _classification("Imprecisa", _loss_coach_text("IMPRECISA", best, loss), "inaccuracy", false, false, alternative_gap)
    if loss < CP_MISTAKE:
        return _classification("Error", _loss_coach_text("ERROR", best, loss), "mistake", false, false, alternative_gap)
    return _classification("Error grave", _loss_coach_text("ERROR GRAVE", best, loss), "blunder", false, false, alternative_gap)

func _classification(name: String, coach: String, special: String, sacrifice: bool, critical: bool, gap: float) -> Dictionary:
    return {
        "classification": name,
        "coach_text": coach,
        "special": special,
        "sacrifice_candidate": sacrifice,
        "critical": critical,
        "alternative_gap": gap,
    }

func _is_near_best(loss: float) -> bool:
    return loss <= CP_VERY_GOOD

func _is_piece_sacrifice_candidate(before: Dictionary, move: Dictionary) -> bool:
    var board: Array = before.get("board", [])
    if board.size() != 8:
        return false
    var from := _square_to_pos(String(move.get("from", "")))
    var to := _square_to_pos(String(move.get("to", "")))
    if from == Vector2i(-1, -1) or to == Vector2i(-1, -1):
        return false
    var piece := String(board[from.y][from.x])
    if piece.is_empty() or piece.begins_with("peon_") or piece.begins_with("rey_"):
        return false
    # A sacrifice candidate is a non-pawn/non-king piece moved onto a square
    # controlled by the opponent, with at least one legal capture available.
    # This intentionally errs on the conservative side; the engine still has
    # to confirm that the move is near-best before it can become Brilliant.
    var after := board.duplicate(true)
    after[from.y][from.x] = ""
    after[to.y][to.x] = piece
    var white := rules.is_white(piece)
    if not rules.is_square_attacked(after, to, not white):
        return false
    var value := _piece_value(piece)
    if value < BRILLIANT_MIN_PIECE:
        return false
    for y in range(8):
        for x in range(8):
            var attacker := String(after[y][x])
            if attacker.is_empty() or rules.is_white(attacker) == white:
                continue
            var from_attacker := Vector2i(x, y)
            if rules.valid(after, from_attacker, to, attacker, {}, Vector2i(-1, -1)):
                return true
    return false

func _piece_value(piece: String) -> float:
    if piece.begins_with("caballo_") or piece.begins_with("alfil_"): return 3.0
    if piece.begins_with("torre_"): return 5.0
    if piece.begins_with("dama_"): return 9.0
    return 0.0

func _miss_coach_text(best: Dictionary, played: Dictionary, loss: float) -> String:
    var best_move := String(best.get("bestmove", ""))
    if best_move.is_empty():
        return "OPORTUNIDAD PERDIDA. Tu rival dejó una oportunidad ganadora, pero esta jugada no la aprovecha."
    return "OPORTUNIDAD PERDIDA. Tu rival dejó una oportunidad ganadora: %s mantenía una ventaja decisiva. Esta jugada pierde %.0f centipeones." % [best_move, loss]

func _brilliant_coach_text(move: Dictionary, played_score: float, gap: float) -> String:
    var piece := _piece_label(String(move.get("piece", "")))
    var from_sq := String(move.get("from", ""))
    var to_sq := String(move.get("to", ""))
    var detail := "El motor mantiene una posición favorable después del sacrificio."
    if gap >= GREAT_GAP:
        detail = "Además, las alternativas principales pierden bastante más según el motor."
    return "¡BRILLANTE! Sacrificaste tu %s de %s a %s. %s" % [piece, from_sq, to_sq, detail]

func _piece_label(piece: String) -> String:
    if piece.is_empty(): return "pieza"
    var names := {"peon_blanca":"peón","torre_blanca":"torre","caballo_blanca":"caballo","alfil_blanca":"alfil","dama_blanca":"dama","rey_blanca":"rey","peon_negro":"peón","torre_negro":"torre","caballo_negro":"caballo","alfil_negro":"alfil","dama_negro":"dama","rey_negro":"rey"}
    return String(names.get(piece, "pieza"))

func _critical_coach_text(best_score: float, played_score: float, gap: float) -> String:
    if best_score < -0.25 and played_score > -0.50:
        return "¡GENIAL! Encontraste una defensa crítica: esta jugada evita que la posición se hunda."
    if best_score <= 0.35 and played_score > 0.35:
        return "¡GENIAL! Esta era una oportunidad crítica para convertir la posición en una ventaja."
    return "¡GENIAL! Encontraste una jugada crítica: las alternativas pierden bastante más."

func _loss_coach_text(title: String, best: Dictionary, loss: float) -> String:
    var best_move := String(best.get("bestmove", ""))
    if best_move.is_empty():
        return "%s. Esta jugada pierde aproximadamente %.0f centipeones frente a la mejor continuación." % [title, loss]
    return "%s. La mejor continuación era %s; esta jugada pierde aproximadamente %.0f centipeones." % [title, best_move, loss]

func _decode_state(state: Dictionary, move_index: int = -1) -> Dictionary:
    var encoded := String(state.get("board", ""))
    if encoded.length() != 64:
        return {}
    var decoded: Array = []
    const pieces := {"P":"peon_blanca","R":"torre_blanca","N":"caballo_blanca","B":"alfil_blanca","Q":"dama_blanca","K":"rey_blanca","p":"peon_negro","r":"torre_negro","n":"caballo_negro","b":"alfil_negro","q":"dama_negro","k":"rey_negro"}
    for y in range(8):
        var row: Array = []
        for x in range(8):
            row.append(String(pieces.get(encoded.substr(y * 8 + x, 1), "")))
        decoded.append(row)
    return {"board": decoded, "castling": String(state.get("castling", "")), "ep": state.get("ep", [-1, -1]), "turn": int(state.get("turn", 0)), "side_to_move": int(state.get("side_to_move", (int(state.get("turn", 0)) % 2) if move_index < 0 else (move_index % 2))), "halfmove_clock": int(state.get("halfmove_clock", 0))}

func _state_to_fen(state: Dictionary, move_index: int) -> String:
    var board: Array = state.get("board", [])
    var ranks: Array[String] = []
    for y in range(8):
        var empty := 0
        var rank := ""
        for x in range(8):
            var piece := String(board[y][x])
            if piece.is_empty():
                empty += 1
            else:
                if empty > 0:
                    rank += str(empty)
                    empty = 0
                rank += _piece_to_fen(piece)
        if empty > 0:
            rank += str(empty)
        ranks.append(rank)
    var side := "w" if int(state.get("side_to_move", 0)) == 0 else "b"
    var castling := String(state.get("castling", ""))
    if castling.is_empty(): castling = "-"
    var ep := "-"
    var ep_raw: Variant = state.get("ep", [-1, -1])
    if ep_raw is Array and ep_raw.size() >= 2 and int(ep_raw[0]) >= 0 and int(ep_raw[1]) >= 0:
        ep = String.chr(97 + int(ep_raw[0])) + str(8 - int(ep_raw[1]))
    var fullmove := maxi(1, int(floor(float(move_index) / 2.0)) + 1)
    return "%s %s %s %s %d %d" % ["/".join(ranks), side, castling, ep, maxi(0, int(state.get("halfmove_clock", 0))), fullmove]

func _piece_to_fen(piece: String) -> String:
    var map := {"peon_blanca":"P","torre_blanca":"R","caballo_blanca":"N","alfil_blanca":"B","dama_blanca":"Q","rey_blanca":"K","peon_negro":"p","torre_negro":"r","caballo_negro":"n","alfil_negro":"b","dama_negro":"q","rey_negro":"k"}
    return String(map.get(piece, ""))

func _move_to_uci(move: Dictionary) -> String:
    var from_sq := String(move.get("from", ""))
    var to_sq := String(move.get("to", ""))
    if from_sq.length() != 2 or to_sq.length() != 2:
        return ""
    var promotion := str(move.get("promotion", ""))
    var suffix := ""
    if not promotion.is_empty() and promotion != "false" and promotion != "pending":
        var promo_map := {"dama":"q", "torre":"r", "alfil":"b", "caballo":"n"}
        suffix = String(promo_map.get(promotion, ""))
    return from_sq + to_sq + suffix

func _square_to_pos(square: String) -> Vector2i:
    if square.length() != 2:
        return Vector2i(-1, -1)
    var x := square.unicode_at(0) - 97
    var rank := square.unicode_at(1) - 48
    var y := 8 - rank
    return Vector2i(x, y) if x >= 0 and x < 8 and y >= 0 and y < 8 else Vector2i(-1, -1)

func _centipawn_loss(best: Dictionary, played: Dictionary, move_index: int) -> float:
    var best_score := float(best.get("score", 0.0))
    var played_score := float(played.get("score", 0.0))
    var loss := (best_score - played_score) * 100.0
    if loss < 0.0:
        loss = 0.0
    return loss

func _classify_loss(loss: float) -> String:
    if loss < CP_EXCELLENT: return "Excelente"
    if loss < CP_VERY_GOOD: return "Muy bien"
    if loss < CP_GOOD: return "Bien"
    if loss < CP_INACCURACY: return "Imprecisa"
    if loss < CP_MISTAKE: return "Error"
    return "Error grave"
