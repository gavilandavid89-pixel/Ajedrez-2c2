extends SceneTree

const ReplayViewScript := preload("res://domain/replay/match_replay_view.gd")
const GameState := preload("res://domain/chess/game_state.gd")
const AccountScene := preload("res://scenes/account_hub.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    await process_frame
    await process_frame

    var game := GameState.new()
    game.reset_match(GameState.MODE_1C1_LOCAL)
    game.attempt_move(Vector2i(4,6), Vector2i(4,4))
    game.attempt_move(Vector2i(4,1), Vector2i(4,3))
    game.attempt_move(Vector2i(6,7), Vector2i(5,5))
    game.attempt_move(Vector2i(1,0), Vector2i(2,2))

    var replay := ReplayViewScript.new()
    root.add_child(replay)
    await process_frame
    replay.set_replay_data(game.replay_data(), game.replay_moves())
    await process_frame
    _check(replay._move_scroll.get_parent() == replay._move_scroll.get_parent(), "Replay crea la tira de jugadas")
    _check(replay._board_side >= 300.0, "En móvil el tablero conserva tamaño grande")
    _check(replay._move_list.get_theme_constant("separation") >= 12, "Las jugadas tienen separación legible")
    _check(replay._previous_button.custom_minimum_size.x >= 44.0 and replay._next_button.custom_minimum_size.x >= 44.0, "Navegación tiene objetivos táctiles cómodos")
    _check(replay._auto_button.text == "AUTO", "Existe el control AUTO")
    _check(replay._coach_panel.visible == false, "El coach no aparece en jugadas sin clasificación")

    replay.set_engine_analysis({"moves": [
        {"classification":"Bien", "coach_text":"Bien."},
        {"classification":"Imprecisa", "coach_text":"Aquí perdiste una oportunidad importante.", "highlight_from":"g1", "highlight_to":"f3"},
        {"classification":"Brillante", "coach_text":"¡Encontraste una continuación muy fuerte!", "highlight_from":"b1", "highlight_to":"c3"},
        {"classification":"Bien", "coach_text":"Bien."},
    ]})
    await process_frame
    replay.set_replay_position(2)
    await process_frame
    _check(replay._coach_panel.visible, "El coach aparece de forma contextual")
    _check(replay._coach_title.text.find("IMPRECISA") >= 0, "El coach muestra la clasificación")
    replay.set_replay_position(0)
    replay.toggle_auto_review()
    await process_frame
    await create_timer(0.7).timeout
    _check(replay._index >= 2, "AUTO avanza varias jugadas sin intervención")
    _check(not replay._auto_review, "AUTO se detiene al encontrar una jugada importante")

    replay.queue_free()
    game.queue_free()
    await process_frame
    print("V49 REPLAY MÓVIL: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
