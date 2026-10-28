extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
    await _check_portrait()
    await _check_landscape()
    print("V144 PROFESSIONAL HUD: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)

func _make_game(size: Vector2i) -> Array:
    var sv := SubViewport.new()
    sv.size = size
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    root.add_child(sv)
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    return [sv, game]

func _check_portrait() -> void:
    var pair := await _make_game(Vector2i(360, 640))
    var sv: SubViewport = pair[0]
    var game = pair[1]
    var hud = game.hud
    var back: Control = hud.get_node("CompactBack")
    var black: Control = hud.get_node("BlackInfo")
    var white: Control = hud.get_node("WhiteInfo")
    var top: Control = black if black.position.y < white.position.y else white
    var bottom: Control = white if top == black else black
    var top_players: Control = top.get_node("Players")
    var top_clock: Control = top.get_node("TeamClock")
    var first_card: Control = top_players.get_child(0)
    var avatar: Control = first_card.get_node("Avatar")
    _check(LayoutMetrics.board_rect(Vector2(360, 640)).size.x >= 320.0 and LayoutMetrics.board_rect(Vector2(360, 640)).size.x <= 344.0, "portrait board uses nearly all width with safe margins")
    _check(not back.get_global_rect().intersects(avatar.get_global_rect()), "back control never overlaps top player avatar")
    _check(top_players.get_global_rect().end.x <= top_clock.get_global_rect().position.x + 3.0, "top clock stays attached after the player group")
    _check(avatar.size.x >= 48.0 and avatar.size.y >= 48.0, "portrait avatar remains large and legible")
    _check(bottom.get_global_rect().end.x >= 350.0, "local player group is anchored toward the opposite corner")
    game.queue_free(); sv.queue_free(); await process_frame

func _check_landscape() -> void:
    var pair := await _make_game(Vector2i(800, 480))
    var sv: SubViewport = pair[0]
    var game = pair[1]
    var hud = game.hud
    var back: Control = hud.get_node("CompactBack")
    var black: Control = hud.get_node("BlackInfo")
    var white: Control = hud.get_node("WhiteInfo")
    var left: Control = black if black.position.x < white.position.x else white
    var right: Control = white if left == black else black
    var left_players: Control = left.get_node("Players")
    var left_clock: Control = left.get_node("TeamClock")
    var card: Control = left_players.get_child(0)
    var avatar: Control = card.get_node("Avatar")
    var info: Control = card.get_node("Info")
    var name_label: Control = card.get_node("Info/Name")
    _check(left.position.y >= 48.0 and right.position.y >= 48.0, "landscape player rails start below corner controls")
    _check(not back.get_global_rect().intersects(avatar.get_global_rect()), "landscape back control does not cover an avatar")
    _check(left_clock.size.x >= left.size.x - 12.0, "landscape clock uses the full side-rail width")
    _check(info.position.x >= avatar.position.x + avatar.size.x, "landscape player name sits beside the avatar")
    _check(name_label.size.x >= 72.0, "landscape player name has readable width")
    game.queue_free(); sv.queue_free(); await process_frame
