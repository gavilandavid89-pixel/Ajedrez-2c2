extends SceneTree

const BotDataScript = preload("res://domain/bots/bot_data.gd")
const BotController = preload("res://domain/bots/bot_controller.gd")
const ChessRules = preload("res://domain/chess/rules.gd")

const GAMES_PER_PAIR := 5
const MAX_PLIES := 120
const START_RATING := 1000.0
const K := 20.0

var results: Dictionary = {}
var rng := RandomNumberGenerator.new()
var rules := ChessRules.new()

func _init() -> void:
	rng.seed = 20260930
	var profiles := BotDataScript.profiles()
	for p in profiles:
		results[String(p["id"])] = {"wins":0, "losses":0, "draws":0, "games":0, "points":0.0}

	var pair_rows: Array[Dictionary] = []
	for i in range(profiles.size() - 1):
		var a := String(profiles[i]["id"])
		var b := String(profiles[i + 1]["id"])
		var row := _play_pair(a, int(profiles[i]["elo"]), b, int(profiles[i + 1]["elo"]), GAMES_PER_PAIR)
		pair_rows.append(row)

	var ratings := _fit_elo(pair_rows)
	var csv := _csv(pair_rows, ratings)
	print(csv)
	var f := FileAccess.open("user://bot_calibration_results.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({
		"date":"2026-09-30",
		"games_per_pair":GAMES_PER_PAIR,
		"max_plies":MAX_PLIES,
		"pair_results":pair_rows,
		"empirical_ratings":ratings,
		"parameters":_parameter_snapshot()
	}, "\t"))
	f.close()
	quit(0)

func _play_pair(a_id: String, a_elo: int, b_id: String, b_elo: int, games: int) -> Dictionary:
	var row := {"a":a_id, "b":b_id, "a_elo":a_elo, "b_elo":b_elo, "a_wins":0, "b_wins":0, "draws":0, "games":games}
	for g in range(games):
		var a_white := (g % 2 == 0)
		var result := _play_game(a_elo if a_white else b_elo, b_elo if a_white else a_elo, a_id if a_white else b_id, b_id if a_white else a_id)
		if result == 1:
			if a_white: row["a_wins"] += 1
			else: row["b_wins"] += 1
		elif result == -1:
			if a_white: row["b_wins"] += 1
			else: row["a_wins"] += 1
		else:
			row["draws"] += 1
	return row

# Returns 1 if white bot won, -1 if black bot won, 0 draw.
func _play_game(white_elo: int, black_elo: int, white_id: String, black_id: String) -> int:
	var board := _initial_board()
	var rights := {"WK":true, "WQ":true, "BK":true, "BQ":true}
	var ep := ChessRules.NO_SQUARE
	var repetitions := {}
	var white_to_move := true
	for ply in range(MAX_PLIES):
		var key := _position_key(board, rights, ep, white_to_move)
		repetitions[key] = int(repetitions.get(key, 0)) + 1
		if int(repetitions[key]) >= 3:
			return 0
		var elo := white_elo if white_to_move else black_elo
		var id := white_id if white_to_move else black_id
		var move := BotController.choose_move(board, rules, rights, ep, white_to_move, elo, rng)
		if move.is_empty():
			return -1 if white_to_move else 1
		var next := BotController._simulate(board, rules, move["from"], move["to"], move["piece"], rights, ep)
		board = next["board"]
		rights = next["castling_rights"]
		ep = next["en_passant_target"]
		# _simulate promotes to queen, matching the bot path.
		if rules.is_checkmate(board, not white_to_move):
			return 1 if white_to_move else -1
		if rules.is_stalemate(board, not white_to_move):
			return 0
		white_to_move = not white_to_move
	return 0

func _fit_elo(rows: Array[Dictionary]) -> Dictionary:
	var ids: Array[String] = []
	for p in BotDataScript.profiles(): ids.append(String(p["id"]))
	var r := {}
	for id in ids: r[id] = START_RATING
	# Iterative pairwise Elo updates, enough for a stable empirical ordering.
	for pass_i in range(200):
		for row in rows:
			var a := String(row["a"])
			var b := String(row["b"])
			var games := float(row["games"])
			var score_a := (float(row["a_wins"]) + 0.5 * float(row["draws"])) / games
			var expected_a := 1.0 / (1.0 + pow(10.0, (float(r[b]) - float(r[a])) / 400.0))
			var delta := K * (score_a - expected_a)
			r[a] = float(r[a]) + delta
			r[b] = float(r[b]) - delta
	# Anchor the middle/third profile at 1000 while preserving gaps.
	var middle_id := "tactico"
	var shift := START_RATING - float(r.get(middle_id, START_RATING))
	for id in ids: r[id] = roundi(int(round(float(r[id]) + shift)))
	return r

func _csv(rows: Array[Dictionary], ratings: Dictionary) -> String:
	var out := "BOT CALIBRATION\n\n"
	out += "Pair,Games,A Elo target,B Elo target,A wins,B wins,Draws\n"
	for row in rows:
		out += "%s vs %s,%d,%d,%d,%d,%d,%d\n" % [row["a"], row["b"], row["games"], row["a_elo"], row["b_elo"], row["a_wins"], row["b_wins"], row["draws"]]
	out += "\nEmpirical Elo\n"
	for p in BotDataScript.profiles():
		var id := String(p["id"])
		out += "%s,%d (target %d)\n" % [String(p["name"]), int(ratings[id]), int(p["elo"])]
	return out

func _parameter_snapshot() -> Dictionary:
	var d := {}
	for elo in [400,700,1000,1300,1600]:
		d[str(elo)] = {
			"randomness":BotController._randomness_for(elo),
			"noise":BotController._noise_for(elo),
			"depth":BotController._depth_for(elo)
		}
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

func _position_key(board: Array, rights: Dictionary, ep: Vector2i, white: bool) -> String:
	var flat := ""
	for row in board:
		flat += ",".join(row) + ";"
	return "%s|%s|%s|%s|%s|%s" % [flat, rights.get("WK",false), rights.get("WQ",false), rights.get("BK",false), rights.get("BQ",false), str(ep) + ("w" if white else "b")]
