extends SceneTree
const AccountScene := preload("res://scenes/account_hub.tscn")
const GameState := preload("res://domain/chess/game_state.gd")
func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    var data = get_root().get_node_or_null("PlayerData")
    if data == null:
        quit(1); return
    await process_frame; await process_frame
    data.history.clear()
    var game := GameState.new()
    game.reset_match(GameState.MODE_1C1_LOCAL)
    game.attempt_move(Vector2i(4,6), Vector2i(4,4))
    game.attempt_move(Vector2i(4,1), Vector2i(4,3))
    game.attempt_move(Vector2i(6,7), Vector2i(5,5))
    game.attempt_move(Vector2i(1,0), Vector2i(2,2))
    data.record_noncompetitive_match({"match_id":"V40_CAPTURE","mode":GameState.MODE_1C1_LOCAL,"outcome":"win","move_count":4,"moves":game.replay_moves(),"replay_data":game.replay_data(),"rating_delta":15,"rating_after":1015,"cup_delta":1,"cups_after":11,"analysis_viewed":false})
    game.free()
    var scene := AccountScene.instantiate()
    root.add_child(scene)
    await process_frame; await process_frame; await process_frame
    scene.selected_history_index = data.history.size() - 1
    scene.page = "analysis"; scene._refresh()
    await process_frame; await process_frame; await process_frame
    await RenderingServer.frame_post_draw
    var image := get_root().get_viewport().get_texture().get_image()
    image.save_png("/mnt/data/v40_analysis_portrait.png")
    scene.queue_free(); await process_frame
    data.history.clear(); data.save_data(); quit(0)
