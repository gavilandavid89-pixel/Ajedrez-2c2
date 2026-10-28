extends SceneTree

func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(720, 1280))
    await process_frame
    var data := get_root().get_node_or_null("PlayerData")
    if data == null:
        push_error("PlayerData autoload missing")
        quit(2)
        return
    data.set_display_name("Eragon")
    data.history.clear()
    # Three recent entries so the home shows activity, history and a live daily streak.
    for spec in [
        {"id":"V91_HOME_1","outcome":"loss","winner_team":1},
        {"id":"V91_HOME_2","outcome":"loss","winner_team":1},
        {"id":"V91_HOME_3","outcome":"loss","winner_team":1}
    ]:
        data.record_noncompetitive_match({
            "match_id": String(spec["id"]), "mode": 2, "outcome": String(spec["outcome"]), "winner_team": int(spec["winner_team"]),
            "reason": "Jaque mate", "move_count": 6, "moves": [], "partner": "Alex",
            "opponents": ["Rival", "Nora"]
        })
    var main := preload("res://scenes/mode_menu.tscn").instantiate()
    root.add_child(main)
    await process_frame
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var image := get_root().get_viewport().get_texture().get_image()
    image.save_png("/mnt/data/aj2c2_work/v91/home_720x1280.png")
    main.queue_free()
    await process_frame
    quit(0)
