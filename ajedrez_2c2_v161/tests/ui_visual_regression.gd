extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const MENU_SCENE := preload("res://scenes/mode_menu.tscn")
const LOADING_SCENE := preload("res://scenes/loading.tscn")
const GameState := preload("res://domain/chess/game_state.gd")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var failures: Array[String] = []
var checks := 0

func _initialize() -> void:
    await process_frame

    var game_viewports := [
        Vector2(360, 640),
        Vector2(390, 844),
        Vector2(412, 915),
        Vector2(720, 1280),
        Vector2(800, 480),
        Vector2(1024, 600),
        Vector2(1280, 720),
        Vector2(1920, 1080),
    ]
    var modes := [
        GameState.MODE_2C2,
        GameState.MODE_1C1,
        GameState.MODE_VS_BOT,
        GameState.MODE_1C1_LOCAL,
    ]

    for vp in game_viewports:
        for mode in modes:
            await _test_game_viewport(vp, mode)

    await _test_mode_menu(Vector2(720, 1280))
    await _test_mode_menu(Vector2(1280, 720))
    await _test_loading(Vector2(720, 1280))
    await _test_loading(Vector2(1280, 720))

    print("VISUAL RESPONSIVE AUDIT: %d OK / %d FALLARON" % [checks - failures.size(), failures.size()])
    for failure in failures:
        print("[FAIL] ", failure)
    quit(1 if not failures.is_empty() else 0)

func _make_subviewport(vp: Vector2) -> SubViewport:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    get_root().add_child(sv)
    return sv

func _test_game_viewport(vp: Vector2, mode: int) -> void:
    var sv := _make_subviewport(vp)
    var root_game = GAME_SCENE.instantiate()
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.selected_mode = mode
    sv.add_child(root_game)
    await process_frame
    await process_frame
    root_game.hud.refresh()
    await process_frame

    var hud: Control = root_game.hud
    var br: Rect2 = LayoutMetrics.board_rect(vp)
    var calculated: Rect2 = root_game.board_view.layout_for_viewport(vp)
    _check(is_equal_approx(calculated.position.x, br.position.x), "board x %s mode %s" % [vp, mode])
    _check(is_equal_approx(calculated.position.y, br.position.y), "board y %s mode %s" % [vp, mode])
    _check(is_equal_approx(calculated.size.x, br.size.x), "board size %s mode %s" % [vp, mode])
    _check(_inside(calculated, Rect2(Vector2.ZERO, vp)), "board bounds %s mode %s" % [vp, mode])

    var bottom := _root_rect(hud.get_node("Bottom"))
    var black := _root_rect(hud.get_node("BlackInfo"))
    var white := _root_rect(hud.get_node("WhiteInfo"))
    _check(_inside(bottom, Rect2(Vector2.ZERO, vp)), "bottom bounds %s mode %s" % [vp, mode])
    _check(_inside(black, Rect2(Vector2.ZERO, vp)), "black panel bounds %s mode %s" % [vp, mode])
    _check(_inside(white, Rect2(Vector2.ZERO, vp)), "white panel bounds %s mode %s" % [vp, mode])

    if vp.y >= vp.x:
        _check(is_equal_approx(br.position.x, 0.0), "portrait board starts at screen edge %s mode %s" % [vp, mode])
        _check(is_equal_approx(br.size.x, vp.x) and is_equal_approx(br.size.y, vp.x), "portrait board fills width square %s mode %s" % [vp, mode])
        _check(black.end.y <= br.position.y + 0.1, "portrait black before board %s mode %s" % [vp, mode])
        _check(not hud.get_node("Turn").visible and not hud.get_node("Status").visible, "portrait turn/status labels removed %s mode %s" % [vp, mode])
        _check(white.position.y >= br.end.y - 0.1, "portrait white after board %s mode %s" % [vp, mode])
        _check(bottom.position.y >= white.end.y - 0.1, "portrait bottom after white player %s mode %s" % [vp, mode])
    else:
        var side_h: float = LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_2C2 if mode == GameState.MODE_2C2 else LayoutMetrics.TEAM_HEADER_LANDSCAPE_HEIGHT_1C1
        var black_side: Rect2 = LayoutMetrics.landscape_side_rect(vp, false, side_h)
        var white_side: Rect2 = LayoutMetrics.landscape_side_rect(vp, true, side_h)
        _check(_inside(black_side, Rect2(Vector2.ZERO, vp)), "landscape black side %s mode %s" % [vp, mode])
        _check(_inside(white_side, Rect2(Vector2.ZERO, vp)), "landscape white side %s mode %s" % [vp, mode])
        _check(br.position.x >= black_side.end.x + 1.0, "landscape board clears left panel %s mode %s" % [vp, mode])
        _check(br.end.x <= white_side.position.x - 1.0, "landscape board clears right panel %s mode %s" % [vp, mode])
        _check(bottom.position.y >= br.end.y + 9.0, "landscape bottom after board %s mode %s" % [vp, mode])

    _check(not hud.get_node("Top").visible, "game top mode bar removed %s mode %s" % [vp, mode])
    _check(not hud.get_node("Top/Mode").visible and not hud.get_node("Top/OnlineStatus").visible and not hud.get_node("Top/TimeControl").visible, "online/mode/time labels hidden %s mode %s" % [vp, mode])
    _check(_inside(_root_rect(hud.get_node("CompactBack")), Rect2(Vector2.ZERO, vp)), "compact menu control bounds %s mode %s" % [vp, mode])
    _check(_inside(_root_rect(hud.get_node("CompactReset")), Rect2(Vector2.ZERO, vp)), "compact reset control bounds %s mode %s" % [vp, mode])
    # El historial de movimientos ahora vive bajo el tablero; el panel antiguo
    # permanece oculto para evitar duplicar la misma información.
    _check(not hud.get_node("Bottom/History").visible, "panel historial antiguo oculto %s mode %s" % [vp, mode])

    if mode == GameState.MODE_2C2:
        _check(hud.get_node("Bottom/Chat").visible, "2c2 chat visible %s" % vp)
        _check(hud.get_node("Bottom/Actions/Suggest").visible, "2c2 sugerir visible %s" % vp)
        _check(hud.get_node("Bottom/Actions/Swap").visible, "2c2 cambiar visible %s" % vp)
        _check(not hud.get_node("Bottom/Actions/Draw").visible, "2c2 tablas movidas al menu %s" % vp)
        _check(hud.get_node("Bottom/GameMenu").visible, "2c2 menu de partida visible %s" % vp)
    elif mode == GameState.MODE_1C1:
        _check(hud.get_node("Bottom/Chat").visible, "1c1 chat visible %s" % vp)
        _check(hud.get_node("Bottom/Emotes").visible, "1c1 reacciones visibles %s" % vp)
        _check(not hud.get_node("Bottom/Actions/Suggest").visible, "1c1 online sin sugerencias %s" % vp)
        _check(not hud.get_node("Bottom/Actions/Swap").visible, "1c1 online sin cambio %s" % vp)
        _check(not hud.get_node("Bottom/Actions/Draw").visible, "1c1 tablas movidas al menu %s" % vp)
        _check(hud.get_node("Bottom/GameMenu").visible, "1c1 menu de partida visible %s" % vp)
    else:
        _check(not hud.get_node("Bottom/Chat").visible, "chat oculto modo %s %s" % [mode, vp])
        _check(not hud.get_node("Bottom/Actions/Suggest").visible, "suggest oculto modo %s %s" % [mode, vp])
        _check(not hud.get_node("Bottom/Actions/Swap").visible, "swap oculto modo %s %s" % [mode, vp])
        _check(not hud.get_node("Bottom/Actions/Draw").visible, "draw fuera de la barra modo %s %s" % [mode, vp])

    _check(hud.get_node("BlackInfo/TeamClock").visible and hud.get_node("WhiteInfo/TeamClock").visible, "relojes de lado visibles %s mode %s" % [vp, mode])
    for panel_name in ["BlackInfo/Players", "WhiteInfo/Players"]:
        var players := hud.get_node(panel_name) as Control
        var cards: Array[Control] = []
        for card in players.get_children():
            _check(not card.has_node("Clock"), "sin reloj duplicado en PlayerCard %s" % vp)
            _check(card.get_node("Info").size.x >= 40.0, "info de jugador útil %s" % vp)
            _check(_inside(_root_rect(card), _root_rect(players)), "card no desborda panel %s" % vp)
            _check(not _overlaps(_root_rect(card.get_node("Info")), _root_rect(card.get_node("Avatar"))), "info no cubre avatar %s" % vp)
            var name_label := card.get_node("Info/Name") as Label
            var name_font: Font = name_label.get_theme_font("font")
            var name_size: float = float(name_label.get_theme_font_size("font_size"))
            var name_needed: float = name_font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, name_size).x
            _check(name_needed <= name_label.size.x + 2.0, "nombre de jugador cabe %s" % vp)
            cards.append(card)
        for i in range(cards.size()):
            for j in range(i + 1, cards.size()):
                _check(not _overlaps(_root_rect(cards[i]), _root_rect(cards[j])), "cards no se solapan %s" % vp)

    for panel_path in ["BlackInfo", "WhiteInfo"]:
        var team_panel := hud.get_node(panel_path) as Control
        var title_node: Control = team_panel.get_node("Title")
        var clock_node: Control = team_panel.get_node("TeamClock")
        var players_node: Control = team_panel.get_node("Players")
        _check(not title_node.visible, "team title removed from gameplay %s" % vp)
        _check(not _overlaps(_root_rect(clock_node), _root_rect(players_node)), "team clock clears player grid %s" % vp)

    _check(_bottom_controls_fit(hud, vp), "bottom controls fit without overlap %s mode %s" % [vp, mode])
    for panel_name in ["MiniPanel", "ChatPanel", "HistoryPanel", "EmotePicker", "Result"]:
        var panel := hud.get_node(panel_name) as Control
        if panel.visible:
            _check(_inside(_root_rect(panel), Rect2(Vector2.ZERO, vp)), "%s fits viewport %s mode %s" % [panel_name, vp, mode])

    await _test_real_board_input(root_game, vp, mode)

    if vp.y >= vp.x and LayoutMetrics.is_compact_portrait(vp):
        _check(hud.get_node("BlackInfo/Players").size.y >= 40.0, "compact portrait player row %s" % vp)
        _check(hud.get_node("WhiteInfo/Players").size.y >= 40.0, "compact portrait white row %s" % vp)

    root_game.queue_free()
    sv.queue_free()
    await process_frame

func _test_real_board_input(root_game, vp: Vector2, mode: int) -> void:
    if mode != GameState.MODE_2C2 or vp.x < 300.0:
        return
    var game_state = root_game.game
    var board = root_game.board_view
    var br: Rect2 = root_game.board_view.board_rect
    var cell := br.size.x / 8.0
    var e2 := br.position + Vector2((4.5) * cell, (6.5) * cell)
    var e4 := br.position + Vector2((4.5) * cell, (4.5) * cell)
    board._emit_square(e2)
    _check(board.selected == Vector2i(4, 6), "touch maps e2 %s" % vp)
    board._emit_square(e4)
    _check(game_state.get_piece(Vector2i(4, 4)) == "peon_blanca", "touch moves e2-e4 %s" % vp)
    _check(board.selected == Vector2i(-1, -1), "selection clears after touch move %s" % vp)

func _bottom_controls_fit(hud: Control, vp: Vector2) -> bool:
    var bottom := _root_rect(hud.get_node("Bottom"))
    var visible: Array[Control] = []
    for button_path in [
        "Bottom/Actions/Suggest",
        "Bottom/Actions/Swap",
        "Bottom/Actions/Surrender",
        "Bottom/Actions/Draw",
        "Bottom/History",
        "Bottom/Chat",
        "Bottom/Emotes"
    ]:
        var b := hud.get_node(button_path) as Control
        if b.visible:
            visible.append(b)
            if not _inside(_root_rect(b), bottom):
                return false
    for i in range(visible.size()):
        for j in range(i + 1, visible.size()):
            if _overlaps(_root_rect(visible[i]), _root_rect(visible[j])):
                return false
    return true

func _overlaps(a: Rect2, b: Rect2) -> bool:
    var overlap := a.intersection(b)
    return overlap.size.x > 0.5 and overlap.size.y > 0.5

func _test_mode_menu(vp: Vector2) -> void:
    var sv := _make_subviewport(vp)
    var menu = MENU_SCENE.instantiate()
    sv.add_child(menu)
    await process_frame
    await process_frame
    var margin := menu.get_node("Margin") as Control
    var vbox := menu.get_node("Margin/VBox") as Control
    var expected_max := 720.0 if vp.y >= vp.x else 920.0
    _check(vbox.size.x <= expected_max + 0.1, "mode menu width %s" % vp)
    var menu_rect := _root_rect(vbox)
    _check(menu_rect.position.x >= 0.0 and menu_rect.end.x <= vp.x + 0.1, "mode menu x bounds %s" % vp)
    var mode_buttons: Array[Control] = []
    for name in ["2c2", "1c1", "Bot", "Local"]:
        var b := menu.get_node("Margin/VBox/" + name) as Button
        var r := _root_rect(b)
        _check(b.visible and r.end.x <= vp.x + 0.1 and r.end.y <= vp.y + 0.1, "mode %s visible/fits %s" % [name, vp])
        mode_buttons.append(b)
    _check(menu.main_nav != null and menu.main_nav.get_node("Bar/Items").get_child_count() == 4, "main navigation has four destinations %s" % vp)
    _check(menu.profile_button != null, "profile remains outside the main navigation %s" % vp)
    for i in range(mode_buttons.size()):
        for j in range(i + 1, mode_buttons.size()):
            _check(not _overlaps(_root_rect(mode_buttons[i]), _root_rect(mode_buttons[j])), "mode buttons do not overlap %s" % vp)
    menu.queue_free()
    sv.queue_free()
    await process_frame

func _test_loading(vp: Vector2) -> void:
    var sv := _make_subviewport(vp)
    var loading = LOADING_SCENE.instantiate()
    sv.add_child(loading)
    await process_frame
    var vbox := loading.get_node("Center/VBox") as Control
    var r := _root_rect(vbox)
    _check(r.size.x <= vp.x + 0.1, "loading width fits %s" % vp)
    _check(_inside(r, Rect2(Vector2.ZERO, vp)), "loading bounds %s" % vp)
    loading.queue_free()
    sv.queue_free()
    await process_frame

func _root_rect(control: Control) -> Rect2:
    var pos := control.global_position
    return Rect2(pos, control.size)

func _inside(rect: Rect2, outer: Rect2) -> bool:
    return (
        rect.position.x >= outer.position.x - 0.1
        and rect.position.y >= outer.position.y - 0.1
        and rect.end.x <= outer.end.x + 0.1
        and rect.end.y <= outer.end.y + 0.1
    )

func _check(condition: bool, label: String) -> void:
    checks += 1
    if condition:
        print("[OK] ", label)
    else:
        failures.append(label)
