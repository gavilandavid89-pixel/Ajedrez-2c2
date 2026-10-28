extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")
const AppConfig := preload("res://core/services/app.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_mode(GameState.MODE_2C2)
	await _test_mode(GameState.MODE_1C1)
	await _test_mode(GameState.MODE_VS_BOT)
	await _test_local_mode()
	await _test_result_layout()
	print("UI REGRESSION: %d OK / %d FALLARON" % [checks - failures.size(), failures.size()])
	for failure in failures:
		print("[FAIL] ", failure)
	quit(1 if not failures.is_empty() else 0)


func _set_mode(mode: int) -> void:
	var app = get_root().get_node_or_null("App")
	if app != null:
		app.selected_mode = mode

func _test_mode(mode: int) -> void:
	_set_mode(mode)
	var root_game = GAME_SCENE.instantiate()
	get_root().add_child(root_game)
	await process_frame
	await process_frame

	var state: GameState = root_game.game
	var board = root_game.board_view
	if mode == GameState.MODE_2C2 or mode == GameState.MODE_1C1:
		state.assign_roles_for_local_team(GameState.TEAM_WHITE)
		board.set_flipped(false)
		board.set_game(state)
	var hud = root_game.hud

	var expected_chat: bool = mode == GameState.MODE_2C2 or mode == GameState.MODE_1C1
	var expected_suggest: bool = mode == GameState.MODE_2C2
	var expected_draw: bool = false
	var expected_swap: bool = mode == GameState.MODE_2C2

	_check(state.mode == mode, "modo %d carga correctamente" % mode)
	var vp: Vector2 = board.get_viewport_rect().size
	var expected_rect: Rect2 = board.layout_for_viewport(vp)
	_check(is_equal_approx(board.board_rect.position.x, expected_rect.position.x) and is_equal_approx(board.board_rect.size.x, expected_rect.size.x), "tablero responsive en modo %d" % mode)
	_check(board.board_rect.position.x >= -0.01 and board.board_rect.end.x <= vp.x + 0.01, "tablero no se sale del viewport en modo %d" % mode)
	_check(hud.get_node("Bottom/Chat").visible == expected_chat, "chat coherente en modo %d" % mode)
	_check(hud.get_node("Bottom/Emotes").visible == (mode != GameState.MODE_VS_BOT), "emotes coherentes en modo %d" % mode)
	_check(hud.action_row.get_node("Suggest").visible == expected_suggest, "sugerencia coherente en modo %d" % mode)
	_check(hud.action_row.get_node("Draw").visible == expected_draw, "tablas coherentes en modo %d" % mode)
	_check(hud.action_row.get_node("Swap").visible == expected_swap, "cambio coherente en modo %d" % mode)

	if mode == GameState.MODE_2C2 or mode == GameState.MODE_1C1:
		_check(hud.get_node("CompactBack").visible, "menu compacto disponible durante partida online en modo %d" % mode)
		_check(not hud.get_node("CompactReset").visible, "reinicio bloqueado durante partida online en modo %d" % mode)
		_check(not hud.get_node("Top/OnlineStatus").visible, "barra online oculta en modo %d" % mode)
		_check(hud.get_node("Result/ToMenu").text in ["Volver al menú", "Menú"], "salida postpartida preparada en modo %d" % mode)
	else:
		_check(hud.get_node("Top/Back").visible, "menu disponible en modo offline %d" % mode)
		_check(hud.get_node("Top/Reset").visible, "reiniciar disponible en modo offline %d" % mode)
		_check(not hud.get_node("Top/OnlineStatus").visible, "barra online oculta en modo offline %d" % mode)

	if mode == GameState.MODE_2C2 or mode == GameState.MODE_1C1:
		await _test_input_path(root_game, state, board, mode)

	root_game.queue_free()
	await process_frame

func _tap_board(root_game, point: Vector2) -> void:
	var down := InputEventScreenTouch.new()
	down.pressed = true
	down.position = point
	root_game._input(down)
	var up := InputEventScreenTouch.new()
	up.pressed = false
	up.position = point
	root_game._input(up)

func _test_input_path(root_game, state: GameState, board, mode: int) -> void:
	var cell: float = board.board_rect.size.x / 8.0
	var e2_local: Vector2 = board.board_rect.position + Vector2(4.5 * cell, 6.5 * cell)
	var e4_local: Vector2 = board.board_rect.position + Vector2(4.5 * cell, 4.5 * cell)
	var e2_screen: Vector2 = board.get_global_transform_with_canvas() * e2_local
	var e4_screen: Vector2 = board.get_global_transform_with_canvas() * e4_local
	_tap_board(root_game, e2_screen)
	_check(board.selected == Vector2i(4, 6), "entrada táctil selecciona e2 en modo %d" % mode)
	_tap_board(root_game, e4_screen)
	await process_frame
	_check(state.get_piece(Vector2i(4, 4)) == "peon_blanca", "entrada táctil mueve e2-e4 en modo %d" % mode)
	_check(state.get_piece(Vector2i(4, 6)) == "", "origen e2 queda vacío en modo %d" % mode)

func _test_local_mode() -> void:
	_set_mode(GameState.MODE_1C1_LOCAL)
	var root_game = GAME_SCENE.instantiate()
	get_root().add_child(root_game)
	await process_frame
	await process_frame
	var board = root_game.board_view
	root_game.game.assign_roles_for_local_team(GameState.TEAM_WHITE)
	board.set_flipped(false)
	board.set_game(root_game.game)
	var before: bool = board.flipped
	var cell: float = board.board_rect.size.x / 8.0
	var e2_local: Vector2 = board.board_rect.position + Vector2(4.5 * cell, 6.5 * cell)
	var e4_local: Vector2 = board.board_rect.position + Vector2(4.5 * cell, 4.5 * cell)
	_tap_board(root_game, board.get_global_transform_with_canvas() * e2_local)
	_tap_board(root_game, board.get_global_transform_with_canvas() * e4_local)
	await process_frame
	_check(not before and board.flipped, "1c1 local gira el tablero despues de mover")
	_check(not root_game.hud.get_node("Bottom/Chat").visible, "1c1 local no muestra chat online")
	_check(root_game.hud.get_node("Bottom/Emotes").visible, "1c1 local mantiene emotes")
	root_game.queue_free()
	await process_frame

func _test_result_layout() -> void:
	_set_mode(GameState.MODE_2C2)
	var root_game = GAME_SCENE.instantiate()
	get_root().add_child(root_game)
	await process_frame
	await process_frame
	var state: GameState = root_game.game
	var hud = root_game.hud
	state.finish(GameState.TEAM_WHITE, "Jaque mate")
	await process_frame
	await process_frame
	var vp: Vector2 = root_game.get_viewport_rect().size
	var result: Control = hud.get_node("Result")
	var result_screen: Control = hud.get_node("MatchResultScreen")
	_check(result_screen.visible, "pantalla final visible al terminar")
	_check(not result.visible, "modal antiguo de resultado queda reemplazado")
	_check(result_screen.get_node("Close") != null, "X devuelve al tablero terminado")
	_check(result_screen.get_node("ResultScroll") != null, "pantalla final permite deslizar")
	_check(_contains_text(result_screen, "ANALIZAR PARTIDA"), "resultado ofrece acceso directo al análisis")
	_check(not hud.get_node("Bottom").visible, "controles inferiores ocultos al terminar")
	_check(not hud.get_node("Turn").visible and not hud.get_node("Status").visible, "estado de partida oculto al terminar")
	_check(hud.get_node("FinishedResultButton").visible == false, "botón para reabrir resultado queda oculto mientras está abierto")
	hud.set_result_entry({"competitive": true, "rating_delta": 10, "cup_delta": 10})
	_check("Rating +10" in hud.result_label.text and "Copas +10" in hud.result_label.text, "compatibilidad de progreso competitivo sigue actualizada")
	root_game.queue_free()
	await process_frame

func _contains_text(node: Node, text_value: String) -> bool:
	if node is Button and String(node.text).find(text_value) >= 0:
		return true
	if node is Label and String(node.text).find(text_value) >= 0:
		return true
	for child in node.get_children():
		if _contains_text(child, text_value):
			return true
	return false

func _check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("[OK] ", label)
	else:
		failures.append(label)
