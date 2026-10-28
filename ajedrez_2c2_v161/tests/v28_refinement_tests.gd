extends SceneTree

const GameState = preload("res://domain/chess/game_state.gd")
const BotData = preload("res://domain/bots/bot_data.gd")
const GameScene = preload("res://scenes/game.tscn")
const ModeScene = preload("res://scenes/mode_menu.tscn")
const AccountScene = preload("res://scenes/account_hub.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    await process_frame
    _check(BotData.thinking_time_for("mateo") > BotData.thinking_time_for("nora"), "Mateo piensa más que Nora")
    _check(BotData.thinking_time_for("nora") > BotData.thinking_time_for("tactico"), "Nora piensa más que Táctico")
    _check(BotData.thinking_time_for("tactico") > BotData.thinking_time_for("estratega"), "Táctico piensa más que Estratega")
    _check(BotData.thinking_time_for("estratega") > BotData.thinking_time_for("experto"), "Estratega piensa más que Experto")
    _check(BotData.thinking_time_for("mateo") >= 1.5, "bot bajo nunca juega al instante")

    var game := GameState.new()
    root.add_child(game)
    game.reset_match(GameState.MODE_2C2)
    game.set_temporary_bot(2, "nora")
    game.current_slot = 2
    var suggestion_ok := game.bot_prepare_suggestion()
    _check(suggestion_ok, "bot 2c2 puede generar sugerencia")
    _check(not game.suggestion.is_empty(), "sugerencia del bot queda visible en estado")
    _check(int(game.suggestion.get("by_slot", -1)) == 2 and int(game.suggestion.get("recipient_slot", -1)) == 0, "sugerencia del bot llega al compañero humano")
    _check(game.get_piece(Vector2i(4, 6)) == "peon_blanca", "sugerir no mueve la pieza")

    var mode := ModeScene.instantiate()
    root.add_child(mode)
    await process_frame
    var main_nav := mode.get_node_or_null("MainNavigation")
    _check(main_nav != null, "menú principal contiene navegación principal reutilizable")
    _check(main_nav != null and main_nav.get_node("Bar/Items").get_child_count() == 4, "navegación principal tiene 4 destinos")
    _check(main_nav != null and main_nav._active == "home", "Inicio queda seleccionado en el menú principal")
    mode.queue_free()

    var account := AccountScene.instantiate()
    root.add_child(account)
    await process_frame
    _check(account.page == "profile", "Perfil abre como pantalla principal")
    _check(account.history_action != null and account.settings_action != null, "Perfil expone accesos directos a Historial y Ajustes")
    account.queue_free()

    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = GameState.MODE_VS_BOT
        app.selected_bot_id = "mateo"
        app.selected_bot_elo = 400
    var game_scene := GameScene.instantiate()
    root.add_child(game_scene)
    await process_frame
    await process_frame
    _check(game_scene.game != null, "escena de partida inicializa estado")
    _check(game_scene.board_view != null, "tablero inicializa")
    game_scene.game.current_slot = 1
    var bot_moves_before: int = game_scene.game.move_history.size()
    await create_timer(0.60).timeout
    _check(game_scene.game.move_history.size() == bot_moves_before, "Mateo no mueve al instante")
    await create_timer(2.60).timeout
    _check(game_scene.game.move_history.size() > bot_moves_before, "Mateo mueve despues de pensar")
    game_scene.game.current_slot = 0
    var before: String = game_scene.game.get_piece(Vector2i(4, 6))
    game_scene._on_board_square(Vector2i(4, 6))
    _check(game_scene.board_view.selected == Vector2i(4, 6), "primer toque selecciona e2 sin segundo toque")
    game_scene._on_board_square(Vector2i(4, 4))
    _check(game_scene.game.get_piece(Vector2i(4, 4)) == before and game_scene.game.get_piece(Vector2i(4, 6)) == "", "segundo toque mueve e2-e4 sin duplicar entrada")
    game_scene.queue_free()

    if app != null:
        app.selected_mode = GameState.MODE_2C2
        app.temporary_online_bots = true
    var coop_scene := GameScene.instantiate()
    root.add_child(coop_scene)
    await process_frame
    await process_frame
    coop_scene.game.current_slot = 2
    coop_scene.game.set_temporary_bot(2, "nora")
    _check(coop_scene.game.bot_prepare_suggestion(), "bot cooperativo prepara sugerencia")
    coop_scene.hud.refresh()
    _check(coop_scene.hud.get_node("MiniPanel").visible, "HUD muestra la sugerencia del bot")
    _check(not String(coop_scene.hud.get_node("MiniPanel/Title").text).strip_edges().is_empty() and String(coop_scene.hud.get_node("MiniPanel/Body").text).find("sugiere") >= 0, "HUD etiqueta la sugerencia del bot")
    coop_scene.queue_free()
    if app != null:
        app.temporary_online_bots = false

    print("V28 REFINAMIENTO: %d OK / %d FAIL" % [passed, failed])
    quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        print("[FAIL] " + label)
