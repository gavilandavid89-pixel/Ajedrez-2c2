extends RefCounted
class_name MatchViewSession

## Connection/presentation state is deliberately separate from the chess match.
## This service routes a returning client to the live match or its final result;
## it never changes board, turn, clock, result, history, or team delegation.
const ROUTE_LIVE_MATCH := "live_match"
const ROUTE_MATCH_RESULT := "match_result"
const ROUTE_LOBBY := "lobby"

var viewers: Dictionary = {}

func attach_viewer(viewer_id: String, match_id: String, authoritative_snapshot: Dictionary) -> Dictionary:
	var viewer := viewer_id.strip_edges()
	var mid := match_id.strip_edges()
	if viewer.is_empty() or mid.is_empty() or authoritative_snapshot.is_empty():
		return {"ok": false, "reason": "invalid_request"}
	var route := _route_for_snapshot(authoritative_snapshot)
	var record := {
		"viewer_id": viewer,
		"match_id": mid,
		"connected": true,
		"route": route,
		"last_revision": int(authoritative_snapshot.get("revision", 0)),
	}
	viewers[viewer] = record
	return {"ok": true, "route": route, "match_id": mid, "revision": record["last_revision"]}

func disconnect_viewer(viewer_id: String) -> bool:
	var viewer := viewer_id.strip_edges()
	if not viewers.has(viewer):
		return false
	var record: Dictionary = viewers[viewer]
	record["connected"] = false
	viewers[viewer] = record
	return true

## Reconnection consumes the authoritative match snapshot; it does not resume or
## mutate the match. A finished match always routes to the result screen.
func reconnect_viewer(viewer_id: String, match_id: String, authoritative_snapshot: Dictionary) -> Dictionary:
	var viewer := viewer_id.strip_edges()
	var mid := match_id.strip_edges()
	if viewer.is_empty() or mid.is_empty() or authoritative_snapshot.is_empty():
		return {"ok": false, "reason": "invalid_request"}
	var route := _route_for_snapshot(authoritative_snapshot)
	var record := {
		"viewer_id": viewer,
		"match_id": mid,
		"connected": true,
		"route": route,
		"last_revision": int(authoritative_snapshot.get("revision", 0)),
	}
	viewers[viewer] = record
	return {"ok": true, "route": route, "match_id": mid, "revision": record["last_revision"], "snapshot": authoritative_snapshot.duplicate(true)}

func update_viewer_snapshot(viewer_id: String, authoritative_snapshot: Dictionary) -> Dictionary:
	var viewer := viewer_id.strip_edges()
	if not viewers.has(viewer) or not bool((viewers[viewer] as Dictionary).get("connected", false)) or authoritative_snapshot.is_empty():
		return {"ok": false, "reason": "viewer_unavailable"}
	var record: Dictionary = viewers[viewer]
	var incoming_revision := int(authoritative_snapshot.get("revision", 0))
	if incoming_revision < int(record.get("last_revision", 0)):
		return {"ok": false, "reason": "stale_snapshot"}
	record["last_revision"] = incoming_revision
	record["route"] = _route_for_snapshot(authoritative_snapshot)
	viewers[viewer] = record
	return {"ok": true, "route": record["route"], "revision": incoming_revision}

func viewer_snapshot(viewer_id: String) -> Dictionary:
	var viewer := viewer_id.strip_edges()
	if not viewers.has(viewer):
		return {}
	return (viewers[viewer] as Dictionary).duplicate(true)

func _route_for_snapshot(snapshot: Dictionary) -> String:
	if bool(snapshot.get("finished", false)):
		return ROUTE_MATCH_RESULT
	if bool(snapshot.get("exists", true)):
		return ROUTE_LIVE_MATCH
	return ROUTE_LOBBY
