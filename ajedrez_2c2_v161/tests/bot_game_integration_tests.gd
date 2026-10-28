extends SceneTree

const ChessGameState = preload("res://domain/chess/game_state.gd")
const AppConfig = preload("res://core/services/app.gd")
const ChessRules = preload("res://domain/chess/rules.gd")

var passed := 0
var failed := 0

func _init() -> void:
	var app := Node.new()
	app.name = "App"
	app.set_script(load("res://core/services/app.gd"))
	get_root().add_child(app)
	app.selected_mode = AppConfig.MODE_VS_BOT
	app.selected_bot_id = "experto"
	app.selected_bot_elo = 1600

	var game := ChessGameState.new()
	get_root().add_child(game)
	game.reset_match(AppConfig.MODE_VS_BOT, 10)
	_ok(game.current_slot == 0, "VS IA comienza con humano")
	var moved := game.attempt_move(Vector2i(4, 6), Vector2i(4, 4), "dama", false)
	_ok(moved, "humano puede mover e2-e4")
	_ok(game.current_slot == 1, "turno pasa al bot")
	var bot_moved := game.bot_take_turn()
	_ok(bot_moved, "bot mueve después del humano")
	_ok(game.move_history.size() == 2, "historial contiene la jugada humana y la del bot")
	_ok(game.board_valid() if game.has_method("board_valid") else ChessRules.new().board_valid(game.board), "tablero sigue válido")
	print("BOT INTEGRATION: %d/%d OK" % [passed, passed + failed])
	quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)
