extends SceneTree
const Supervisor = preload("res://domain/online/match_supervisor.gd")
const Policy = preload("res://domain/online/disconnection_policy.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var s = Supervisor.new()
	_check(s.register_player("p1", 100.0), "Supervisor registers player session")
	var live := {"exists": true, "finished": false, "revision": 5, "board": "untouched"}
	var thinking: Dictionary = s.inspect_player("m1", "p1", 105.0, live)
	_check(thinking.get("state") == Policy.STATE_CONNECTED, "Thinking while heartbeat is fresh remains connected")
	_check(int(thinking.get("countdown", -2)) == -1, "No abandonment countdown for a connected thinker")
	_check(not bool(thinking.get("recommend_forfeit", true)), "No false forfeit recommendation")
	var grace: Dictionary = s.inspect_player("m1", "p1", 108.0, live)
	_check(grace.get("state") == Policy.STATE_GRACE, "Lost heartbeat starts grace period")
	_check(int(grace.get("countdown", -2)) == -1, "Grace countdown hidden at start")
	var final_ten: Dictionary = s.inspect_player("m1", "p1", 158.0, live)
	_check(int(final_ten.get("countdown", -2)) == 10, "Visible countdown only in final ten seconds")
	var expired: Dictionary = s.inspect_player("m1", "p1", 168.0, live)
	_check(expired.get("state") == Policy.STATE_DISCONNECTED, "Grace expiration detected")
	_check(bool(expired.get("recommend_forfeit", false)), "Supervisor recommends forfeit after expiration")
	var duplicate: Dictionary = s.inspect_player("m1", "p1", 180.0, live)
	_check(not bool(duplicate.get("recommend_forfeit", true)), "Forfeit recommendation is idempotent")
	var finished := {"exists": true, "finished": true, "revision": 9, "result": "white_win"}
	var routed: Dictionary = s.reconnect("p1", "m1", finished)
	_check(routed.get("route") == "match_result", "Late reconnect routes to final result screen")
	var after_finish: Dictionary = s.inspect_player("m1", "p1", 250.0, live)
	_check(after_finish.get("route") == "match_result", "Once final snapshot observed, live route cannot reopen")
	_check(not bool(after_finish.get("recommend_forfeit", true)), "Finished match suppresses forfeit processing")
	_check(after_finish.get("state") == "match_finished", "Supervisor reports terminal match state")
	_check(s.mark_match_finished("m2"), "Authoritative owner can mark a match terminal")
	var terminal: Dictionary = s.inspect_player("m2", "p1", 300.0, live)
	_check(terminal.get("route") == "match_result", "Marked terminal match remains on result route")
	_check(not s.mark_match_finished(" "), "Empty match id rejected")
	_check(not s.reconnect("", "m1", live).get("ok", true), "Invalid reconnect rejected")
	_check(s.heartbeat("p1", 301.0), "Valid heartbeat accepted")
	var resumed: Dictionary = s.inspect_player("m3", "p1", 302.0, live)
	_check(resumed.get("state") == Policy.STATE_CONNECTED, "Reconnected session stays live in another match")
	_check(not bool(resumed.get("recommend_forfeit", true)), "Reconnected player receives no forfeit recommendation")
	_check(live.get("board") == "untouched" and int(live.get("revision")) == 5, "Supervisor never mutates authoritative snapshot")
	print("V123 MATCH SUPERVISOR: %d OK / %d FAILED" % [passed, failed])
	for failure in failures: push_error(failure)
	quit(0 if failed == 0 else 1)
func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[OK] ", label)
	else:
		failed += 1
		failures.append(label)
		print("[FAIL] ", label)
