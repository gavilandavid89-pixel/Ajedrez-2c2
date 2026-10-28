extends SceneTree

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_previews/v146/portrait"))
    root.size = Vector2i(390, 844)
    await process_frame
    await process_frame
    var game := load("res://scenes/game.tscn").instantiate() as Control
    root.add_child(game)
    await process_frame
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var err := root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://qa_previews/v146/portrait/game.png"))
    print("V146 GAME PORTRAIT CAPTURE: ", err)
    quit(0 if err == OK else 1)
