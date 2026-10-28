extends SceneTree

const GameState = preload("res://domain/chess/game_state.gd")
const BoardScene = preload("res://scenes/board.tscn")

var fails := 0

func _initialize() -> void:
	_test_modes()
	_test_clock()
	_test_board_layout()
	_test_bot()
	_test_hud_metadata()
	_test_local_flip()
	print("BASE EXTRA RESULT: %d OK / %d FALLARON" % [9 - fails, fails])
	quit(fails)

func _ok(name: String) -> void:
	print("[OK] ", name)

func _fail(name: String, detail: String = "") -> void:
	fails += 1
	print("[FAIL] ", name, " ", detail)

func _test_modes() -> void:
	var modes: Array[int] = [GameState.MODE_2C2, GameState.MODE_1C1, GameState.MODE_VS_BOT, GameState.MODE_1C1_LOCAL]
	var labels: Array[String] = ["2c2", "1c1", "vs bot", "1c1 local"]
	for i in range(modes.size()):
		var g: GameState = GameState.new()
		g.reset_match(modes[i])
		root.add_child(g)
		var active := 0
		for a in g.slot_active:
			if a: active += 1
		var expected := 4 if i == 0 else 2
		if active != expected:
			_fail("modo " + labels[i], "activos=%d esperado=%d" % [active, expected])
		else:
			_ok("modo " + labels[i] + " configurado")
		g.queue_free()

func _test_clock() -> void:
	var g: GameState = GameState.new()
	g.reset_match(GameState.MODE_2C2)
	root.add_child(g)
	if g.team_time.size() == 2 and g.team_time[0] == GameState.MATCH_SECONDS and g.team_time[1] == GameState.MATCH_SECONDS:
		_ok("reloj por equipos presente")
	else:
		_fail("reloj por equipos presente")
	g.queue_free()

func _test_board_layout() -> void:
	var board = BoardScene.instantiate()
	root.add_child(board)
	var mobile: Rect2 = board.layout_for_viewport(Vector2(720, 1280))
	var landscape: Rect2 = board.layout_for_viewport(Vector2(1280, 720))
	var mobile_ok := is_equal_approx(mobile.size.x, 720.0) and is_equal_approx(mobile.position.x, 0.0)
	var landscape_ok := is_equal_approx(landscape.position.x, (1280.0 - landscape.size.x) * 0.5)
	if mobile_ok and landscape_ok:
		_ok("tablero centrado y a todo el ancho en móvil")
	else:
		_fail("tablero centrado y a todo el ancho en móvil", "mobile=%s landscape=%s" % [mobile, landscape])
	board.queue_free()

func _test_bot() -> void:
	var g: GameState = GameState.new()
	g.reset_match(GameState.MODE_VS_BOT)
	root.add_child(g)
	var human_moved := g.attempt_move(Vector2i(4, 6), Vector2i(4, 4))
	var bot_moved := g.bot_take_turn()
	if human_moved and bot_moved and g.current_slot == 0:
		_ok("vs bot hace su respuesta y devuelve el turno")
	else:
		_fail("vs bot hace su respuesta y devuelve el turno")
	g.queue_free()

func _test_hud_metadata() -> void:
	var hud_scene = preload("res://scenes/game_hud.tscn")
	var hud = hud_scene.instantiate()
	root.add_child(hud)
	var suggest = hud.get_node("Bottom/Actions/Suggest")
	var swap = hud.get_node("Bottom/Actions/Swap")
	if suggest.get_meta("_action") == "suggest" and swap.get_meta("_action") == "swap":
		_ok("acciones de HUD correctamente enlazadas")
	else:
		_fail("acciones de HUD correctamente enlazadas")
	hud.queue_free()

func _test_local_flip() -> void:
	var board = BoardScene.instantiate()
	root.add_child(board)
	var normal: Vector2i = board._screen_pos(Vector2i(0, 7))
	board.set_flipped(true)
	var flipped: Vector2i = board._screen_pos(Vector2i(0, 7))
	if normal == Vector2i(0, 7) and flipped == Vector2i(7, 0):
		_ok("1c1 local puede girar el tablero")
	else:
		_fail("1c1 local puede girar el tablero")
	board.queue_free()
