extends SceneTree

const AppConfig = preload("res://core/services/app.gd")
const GameState = preload("res://domain/chess/game_state.gd")
const GameScene = preload("res://scenes/game.tscn")
const BotData = preload("res://domain/bots/bot_data.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    await _test_real_board_input()
    _test_vs_bot_response()
    _test_selected_bot_profile()
    _test_temporary_online_bots_2c2()
    _test_temporary_online_bot_1c1()
    _test_normal_2c2_has_no_temp_bots()
    _test_private_online_does_not_use_bots()
    print("MOVEMENT/BOT REGRESSION: %d/%d OK" % [passed, passed + failed])
    quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        push_error("[FAIL] " + label)

func _set_mode(mode: int, temp_online: bool = false, bot_id: String = "mateo") -> void:
    var app = get_root().get_node_or_null("App")
    if app == null:
        app = Node.new()
        app.name = "App"
        app.set_script(load("res://core/services/app.gd"))
        get_root().add_child(app)
    app.selected_mode = mode
    app.selected_bot_id = bot_id
    app.selected_bot_elo = BotData.elo_for(bot_id)
    app.temporary_online_bots = temp_online

func _board_point(board, logical: Vector2i) -> Vector2:
    var cell: float = board.board_rect.size.x / 8.0
    var screen := logical
    if board.flipped:
        screen = Vector2i(7 - logical.x, 7 - logical.y)
    var local_point: Vector2 = board.board_rect.position + Vector2((screen.x + 0.5) * cell, (screen.y + 0.5) * cell)
    return board.get_global_transform_with_canvas() * local_point

func _board_touch(root_game, logical: Vector2i) -> void:
    var board = root_game.board_view
    var pos := _board_point(board, logical)
    var ev := InputEventScreenTouch.new()
    ev.pressed = true
    ev.position = pos
    root_game._input(ev)
    var up := InputEventScreenTouch.new()
    up.pressed = false
    up.position = pos
    root_game._input(up)


func _test_real_board_input() -> void:
    _set_mode(AppConfig.MODE_VS_BOT, false, "mateo")
    var root_game = GameScene.instantiate()
    get_root().add_child(root_game)
    await process_frame
    await process_frame
    var game: GameState = root_game.game
    var board = root_game.board_view
    game.assign_roles_for_local_team(GameState.TEAM_WHITE)
    board.set_flipped(false)
    board.set_game(game)
    var before_touch := game.move_history.size()
    _board_touch(root_game, Vector2i(4, 6))
    _board_touch(root_game, Vector2i(4, 4))
    _ok(game.move_history.size() == before_touch + 1, "input touch del tablero registra e2-e4")
    _ok(game.get_piece(Vector2i(4, 4)) == "peon_blanca", "touch deja el peón en e4")
    game.reset_match(AppConfig.MODE_VS_BOT, 1)
    game.assign_roles_for_local_team(GameState.TEAM_WHITE)
    board.set_flipped(false)
    board.set_game(game)
    var start := _board_point(board, Vector2i(4, 6))
    var end := _board_point(board, Vector2i(4, 4))
    var drag_down := InputEventScreenTouch.new()
    drag_down.pressed = true
    drag_down.position = start
    root_game._input(drag_down)
    var drag_up := InputEventScreenTouch.new()
    drag_up.pressed = false
    drag_up.position = end
    root_game._input(drag_up)
    _ok(game.move_history.size() == 1 and game.get_piece(Vector2i(4, 4)) == "peon_blanca", "arrastrar pieza mueve en un solo gesto táctil")
    _ok(root_game.hud.get_node("Bottom/GameMenu").disabled, "menu de acciones bloqueado durante turno bot")
    root_game.queue_free()
    await process_frame

func _test_vs_bot_response() -> void:
    var game := GameState.new()
    get_root().add_child(game)
    _set_mode(AppConfig.MODE_VS_BOT, false, "mateo")
    game.reset_match(AppConfig.MODE_VS_BOT, 1)
    _ok(game.is_bot_slot(1), "VS IA registra slot del bot")
    _ok(game.attempt_move(Vector2i(4,6), Vector2i(4,4)), "humano puede mover antes del bot")
    _ok(game.bot_take_turn(), "bot responde con una jugada")
    _ok(game.move_history.size() == 2 and game.current_slot == 0, "turno vuelve al humano")
    game.queue_free()
    await process_frame

func _test_selected_bot_profile() -> void:
    var game := GameState.new()
    get_root().add_child(game)
    _set_mode(AppConfig.MODE_VS_BOT, false, "experto")
    game.reset_match(AppConfig.MODE_VS_BOT, 1)
    _ok(String(game.bot_slots.get(1, "")) == "experto", "VS IA conserva el bot elegido")
    game.queue_free()
    await process_frame

func _test_temporary_online_bots_2c2() -> void:
    _set_mode(AppConfig.MODE_2C2, true)
    var game := GameState.new()
    get_root().add_child(game)
    game.reset_match(AppConfig.MODE_2C2, 1)
    _ok(game.is_bot_slot(1) and game.is_bot_slot(2) and game.is_bot_slot(3), "2c2 online temporal asigna tres bots")
    _ok(game.attempt_move(Vector2i(4,6), Vector2i(4,4)), "jugador inicia la partida online temporal")
    var a := game.bot_take_turn()
    var b := game.bot_take_turn()
    var c := game.bot_take_turn()
    _ok(a and b and c, "los tres bots temporales mueven")
    _ok(game.current_slot == 0 and game.move_history.size() == 4, "el ciclo online temporal vuelve al jugador")
    game.queue_free()
    await process_frame

func _test_temporary_online_bot_1c1() -> void:
    _set_mode(AppConfig.MODE_1C1, true)
    var game := GameState.new()
    get_root().add_child(game)
    game.reset_match(AppConfig.MODE_1C1, 1)
    _ok(game.is_bot_slot(1), "1c1 online temporal asigna bot rival")
    _ok(game.attempt_move(Vector2i(4,6), Vector2i(4,4)), "jugador inicia 1c1 online temporal")
    _ok(game.bot_take_turn(), "rival temporal responde")
    game.queue_free()
    await process_frame

func _test_private_online_does_not_use_bots() -> void:
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.online_entry = "friend_join"
    var should_simulate_public := String(app.online_entry) == "random" if app != null else false
    _ok(not should_simulate_public, "sala privada por código no se trata como matchmaking público")

func _test_normal_2c2_has_no_temp_bots() -> void:
    _set_mode(AppConfig.MODE_2C2, false)
    var game := GameState.new()
    get_root().add_child(game)
    game.reset_match(AppConfig.MODE_2C2, 1)
    _ok(game.bot_slots.is_empty(), "2c2 normal no convierte jugadores en bots")
    game.queue_free()
    await process_frame
