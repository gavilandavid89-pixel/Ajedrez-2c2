extends RefCounted
class_name MatchReplayStateService

var host: Node

const REPLAY_CODES := {
    "peon_blanca":"P", "torre_blanca":"R", "caballo_blanca":"N", "alfil_blanca":"B", "dama_blanca":"Q", "rey_blanca":"K",
    "peon_negro":"p", "torre_negro":"r", "caballo_negro":"n", "alfil_negro":"b", "dama_negro":"q", "rey_negro":"k"
}
const REPLAY_PIECES := {
    "P":"peon_blanca", "R":"torre_blanca", "N":"caballo_blanca", "B":"alfil_blanca", "Q":"dama_blanca", "K":"rey_blanca",
    "p":"peon_negro", "r":"torre_negro", "n":"caballo_negro", "b":"alfil_negro", "q":"dama_negro", "k":"rey_negro"
}

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

func encode_board() -> String:
    var out := ""
    for y in range(8):
        for x in range(8):
            out += String(REPLAY_CODES.get(String(host.board[y][x]), "."))
    return out

func capture_state() -> void:
    if not host.rules.board_valid(host.board):
        return
    var rights := ""
    if bool(host.castling_rights.get("WK", false)): rights += "K"
    if bool(host.castling_rights.get("WQ", false)): rights += "Q"
    if bool(host.castling_rights.get("BK", false)): rights += "k"
    if bool(host.castling_rights.get("BQ", false)): rights += "q"
    var position_key := current_position_key(rights)
    var occurrence := int(host.position_repetition_counts.get(position_key, 0)) + 1
    host.position_repetition_counts[position_key] = occurrence
    host.replay_states.append({
        "board": encode_board(),
        "castling": rights,
        "ep": [host.en_passant_target.x, host.en_passant_target.y],
        "turn": host.current_slot,
        "side_to_move": host.current_team(),
        "halfmove_clock": int(host.halfmove_clock),
        "position_key": position_key,
        "repetition_count": occurrence,
        "active": host.slot_active.duplicate(),
        "running": host.running,
    })
    if host.replay_states.size() > 401:
        host.replay_states.pop_front()

func data() -> Dictionary:
    return {
        "version": 1,
        "states": host.replay_states.duplicate(true),
        "move_count": host.move_history.size(),
        "initial_mode": host.mode,
    }

static func decode_state(state: Dictionary) -> Dictionary:
    var encoded := String(state.get("board", ""))
    if encoded.length() != 64:
        return {}
    var decoded: Array = []
    for y in range(8):
        var row: Array = []
        for x in range(8):
            var code := encoded.substr(y * 8 + x, 1)
            row.append(String(REPLAY_PIECES.get(code, "")))
        decoded.append(row)
    var ep_raw: Variant = state.get("ep", [-1, -1])
    var ep := Vector2i(-1, -1)
    if ep_raw is Array and ep_raw.size() >= 2:
        ep = Vector2i(int(ep_raw[0]), int(ep_raw[1]))
    return {"board": decoded, "castling": String(state.get("castling", "")), "ep": ep, "turn": int(state.get("turn", 0)), "side_to_move": int(state.get("side_to_move", 0)), "halfmove_clock": int(state.get("halfmove_clock", 0)), "position_key": String(state.get("position_key", "")), "repetition_count": int(state.get("repetition_count", 1)), "active": state.get("active", []).duplicate(true) if state.get("active", []) is Array else [], "running": bool(state.get("running", true))}

func current_position_repetition_count() -> int:
    var rights := ""
    if bool(host.castling_rights.get("WK", false)): rights += "K"
    if bool(host.castling_rights.get("WQ", false)): rights += "Q"
    if bool(host.castling_rights.get("BK", false)): rights += "k"
    if bool(host.castling_rights.get("BQ", false)): rights += "q"
    return int(host.position_repetition_counts.get(current_position_key(rights), 0))

func current_position_key(rights: String = "") -> String:
    if rights.is_empty():
        if bool(host.castling_rights.get("WK", false)): rights += "K"
        if bool(host.castling_rights.get("WQ", false)): rights += "Q"
        if bool(host.castling_rights.get("BK", false)): rights += "k"
        if bool(host.castling_rights.get("BQ", false)): rights += "q"
    var ep_part := "-"
    var ep: Vector2i = host.en_passant_target
    if host.rules.inside(ep):
        var white_to_move: bool = int(host.current_team()) == int(host.TEAM_WHITE)
        var dir := -1 if white_to_move else 1
        var from_y := ep.y - dir
        for dx in [-1, 1]:
            var from := Vector2i(ep.x + dx, from_y)
            if not host.rules.inside(from):
                continue
            var piece := String(host.board[from.y][from.x])
            if piece.begins_with("peon_") and host.rules.is_white(piece) == white_to_move and host.rules.valid(host.board, from, ep, piece, host.castling_rights, ep):
                ep_part = String.chr(97 + ep.x) + str(8 - ep.y)
                break
    var side := "w" if host.current_team() == host.TEAM_WHITE else "b"
    return "%s|%s|%s|%s" % [encode_board(), side, rights if not rights.is_empty() else "-", ep_part]

func moves() -> Array[Dictionary]:
    return host.move_history.duplicate(true)
