extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const AppConfig := preload("res://core/services/app.gd")

func _initialize() -> void:
    await _capture_portrait()
    await _capture_portrait_dragged()
    await _capture_landscape()
    quit()

func _new_game(vp: Vector2i):
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
    return [sv, game]

func _save(sv: SubViewport, path: String) -> void:
    await create_timer(0.20).timeout
    var image := sv.get_texture().get_image()
    if image != null:
        image.save_png(path)

func _capture_portrait() -> void:
    var pack = await _new_game(Vector2i(360, 640))
    await _save(pack[0], "/mnt/data/v61_suggestion_portrait_360x640.png")
    pack[1].queue_free(); pack[0].queue_free(); await process_frame

func _capture_portrait_dragged() -> void:
    var pack = await _new_game(Vector2i(360, 640))
    var game = pack[1]
    game.hud._move_suggestion_panel(Vector2(8.0, 82.0))
    await process_frame
    await _save(pack[0], "/mnt/data/v61_suggestion_dragged_360x640.png")
    game.queue_free(); pack[0].queue_free(); await process_frame

func _capture_landscape() -> void:
    var pack = await _new_game(Vector2i(800, 480))
    await _save(pack[0], "/mnt/data/v61_suggestion_landscape_800x480.png")
    pack[1].queue_free(); pack[0].queue_free(); await process_frame
