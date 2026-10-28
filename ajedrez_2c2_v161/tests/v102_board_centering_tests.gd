extends SceneTree

const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    for vp in [Vector2(320, 568), Vector2(360, 640), Vector2(390, 844), Vector2(412, 915), Vector2(720, 720), Vector2(1080, 2400)]:
        _check_viewport(vp, false)
    for vp in [Vector2(320, 568), Vector2(390, 844), Vector2(720, 720)]:
        _check_viewport(vp, true)
    print("PORTRAIT BOARD STACK: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check_viewport(vp: Vector2, result_mode: bool) -> void:
    var rect: Rect2 = LayoutMetrics.board_rect(vp, result_mode)
    var label := "%s result=%s" % [vp, result_mode]
    _check(rect.size.x > 0.0 and is_equal_approx(rect.size.x, rect.size.y), "square board: " + label)
    _check(absf(rect.position.x - ((vp.x - rect.size.x) * 0.5)) < 0.51, "centered board: " + label)
    _check(rect.position.x >= -0.01 and rect.end.x <= vp.x + 0.51, "horizontal bounds: " + label)
    _check(rect.position.y >= 0.0 and rect.end.y <= vp.y + 0.51, "vertical bounds: " + label)
    if not result_mode:
        var metrics := LayoutMetrics.portrait_stack_metrics(vp)
        var team_height: float = float(metrics["team_height"])
        var lower_stack_height: float = float(metrics["lower_stack_height"])
        var team_top: float = LayoutMetrics.portrait_team_top(vp)
        _check(absf(rect.position.y - (team_top + team_height + LayoutMetrics.PORTRAIT_BOARD_HEADER_GAP)) <= 0.51, "board follows top team: " + label)
        _check(rect.end.y + lower_stack_height <= vp.y + 0.51, "board and lower HUD fit: " + label)
        _check(team_top >= 0.0 and team_top < vp.y * 0.25, "team identity stays near top edge: " + label)
        if vp.x <= 412.0 and vp.y > vp.x:
            _check(rect.size.x >= vp.x - 20.1, "board fills phone width with narrow safe margin: " + label)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
