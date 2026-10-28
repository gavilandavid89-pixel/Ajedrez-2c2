extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameController := preload("res://ui/screens/game.gd")
const AppConfig := preload("res://core/services/app.gd")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    await _check_action_menu()
    await _check_chat_toggle_and_landscape()
    await _check_suggestion_menu_fits()
    await _check_layout_coalescing()
    await _check_social_actions_during_bot_turn()
    print("V60 UI RESULT: %d OK / %d FAIL" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _check(label: String, ok: bool) -> void:
    if ok:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        push_error("[FAIL] " + label)

func _make_game(vp: Vector2i):
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
    get_root().add_child(sv)
    var game: GameController = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    return [sv, game]

func _check_action_menu() -> void:
    var pack = await _make_game(Vector2i(360, 640))
    var sv = pack[0]
    var game = pack[1]
    game.game.reset_match(AppConfig.MODE_1C1, 10)
    game.hud.set_game(game.game)
    game.hud._toggle_game_menu()
    await process_frame
    var menu = game.hud.get_node("GameActionMenu")
    _check("action menu visible", menu.visible)
    _check("action menu has exactly two buttons", menu.get_node("Panel/Buttons").get_child_count() == 2)
    _check("action menu title removed", menu.get_node_or_null("Panel/Title") == null)
    _check("action menu close button removed", menu.get_node_or_null("Panel/Close") == null)
    _check("action menu fits viewport", menu.get_node("Panel").get_global_rect().end.x <= 360.0 and menu.get_node("Panel").get_global_rect().end.y <= 640.0)
    game.queue_free(); sv.queue_free(); await process_frame

func _check_chat_toggle_and_landscape() -> void:
    var pack = await _make_game(Vector2i(800, 480))
    var sv = pack[0]
    var game = pack[1]
    game.game.reset_match(AppConfig.MODE_1C1, 10)
    game.hud.set_game(game.game)
    game.hud._toggle_chat()
    await process_frame
    var chat = game.hud.get_node("ChatPanel")
    var player_side = game.hud.get_node("WhiteInfo")
    _check("landscape chat opens", chat.visible)
    _check("landscape chat is below player", chat.position.y > player_side.position.y + player_side.size.y)
    _check("landscape chat does not overlap board", not chat.get_global_rect().intersects(game.board_view.board_rect))
    game.hud._toggle_chat()
    await process_frame
    _check("same chat icon closes chat", not chat.visible)
    game.queue_free(); sv.queue_free(); await process_frame


func _check_suggestion_menu_fits() -> void:
    var pack = await _make_game(Vector2i(360, 640))
    var sv = pack[0]
    var game = pack[1]
    game.game.reset_match(AppConfig.MODE_2C2, 10)
    game.hud.set_game(game.game)
    game.hud._show_mini_panel(
        "Sugerencia del compañero",
        "Tu compañero propone e4. Revisa la idea antes de mover.",
        "Cooldown · 2s",
        [
            ["Aceptar", "accept_suggestion", "#4F6B56"],
            ["Rechazar", "reject_suggestion", "#B64B3E"],
            ["Cuestionar", "challenge", "#8D6A36"],
        ]
    )
    game.hud.get_node("MiniPanel").set_meta("manual_open", true)
    await process_frame; await process_frame
    var panel: Control = game.hud.get_node("MiniPanel")
    var r := panel.get_global_rect()
    _check("suggestion menu fits mobile viewport", r.position.x >= 0.0 and r.end.x <= 360.0 and r.position.y >= 0.0 and r.end.y <= 640.0)
    var actions = panel.get_node("Actions")
    for child in actions.get_children():
        if child is Control:
            var cr: Rect2 = child.get_global_rect()
            _check("suggestion action stays inside menu", cr.position.x >= r.position.x and cr.end.x <= r.end.x + 1.0)
    game.queue_free(); sv.queue_free(); await process_frame

func _check_layout_coalescing() -> void:
    var pack = await _make_game(Vector2i(360, 640))
    var sv = pack[0]
    var game = pack[1]
    var hud = game.hud
    hud._queue_layout_refresh()
    hud._queue_layout_refresh()
    _check("layout refresh coalesces repeated requests", hud._layout_queued)
    await process_frame
    _check("layout queue clears after applying", not hud._layout_queued and not hud._layout_dirty)
    game.queue_free(); sv.queue_free(); await process_frame

func _check_social_actions_during_bot_turn() -> void:
    var pack = await _make_game(Vector2i(360, 640))
    var sv = pack[0]
    var controller = pack[1]
    controller.game.reset_match(AppConfig.MODE_2C2, 10)
    controller.game.current_slot = 1
    controller.game.bot_slots[1] = "test_bot"
    controller.hud.set_game(controller.game)
    controller.hud.refresh()
    var chat_button: Button = controller.hud.get_node("Bottom/Chat")
    var emote_button: Button = controller.hud.get_node("Bottom/Emotes")
    var suggest_button: Button = controller.hud.action_row.get_node("Suggest")
    var swap_button: Button = controller.hud.action_row.get_node("Swap")
    _check("social buttons remain enabled while a 2c2 bot is thinking", controller.game.is_bot_turn() and not chat_button.disabled and not emote_button.disabled and not suggest_button.disabled and not swap_button.disabled)
    controller.hud._toggle_chat()
    controller.hud.refresh()
    _check("chat stays open through a bot turn refresh", controller.hud.get_node("ChatPanel").visible)
    controller.hud._close_chat()
    controller.hud._toggle_emotes()
    controller.hud.refresh()
    _check("reaction picker stays available through a bot turn refresh", controller.hud.get_node("EmotePicker").visible)
    controller.queue_free(); sv.queue_free(); await process_frame
