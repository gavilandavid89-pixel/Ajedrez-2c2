extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var script = load("res://domain/supervision/touch_observer_agent.gd")
    var agent = script.new(null)
    agent.observe_touch(true, Vector2(100, 100), Vector2i(3, 4), Vector2i(-1, -1), true, "", 0)
    agent.observe_touch(false, Vector2(100, 100), Vector2i(3, 4), Vector2i(3, 4), true, "", 0)
    var second: Dictionary = agent.observe_touch(true, Vector2(102, 101), Vector2i(3, 4), Vector2i(3, 4), true, "", 0)
    _check(bool(second.double_tap), "detects a completed same-finger double tap")
    _check(bool(second.same_square_double_tap), "identifies double tap on same logical square")
    _check(int(second.pointer_index) == 0, "preserves pointer index")

    var other_finger = script.new(null)
    other_finger.observe_touch(true, Vector2(100, 100), Vector2i(3, 4), Vector2i(-1, -1), true, "", 0)
    other_finger.observe_touch(false, Vector2(100, 100), Vector2i(3, 4), Vector2i(3, 4), true, "", 0)
    var second_finger: Dictionary = other_finger.observe_touch(true, Vector2(101, 100), Vector2i(3, 4), Vector2i(3, 4), true, "", 1)
    _check(not bool(second_finger.double_tap), "does not combine different fingers into a double tap")

    var incomplete = script.new(null)
    incomplete.observe_touch(true, Vector2(100, 100), Vector2i(3, 4), Vector2i(-1, -1), true, "", 0)
    var no_release: Dictionary = incomplete.observe_touch(true, Vector2(100, 100), Vector2i(3, 4), Vector2i(3, 4), true, "", 0)
    _check(not bool(no_release.double_tap), "requires the first tap to complete with a release")
    _check(int(incomplete.summary().duplicate_press_count) == 1, "flags a second press without release")

    var anomalies = script.new(null)
    anomalies.observe_touch(false, Vector2(20, 20), Vector2i(-1, -1), Vector2i(-1, -1), true, "", 0)
    _check(int(anomalies.summary().unmatched_release_count) == 1, "counts release without observed press")
    anomalies.observe_touch(true, Vector2(30, 30), Vector2i(-1, -1), Vector2i(-1, -1), true, "hud_blocks_board_input", 0)
    _check(int(anomalies.summary().blocked_touch_count) == 1, "counts known blocked touches")
    _check(int(anomalies.summary().outside_board_count) == 2, "counts taps outside board coordinates")

    var correlated = script.new(null)
    correlated.observe_touch(true, Vector2(50, 50), Vector2i(2, 2), Vector2i(-1, -1), true, "", 0)
    correlated.observe_result("press_processed", Vector2i(-1, -1), Vector2i(2, 2), 0, 0, false)
    _check(int(correlated.summary().action_result_count) == 1, "counts action results correlated to touch session")
    _check(not String(correlated.summary().session_id).is_empty(), "creates session identifier for trace grouping")

    var hub_source := FileAccess.get_file_as_string("res://core/services/supervisor_hub.gd")
    var controller_source := FileAccess.get_file_as_string("res://ui/components/game/game_input_controller.gd")
    _check(hub_source.contains("touch_observer_summary.json"), "exports dedicated touch summary in QA bundle")
    _check(hub_source.contains("if DirAccess.dir_exists_absolute(capture_dir)"), "avoids Output error when no captures exist yet")
    _check(controller_source.contains("touch_event.index"), "forwards pointer identity from Godot input")
    _check(controller_source.find("hub.observe_touch(") < controller_source.find("if game == null or board_view == null or not game.running:"), "observes before gameplay guards")

    print("V133 TOUCH PRECISION: %d OK / %d FAILED" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
    else:
        failed += 1
        push_error("[FAIL] " + label)
