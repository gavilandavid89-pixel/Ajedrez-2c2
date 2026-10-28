extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var agent_script = load("res://domain/supervision/touch_observer_agent.gd")
    var agent = agent_script.new(null)
    var first: Dictionary = agent.observe_touch(true, Vector2(100, 100), Vector2i(3, 4), Vector2i(-1, -1), true)
    _check(first.event == "press", "records touchscreen press")
    var release: Dictionary = agent.observe_touch(false, Vector2(100, 100), Vector2i(3, 4), Vector2i(3, 4), true)
    _check(release.event == "release", "records touchscreen release")
    var second: Dictionary = agent.observe_touch(true, Vector2(101, 101), Vector2i(3, 4), Vector2i(3, 4), true)
    _check(bool(second.double_tap), "detects close consecutive taps")
    _check(bool(second.same_square_double_tap), "flags double tap on same square")
    var distant: Dictionary = agent.observe_touch(true, Vector2(300, 300), Vector2i(7, 7), Vector2i(3, 4), true)
    _check(not bool(distant.double_tap), "does not classify distant touch as double tap")
    agent.observe_result("press_processed", Vector2i(-1, -1), Vector2i(3, 4), 0, 0, false)
    _check(agent.summary().touch_count == 4, "summarizes observed touch events")
    _check(agent.summary().double_tap_count == 1, "summarizes double taps")

    var controller_source := FileAccess.get_file_as_string("res://ui/components/game/game_input_controller.gd")
    _check(controller_source.contains("hub.observe_touch("), "game input forwards touch telemetry")
    _check(controller_source.contains("hub.observe_touch_result("), "game input records interaction outcome")
    _check(controller_source.find("hub.observe_touch(") < controller_source.find("if game == null or board_view == null or not game.running:"), "records touches before gameplay guards")
    var hub_source := FileAccess.get_file_as_string("res://core/services/supervisor_hub.gd")
    _check(hub_source.contains("touch_observer_summary"), "supervisor hub exposes touch summary")
    print("V132 TOUCH OBSERVER: %d OK / %d FAILED" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
    else:
        failed += 1
        push_error("[FAIL] " + label)
