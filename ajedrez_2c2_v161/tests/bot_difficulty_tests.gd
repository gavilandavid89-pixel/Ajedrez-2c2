extends SceneTree

const BotDataScript = preload("res://domain/bots/bot_data.gd")
const BotController = preload("res://domain/bots/bot_controller.gd")
const ChessRules = preload("res://domain/chess/rules.gd")

var passed := 0
var failed := 0

func _init() -> void:
	_test_names()
	_test_levels()
	_test_catalog_structure()
	_test_black_queen_identity()
	_test_move_generation()
	_test_fast_move_generation_matches_rules()
	_test_target_changes()
	_test_calibration_curve()
	_test_nexus_spacing()
	print("BOT TESTS: %d/%d OK" % [passed, passed + failed])
	quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _test_names() -> void:
	for profile in BotDataScript.profiles():
		_ok(String(profile["name"]).length() <= 10, "nombre <= 10: %s" % String(profile["name"]))

func _test_levels() -> void:
	var last_elo := 0
	var last_nexus := -1
	for profile in BotDataScript.profiles():
		var elo := int(profile["elo"])
		var nexus := int(profile["nexus"])
		_ok(elo >= BotDataScript.MIN_ELO and elo <= BotDataScript.MAX_ELO, "elo en rango")
		_ok(elo >= last_elo, "elo ordenado")
		_ok(nexus >= BotDataScript.MIN_NEXUS and nexus <= BotDataScript.MAX_NEXUS, "nexus en rango")
		_ok(nexus > last_nexus, "nexus ordenado")
		last_elo = elo
		last_nexus = nexus

func _test_catalog_structure() -> void:
	var profiles := BotDataScript.profiles()
	_ok(profiles.size() == 20, "catálogo contiene 20 bots")
	var counts := {}
	for profile in profiles:
		var difficulty := String(profile["difficulty"])
		counts[difficulty] = int(counts.get(difficulty, 0)) + 1
		_ok(float(profile["calibration_quality"]) >= 0.0 and float(profile["calibration_quality"]) <= 1.0, "calibración en rango")
		_ok(float(profile["acceptable_rate"]) >= 0.0 and float(profile["acceptable_rate"]) <= 1.0, "acceptable en rango")
		_ok(float(profile["blunder_rate"]) >= 0.0 and float(profile["blunder_rate"]) <= 1.0, "blunder en rango")
	for difficulty in ["Fácil", "Normal", "Difícil", "Muy difícil", "Extremo"]:
		_ok(int(counts.get(difficulty, 0)) == 4, "4 bots en %s" % difficulty)

func _test_black_queen_identity() -> void:
	var rules := ChessRules.new()
	_ok(rules.is_black("dama_negro"), "dama negra se reconoce como negra")
	_ok(not rules.is_black("dama_negra"), "forma antigua dama_negra no se acepta")

func _test_move_generation() -> void:
	var rules := ChessRules.new()
	var board := _initial_board()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var move := BotController.choose_move(board, rules, {"WK":true,"WQ":true,"BK":true,"BQ":true}, ChessRules.NO_SQUARE, false, 1000, rng)
	_ok(not move.is_empty(), "genera movimiento")
	_ok(rules.valid(board, move["from"], move["to"], move["piece"], {"WK":true,"WQ":true,"BK":true,"BQ":true}, ChessRules.NO_SQUARE), "movimiento legal")

func _test_fast_move_generation_matches_rules() -> void:
	var rules := ChessRules.new()
	var board := _initial_board()
	var rights := {"WK":true,"WQ":true,"BK":true,"BQ":true}
	for white in [true, false]:
		var fast := BotController._collect_moves(board, rules, rights, ChessRules.NO_SQUARE, white)
		var slow_keys := {}
		for y in range(8):
			for x in range(8):
				var from := Vector2i(x,y)
				var piece: String = board[y][x]
				if piece.is_empty() or rules.is_white(piece) != white: continue
				for to in rules.legal_moves(board, from, rights, ChessRules.NO_SQUARE):
					slow_keys["%s>%s" % [from,to]] = true
		var fast_keys := {}
		for move in fast:
			fast_keys["%s>%s" % [move["from"], move["to"]]] = true
		_ok(fast_keys == slow_keys, "generación rápida coincide (%s)" % ("blancas" if white else "negras"))

func _test_target_changes() -> void:
	var low := BotController._randomness_for(400)
	var high := BotController._randomness_for(1600)
	_ok(low > high, "dificultad reduce aleatoriedad")
	_ok(BotController._depth_for(400) < BotController._depth_for(1600), "dificultad aumenta profundidad")
	_ok(BotController._noise_for(400) > BotController._noise_for(1600), "dificultad reduce ruido")

func _test_calibration_curve() -> void:
	var profiles := BotDataScript.profiles()
	for profile in profiles:
		var quality := float(profile["calibration_quality"])
		var acceptable := float(profile["acceptable_rate"])
		var blunders := float(profile["blunder_rate"])
		_ok(quality >= 0.0 and quality <= 1.0, "calidad calibrada en rango")
		_ok(acceptable >= 0.0 and acceptable <= 1.0, "tasa aceptable en rango")
		_ok(blunders >= 0.0 and blunders <= 1.0, "errores graves en rango")
		_ok(String(profile["name"]).length() <= 10, "nombre de bot <= 10")

func _test_nexus_spacing() -> void:
	var profiles := BotDataScript.profiles()
	var difficult := []
	var very_hard := []
	var extreme := []
	for profile in profiles:
		match String(profile["difficulty"]):
			"Difícil": difficult.append(int(profile["nexus"]))
			"Muy difícil": very_hard.append(int(profile["nexus"]))
			"Extremo": extreme.append(int(profile["nexus"]))
	for values in [difficult, very_hard, extreme]:
		values.sort()
		for i in range(1, values.size()):
			_ok(values[i] > values[i - 1], "NEXUS sigue estrictamente creciente")
	_ok(difficult[1] - difficult[0] >= 150 and difficult[2] - difficult[1] >= 150 and difficult[3] - difficult[2] >= 150, "Difícil tiene separación amplia")
	_ok(very_hard[1] - very_hard[0] >= 100 and very_hard[2] - very_hard[1] >= 100 and very_hard[3] - very_hard[2] >= 50, "Muy difícil mantiene separación")
	_ok(extreme[-1] == 3000 and extreme[1] - extreme[0] >= 25 and extreme[2] - extreme[1] >= 25 and extreme[3] - extreme[2] >= 25, "Extremo mantiene separación")

func _initial_board() -> Array:
	var b: Array = []
	for y in range(8):
		var row: Array = []
		for x in range(8): row.append("")
		b.append(row)
	var back_white := ["torre_blanca","caballo_blanca","alfil_blanca","dama_blanca","rey_blanca","alfil_blanca","caballo_blanca","torre_blanca"]
	var back_black := ["torre_negro","caballo_negro","alfil_negro","dama_negro","rey_negro","alfil_negro","caballo_negro","torre_negro"]
	for x in range(8):
		b[7][x] = back_white[x]
		b[6][x] = "peon_blanca"
		b[1][x] = "peon_negro"
		b[0][x] = back_black[x]
	return b
