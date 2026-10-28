extends SceneTree

const GAME_SCENE := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")
const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
    await process_frame
    var vps := [Vector2(360, 640), Vector2(390, 844), Vector2(720, 1280), Vector2(800, 480), Vector2(1024, 600), Vector2(1280, 720)]
    for vp in vps:
        await _check_game(vp)
    print("RESPONSIVE TOUCH TARGETS V25: %d OK / %d FAIL" % [checks - failures.size(), failures.size()])
    for f in failures: print("[FAIL] ", f)
    quit(1 if failures else 0)

func _check_game(vp: Vector2) -> void:
    var sv := SubViewport.new()
    sv.size = vp
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    get_root().add_child(sv)
    var game = GAME_SCENE.instantiate()
    var app = get_root().get_node_or_null("App")
    if app: app.selected_mode = GameState.MODE_2C2
    sv.add_child(game)
    await process_frame
    await process_frame
    var hud = game.hud
    _check(hud.get_node("Bottom/Actions/Suggest").size.y >= 40.0 or not hud.get_node("Bottom/Actions/Suggest").visible, "suggest target %s" % vp)
    _check(hud.get_node("Bottom/Chat").size.y >= 40.0 or not hud.get_node("Bottom/Chat").visible, "chat target %s" % vp)
    _check(hud.get_node("Bottom/Emotes").size.y >= 40.0 or not hud.get_node("Bottom/Emotes").visible, "emotes target %s" % vp)
    _check(hud.get_node("BlackInfo").size.y >= 44.0, "black profile panel %s" % vp)
    _check(hud.get_node("WhiteInfo").size.y >= 44.0, "white profile panel %s" % vp)
    sv.queue_free()
    await process_frame

func _check(cond: bool, msg: String) -> void:
    checks += 1
    if not cond: failures.append(msg)
