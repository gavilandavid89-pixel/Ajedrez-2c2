extends SceneTree
func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(390,844))
    await process_frame
    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = 0
        app.selected_bot_id = "nora"
        app.selected_bot_elo = 700
    var game_scene = load("res://scenes/game.tscn").instantiate()
    root.add_child(game_scene)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image := get_root().get_texture().get_image()
    image.save_png("/mnt/data/v49_game_mobile.png")
    quit(0)
