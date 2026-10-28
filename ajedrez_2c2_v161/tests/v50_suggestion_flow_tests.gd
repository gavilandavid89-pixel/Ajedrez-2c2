extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.selected_mode = GameState.MODE_2C2
        app.temporary_online_bots = false

    var scene = GAME_SCENE.instantiate()
    get_root().add_child(scene)
    await process_frame
    await process_frame

    var game: GameState = scene.game
    var board = scene.board_view

    # Flujo normal de Sugerir: botón -> origen -> destino. Nunca mueve la pieza.
    scene._on_action("suggest")
    _check(scene.suggestion_mode, "Sugerir activa modo de marcado")
    _check(board.selected == Vector2i(-1, -1), "sin selección inicial")
    scene._on_board_square(Vector2i(4, 6))
    _check(board.selected == Vector2i(4, 6), "Sugerir permite seleccionar origen")
    _check(game.move_history.is_empty(), "seleccionar origen no crea movimiento")
    scene._on_board_square(Vector2i(4, 4))
    _check(game.move_history.is_empty(), "seleccionar destino no mueve la pieza")
    _check(game.get_piece(Vector2i(4, 6)) == "peon_blanca", "la pieza original permanece en e2")
    _check(game.get_piece(Vector2i(4, 4)) == "", "e4 permanece vacío")
    _check(int(game.suggestion.get("by_slot", -1)) == 0, "la sugerencia pertenece al jugador local")
    _check(int(game.suggestion.get("recipient_slot", -1)) == 2, "la sugerencia llega al compañero")
    _check(game.suggestion.get("from", Vector2i(-1, -1)) == Vector2i(4, 6), "flecha fantasma conserva origen")
    _check(game.suggestion.get("to", Vector2i(-1, -1)) == Vector2i(4, 4), "flecha fantasma conserva destino")
    _check(not scene.suggestion_mode, "modo Sugerir termina al enviar")

    # Si la pieza ya estaba seleccionada, Sugerir pide directamente el destino.
    game.reset_match(GameState.MODE_2C2)
    await process_frame
    scene._on_board_square(Vector2i(4, 6))
    scene._on_action("suggest")
    _check(scene.suggestion_mode, "Sugerir funciona con pieza ya seleccionada")
    scene._on_board_square(Vector2i(4, 4))
    _check(game.move_history.is_empty() and game.get_piece(Vector2i(4, 6)) == "peon_blanca", "pieza seleccionada tampoco se mueve al sugerir")
    _check(not game.suggestion.is_empty(), "se crea la sugerencia con selección previa")

    # La sugerencia del bot debe verse para el slot local aunque sea turno del bot.
    game.reset_match(GameState.MODE_2C2)
    game.set_temporary_bot(2, "nora")
    game.current_slot = 2
    _check(game.bot_prepare_suggestion(), "bot prepara sugerencia para su compañero")
    _check(game.suggestion_visible_to(0), "slot local puede ver la sugerencia del compañero")
    _check(not game.suggestion_visible_to(1), "rival no puede ver la sugerencia")
    _check(game.get_piece(Vector2i(4, 6)) == "peon_blanca", "sugerencia del bot no mueve piezas")

    # La vista local no debe depender del turno actual para responder.
    game.current_slot = 2
    game.local_player_slot = 0
    game.suggestion = {"from": Vector2i(4, 6), "to": Vector2i(4, 4), "by_slot": 2, "recipient_slot": 0, "accepted": false, "questioned": false}
    _check(game.answer_suggestion(true, game.local_player_slot), "jugador local puede responder a sugerencia aunque el turno sea del compañero")
    _check(bool(game.suggestion.get("accepted", false)), "respuesta de sugerencia se registra para el slot local")

    scene.queue_free()
    print("V50 SUGERENCIAS: %d OK / %d FALLARON" % [checks - failures.size(), failures.size()])
    for failure in failures:
        print("[FAIL] ", failure)
    quit(1 if not failures.is_empty() else 0)

func _check(value: bool, label: String) -> void:
    checks += 1
    if value:
        print("[OK] ", label)
    else:
        failures.append(label)
