extends SceneTree

const GameScene = preload("res://scenes/game.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    await process_frame
    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = 0
        app.temporary_online_bots = true
        app.selected_bot_id = "nora"
        app.selected_bot_elo = 700

    var scene := GameScene.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame

    scene.game.current_slot = 2
    scene.game.set_temporary_bot(2, "nora")
    var initial_moves: int = scene.game.move_history.size()
    var appeared := false
    var elapsed := 0.0
    while elapsed < 3.2:
        await create_timer(0.10).timeout
        elapsed += 0.10
        if not scene.game.suggestion.is_empty():
            appeared = true
            break

    _check(appeared, "la sugerencia del bot aparece durante su turno")
    if appeared:
        var before_hold_moves: int = scene.game.move_history.size()
        await create_timer(1.0).timeout
        _check(scene.game.move_history.size() == before_hold_moves, "el bot no juega inmediatamente despues de sugerir")
        _check(not scene.game.suggestion.is_empty(), "la sugerencia sigue visible durante la lectura")
        await create_timer(1.3).timeout
        _check(scene.game.move_history.size() > before_hold_moves, "el bot juega despues del tiempo de lectura")

    _check(scene.game.move_history.size() >= initial_moves, "la partida conserva el historial")

    # Sugerir entra en modo de marcado sin seleccionar ni mover una pieza.
    # La sugerencia solo se crea después de elegir origen y destino.
    scene.game.reset_match(0, 1)
    scene.board_view.set_game(scene.game)
    scene._on_action("suggest")
    _check(scene.suggestion_mode and scene.game.suggestion.is_empty(), "Sugerir activa el marcado sin selección previa")
    scene._on_board_square(Vector2i(4, 6))
    scene._on_board_square(Vector2i(4, 4))
    _check(scene.game.move_history.is_empty(), "Sugerir sigue sin ejecutar una jugada")
    _check(not scene.game.suggestion.is_empty(), "Sugerir crea la propuesta tras origen y destino")

    scene.queue_free()
    if app != null:
        app.temporary_online_bots = false
    print("V49 BOT SUGERENCIA: %d OK / %d FAIL" % [passed, failed])
    quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        print("[FAIL] " + label)
