extends SceneTree
const JournalScript = preload("res://domain/supervision/supervisor_journal.gd")
const AgentScript = preload("res://domain/supervision/board_piece_supervisor_agent.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var journal = JournalScript.new()
	journal.configure_path("user://v125_board_piece_test.jsonl")
	var agent = AgentScript.new(journal)
	var row_back := ["torre_negro", "caballo_negro", "alfil_negro", "dama_negro", "rey_negro", "alfil_negro", "caballo_negro", "torre_negro"]
	var row_pawns := ["peon_negro", "peon_negro", "peon_negro", "peon_negro", "peon_negro", "peon_negro", "peon_negro", "peon_negro"]
	var row_empty := ["", "", "", "", "", "", "", ""]
	var row_white_pawns := ["peon_blanca", "peon_blanca", "peon_blanca", "peon_blanca", "peon_blanca", "peon_blanca", "peon_blanca", "peon_blanca"]
	var row_white_back := ["torre_blanca", "caballo_blanca", "alfil_blanca", "dama_blanca", "rey_blanca", "alfil_blanca", "caballo_blanca", "torre_blanca"]
	var board: Array = [row_back, row_pawns, row_empty.duplicate(), row_empty.duplicate(), row_empty.duplicate(), row_empty.duplicate(), row_white_pawns, row_white_back]
	var texture_keys := AgentScript.PIECES
	var good := agent.inspect_board(board, texture_keys, "classic", "classic", Rect2(0, 0, 640, 640), Vector2(720, 1280))
	_check(bool(good.ok), "Valid 8x8 board with both kings passes")
	_check(int(good.piece_count) == 32, "Initial position counts 32 pieces")
	var bad_board: Array = board.duplicate(true)
	bad_board[0][4] = ""
	var bad := agent.inspect_board(bad_board, texture_keys, "classic", "classic", Rect2(0, 0, 640, 600), Vector2(720, 1280))
	_check(not bool(bad.ok), "Missing king and non-square board are detected")
	_check(bad.issues.has("black_king_count_0"), "Missing king issue identifies affected side")
	var bad_piece_board: Array = board.duplicate(true)
	bad_piece_board[0][0] = "dragon_black"
	var bad_piece := agent.inspect_board(bad_piece_board, texture_keys, "classic", "classic", Rect2(0, 0, 640, 640), Vector2(720, 1280))
	_check(bad_piece.issues.has("unknown_piece_at_0_0"), "Unknown piece identifier is detected")
	var missing_texture := agent.inspect_board(board, [], "classic", "classic", Rect2(0, 0, 640, 640), Vector2(720, 1280))
	_check(missing_texture.issues.has("missing_texture_key_torre_negro"), "Missing texture mapping is detected")
	_check(journal.recent_events(20).size() >= 3, "Board audit events are sent to persistent journal")
	if FileAccess.file_exists("user://v125_board_piece_test.jsonl"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://v125_board_piece_test.jsonl"))
	print("V125 BOARD/PIECE AGENT: %d OK / %d FAILED" % [passed, failed])
	quit(0 if failed == 0 else 1)
func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[OK] ", label)
	else:
		failed += 1
		push_error(label)
