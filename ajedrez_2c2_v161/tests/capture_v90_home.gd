extends SceneTree

const PLAYER_DATA := preload("res://domain/player/player_data.gd")

func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(720, 1280))
    await process_frame
    var data = get_root().get_node_or_null("PlayerData")
    if data == null:
        push_error("PlayerData autoload missing")
        quit(2)
        return
    data.set_display_name("Eragon")
    data.history.clear()
    data.record_noncompetitive_match({
        "match_id": "CAPTURE_HOME_1", "mode": 2, "outcome": "loss", "winner_team": 1,
        "reason": "Jaque mate", "move_count": 6, "moves": [], "partner": "Alex",
        "opponents": ["Rival", "Nora"]
    })
    data.record_noncompetitive_match({
        "match_id": "CAPTURE_HOME_2", "mode": 2, "outcome": "win", "winner_team": 0,
        "reason": "Jaque mate", "move_count": 8, "moves": [], "partner": "Alex",
        "opponents": ["Rival", "Nora"]
    })
    data.record_noncompetitive_match({
        "match_id": "CAPTURE_HOME_3", "mode": 2, "outcome": "loss", "winner_team": 1,
        "reason": "Jaque mate", "move_count": 7, "moves": [], "partner": "Alex",
        "opponents": ["Rival", "Nora"]
    })
    change_scene_to_file("res://scenes/mode_menu.tscn")
    await process_frame
    await process_frame
    await process_frame
    await _capture("/mnt/data/aj2c2_work/v90/home_final.png")
    current_scene.queue_free()
    await process_frame
    quit(0)

func _capture(path: String) -> void:
    await RenderingServer.frame_post_draw
    var texture := get_root().get_viewport().get_texture()
    if texture == null:
        push_error("capture viewport texture is null")
        quit(2)
        return
    texture.get_image().save_png(path)
