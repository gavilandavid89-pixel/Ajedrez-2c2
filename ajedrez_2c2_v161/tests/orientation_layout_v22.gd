extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    await process_frame

    _check(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 6, "Android/iOS orientation is full sensor")
    _check(LayoutMetrics.landscape_side_width(Vector2(1280, 720)) >= 176.0, "wide landscape keeps a usable side column")
    _check(LayoutMetrics.landscape_side_width(Vector2(800, 480)) >= 176.0, "small landscape keeps a usable side column")
    _check(LayoutMetrics.landscape_side_width(Vector2(1920, 1080)) <= 320.0, "desktop landscape side column has a sensible maximum")

    await _inspect_game(Vector2(1280, 720), GameState.MODE_2C2)
    await _inspect_game(Vector2(800, 480), GameState.MODE_2C2)
    await _inspect_game(Vector2(360, 640), GameState.MODE_2C2)

    print("ORIENTATION/LAYOUT V22: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _inspect_game(vp: Vector2, mode: int) -> void:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    get_root().add_child(sv)

    var app = get_root().get_node_or_null("App")
    if app != null:
        app.selected_mode = mode

    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame

    var hud: Control = game.hud
    var landscape := vp.x > vp.y
    if landscape:
        var side := LayoutMetrics.landscape_side_width(vp)
        _check(hud.get_node("BlackInfo").size.x >= side - 0.5, "black profile column width >= %.0f at %s" % [side, vp])
        _check(hud.get_node("WhiteInfo").size.x >= side - 0.5, "white profile column width >= %.0f at %s" % [side, vp])
        _check(hud.get_node("Bottom").size.x >= vp.x - 24.0 - 0.5, "landscape action bar uses screen width at %s" % vp)
        var card := hud.get_node("BlackInfo/Players").get_child(0) as Control
        _check(card.size.x >= 80.0, "landscape player card keeps a readable compact width at %s" % vp)
        _check(card.size.y >= 48.0, "landscape player card height is usable at %s" % vp)

        hud._toggle_chat()
        await process_frame
        _check(hud.get_node("ChatPanel").size.x >= side - 0.5, "landscape chat uses side column width at %s" % vp)
        _check(hud.get_node("ChatPanel").size.x >= 260.0 or vp.x < 900.0, "landscape chat is not tiny at %s" % vp)
        hud._close_chat()

        hud._toggle_emotes()
        await process_frame
        _check(hud.get_node("EmotePicker").size.x >= 260.0, "landscape emote picker is not tiny at %s" % vp)
        hud._close_emote_picker()
    else:
        _check(hud.get_node("Bottom").position.x >= 0.0 and hud.get_node("Bottom").get_global_rect().end.x <= vp.x + 0.5, "portrait action bar fits screen at %s" % vp)
        var local_panel_name := "BlackInfo" if int(game.game.local_team()) == GameState.TEAM_BLACK else "WhiteInfo"
        _check(hud.get_node(local_panel_name).position.y >= LayoutMetrics.board_rect(vp).end.y - 0.5, "portrait local profile remains below board at %s" % vp)

    game.queue_free()
    sv.queue_free()
    await process_frame

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        print("[FAIL] ", label)
