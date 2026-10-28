extends SceneTree

const BotDataScript = preload("res://domain/bots/bot_data.gd")
const BotController = preload("res://domain/bots/bot_controller.gd")
const ChessRules = preload("res://domain/chess/rules.gd")

const POSITIONS := 30
const RANDOM_PLIES_PER_POSITION := 8

var rules := ChessRules.new()
var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.seed = 260930
	var boards: Array = []
	for i in range(POSITIONS):
		boards.append(_random_position())
	var report := {}
	for p in BotDataScript.profiles():
		var id := String(p["id"])
		var total_quality := 0.0
		var acceptable := 0
		var blunders := 0
		for board_state in boards:
			var white := bool(board_state["white"])
			var moves: Array[Dictionary] = BotController._collect_moves(board_state["board"], rules, board_state["rights"], board_state["ep"], white)
			if moves.is_empty(): continue
			var best := -INF
			var scores := {}
			for m in moves:
				var sc := BotController._move_score(board_state["board"], rules, m, board_state["rights"], board_state["ep"], white, 0)
				scores["%s>%s" % [m["from"],m["to"]]] = sc
				best = max(best, sc)
			var pick := BotController.choose_move(board_state["board"], rules, board_state["rights"], board_state["ep"], white, int(p["elo"]), rng)
			if pick.is_empty(): continue
			var chosen := float(scores.get("%s>%s" % [pick["from"],pick["to"]], best))
			var loss: float = max(0.0, float(best - chosen))
			var quality := clampf(1.0 - loss / 900.0, 0.0, 1.0)
			total_quality += quality
			if loss <= 80.0: acceptable += 1
			if loss >= 350.0: blunders += 1
		var count: int = max(1, POSITIONs_played(boards))
		report[id] = {"avg_quality": total_quality / float(count), "acceptable_rate": float(acceptable) / float(count), "blunder_rate": float(blunders) / float(count)}
	print(JSON.stringify({"positions":POSITIONS,"report":report,"parameters":_parameter_snapshot()}, "\t"))
	var f := FileAccess.open("res://bot_decision_benchmark.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"positions":POSITIONS,"report":report,"parameters":_parameter_snapshot()}, "\t"))
	f.close()
	quit(0)

func POSITIONs_played(_boards: Array) -> int:
	return POSITIONS

func _random_position() -> Dictionary:
	var board := _initial_board()
	var rights := {"WK":true,"WQ":true,"BK":true,"BQ":true}
	var ep := ChessRules.NO_SQUARE
	var white := true
	for i in range(RANDOM_PLIES_PER_POSITION):
		var moves := BotController._collect_moves(board, rules, rights, ep, white)
		if moves.is_empty(): break
		var pick: Dictionary = moves[rng.randi_range(0, moves.size() - 1)]
		var next := BotController._simulate(board, rules, pick["from"], pick["to"], pick["piece"], rights, ep)
		board = next["board"]
		rights = next["castling_rights"]
		ep = next["en_passant_target"]
		white = not white
	return {"board":board,"rights":rights,"ep":ep,"white":white}

func _parameter_snapshot() -> Dictionary:
	var d := {}
	for elo in [400,700,1000,1300,1600]:
		d[str(elo)] = {"randomness":BotController._randomness_for(elo),"noise":BotController._noise_for(elo),"depth":BotController._depth_for(elo)}
	return d

func _initial_board() -> Array:
	return [
		["torre_negro","caballo_negro","alfil_negro","dama_negro","rey_negro","alfil_negro","caballo_negro","torre_negro"],
		["peon_negro","peon_negro","peon_negro","peon_negro","peon_negro","peon_negro","peon_negro","peon_negro"],
		["","","","","","","",""],
		["","","","","","","",""],
		["","","","","","","",""],
		["","","","","","","",""],
		["peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca","peon_blanca"],
		["torre_blanca","caballo_blanca","alfil_blanca","dama_blanca","rey_blanca","alfil_blanca","caballo_blanca","torre_blanca"]
	]
