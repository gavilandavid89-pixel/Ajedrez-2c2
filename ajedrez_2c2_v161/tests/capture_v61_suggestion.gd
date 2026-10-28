extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const AppConfig := preload("res://core/services/app.gd")

func _initialize() -> void:
    await _capture(Vector2i(360, 640), "/mnt/data/v61_suggestion_portrait_360x640.png")
    await _capture(Vector2i(800, 480), "/mnt/data/v61_suggestion_landscape_800x480.png")
    quit()

func _capture(vp: Vector2i, path: String) -> void:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    root.add_child(sv)
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    game.game.reset_match(AppConfig.MODE_2C2, 10)
    game.hud.set_game(game.game)
    game.game.suggestion = {
        "from": Vector2i(4, 6),
        "to": Vector2i(4, 3),
        "by_slot": 2,
        "recipient_slot": 0,
        "accepted": false,
        "questioned": false,
    }
    game.hud.refresh()
    await process_frame
    await process_frame
    await create_timer(0.30).timeout
    var image := sv.get_texture().get_image()
    if image != null:
        image.save_png(path)
    game.queue_free()
    sv.queue_free()
    await process_frame
