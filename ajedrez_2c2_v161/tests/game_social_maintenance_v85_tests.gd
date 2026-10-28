extends SceneTree

const GameState = preload("res://domain/chess/game_state.gd")

var passed := 0
var failed := 0
var game: GameState

func _initialize() -> void:
	game = GameState.new()
	root.add_child(game)
	game.reset_match(GameState.MODE_2C2)
	_test_suggestion_acceptance_is_local_and_manual()
	_test_suggestion_reject_clears()
	_test_question_is_one_shot_and_does_not_move()
	_test_swap_requires_target_teammate()
	_test_surrender_uses_local_player()
	_test_draw_uses_local_player()
	_test_social_controls_work_off_turn()
	print("GAME SOCIAL V85: %d OK / %d FALLARON" % [passed, failed])
	game.queue_free()
	quit(0 if failed == 0 else 1)

func _reset() -> void:
	game.reset_match(GameState.MODE_2C2)
	game.local_player_slot = 0

func _ok(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _test_suggestion_acceptance_is_local_and_manual() -> void:
	_reset()
	game.board[6][4] = ""
	game.board[4][4] = "peon_blanca"
	_ok(game.propose_suggestion(Vector2i(4,4), Vector2i(4,3)), "local puede sugerir en su turno")
	_ok(game.answer_suggestion(true, game.local_player_slot) == false, "proponente no puede aceptar su propia sugerencia")
	game.local_player_slot = 2
	var before_piece := game.get_piece(Vector2i(4,4))
	_ok(game.answer_suggestion(true, game.local_player_slot), "compañero local puede aceptar")
	_ok(bool(game.suggestion.get("accepted", false)), "aceptación queda registrada")
	_ok(String(game.suggestion.get("status", "")) == "accepted", "estado pasa a accepted")
	_ok(game.get_piece(Vector2i(4,4)) == before_piece and game.move_history.is_empty(), "aceptar no ejecuta movimiento")

func _test_suggestion_reject_clears() -> void:
	_reset()
	game.board[6][4] = ""
	game.board[4][4] = "peon_blanca"
	_ok(game.propose_suggestion(Vector2i(4,4), Vector2i(4,3)), "se crea sugerencia para rechazar")
	game.local_player_slot = 2
	_ok(game.answer_suggestion(false, game.local_player_slot), "compañero puede rechazar")
	_ok(game.suggestion.is_empty(), "rechazar limpia la sugerencia")

func _test_question_is_one_shot_and_does_not_move() -> void:
	_reset()
	game.board[6][4] = ""
	game.board[4][4] = "peon_blanca"
	_ok(game.propose_suggestion(Vector2i(4,4), Vector2i(4,3)), "se crea sugerencia para cuestionar")
	game.local_player_slot = 2
	_ok(game.question_suggestion(game.local_player_slot), "compañero puede cuestionar")
	_ok(bool(game.suggestion.get("questioned", false)), "cuestionar queda registrado")
	_ok(not game.question_suggestion(game.local_player_slot), "una sugerencia no puede cuestionarse dos veces")
	_ok(game.move_history.is_empty(), "cuestionar no mueve pieza")

func _test_swap_requires_target_teammate() -> void:
	_reset()
	game.current_slot = 0
	_ok(game.request_swap(), "jugador cuyo turno está activo puede solicitar Cambio")
	game.local_player_slot = 0
	_ok(not game.answer_swap(true), "proponente no puede autoaceptar Cambio")
	game.local_player_slot = 2
	_ok(game.answer_swap(true), "compañero puede aceptar Cambio")

func _test_surrender_uses_local_player() -> void:
	_reset()
	game.current_slot = 0
	game.local_player_slot = 0
	_ok(game.request_surrender(), "rendición usa el jugador local durante su turno")
	_ok(not game.request_surrender(), "no se pueden apilar rendiciones")
	_ok(int(game.surrender_request.get("from", -1)) == 0, "rendición pertenece al jugador local")
	_ok(int(game.surrender_request.get("waiting", -1)) == 2, "espera a su compañero real")

func _test_draw_uses_local_player() -> void:
	_reset()
	game.current_slot = 0
	game.local_player_slot = 0
	_ok(game.request_draw(), "tablas usa el jugador local durante su turno")
	_ok(not game.request_draw(), "no se pueden apilar ofertas de tablas")
	_ok(int(game.draw_state.get("by_slot", -1)) == 0, "oferta de tablas pertenece al jugador local")
	_ok(int(game.draw_state.get("target_team", -1)) == 1, "oponente objetivo es el equipo contrario al local")

func _test_social_controls_work_off_turn() -> void:
	_reset()
	game.local_player_slot = 0
	game.current_slot = 1 # turno del equipo rival
	game.board[6][4] = ""
	game.board[4][4] = "peon_blanca"
	_ok(game.propose_suggestion(Vector2i(4,4), Vector2i(4,3)), "puede sugerir fuera de su turno, usando una pieza de su equipo")
	_reset()
	game.local_player_slot = 0
	game.current_slot = 1
	_ok(game.request_swap(), "puede solicitar cambio fuera de su turno")
	_reset()
	game.local_player_slot = 0
	game.current_slot = 1
	var before_chat := game.chat_history.size()
	game.chat("¡Buena partida!")
	_ok(game.chat_history.size() == before_chat + 1, "chat acepta mensajes fuera de turno")
	_ok(game.emote("bien"), "puede reaccionar fuera de turno")
