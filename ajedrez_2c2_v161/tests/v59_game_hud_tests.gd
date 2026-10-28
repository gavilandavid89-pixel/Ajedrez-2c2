extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameController := preload("res://ui/screens/game.gd")
const AppConfig := preload("res://core/services/app.gd")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    await _test_mode(AppConfig.MODE_1C1, "1c1")
    await _test_mode(AppConfig.MODE_2C2, "2c2")
    await _test_mode(AppConfig.MODE_VS_BOT, "bot")
    _test("portrait board uses almost full width with safe 8px side margins", LayoutMetrics.board_rect(Vector2(360, 640)).size.x >= 320.0 and LayoutMetrics.board_rect(Vector2(360, 640)).size.x <= 344.0)
    _test("portrait board remains square", is_equal_approx(LayoutMetrics.board_rect(Vector2(390, 844)).size.x, LayoutMetrics.board_rect(Vector2(390, 844)).size.y))
    print("V59 UI RESULT: %d OK / %d FAIL" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _test_mode(mode: int, label: String) -> void:
    var sv := SubViewport.new()
    sv.size = Vector2i(360, 640)
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    get_root().add_child(sv)
    var game: GameController = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    game.game.reset_match(mode, 10)
    game.hud.set_game(game.game)
    game.hud.refresh()
    await process_frame
    var is_2c2 := mode == AppConfig.MODE_2C2
    var social := mode != AppConfig.MODE_VS_BOT
    _test(label + " suggest mode visibility", game.hud.get_node("Bottom/Actions/Suggest").visible == is_2c2)
    _test(label + " swap visibility", game.hud.get_node("Bottom/Actions/Swap").visible == is_2c2)
    _test(label + " chat visibility", game.hud.get_node("Bottom/Chat").visible == social)
    _test(label + " reaction visibility", game.hud.get_node("Bottom/Emotes").visible == social)
    _test(label + " action menu visibility", game.hud.get_node("Bottom/GameMenu").visible)
    game.hud._toggle_game_menu()
    await process_frame
    _test(label + " action menu opens", game.hud.get_node("GameActionMenu").visible)
    _test(label + " action menu only has two choices", game.hud.get_node("GameActionMenu/Panel/Buttons").get_child_count() == 2)
    game.hud._close_game_menu()
    if social:
        game.hud._toggle_chat()
        await process_frame
        _test(label + " chat opens", game.hud.get_node("ChatPanel").visible)
        game.hud._close_chat()
    game.queue_free()
    sv.queue_free()
    await process_frame

func _test(label: String, ok: bool) -> void:
    if ok:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        print("[FAIL] ", label)
