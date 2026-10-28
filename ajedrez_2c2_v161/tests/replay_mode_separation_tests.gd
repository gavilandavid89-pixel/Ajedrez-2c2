extends SceneTree

const ReplayViewScript = preload("res://domain/replay/match_replay_view.gd")

var failures := 0
var checks := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var view: Control = ReplayViewScript.new()
    root.add_child(view)
    await process_frame
    _check(view._review_mode == "replay", "Replay is the default mode")
    _check(is_instance_valid(view._analysis_entry_button) and view._analysis_entry_button.visible, "Replay exposes an explicit Analyze Game action")
    _check(is_instance_valid(view._coach_panel) and not view._coach_panel.visible, "Coach is hidden in clean replay mode")
    view.set_review_mode("analysis")
    await process_frame
    _check(view._review_mode == "analysis", "Analysis mode can be activated independently")
    _check(not view._analysis_entry_button.visible, "Analyze entry button is hidden while already in analysis")
    _check(not view._white_player_header.visible and not view._black_player_header.visible, "Analysis hides player cards and clocks")
    view.set_review_mode("replay")
    await process_frame
    _check(view._analysis_entry_button.visible, "Returning to replay restores the explicit analysis entry")
    _check(view._white_player_header.visible and view._black_player_header.visible, "Returning to replay restores player cards and clocks")
    var emitted := [false]
    view.analysis_requested.connect(func(): emitted[0] = true)
    view.request_analysis()
    _check(emitted[0], "Analysis request is signalled without running an engine in the replay view")
    print("REPLAY MODE TESTS: %d OK / %d FALLARON" % [checks - failures, failures])
    view.queue_free()
    quit(1 if failures > 0 else 0)

func _check(condition: bool, description: String) -> void:
    checks += 1
    if condition:
        print("[OK] " + description)
    else:
        failures += 1
        push_error("[FALLA] " + description)
