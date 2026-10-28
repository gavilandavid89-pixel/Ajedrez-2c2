extends SceneTree

const MENU_SCENE := preload("res://scenes/mode_menu.tscn")
const SETUP_SCENE := preload("res://scenes/online_setup.tscn")
const MATCHMAKING_SCENE := preload("res://scenes/online_matchmaking.tscn")
const GAME_SCENE := preload("res://scenes/game.tscn")
const AppConfig := preload("res://core/services/app.gd")

const VP := Vector2i(360, 640)

func _initialize() -> void:
    var data = get_root().get_node_or_null("PlayerData")
    var app = get_root().get_node_or_null("App")
    if data != null:
        data.individual_1c1["rating"] = 1124
        data.individual_1c1["cups"] = 76
        data.individual_1c1["wins"] = 5
        data.individual_1c1["losses"] = 2
        data.individual_1c1["draws"] = 1
        data.individual_1c1["streak"] = 3
    if app != null:
        app.selected_mode = AppConfig.MODE_1C1
        app.selected_time_minutes = 10
        app.online_entry = "random"
        app.temporary_online_bots = false

    await _capture_menu(data)
    await _capture_setup(app)
    await _capture_matchmaking(app)
    await _capture_game(app)
    await _capture_result(app)
    quit()

func _make_viewport() -> SubViewport:
    var sv := SubViewport.new()
    sv.size = VP
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

func _capture_menu(data) -> void:
    var sv := _make_viewport()
    var menu = MENU_SCENE.instantiate()
    sv.add_child(menu)
    await process_frame
    menu._refresh_menu_state()
    await _save(sv, "/mnt/data/v57_menu_360x640.png")
    sv.queue_free()
    await process_frame

func _capture_setup(app) -> void:
    var sv := _make_viewport()
    var setup = SETUP_SCENE.instantiate()
    sv.add_child(setup)
    await process_frame
    setup.open_for_mode(AppConfig.MODE_1C1)
    await process_frame
    await _save(sv, "/mnt/data/v57_1c1_setup_360x640.png")
    sv.queue_free()
    await process_frame

func _capture_matchmaking(app) -> void:
    if app != null:
        app.selected_mode = AppConfig.MODE_1C1
        app.selected_time_minutes = 10
        app.online_entry = "random"
        app.temporary_online_bots = false
    var sv := _make_viewport()
    var screen = MATCHMAKING_SCENE.instantiate()
    sv.add_child(screen)
    await process_frame
    await create_timer(0.30).timeout
    await _save(sv, "/mnt/data/v57_matchmaking_360x640.png")
    sv.queue_free()
    await process_frame

func _capture_game(app) -> void:
    if app != null:
        app.selected_mode = AppConfig.MODE_1C1
        app.selected_time_minutes = 10
    var sv := _make_viewport()
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    await _save(sv, "/mnt/data/v57_1c1_game_360x640.png")
    sv.queue_free()
    await process_frame

func _capture_result(app) -> void:
    if app != null:
        app.selected_mode = AppConfig.MODE_1C1
        app.selected_time_minutes = 10
    var sv := _make_viewport()
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    game.game.running = false
    game.game.winner_team = game.game.TEAM_WHITE
    game.game.winner_reason = "checkmate"
    game.hud.set_result_entry({
        "competitive": true,
        "rating_delta": 18,
        "cup_delta": 10,
        "rating_after": 1142,
        "cups_after": 86,
        "league_after": "Bronce",
        "streak_after": 4,
    })
    game.hud.refresh()
    await process_frame
    await create_timer(0.32).timeout
    await _save(sv, "/mnt/data/v57_1c1_result_360x640.png")
    sv.queue_free()
    await process_frame
