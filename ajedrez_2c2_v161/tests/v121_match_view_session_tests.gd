extends SceneTree
const ViewSession = preload("res://domain/online/match_view_session.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var view := ViewSession.new()
	var match_state := {"exists": true, "finished": false, "revision": 7, "board_hash": "board-A", "turn": 2, "clock": 315.0, "history_count": 11}
	var baseline := match_state.duplicate(true)
	var attached: Dictionary = view.attach_viewer("player-A", "match-77", match_state)
	_check(bool(attached.get("ok", false)), "Viewer attaches to live match")
	_check(attached.get("route") == ViewSession.ROUTE_LIVE_MATCH, "Live match routes to match view")
	_check(view.disconnect_viewer("player-A"), "Viewer disconnects independently")
	_check(match_state == baseline, "Viewer disconnect does not mutate authoritative match state")
	_check(not bool(view.viewer_snapshot("player-A").get("connected", true)), "Only viewer connection state changes")
	var reconnected: Dictionary = view.reconnect_viewer("player-A", "match-77", match_state)
	_check(bool(reconnected.get("ok", false)), "Viewer can reconnect to active match")
	_check(reconnected.get("route") == ViewSession.ROUTE_LIVE_MATCH, "Active reconnect routes back to current match")
	_check(int(reconnected.get("revision", -1)) == 7, "Reconnect consumes current authoritative revision")
	_check(match_state == baseline, "Reconnect does not resume or reset match")
	var finished := {"exists": true, "finished": true, "revision": 12, "result": "white_win", "history_count": 19}
	var final_route: Dictionary = view.reconnect_viewer("player-A", "match-77", finished)
	_check(final_route.get("route") == ViewSession.ROUTE_MATCH_RESULT, "Finished reconnect routes to final result screen")
	_check(final_route.get("snapshot", {}).get("result") == "white_win", "Final result snapshot is preserved")
	_check(match_state == baseline, "Late reconnect leaves earlier match snapshot untouched")
	_check(bool(view.update_viewer_snapshot("player-A", {"exists": true, "finished": false, "revision": 13}).get("ok", false)), "Current viewer snapshot updates")
	var stale: Dictionary = view.update_viewer_snapshot("player-A", {"exists": true, "finished": false, "revision": 12})
	_check(not bool(stale.get("ok", true)), "Older snapshot cannot overwrite newer viewer state")
	_check(stale.get("reason") == "stale_snapshot", "Stale snapshot rejection is explicit")
	_check(not bool(view.attach_viewer("", "match-77", match_state).get("ok", true)), "Empty viewer identity is rejected")
	_check(not bool(view.reconnect_viewer("player-A", "", finished).get("ok", true)), "Empty match identity is rejected")
	print("V121 MATCH VIEW SESSION: %d OK / %d FAILED" % [passed, failed])
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
