extends SceneTree

const AccountScene := preload("res://scenes/account_hub.tscn")
const GameState := preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    var player = root.get_node_or_null("PlayerData")
    var app = root.get_node_or_null("App")
    if player == null or app == null:
        quit(1)
        return
    await process_frame
    player.history.clear()

    var game := GameState.new()
    game.reset_match(GameState.MODE_1C1_LOCAL)
    game.attempt_move(Vector2i(4,6), Vector2i(4,4))
    game.attempt_move(Vector2i(4,1), Vector2i(4,3))
    game.attempt_move(Vector2i(6,7), Vector2i(5,5))
    game.attempt_move(Vector2i(1,0), Vector2i(2,2))
    game.attempt_move(Vector2i(5,5), Vector2i(4,3))
    game.attempt_move(Vector2i(3,0), Vector2i(7,4))
    player.record_noncompetitive_match({
        "match_id":"V49_CAPTURE",
        "mode":GameState.MODE_1C1_LOCAL,
        "outcome":"win",
        "move_count":6,
        "moves":game.replay_moves(),
        "replay_data":game.replay_data(),
        "analysis_viewed":true,
        "engine_analysis":{
            "moves":[
                {"classification":"Bien","coach_text":"Desarrollo correcto."},
                {"classification":"Muy bien","coach_text":"Buena coordinación y presión sobre el centro.","highlight_from":"g1","highlight_to":"f3"},
                {"classification":"Imprecisa","coach_text":"Aquí perdiste una oportunidad concreta: la alternativa mantenía más ventaja.","highlight_from":"f3","highlight_to":"e5"},
                {"classification":"Brillante","coach_text":"¡Encontraste una continuación muy fuerte! Esta jugada supera claramente las alternativas.","highlight_from":"d1","highlight_to":"h5"},
                {"classification":"Bien","coach_text":"Bien."},
                {"classification":"Error grave","coach_text":"Esta jugada permite una respuesta táctica que cambia la posición.","highlight_from":"h5","highlight_to":"f7"}
            ]
        }
    })
    game.queue_free()

    app.account_start_page = "history"
    var account := AccountScene.instantiate()
    root.add_child(account)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    _save("/mnt/data/v49_history_mobile.png")

    var buttons := _buttons_with_text(account, "Ver")
    if buttons.is_empty():
        buttons = _buttons_with_text(account, "Analizar partida")
    if not buttons.is_empty():
        buttons[0].pressed.emit()
    await process_frame
    await process_frame
    var study: MatchReplayView = account.body.find_child("GameReviewStudy", true, false)
    if study != null:
        study.set_replay_position(3)
    await process_frame
    await RenderingServer.frame_post_draw
    _save("/mnt/data/v49_replay_portrait.png")

    account.queue_free()
    await process_frame
    quit(0)

func _save(path: String) -> void:
    var image := get_root().get_texture().get_image()
    image.save_png(path)

func _buttons_with_text(root_node: Node, value: String) -> Array[Button]:
    var found: Array[Button] = []
    for child in root_node.get_children():
        if child is Button and child.text.strip_edges() == value:
            found.append(child)
        found.append_array(_buttons_with_text(child, value))
    return found
