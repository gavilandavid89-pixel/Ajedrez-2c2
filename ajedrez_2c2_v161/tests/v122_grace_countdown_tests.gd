extends SceneTree

const Policy = preload("res://domain/online/disconnection_policy.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var p = Policy.new()
    _check(Policy.DEFAULT_GRACE_SECONDS == 60.0, "Grace period defaults to 60 seconds")
    _check(Policy.DEFAULT_HEARTBEAT_TIMEOUT_SECONDS == 8.0, "Heartbeat detection has a separate threshold")
    _check(p.register_session("player", 100.0), "Player session registers")
    _check(p.countdown_seconds("player", 105.0) == -1, "No countdown while connected and thinking")
    _check(p.evaluate("player", 107.9) == Policy.STATE_CONNECTED, "Connection stays live before heartbeat timeout")
    _check(p.evaluate("player", 108.0) == Policy.STATE_GRACE, "Missing heartbeat starts grace period")
    _check(p.grace_reason("player") == "connection_lost", "Network loss reason is recorded")
    _check(p.countdown_seconds("player", 108.0) == -1, "No visible countdown at start of 60-second grace")
    _check(p.countdown_seconds("player", 158.0) == 10, "Countdown appears only in final ten seconds")
    _check(p.evaluate("player", 167.9) == Policy.STATE_GRACE, "Grace remains active until full minute expires")
    _check(p.evaluate("player", 168.0) == Policy.STATE_DISCONNECTED, "Disconnected player loses eligibility after grace expires")
    _check(p.countdown_seconds("player", 168.0) == -1, "Expired session no longer displays grace countdown")
    _check(p.heartbeat("player", 169.0), "Reconnection heartbeat accepted after terminal session state")
    _check(p.evaluate("player", 169.0) == Policy.STATE_CONNECTED, "Valid heartbeat restores connected session policy state")

    _check(p.register_session("leaver", 200.0), "Explicit-leave session registers")
    var generation := int(p.snapshot("leaver").get("session_generation", 0))
    _check(not p.report_explicit_leave("leaver", 201.0, generation + 1), "Stale session cannot trigger leave grace")
    _check(p.report_explicit_leave("leaver", 201.0, generation), "Explicit leave starts grace period")
    _check(p.grace_reason("leaver") == "explicit_leave", "Explicit leave is distinguished from network loss")
    _check(p.countdown_seconds("leaver", 251.0) == 10, "Explicit leave countdown appears only in final ten seconds")
    _check(p.heartbeat("leaver", 252.0, generation), "Return during grace is accepted")
    _check(p.countdown_seconds("leaver", 252.0) == -1, "Reconnect cancels grace countdown")

    _check(p.register_session("idle", 300.0), "Idle player session registers")
    _check(p.heartbeat("idle", 358.0), "Connected thinker continues sending connection heartbeat")
    _check(p.countdown_seconds("idle", 359.0) == -1, "Elapsed thinking time alone never creates disconnect countdown")
    _check(p.evaluate("idle", 359.0) == Policy.STATE_CONNECTED, "No server-observed disconnect means no grace or forfeit")

    print("V122 GRACE COUNTDOWN: %d OK / %d FAILED" % [passed, failed])
    for failure in failures:
        push_error(failure)
    quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        failures.append(label)
        print("[FAIL] ", label)
