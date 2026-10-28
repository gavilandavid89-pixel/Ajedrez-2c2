extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameController := preload("res://ui/screens/game.gd")
const AppConfig := preload("res://core/services/app.gd")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    await _check_portrait_compact_suggestion()
    await _check_landscape_stack()
    await _check_icons_and_name()
    await _check_drag_handle()
    print("V61 SUGGESTION RESULT: %d OK / %d FAIL" % [passed, failed])
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

func _prepare_suggestion(game) -> void:
    game.game.reset_match(AppConfig.MODE_2C2, 10)
    game.hud.set_game(game.game)
    # Slot 2 (Compañero) sugiere a slot 0 (Tú), sin alterar las reglas: esto
    # solo prepara el estado para revisar el HUD de la sugerencia.
    game.game.suggestion = {
        "from": Vector2i(4, 6),
        "to": Vector2i(4, 3),
        "by_slot": 2,
        "recipient_slot": 0,
        "accepted": false,
        "questioned": false,
    }
    game.hud.refresh()
    await process_frame
    await process_frame

func _check_portrait_compact_suggestion() -> void:
    var pack = await _make_game(Vector2i(360, 640))
    var sv = pack[0]
    var game = pack[1]
    await _prepare_suggestion(game)
    var panel: Control = game.hud.get_node("MiniPanel")
    var board = game.board_view.board_rect
    var r := panel.get_global_rect()
    _check("portrait suggestion visible", panel.visible)
    _check("portrait suggestion does not overlap board", not r.intersects(board))
    _check("portrait suggestion is compact", r.size.y <= 52.0 and r.size.x <= 308.0)
    _check("portrait suggestion sits after board", r.position.y >= board.end.y)
    game.queue_free(); sv.queue_free(); await process_frame

func _check_landscape_stack() -> void:
    var pack = await _make_game(Vector2i(800, 480))
    var sv = pack[0]
    var game = pack[1]
    await _prepare_suggestion(game)
    var panel: Control = game.hud.get_node("MiniPanel")
    var chat: Control = game.hud.get_node("ChatPanel")
    var board = game.board_view.board_rect
    var player_side = game.hud.get_node("WhiteInfo")
    var r := panel.get_global_rect()
    _check("landscape suggestion does not overlap board", not r.intersects(board))
    _check("landscape suggestion below player", r.position.y >= player_side.position.y + player_side.size.y)
    game.hud._toggle_chat()
    await process_frame
    _check("landscape chat opens after suggestion closes", chat.visible and not panel.visible)
    _check("landscape chat is below player", chat.position.y >= player_side.position.y + player_side.size.y)
    _check("landscape chat does not overlap board", not chat.get_global_rect().intersects(board))
    game.queue_free(); sv.queue_free(); await process_frame

func _check_icons_and_name() -> void:
    var pack = await _make_game(Vector2i(360, 640))
    var sv = pack[0]
    var game = pack[1]
    await _prepare_suggestion(game)
    var panel: Control = game.hud.get_node("MiniPanel")
    _check("suggestion name is quoted", String(panel.get_node("Title").text).begins_with("\"") and String(panel.get_node("Title").text).ends_with("\""))
    _check("suggestion uses real companion name", String(panel.get_node("Title").text).contains("Compañero"))
    _check("suggestion text is compact", panel.get_node("Body").text == "sugiere e5")
    _check("cooldown hidden", not panel.get_node("Cooldown").visible)
    _check("review hint removed", not String(panel.get_node("Body").text).contains("revisa") and not String(panel.get_node("Body").text).contains("decidir"))
    var actions = panel.get_node("Actions").get_children()
    _check("exactly three suggestion actions", actions.size() == 3)
    var texts: Array[String] = []
    for child in actions:
        texts.append(String(child.text))
    _check("accept icon", texts[0] == "✅")
    _check("cancel icon", texts[1] == "❌")
    _check("question icon", texts[2] == "❔❔")
    game.queue_free(); sv.queue_free(); await process_frame

func _check_drag_handle() -> void:
    var pack = await _make_game(Vector2i(360, 640))
    var sv = pack[0]
    var game = pack[1]
    await _prepare_suggestion(game)
    var panel: Control = game.hud.get_node("MiniPanel")
    var title: Control = panel.get_node("Title")
    _check("companion name is drag handle", title.mouse_filter == Control.MOUSE_FILTER_STOP)
    _check("drag cursor is move", title.mouse_default_cursor_shape == Control.CURSOR_MOVE)
    var old_pos := panel.global_position
    game.hud._move_suggestion_panel(old_pos + Vector2(20.0, 14.0))
    _check("suggestion can be repositioned", panel.global_position != old_pos)
    _check("reposition stays inside viewport", panel.get_global_rect().position.x >= 0.0 and panel.get_global_rect().end.x <= 360.0 and panel.get_global_rect().position.y >= 0.0 and panel.get_global_rect().end.y <= 640.0)
    game.queue_free(); sv.queue_free(); await process_frame
