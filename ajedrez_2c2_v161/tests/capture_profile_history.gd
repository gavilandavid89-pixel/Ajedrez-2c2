extends SceneTree

const PLAYER_DATA := preload("res://domain/player/player_data.gd")

func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(360, 640))
    var data = get_root().get_node_or_null("PlayerData")
    if data == null:
        data = PLAYER_DATA.new()
        data.name = "PlayerData"
        get_root().add_child(data)
    data.set_display_name("Eragon")
    data.current_partner = {"id": "USR_PARTNER01", "name": "Alex", "pair_key": data.pair_key("Alex", "USR_PARTNER01")}
    var pair_key_value := String(data.current_partner["pair_key"])
    data.ensure_pair_record(pair_key_value, "Alex", "USR_PARTNER01")
    data.pair_records[pair_key_value]["rating"] = 1342
    data.pair_records[pair_key_value]["best_rating"] = 1487
    data.pair_records[pair_key_value]["cups"] = 986
    data.pair_records[pair_key_value]["games"] = 81
    data.pair_records[pair_key_value]["wins"] = 57
    data.history.clear()
    data.record_noncompetitive_match({
        "match_id": "CAPTURE_MATCH_1",
        "mode": 2,
        "outcome": "win",
        "winner_team": 0,
        "reason": "Jaque mate",
        "move_count": 6,
        "moves": [
            {"actor": "Eragon", "from": "e2", "to": "e4", "captured": "", "castle": false, "en_passant": false, "promotion": false},
            {"actor": "Nora", "from": "e7", "to": "e5", "captured": "", "castle": false, "en_passant": false, "promotion": false},
            {"actor": "Eragon", "from": "g1", "to": "f3", "captured": "", "castle": false, "en_passant": false, "promotion": false},
            {"actor": "Nora", "from": "b8", "to": "c6", "captured": "", "castle": false, "en_passant": false, "promotion": false},
            {"actor": "Eragon", "from": "f1", "to": "b5", "captured": "", "castle": false, "en_passant": false, "promotion": false},
            {"actor": "Nora", "from": "a7", "to": "a6", "captured": "", "castle": false, "en_passant": false, "promotion": false}
        ],
        "partner": "Alex",
        "opponents": ["Nora", "Mateo"]
    })
    data.save_data()

    change_scene_to_file("res://scenes/mode_menu.tscn")
    await process_frame
    await process_frame
    await process_frame
    await _capture("/mnt/data/ajedrez_work/current_capture_menu.png")

    change_scene_to_file("res://scenes/account_hub.tscn")
    await process_frame
    await process_frame
    await process_frame
    await _capture("/mnt/data/ajedrez_work/current_capture_profile.png")

    var account = current_scene
    account.page = "history"
    account._refresh()
    await process_frame
    await process_frame
    await _capture("/mnt/data/ajedrez_work/current_capture_history.png")

    account.selected_history_index = 0
    account.page = "analysis"
    account._refresh()
    await process_frame
    await process_frame
    await _capture("/mnt/data/ajedrez_work/current_capture_analysis.png")
    quit(0)

func _capture(path: String) -> void:
    await RenderingServer.frame_post_draw
    var image := get_root().get_viewport().get_texture().get_image()
    image.save_png(path)
