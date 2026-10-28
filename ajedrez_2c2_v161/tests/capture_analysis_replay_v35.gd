extends SceneTree

const AccountScene := preload("res://scenes/account_hub.tscn")
const GameState := preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
    for vp in [Vector2i(390, 844), Vector2i(1280, 720)]:
        await _capture(vp, "portrait" if vp.y > vp.x else "landscape")
    quit(0)

func _capture(vp: Vector2i, suffix: String) -> void:
    DisplayServer.window_set_size(vp)
    var data = get_root().get_node_or_null("PlayerData")
    if data == null:
        push_error("PlayerData no disponible")
        return
    await process_frame
    data.history.clear()
    var game := GameState.new()
    game.reset_match(GameState.MODE_1C1_LOCAL)
    game.attempt_move(Vector2i(4,6), Vector2i(4,4))
    game.attempt_move(Vector2i(4,1), Vector2i(4,3))
    game.attempt_move(Vector2i(6,7), Vector2i(5,5))
    game.attempt_move(Vector2i(1,0), Vector2i(2,2))
    var replay := game.replay_data()
    data.record_noncompetitive_match({
        "match_id": "V35_CAPTURE_%s" % suffix,
        "mode": GameState.MODE_1C1_LOCAL,
        "outcome": "win",
        "move_count": 4,
        "moves": game.replay_moves(),
        "replay_data": replay,
        "rating_delta": 15,
        "rating_after": 1015,
        "cup_delta": 1,
        "cups_after": 11,
        "analysis_viewed": false,
    })
    game.free()
    var scene := AccountScene.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    scene.page = "history"
    scene._refresh()
    await process_frame
    await process_frame
    await _save("/mnt/data/v35_history_%s.png" % suffix)
    scene.selected_history_index = scene._data().history.size() - 1
    scene.page = "replay"
    scene._refresh()
    await process_frame
    await process_frame
    await _save("/mnt/data/v35_replay_%s.png" % suffix)
    scene.page = "analysis"
    scene._refresh()
    await process_frame
    await process_frame
    await _save("/mnt/data/v35_analysis_%s.png" % suffix)
    scene.queue_free()
    await process_frame
    data.history.clear()
    data.save_data()

func _save(path: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_root().get_viewport().get_texture().get_image()
    if image != null:
        image.save_png(path)
