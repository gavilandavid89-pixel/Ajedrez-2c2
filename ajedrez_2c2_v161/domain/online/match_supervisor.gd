extends RefCounted
class_name MatchSupervisor

## Deterministic supervisor seam for a future authoritative server / AI supervisor.
## It observes session policy and routing but never edits the board, clock, turn,
## move history, or result itself. A server adapter must apply forfeit recommendations.
const PolicyScript = preload("res://domain/online/disconnection_policy.gd")
const ViewSessionScript = preload("res://domain/online/match_view_session.gd")
const ROUTE_LIVE_MATCH := "live_match"
const ROUTE_MATCH_RESULT := "match_result"
const ROUTE_LOBBY := "lobby"

var policy = PolicyScript.new()
var view_session = ViewSessionScript.new()
var _issued_forfeits: Dictionary = {}
var _finished_matches: Dictionary = {}
var journal

func configure_journal(shared_journal) -> void:
	journal = shared_journal

func register_player(player_id: String, now_seconds: float) -> bool:
	return policy.register_session(player_id, now_seconds)

func heartbeat(player_id: String, now_seconds: float, session_generation: int = -1) -> bool:
	return policy.heartbeat(player_id, now_seconds, session_generation)

func report_explicit_leave(player_id: String, now_seconds: float, session_generation: int = -1) -> bool:
	return policy.report_explicit_leave(player_id, now_seconds, session_generation)

## Feed an authoritative snapshot. Finished results always win over connection state.
func reconnect(player_id: String, match_id: String, authoritative_snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = view_session.reconnect_viewer(player_id, match_id, authoritative_snapshot)
	if bool(result.get("ok", false)) and bool(authoritative_snapshot.get("finished", false)):
		_finished_matches[match_id.strip_edges()] = true
	return result

func disconnect_viewer(player_id: String) -> bool:
	return view_session.disconnect_viewer(player_id)

## Returns a recommendation, not a game mutation. Idempotent per match/player.
func inspect_player(match_id: String, player_id: String, now_seconds: float, authoritative_snapshot: Dictionary) -> Dictionary:
	var mid := match_id.strip_edges()
	var pid := player_id.strip_edges()
	if mid.is_empty() or pid.is_empty() or authoritative_snapshot.is_empty():
		return {"ok": false, "reason": "invalid_request"}
	if bool(authoritative_snapshot.get("finished", false)):
		_finished_matches[mid] = true
		return {"ok": true, "state": "match_finished", "route": ROUTE_MATCH_RESULT, "countdown": -1, "recommend_forfeit": false, "reason": "match_already_finished"}
	if _finished_matches.has(mid):
		return {"ok": true, "state": "match_finished", "route": ROUTE_MATCH_RESULT, "countdown": -1, "recommend_forfeit": false, "reason": "terminal_snapshot_seen"}
	var state: String = policy.evaluate(pid, now_seconds)
	var countdown: int = policy.countdown_seconds(pid, now_seconds)
	var key := mid + "::" + pid
	var recommend := state == PolicyScript.STATE_DISCONNECTED and not _issued_forfeits.has(key)
	if recommend:
		_issued_forfeits[key] = true
	return {
		"ok": true,
		"state": state,
		"route": ROUTE_LIVE_MATCH,
		"countdown": countdown,
		"recommend_forfeit": recommend,
		"reason": policy.grace_reason(pid) if recommend else "",
		"match_id": mid,
		"player_id": pid,
	}

## Call only after the authoritative match owner confirms the terminal result.
func mark_match_finished(match_id: String) -> bool:
	var mid := match_id.strip_edges()
	if mid.is_empty():
		return false
	_finished_matches[mid] = true
	return true
