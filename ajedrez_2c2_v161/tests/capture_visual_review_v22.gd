extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const MENU_SCENE := preload("res://scenes/mode_menu.tscn")
const GameState := preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
    await process_frame
    await _capture_game(Vector2(720, 1280), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v22_captures/portrait.png", false)
    await _capture_game(Vector2(360, 640), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v22_captures/small_portrait.png", false)
    await _capture_game(Vector2(1280, 720), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v22_captures/landscape.png", false)
    await _capture_game(Vector2(800, 480), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v22_captures/small_landscape.png", false)
    await _capture_game(Vector2(1280, 720), GameState.MODE_VS_BOT, "/mnt/data/visual_review_vsai.png", false)
    await _capture_menu(Vector2(720, 1280), "/mnt/data/visual_review_menu_portrait.png")
    await _capture_menu(Vector2(1280, 720), "/mnt/data/visual_review_menu_landscape.png")
    await _capture_game(Vector2(720, 1280), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v22_captures/emotes_portrait.png", true)
    await _capture_game(Vector2(1280, 720), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v22_captures/emotes_landscape.png", true)
    quit()

func _make_subviewport(vp: Vector2) -> SubViewport:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    get_root().add_child(sv)
    return sv

func _capture_game(vp: Vector2, mode: int, path: String, show_emotes: bool) -> void:
    var sv := _make_subviewport(vp)
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.selected_mode = mode
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    if show_emotes and mode != GameState.MODE_VS_BOT:
        game.hud._toggle_emotes()
    await process_frame
    await process_frame
    var image := sv.get_texture().get_image()
    if image:
        image.save_png(path)
    sv.queue_free()
    await process_frame

func _capture_menu(vp: Vector2, path: String) -> void:
    var sv := _make_subviewport(vp)
    var menu = MENU_SCENE.instantiate()
    sv.add_child(menu)
    await process_frame
    await process_frame
    var image := sv.get_texture().get_image()
    if image:
        image.save_png(path)
    sv.queue_free()
    await process_frame
