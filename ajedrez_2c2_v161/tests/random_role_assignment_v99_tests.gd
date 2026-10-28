extends SceneTree

const ChessGameState = preload("res://domain/chess/game_state.gd")
const AppConfig = preload("res://core/services/app.gd")

var passed := 0
var failed := 0

func _init() -> void:
	var app := Node.new()
	app.name = "App"
	app.set_script(load("res://core/services/app.gd"))
	get_root().add_child(app)

	_test_forced_roles(app)
	_test_random_distribution(app)
	_test_skin_independence()
	print("RANDOM ROLES V99: %d/%d OK" % [passed, passed + failed])
	quit(1 if failed > 0 else 0)

func _new_game(mode: int) -> ChessGameState:
	var game := ChessGameState.new()
	get_root().add_child(game)
	game.reset_match(mode, 10)
	return game

func _test_forced_roles(_app: Node) -> void:
	for mode in [AppConfig.MODE_1C1, AppConfig.MODE_VS_BOT, AppConfig.MODE_1C1_LOCAL, AppConfig.MODE_2C2]:
		var game := _new_game(mode)
		game.assign_roles_for_local_team(game.TEAM_WHITE)
		_ok(game.local_team() == game.TEAM_WHITE, "%s: local puede ser Blancas" % mode)
		_ok(game.current_team() == game.TEAM_WHITE, "%s: comienza el turno de Blancas" % mode)
		game.assign_roles_for_local_team(game.TEAM_BLACK)
		_ok(game.local_team() == game.TEAM_BLACK, "%s: local puede ser Negras" % mode)
		_ok(game.current_team() == game.TEAM_WHITE, "%s: aun siendo Negras, comienza Blancas" % mode)
		_ok(game.current_slot != game.local_player_slot, "%s: cuando local es Negro no fuerza su turno" % mode)
		if mode == AppConfig.MODE_2C2:
			_ok(game.slot_colors == [game.TEAM_BLACK, game.TEAM_WHITE, game.TEAM_BLACK, game.TEAM_WHITE], "2c2 mantiene 2 vs 2 al invertir rol local")
		else:
			_ok(game.slot_colors[0] == game.TEAM_BLACK and game.slot_colors[1] == game.TEAM_WHITE, "%s: roles 1c1 quedan invertidos" % mode)
		game.queue_free()

func _test_random_distribution(_app: Node) -> void:
	var saw_white := false
	var saw_black := false
	var game := _new_game(AppConfig.MODE_1C1)
	for _i in range(80):
		game.reset_match(AppConfig.MODE_1C1, 10)
		game.randomize_roles()
		if game.local_team() == game.TEAM_WHITE:
			saw_white = true
		else:
			saw_black = true
		if saw_white and saw_black:
			break
	_ok(saw_white and saw_black, "el rol local se asigna aleatoriamente en nuevas partidas")
	game.queue_free()

func _test_skin_independence() -> void:
	var game := _new_game(AppConfig.MODE_1C1)
	game.assign_roles_for_local_team(game.TEAM_BLACK)
	_ok(game.local_team() == game.TEAM_BLACK, "el rol existe en el estado de partida, no en la skin")
	_ok(game.board[0][4] == "rey_negro" and game.board[7][4] == "rey_blanca", "el tablero conserva piezas blancas/negras reales")
	game.queue_free()

func _ok(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
