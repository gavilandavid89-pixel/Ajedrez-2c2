extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
    await process_frame
    await _capture(Vector2(720, 1280), "/mnt/data/v29_emote_animation_portrait.png")
    await _capture(Vector2(1280, 720), "/mnt/data/v29_emote_animation_landscape.png")
    quit()

func _capture(vp: Vector2, path: String) -> void:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    root.add_child(sv)
    var game = GAME_SCENE.instantiate()
    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = GameState.MODE_2C2
    sv.add_child(game)
    await process_frame
    await process_frame
    game.game.emote("bien")
    await process_frame
    await create_timer(0.22).timeout
    var image := sv.get_texture().get_image()
    if image:
        image.save_png(path)
    game.queue_free()
    sv.queue_free()
    await process_frame
