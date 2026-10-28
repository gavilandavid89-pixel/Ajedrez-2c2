extends SceneTree
const GAME_SCENE := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
    await process_frame
    await _capture(Vector2(360, 640), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v25_captures/portrait.png", false)
    await _capture(Vector2(800, 480), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v25_captures/landscape.png", false)
    await _capture(Vector2(1280, 720), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v25_captures/landscape_wide.png", false)
    await _capture(Vector2(800, 480), GameState.MODE_2C2, "/mnt/data/ajedrez_work/v25_captures/emotes_landscape.png", true)
    quit()

func _make_viewport(vp: Vector2) -> SubViewport:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    get_root().add_child(sv)
    return sv

func _capture(vp: Vector2, mode: int, path: String, show_emotes: bool) -> void:
    var sv := _make_viewport(vp)
    var game = GAME_SCENE.instantiate()
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.selected_mode = mode
    sv.add_child(game)
    await process_frame
    await process_frame
    if show_emotes:
        game.get_node("HUD")._toggle_emotes()
        await process_frame
    var image := sv.get_texture().get_image()
    image.save_png(path)
    sv.queue_free()
    await process_frame
