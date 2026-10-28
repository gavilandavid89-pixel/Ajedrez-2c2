extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const AppConfig := preload("res://core/services/app.gd")

func _initialize() -> void:
    await _capture_game(Vector2i(360, 640), AppConfig.MODE_1C1, "/mnt/data/v59_1c1_clean_360x640.png", false, false)
    await _capture_game(Vector2i(360, 640), AppConfig.MODE_1C1, "/mnt/data/v59_1c1_action_menu_360x640.png", true, false)
    await _capture_game(Vector2i(360, 640), AppConfig.MODE_1C1, "/mnt/data/v59_1c1_chat_360x640.png", false, true)
    await _capture_game(Vector2i(360, 640), AppConfig.MODE_2C2, "/mnt/data/v59_2c2_clean_360x640.png", false, false)
    await _capture_game(Vector2i(800, 480), AppConfig.MODE_1C1, "/mnt/data/v59_1c1_clean_800x480.png", false, false)
    await _capture_game(Vector2i(800, 480), AppConfig.MODE_2C2, "/mnt/data/v59_2c2_clean_800x480.png", false, false)
    quit()

func _make_viewport(vp: Vector2i) -> SubViewport:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    get_root().add_child(sv)
    return sv

func _save(sv: SubViewport, path: String) -> void:
    await process_frame
    await process_frame
    var image := sv.get_texture().get_image()
    if image != null:
        image.save_png(path)

func _capture_game(vp: Vector2i, mode: int, path: String, open_actions: bool, open_chat: bool) -> void:
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
    if open_actions:
        game.hud._toggle_game_menu()
    elif open_chat:
        game.hud._toggle_chat()
    await process_frame
    await process_frame
    await create_timer(0.25).timeout
    await _save(sv, path)
    game.queue_free()
    sv.queue_free()
    await process_frame
