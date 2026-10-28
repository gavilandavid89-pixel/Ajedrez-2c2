extends SceneTree

const MENU_SCENE := preload("res://scenes/mode_menu.tscn")
const GAME_SCENE := preload("res://scenes/game.tscn")
const AppConfig := preload("res://core/services/app.gd")

func _initialize() -> void:
    var app = get_root().get_node_or_null("App")
    await _capture_game(Vector2i(360, 640), AppConfig.MODE_1C1, "/mnt/data/v58b_1c1_board_full_360x640.png")
    await _capture_game(Vector2i(360, 640), AppConfig.MODE_2C2, "/mnt/data/v58b_2c2_board_full_360x640.png")
    await _capture_game(Vector2i(390, 844), AppConfig.MODE_2C2, "/mnt/data/v58b_2c2_board_full_390x844.png")
    await _capture_game(Vector2i(800, 480), AppConfig.MODE_1C1, "/mnt/data/v58b_1c1_board_landscape_800x480.png")
    await _capture_menu(Vector2i(360, 640), "/mnt/data/v58b_menu_profile_icon_360x640.png")
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

func _capture_game(vp: Vector2i, mode: int, path: String) -> void:
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.selected_mode = mode
        app.selected_time_minutes = 10
    var sv := _make_viewport(vp)
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    # Reaplica el modo después de que el nodo hijo haya completado su _ready()
    # inicial para que la captura represente exactamente el modo solicitado.
    game.game.reset_match(mode, 10)
    game.hud.set_game(game.game)
    game.hud.refresh()
    await process_frame
    await process_frame
    await create_timer(0.20).timeout
    print("CAPTURE mode=", game.game.mode, " suggest=", game.hud.get_node("Bottom/Actions/Suggest").visible, " swap=", game.hud.get_node("Bottom/Actions/Swap").visible)
    await _save(sv, path)
    game.queue_free()
    sv.queue_free()
    await process_frame

func _capture_menu(vp: Vector2i, path: String) -> void:
    var sv := _make_viewport(vp)
    var menu = MENU_SCENE.instantiate()
    sv.add_child(menu)
    await process_frame
    await process_frame
    await _save(sv, path)
    menu.queue_free()
    sv.queue_free()
    await process_frame
