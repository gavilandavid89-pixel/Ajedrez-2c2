extends RefCounted
class_name ChessBotController

const ChessRulesScript = preload("res://domain/chess/rules.gd")
const BotDataScript = preload("res://domain/bots/bot_data.gd")

const PIECE_VALUES := {
	"peon": 100,
	"caballo": 320,
	"alfil": 330,
	"torre": 500,
	"dama": 900,
	"rey": 20000,
}
const CENTER_SQUARES := [Vector2i(3, 3), Vector2i(4, 3), Vector2i(3, 4), Vector2i(4, 4)]

static func choose_move(board: Array, rules: ChessRulesScript, castling_rights: Dictionary, en_passant_target: Vector2i, white: bool, target_elo: int, rng: RandomNumberGenerator) -> Dictionary:
	return _choose_move_internal(board, rules, castling_rights, en_passant_target, white, target_elo, BotDataScript.behavior_for(BotDataScript.DEFAULT_BOT), rng)

static func choose_move_with_profile(board: Array, rules: ChessRulesScript, castling_rights: Dictionary, en_passant_target: Vector2i, white: bool, bot_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var profile := BotDataScript.get_profile(bot_id)
	return _choose_move_internal(board, rules, castling_rights, en_passant_target, white, int(profile.get("elo", BotDataScript.MIN_ELO)), BotDataScript.behavior_for(bot_id), rng)

static func _choose_move_internal(board: Array, rules: ChessRulesScript, castling_rights: Dictionary, en_passant_target: Vector2i, white: bool, target_elo: int, behavior: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var choices := _collect_moves(board, rules, castling_rights, en_passant_target, white)
	if choices.is_empty():
		return {}

	var elo := clampi(target_elo, BotDataScript.MIN_ELO, BotDataScript.MAX_ELO)
	var randomness := _randomness_for(elo)
	var depth := _depth_for(elo)

	# Los niveles bajos mezclan movimientos razonables con errores intencionados.
	if rng.randf() < randomness:
		return choices[rng.randi_range(0, choices.size() - 1)]

	var scored: Array[Dictionary] = []
	for choice in choices:
		var score := _move_score(board, rules, choice, castling_rights, en_passant_target, white, depth, behavior)
		scored.append({"move": choice, "score": score + rng.randf_range(-_noise_for(elo), _noise_for(elo))})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["score"]) > float(b["score"]))

	# Incluso en niveles fuertes dejamos una pequeña ventana de elección para que no juegue siempre idéntico.
	var pool := 1 if elo >= 1500 else 2 if elo >= 1000 else 3
	pool = mini(pool, scored.size())
	return scored[rng.randi_range(0, pool - 1)]["move"]

static func _collect_moves(board: Array, rules: ChessRulesScript, castling_rights: Dictionary, ep: Vector2i, white: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for y in range(8):
		for x in range(8):
			var from := Vector2i(x, y)
			var piece: String = board[y][x]
			if piece.is_empty() or rules.is_white(piece) != white:
				continue
			for to in _candidate_targets(board, from, piece, white, ep, castling_rights):
				if rules.valid(board, from, to, piece, castling_rights, ep):
					out.append({"from": from, "to": to, "piece": piece})
	return out

static func _candidate_targets(board: Array, from: Vector2i, piece: String, white: bool, ep: Vector2i, castling_rights: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if piece.begins_with("peon_"):
		var dir := -1 if white else 1
		var start_row := 6 if white else 1
		var one := Vector2i(from.x, from.y + dir)
		if _inside(one):
			out.append(one)
		var two := Vector2i(from.x, from.y + dir * 2)
		if from.y == start_row and _inside(two):
			out.append(two)
		for dx in [-1, 1]:
			var cap := Vector2i(from.x + dx, from.y + dir)
			if _inside(cap):
				out.append(cap)
		if ep != ChessRulesScript.NO_SQUARE:
			out.append(ep)
		return out

	if piece.begins_with("caballo_"):
		for d in [Vector2i(1,2), Vector2i(2,1), Vector2i(-1,2), Vector2i(-2,1), Vector2i(1,-2), Vector2i(2,-1), Vector2i(-1,-2), Vector2i(-2,-1)]:
			var to: Vector2i = from + d
			if _inside(to): out.append(to)
		return out

	if piece.begins_with("rey_"):
		for dy in [-1, 0, 1]:
			for dx in [-1, 0, 1]:
				if dx == 0 and dy == 0: continue
				var to: Vector2i = from + Vector2i(dx, dy)
				if _inside(to): out.append(to)
		if abs(from.x - 4) == 0 and (from.x == 4 or from.x == 5 or from.x == 3):
			out.append(Vector2i(from.x + 2, from.y))
			out.append(Vector2i(from.x - 2, from.y))
		return out

	var diagonal := piece.begins_with("alfil_") or piece.begins_with("dama_")
	var straight := piece.begins_with("torre_") or piece.begins_with("dama_")
	if diagonal:
		for d in [Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]:
			_append_ray_targets(board, from, d, out)
	if straight:
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			_append_ray_targets(board, from, d, out)
	return out

static func _append_ray_targets(board: Array, from: Vector2i, d: Vector2i, out: Array[Vector2i]) -> void:
	var to: Vector2i = from + d
	while _inside(to):
		out.append(to)
		if not String(board[to.y][to.x]).is_empty():
			break
		to += d

static func _inside(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < 8 and p.y >= 0 and p.y < 8

static func _randomness_for(elo: int) -> float:
	var e := clampi(elo, BotDataScript.MIN_ELO, BotDataScript.MAX_ELO)
	if e <= 400: return 0.70
	if e <= 700: return lerpf(0.70, 0.50, float(e - 400) / 300.0)
	if e <= 1000: return lerpf(0.50, 0.25, float(e - 700) / 300.0)
	if e <= 1300: return lerpf(0.25, 0.12, float(e - 1000) / 300.0)
	return lerpf(0.12, 0.03, float(e - 1300) / 300.0)

static func _noise_for(elo: int) -> float:
	var e := clampi(elo, BotDataScript.MIN_ELO, BotDataScript.MAX_ELO)
	if e <= 400: return 220.0
	if e <= 700: return lerpf(220.0, 140.0, float(e - 400) / 300.0)
	if e <= 1000: return lerpf(140.0, 80.0, float(e - 700) / 300.0)
	if e <= 1300: return lerpf(80.0, 35.0, float(e - 1000) / 300.0)
	return lerpf(35.0, 8.0, float(e - 1300) / 300.0)

static func _depth_for(elo: int) -> int:
	if elo < 850:
		return 0
	if elo < 1500:
		return 1
	return 2

static func _move_score(board: Array, rules: ChessRulesScript, choice: Dictionary, rights: Dictionary, ep: Vector2i, white: bool, depth: int, behavior: Dictionary = {}) -> float:
	var from: Vector2i = choice["from"]
	var to: Vector2i = choice["to"]
	var piece: String = choice["piece"]
	var target: String = board[to.y][to.x]
	var next := _simulate(board, rules, from, to, piece, rights, ep)
	var base := _static_eval(next.board, rules, white)
	base += float(_piece_value(target)) * 0.65
	if rules.in_check(next.board, not white):
		base += 80.0
	if piece.begins_with("peon_") and to.y in [0, 7]:
		base += 650.0
	if depth <= 0:
		return base
	var replies := _collect_moves(next.board, rules, next.castling_rights, next.en_passant_target, not white)
	if replies.is_empty():
		return base + (100000.0 if rules.in_check(next.board, not white) else 0.0)
	_reorder_replies(replies, next.board, rules)
	var limit := _reply_width_for_depth(depth)
	limit = mini(limit, replies.size())
	var best_reply := INF
	for i in range(limit):
		var reply: Dictionary = replies[i]
		var reply_next := _simulate(next.board, rules, reply["from"], reply["to"], reply["piece"], next.castling_rights, next.en_passant_target)
		var reply_eval := _static_eval(reply_next.board, rules, white)
		if reply_eval < best_reply:
			best_reply = reply_eval
		if reply_eval < base - 900.0:
			break
	return base + best_reply * 0.35 if best_reply < INF else base



static func _style_adjustment(board: Array, rules: ChessRulesScript, from: Vector2i, to: Vector2i, piece: String, target: String, white: bool, next_board: Array, behavior: Dictionary) -> float:
	if behavior.is_empty():
		return 0.0
	var aggression := float(behavior.get("aggression", 0.5))
	var development := float(behavior.get("development", 0.5))
	var king_safety := float(behavior.get("king_safety", 0.5))
	var center := float(behavior.get("center", 0.5))
	var simplification := float(behavior.get("simplification", 0.5))
	var risk := float(behavior.get("risk", 0.5))
	var score := 0.0
	if not target.is_empty():
		score += float(_piece_value(target)) * (0.03 + aggression * 0.10)
		if simplification > 0.65:
			score += float(_piece_value(target)) * 0.03
	if to in CENTER_SQUARES:
		score += center * 18.0
	if piece.begins_with("caballo_") or piece.begins_with("alfil_"):
		var home_rank := 7 if white else 0
		if from.y == home_rank:
			score += development * 28.0
	if piece.begins_with("dama_") and ((white and from.y == 7) or ((not white) and from.y == 0)):
		score -= risk * 12.0
	if piece.begins_with("rey_"):
		if abs(to.x - from.x) == 2:
			score += king_safety * 48.0
		else:
			var home := Vector2i(4, 7) if white else Vector2i(4, 0)
			if from == home:
				score -= king_safety * 22.0
	# Penaliza piezas capturables inmediatamente solo en estilos prudentes.
	var enemy_white := not white
	var replies := _collect_moves(next_board, rules, {"WK":true,"WQ":true,"BK":true,"BQ":true}, ChessRulesScript.NO_SQUARE, enemy_white)
	for reply in replies:
		if reply.get("to", ChessRulesScript.NO_SQUARE) == to:
			score -= (1.0 - aggression) * 22.0
			break
	return score

static func _reply_width_for_depth(depth: int) -> int:
	return 8 if depth >= 2 else 5

static func _reorder_replies(replies: Array[Dictionary], board: Array, rules: ChessRulesScript) -> void:
	replies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _reply_order_score(a, board, rules) > _reply_order_score(b, board, rules)
	)

static func _reply_order_score(reply: Dictionary, board: Array, _rules: ChessRulesScript) -> float:
	var to: Vector2i = reply["to"]
	var piece: String = reply["piece"]
	var target: String = board[to.y][to.x]
	var score := float(_piece_value(target)) * 10.0
	if piece.begins_with("peon_") and to.y in [0, 7]:
		score += 8000.0
	if piece.begins_with("dama_"):
		score += 80.0
	return score

static func _static_eval(board: Array, rules: ChessRulesScript, white: bool) -> float:
	var total := 0.0
	for y in range(8):
		for x in range(8):
			var piece: String = board[y][x]
			if piece.is_empty():
				continue
			var value := float(_piece_value(piece))
			var sign := 1.0 if rules.is_white(piece) == white else -1.0
			total += value * sign
			var pos := Vector2i(x, y)
			if pos in CENTER_SQUARES:
				total += 18.0 * sign
			if piece.begins_with("peon_"):
				var advance := float(6 - y if rules.is_white(piece) else y - 1)
				total += advance * 4.0 * sign
	return total

static func _piece_value(piece: String) -> int:
	var kind := piece.get_slice("_", 0)
	return int(PIECE_VALUES.get(kind, 0))

static func _simulate(board: Array, rules: ChessRulesScript, from: Vector2i, to: Vector2i, piece: String, rights: Dictionary, ep: Vector2i) -> Dictionary:
	var next := rules._apply_for_legality(board, from, to, piece, rights, ep)
	if piece.begins_with("peon_") and to.y in [0, 7]:
		next[to.y][to.x] = "dama_blanca" if rules.is_white(piece) else "dama_negro"
	var next_rights := rights.duplicate(true)
	var white := rules.is_white(piece)
	if piece.begins_with("rey_"):
		next_rights["WK" if white else "BK"] = false
		next_rights["WQ" if white else "BQ"] = false
	if piece.begins_with("torre_"):
		if from == Vector2i(0, 7): next_rights["WQ"] = false
		if from == Vector2i(7, 7): next_rights["WK"] = false
		if from == Vector2i(0, 0): next_rights["BQ"] = false
		if from == Vector2i(7, 0): next_rights["BK"] = false
	var captured: String = board[to.y][to.x]
	if captured.begins_with("torre_"):
		if to == Vector2i(0, 7): next_rights["WQ"] = false
		if to == Vector2i(7, 7): next_rights["WK"] = false
		if to == Vector2i(0, 0): next_rights["BQ"] = false
		if to == Vector2i(7, 0): next_rights["BK"] = false
	var next_ep := ChessRulesScript.NO_SQUARE
	if piece.begins_with("peon_") and abs(to.y - from.y) == 2:
		next_ep = Vector2i(from.x, (from.y + to.y) / 2)
	return {"board": next, "castling_rights": next_rights, "en_passant_target": next_ep}
