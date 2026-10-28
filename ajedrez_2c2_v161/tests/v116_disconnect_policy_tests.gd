extends SceneTree

const Policy = preload("res://domain/online/disconnection_policy.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var p = Policy.new()
    p.configure(20.0, 8.0)
    _check(not p.register_session("   ", 0.0), "Empty player ID cannot register a session")
    _check(p.register_session("p1", 100.0), "Valid session registers")
    _check(p.evaluate("p1", 107.9) == Policy.STATE_CONNECTED, "Heartbeat timeout has not elapsed before threshold")
    _check(p.evaluate("p1", 108.0) == Policy.STATE_GRACE, "Silence at heartbeat threshold starts grace period")
    _check(p.evaluate("p1", 127.9) == Policy.STATE_GRACE, "Grace period does not expire early")
    _check(p.evaluate("p1", 128.0) == Policy.STATE_DISCONNECTED, "Grace expiration marks session disconnected")
    var s: Dictionary = p.snapshot("p1")
    _check(int(s.get("disconnect_count", 0)) == 1, "Disconnect event is counted once")
    _check(p.heartbeat("p1", 129.0, int(s.get("session_generation", 0))), "Valid reconnect heartbeat is accepted")
    _check(p.evaluate("p1", 129.0) == Policy.STATE_CONNECTED, "Reconnect returns session to connected")
    _check(int(p.snapshot("p1").get("reconnect_count", 0)) == 1, "Reconnect count increments")
    _check(not p.heartbeat("p1", 130.0, int(s.get("session_generation", 0)) + 1), "Unknown session generation is rejected")
    _check(not p.heartbeat("missing", 130.0), "Heartbeat cannot create an unknown session")
    _check(not p.heartbeat("p1", 120.0), "Out-of-order heartbeat timestamp is rejected")
    var old_generation := int(p.snapshot("p1").get("session_generation", 0))
    _check(p.register_session("p1", 140.0), "Replacing session creates a new generation")
    var new_generation := int(p.snapshot("p1").get("session_generation", 0))
    _check(new_generation == old_generation + 1, "Session generation increases after replacement")
    _check(not p.heartbeat("p1", 141.0, old_generation), "Heartbeat from previous session cannot revive replacement")
    _check(p.evaluate("unknown", 150.0) == "unknown", "Unknown player is not treated as disconnected")
    _check(p.remove_session("p1") and p.snapshot("p1").is_empty(), "Session can be explicitly removed")
    print("V116 DISCONNECT POLICY: %d OK / %d FAILED" % [passed, failed])
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
