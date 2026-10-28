extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    get_root().size = Vector2i(844, 390)
    await process_frame
    await process_frame
    var game := load("res://scenes/game.tscn").instantiate() as Control
    root.add_child(game)
    await process_frame
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("/mnt/data/v145_game_landscape.png")
    quit(0)
