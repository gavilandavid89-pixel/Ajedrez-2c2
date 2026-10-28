extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameController := preload("res://ui/screens/game.gd")
const MODE_MENU := preload("res://scenes/mode_menu.tscn")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")
const GameState := preload("res://domain/chess/game_state.gd")

var passed := 0
var failed := 0

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        push_error("[FAIL] " + label)

func _initialize() -> void:
    for vp in [Vector2(320, 568), Vector2(360, 640), Vector2(390, 844), Vector2(412, 915)]:
        await _check_portrait(vp)
    await _check_modes_and_clock()
    await _check_player_corner_layout()
    await _check_profile_icon()
    print("V58 BOARD FIRST HUD: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check_portrait(vp: Vector2) -> void:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
    root.add_child(sv)
    var game: GameController = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    var br: Rect2 = game.board_view.board_rect
    var hud = game.hud
    _check(is_equal_approx(br.position.x, (vp.x - br.size.x) * 0.5), "board is horizontally centered on %s" % vp)
    _check(is_equal_approx(br.size.x, br.size.y), "board stays perfectly square on %s" % vp)
    _check(br.size.x <= vp.x - 0.5 and br.end.x <= vp.x + 0.5 and br.end.y <= vp.y + 0.5, "board stays inside viewport on %s" % vp)
    _check(br.position.x >= 0.0 and (br.position.x * 2.0 + br.size.x) <= vp.x + 0.5, "board keeps balanced side margins on %s" % vp)
    _check(hud.get_node("Bottom/Actions/Suggest").visible == (game.game.mode == GameState.MODE_2C2), "Sugerir visibility is 2c2-only on %s" % vp)
    _check(hud.get_node("Bottom/Actions/Swap").visible == (game.game.mode == GameState.MODE_2C2), "Cambio visibility is 2c2-only on %s" % vp)
    _check(not hud.get_node("Top").visible, "top online/mode bar hidden on %s" % vp)
    _check(not hud.get_node("Top/OnlineStatus").visible and not hud.get_node("Top/TimeControl").visible, "online/time labels hidden on %s" % vp)
    _check(hud.get_node("CompactBack").visible, "floating back control preserves navigation on %s" % vp)
    var reset_expected: bool = game.game.mode == GameState.MODE_1C1_LOCAL or game.game.mode == GameState.MODE_VS_BOT
    _check(hud.get_node("CompactReset").visible == reset_expected, "reset control respects mode permissions on %s" % vp)
    _check(not hud.get_node("Turn").visible and not hud.get_node("Status").visible, "turn/status text removed on %s" % vp)
    game.queue_free(); sv.queue_free(); await process_frame

func _check_modes_and_clock() -> void:
    var sv := SubViewport.new(); sv.size = Vector2(360, 640); sv.render_target_update_mode = SubViewport.UPDATE_DISABLED; root.add_child(sv)
    var game: GameController = GAME_SCENE.instantiate(); sv.add_child(game); await process_frame; await process_frame
    var hud = game.hud
    var active_clock: Label = hud.get_node("BlackInfo/TeamClock") if game.game.current_team() == game.game.TEAM_BLACK else hud.get_node("WhiteInfo/TeamClock")
    var inactive_clock: Label = hud.get_node("WhiteInfo/TeamClock") if game.game.current_team() == game.game.TEAM_BLACK else hud.get_node("BlackInfo/TeamClock")
    _check(active_clock.get_theme_stylebox("normal") != null, "active clock receives highlighted style")
    _check(inactive_clock.get_theme_stylebox("normal") != null, "inactive clock keeps stable style")
    var active_style: StyleBox = active_clock.get_theme_stylebox("normal")
    var inactive_style: StyleBox = inactive_clock.get_theme_stylebox("normal")
    if active_style is StyleBoxFlat and inactive_style is StyleBoxFlat:
        _check((active_style as StyleBoxFlat).border_color != (inactive_style as StyleBoxFlat).border_color, "active clock is more highlighted")
    game.queue_free(); sv.queue_free(); await process_frame


func _check_player_corner_layout() -> void:
    var vp := Vector2(360, 800)
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_DISABLED
    root.add_child(sv)
    var game: GameController = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    var hud = game.hud
    var black: Control = hud.get_node("BlackInfo")
    var white: Control = hud.get_node("WhiteInfo")
    var top: Control = black if black.position.y < white.position.y else white
    var bottom: Control = white if top == black else black
    var top_players: Control = top.get_node("Players")
    var top_clock: Control = top.get_node("TeamClock")
    var bottom_players: Control = bottom.get_node("Players")
    var bottom_clock: Control = bottom.get_node("TeamClock")
    _check(top.position.x <= 10.0, "opponent player group is anchored near the top-left phone corner")
    _check(bottom.get_global_rect().end.x >= vp.x - 10.0, "local player group reaches the bottom-right phone corner")
    _check(top_players.get_global_rect().end.x <= top_clock.get_global_rect().position.x + 3.0, "top team counter follows its player group")
    _check(bottom_clock.get_global_rect().end.x <= bottom_players.get_global_rect().position.x + 3.0, "bottom team counter stays adjacent to the right-aligned player group")
    var found_large_avatar := false
    for card in top_players.get_children():
        if card is Control:
            var avatar := card.get_node_or_null("Avatar") as Control
            if avatar != null and avatar.size.x >= 44.0 and avatar.size.y >= 44.0:
                found_large_avatar = true
    _check(found_large_avatar, "player avatars use a larger mobile touch-era presentation")
    game.queue_free()
    sv.queue_free()
    await process_frame

func _check_profile_icon() -> void:
    var menu = MODE_MENU.instantiate(); root.add_child(menu); await process_frame; await process_frame
    var profile: Button = menu.get_node("ProfileButton")
    _check(profile.text.strip_edges().is_empty(), "home profile button has no text")
    _check(profile.icon != null, "home profile button uses avatar icon")
    _check(profile.custom_minimum_size.x <= 60.0 and profile.custom_minimum_size.y <= 60.0, "home profile button is icon-sized")
    menu.queue_free(); await process_frame
