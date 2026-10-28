extends SceneTree

const LayoutMetrics := preload("res://core/layout/layout_metrics.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    _check(int(ProjectSettings.get_setting("display/window/handheld/orientation", -1)) == 6, "Android orientation follows device sensor")
    for vp in [Vector2(915, 412), Vector2(800, 480), Vector2(1280, 720)]:
        _check_landscape(vp)
    for vp in [Vector2(320, 568), Vector2(390, 844), Vector2(412, 915), Vector2(720, 720)]:
        _check_portrait(vp)
    print("V103 RESPONSIVE ORIENTATION: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check_landscape(vp: Vector2) -> void:
    var board: Rect2 = LayoutMetrics.board_rect(vp)
    var bottom: Rect2 = LayoutMetrics.bottom_rect(vp, board, board.size.x < 520.0)
    var moves_bottom: float = board.end.y + 4.0 + 22.0
    var tag := "landscape %s" % vp
    _check(vp.x > vp.y, "landscape viewport: " + tag)
    _check(is_equal_approx(board.size.x, board.size.y), "square board: " + tag)
    _check(board.position.x >= 0.0 and board.end.x <= vp.x, "board horizontal bounds: " + tag)
    _check(board.position.y >= 0.0 and board.end.y <= vp.y, "board vertical bounds: " + tag)
    _check(moves_bottom <= bottom.position.y + 0.51, "move label clears action bar: " + tag)
    var left: Rect2 = LayoutMetrics.landscape_side_rect(vp, false, 184.0)
    var right: Rect2 = LayoutMetrics.landscape_side_rect(vp, true, 184.0)
    _check(left.end.x <= board.position.x + 0.51, "left team panel clears board: " + tag)
    _check(board.end.x <= right.position.x + 0.51, "right team panel clears board: " + tag)

func _check_portrait(vp: Vector2) -> void:
    var board: Rect2 = LayoutMetrics.board_rect(vp)
    var tag := "portrait %s" % vp
    _check(vp.y >= vp.x, "portrait viewport: " + tag)
    _check(is_equal_approx(board.size.x, board.size.y), "square board: " + tag)
    _check(absf(board.position.x - (vp.x - board.size.x) * 0.5) <= 0.51, "centered board: " + tag)
    _check(board.end.y <= vp.y, "board remains on screen: " + tag)
    var team_height: float = LayoutMetrics.portrait_team_header_height(vp)
    var team_top: float = LayoutMetrics.portrait_team_top(vp)
    _check(absf(board.position.y - (team_top + team_height + 8.0)) <= 0.51, "top team stays grouped with board: " + tag)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
