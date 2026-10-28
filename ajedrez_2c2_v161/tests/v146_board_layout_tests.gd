extends SceneTree

const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    for vp in [Vector2(320, 568), Vector2(360, 640), Vector2(390, 844), Vector2(412, 915)]:
        _check_portrait(vp)
    for vp in [Vector2(844, 390), Vector2(800, 480), Vector2(960, 540), Vector2(1280, 720)]:
        _check_landscape(vp)
    print("V146 BOARD FULL-WIDTH / ORIENTATION LAYOUT: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _check_portrait(vp: Vector2) -> void:
    var rect: Rect2 = LayoutMetrics.board_rect(vp)
    var label := "portrait %s" % vp
    _check(is_equal_approx(rect.size.x, rect.size.y), "square cells " + label)
    _check(rect.size.x >= vp.x - 20.1, "nearly full-width board " + label)
    _check(rect.position.x >= 0.0 and rect.end.x <= vp.x + 0.1, "horizontal bounds " + label)
    _check(rect.position.y >= 0.0 and rect.end.y <= vp.y + 0.1, "vertical bounds " + label)
    var metrics := LayoutMetrics.portrait_stack_metrics(vp)
    _check(rect.end.y + float(metrics["lower_stack_height"]) <= vp.y + 0.6, "room remains for player/action stack " + label)

func _check_landscape(vp: Vector2) -> void:
    var rect: Rect2 = LayoutMetrics.board_rect(vp)
    var label := "landscape %s" % vp
    _check(is_equal_approx(rect.size.x, rect.size.y), "square cells preserved " + label)
    _check(rect.size.x >= vp.y - 24.1, "board maximizes available height " + label)
    _check(rect.position.x >= 0.0 and rect.end.x <= vp.x + 0.1, "horizontal bounds " + label)
    _check(rect.position.y >= 0.0 and rect.end.y <= vp.y + 0.1, "vertical bounds " + label)
    var left: Rect2 = LayoutMetrics.landscape_side_rect(vp, false, vp.y - 48.0)
    var right: Rect2 = LayoutMetrics.landscape_side_rect(vp, true, vp.y - 48.0)
    _check(left.end.x <= rect.position.x + 0.1, "left controls rail doesn't overlap board " + label)
    _check(right.position.x >= rect.end.x - 0.1, "right information rail doesn't overlap board " + label)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
