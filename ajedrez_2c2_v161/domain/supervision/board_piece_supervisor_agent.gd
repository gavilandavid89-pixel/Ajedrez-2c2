extends RefCounted
class_name BoardPieceSupervisorAgent

## Structural and presentation audit for the 8x8 board. It reports observations only;
## chess rules and match state remain authoritative elsewhere.
const PIECES := ["torre_blanca", "caballo_blanca", "alfil_blanca", "dama_blanca", "rey_blanca", "peon_blanca", "torre_negro", "caballo_negro", "alfil_negro", "dama_negro", "rey_negro", "peon_negro"]
const WHITE_KING := "rey_blanca"
const BLACK_KING := "rey_negro"
var journal: SupervisorJournal
var last_fingerprint := ""

func _init(shared_journal: SupervisorJournal = null) -> void:
	journal = shared_journal

func inspect_board(board: Variant, texture_keys: Array, theme_id: String, piece_set_id: String, board_rect: Rect2, viewport_size: Vector2) -> Dictionary:
	var issues: Array[String] = []
	var piece_count := 0
	var white_kings := 0
	var black_kings := 0
	if not (board is Array) or board.size() != 8:
		issues.append("board_not_8_rows")
	else:
		for y in range(8):
			if not (board[y] is Array) or board[y].size() != 8:
				issues.append("row_%d_not_8_columns" % y)
				continue
			for x in range(8):
				var piece := String(board[y][x])
				if piece.is_empty():
					continue
				piece_count += 1
				if not PIECES.has(piece):
					issues.append("unknown_piece_at_%d_%d" % [x, y])
				elif not texture_keys.has(piece):
					issues.append("missing_texture_key_%s" % piece)
				if piece == WHITE_KING:
					white_kings += 1
				elif piece == BLACK_KING:
					black_kings += 1
	if white_kings != 1:
		issues.append("white_king_count_%d" % white_kings)
	if black_kings != 1:
		issues.append("black_king_count_%d" % black_kings)
	if not board_rect.size.is_finite() or board_rect.size.x <= 0.0 or board_rect.size.y <= 0.0:
		issues.append("invalid_board_rect")
	elif absf(board_rect.size.x - board_rect.size.y) > 1.5:
		issues.append("board_not_square")
	if not viewport_size.is_finite() or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		issues.append("invalid_viewport_size")
	if theme_id.is_empty():
		issues.append("empty_board_theme")
	if piece_set_id.is_empty():
		issues.append("empty_piece_set")
	var result := {"ok": issues.is_empty(), "issues": issues, "piece_count": piece_count, "white_kings": white_kings, "black_kings": black_kings, "structural_only": true}
	var fingerprint := JSON.stringify({"issues": issues, "piece_count": piece_count, "theme": theme_id, "piece_set": piece_set_id, "rect": [roundi(board_rect.size.x), roundi(board_rect.size.y)], "viewport": [roundi(viewport_size.x), roundi(viewport_size.y)]})
	if fingerprint != last_fingerprint and journal != null:
		journal.record("board_piece_agent", "error" if not issues.is_empty() else "info", "board_piece_audit", {"ok": issues.is_empty(), "issue_count": issues.size(), "first_issue": issues[0] if not issues.is_empty() else "none", "piece_count": piece_count, "theme": theme_id, "piece_set": piece_set_id, "board_width": board_rect.size.x, "board_height": board_rect.size.y})
	last_fingerprint = fingerprint
	return result
