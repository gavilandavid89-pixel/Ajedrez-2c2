extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const ACCOUNT_SCENE := preload("res://scenes/account_hub.tscn")
const AppConfig := preload("res://core/services/app.gd")

func _initialize() -> void:
    await process_frame
    var player = get_root().get_node_or_null("PlayerData")
    if player == null:
        push_error("PlayerData no disponible")
        quit(1)
        return

    player.appearance["board_theme"] = "classic"
    player.appearance["piece_set"] = "classic"
    await _capture_game("/mnt/data/v95_classic_board.png")

    player.appearance["board_theme"] = "graphite_gold"
    player.appearance["piece_set"] = "graphite_gold"
    await _capture_game("/mnt/data/v95_graphite_gold_board.png")
    await _capture_account("/mnt/data/v95_graphite_gold_account.png")

    # Leave persistent runtime state at the real default so this capture never changes the user's default.
    player.appearance["board_theme"] = "classic"
    player.appearance["piece_set"] = "classic"
    quit(0)

func _make_viewport(vp: Vector2i) -> SubViewport:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    get_root().add_child(sv)
    return sv

func _save(sv: SubViewport, path: String) -> void:
    await process_frame
    await process_frame
    var image := sv.get_texture().get_image()
    if image != null:
        image.save_png(path)

func _capture_game(path: String) -> void:
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.selected_mode = AppConfig.MODE_1C1
        app.selected_time_minutes = 10
    var sv := _make_viewport(Vector2i(390, 844))
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    game.game.reset_match(AppConfig.MODE_1C1, 10)
    game.hud.set_game(game.game)
    game.hud.refresh()
    await process_frame
    await process_frame
    await create_timer(0.15).timeout
    await _save(sv, path)
    game.queue_free()
    sv.queue_free()
    await process_frame

func _capture_account(path: String) -> void:
    var sv := _make_viewport(Vector2i(390, 844))
    var account = ACCOUNT_SCENE.instantiate()
    sv.add_child(account)
    await process_frame
    await process_frame
    account.page = "reactions"
    account._refresh()
    await process_frame
    await process_frame
    await _save(sv, path)
    account.queue_free()
    sv.queue_free()
    await process_frame
