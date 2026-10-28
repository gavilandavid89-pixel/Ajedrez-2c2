extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const AppConfig := preload("res://core/services/app.gd")

func _initialize() -> void:
    await _capture(Vector2i(360, 640), AppConfig.MODE_2C2, "/mnt/data/v60_2c2_suggestion_mode_360x640.png", "suggest_mode")
    await _capture(Vector2i(360, 640), AppConfig.MODE_2C2, "/mnt/data/v60_2c2_suggestion_menu_360x640.png", "suggest_menu")
    await _capture(Vector2i(360, 640), AppConfig.MODE_2C2, "/mnt/data/v60_action_menu_360x640.png", "actions")
    await _capture(Vector2i(800, 480), AppConfig.MODE_1C1, "/mnt/data/v60_1c1_chat_landscape_800x480.png", "chat_landscape")
    quit()

func _make_viewport(vp: Vector2i) -> SubViewport:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    root.add_child(sv)
    return sv

func _save(sv: SubViewport, path: String) -> void:
    await process_frame
    await process_frame
    var image := sv.get_texture().get_image()
    if image != null:
        image.save_png(path)

func _capture(vp: Vector2i, mode: int, path: String, state: String) -> void:
    var sv := _make_viewport(vp)
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    game.game.reset_match(mode, 10)
    game.hud.set_game(game.game)
    game.hud.refresh()
    await process_frame
    await process_frame
    match state:
        "suggest_mode":
            game.hud.set_suggestion_mode(true)
            game.hud.get_node("Bottom/Actions/Suggest").grab_focus()
        "suggest_menu":
            game.hud._show_mini_panel(
                "Sugerencia del compañero",
                "Tu compañero propone e4. Revisa la idea antes de mover.",
                "Cooldown · 2s",
                [
                    ["Aceptar", "accept_suggestion", "#4F6B56"],
                    ["Rechazar", "reject_suggestion", "#B64B3E"],
                    ["Cuestionar", "challenge", "#8D6A36"],
                ]
            )
            game.hud.get_node("MiniPanel").set_meta("manual_open", true)
        "actions":
            game.hud._toggle_game_menu()
        "chat_landscape":
            game.hud._toggle_chat()
    game.hud._queue_layout_refresh()
    await process_frame
    await process_frame
    await create_timer(0.20).timeout
    await _save(sv, path)
    game.queue_free(); sv.queue_free(); await process_frame
