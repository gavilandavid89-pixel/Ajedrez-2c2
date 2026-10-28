extends SceneTree
const AccountScene := preload("res://scenes/account_hub.tscn")
const GameScene := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")
func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    await process_frame
    await process_frame
    var game_scene := GameScene.instantiate()
    root.add_child(game_scene)
    await process_frame
    await process_frame
    var game_board = game_scene.get_node("Board")
    var expected_size: float = game_board.board_rect.size.x
    var expected_pos: Vector2 = game_board.board_rect.position
    game_scene.queue_free()
    await process_frame

    var data = root.get_node_or_null("PlayerData")
    if data == null:
        push_error("PlayerData no disponible"); quit(1); return
    data.history.clear()
    var game := GameState.new(); game.reset_match(GameState.MODE_1C1_LOCAL)
    game.attempt_move(Vector2i(4,6),Vector2i(4,4)); game.attempt_move(Vector2i(4,1),Vector2i(4,3))
    game.attempt_move(Vector2i(6,7),Vector2i(5,5)); game.attempt_move(Vector2i(1,0),Vector2i(2,2))
    data.record_noncompetitive_match({"match_id":"V46_COMPARE","mode":GameState.MODE_1C1_LOCAL,"outcome":"win","move_count":4,"moves":game.replay_moves(),"replay_data":game.replay_data()})
    game.free()
    var scene := AccountScene.instantiate(); root.add_child(scene)
    await process_frame; await process_frame
    scene.selected_history_index = data.history.size()-1; scene.page="replay"; scene._refresh()
    await process_frame; await process_frame
    var replay: MatchReplayView = scene.find_child("GameReplayStudy",true,false)
    var board = replay._board
    print("GAME_BOARD_RECT=", expected_pos, "/", expected_size, " REPLAY_BOARD=", board.position, "/", board.size)
    _check(absf(board.size.x - expected_size) < 0.1, "Replay usa el mismo tamaño de tablero que Partida")
    _check(absf(board.size.y - expected_size) < 0.1, "Replay conserva la misma proporción 1:1")
    _check(absf(board.position.x - expected_pos.x) < 0.1, "Replay usa la misma alineación horizontal que Partida")
    _check(replay._move_scroll.get_global_position().y + replay._move_scroll.size.y <= board.get_global_position().y + 0.1, "Movimientos por encima del tablero")
    var nav = replay.get_node("ReplayLayout/ReplayNavigation")
    _check(nav.position.y >= board.position.y + board.size.y - 0.1, "Navegación inmediatamente debajo del tablero")
    quit(0)
func _check(v: bool,label:String)->void:
    if v: print("[OK] ",label)
    else: push_error("[FALLA] "+label)
