extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var window := get_root()
    window.size = Vector2i(390, 844)
    await process_frame
    await process_frame
    _check(is_equal_approx(window.content_scale_factor, 1.0), "portrait uses the reference scale")

    window.size = Vector2i(844, 390)
    await process_frame
    await process_frame
    var expected := 844.0 / 390.0
    _check(absf(window.content_scale_factor - expected) < 0.03, "short landscape compensates for portrait canvas shrink")

    window.size = Vector2i(1280, 720)
    await process_frame
    await process_frame
    _check(absf(window.content_scale_factor - (844.0 / 720.0)) < 0.03, "larger landscape scales proportionally instead of using a fixed multiplier")

    window.size = Vector2i(390, 844)
    await process_frame
    await process_frame
    _check(is_equal_approx(window.content_scale_factor, 1.0), "returning to portrait restores normal scale")
    print("V145 RESPONSIVE CONTENT SCALE: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
