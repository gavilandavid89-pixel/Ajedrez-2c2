extends RefCounted
class_name OnlineDisconnectionPolicy

## Deterministic policy model for a future authoritative backend.
## This does not open sockets or declare a real network peer disconnected.
const STATE_CONNECTED := "connected"
const STATE_GRACE := "grace_period"
const STATE_DISCONNECTED := "disconnected"
const DEFAULT_GRACE_SECONDS := 60.0
const DEFAULT_HEARTBEAT_TIMEOUT_SECONDS := 8.0
const DEFAULT_VISIBLE_COUNTDOWN_SECONDS := 10.0

var grace_seconds: float = DEFAULT_GRACE_SECONDS
var heartbeat_timeout_seconds: float = DEFAULT_HEARTBEAT_TIMEOUT_SECONDS
var visible_countdown_seconds: float = DEFAULT_VISIBLE_COUNTDOWN_SECONDS
var sessions: Dictionary = {}

func configure(grace: float = DEFAULT_GRACE_SECONDS, heartbeat_timeout: float = DEFAULT_HEARTBEAT_TIMEOUT_SECONDS) -> void:
    grace_seconds = clampf(grace, 1.0, 300.0)
    heartbeat_timeout_seconds = clampf(heartbeat_timeout, 1.0, 60.0)

func register_session(player_id: String, now_seconds: float) -> bool:
    var key := player_id.strip_edges()
    if key.is_empty():
        return false
    sessions[key] = {
        "state": STATE_CONNECTED,
        "last_heartbeat": now_seconds,
        "grace_started": -1.0,
        "grace_reason": "",
        "disconnect_count": 0,
        "reconnect_count": 0,
        "session_generation": int(sessions.get(key, {}).get("session_generation", 0)) + 1,
    }
    return true

## Must only be called after the server authenticates the player/session.
func heartbeat(player_id: String, now_seconds: float, session_generation: int = -1) -> bool:
    var key := player_id.strip_edges()
    if not sessions.has(key):
        return false
    var record: Dictionary = sessions[key]
    if session_generation >= 0 and session_generation != int(record.get("session_generation", 0)):
        return false # Ignore heartbeats from an obsolete connection.
    if now_seconds < float(record.get("last_heartbeat", now_seconds)):
        return false # Ignore out-of-order timestamps.
    var was_disconnected := String(record.get("state", STATE_CONNECTED)) != STATE_CONNECTED
    record["last_heartbeat"] = now_seconds
    record["state"] = STATE_CONNECTED
    record["grace_started"] = -1.0
    record["grace_reason"] = ""
    if was_disconnected:
        record["reconnect_count"] = int(record.get("reconnect_count", 0)) + 1
    sessions[key] = record
    return true

## Returns current state. Expiration is evaluated by trusted server time, never by a client claim.
func evaluate(player_id: String, now_seconds: float) -> String:
    var key := player_id.strip_edges()
    if not sessions.has(key):
        return "unknown"
    var record: Dictionary = sessions[key]
    var state := String(record.get("state", STATE_CONNECTED))
    var silence := maxf(0.0, now_seconds - float(record.get("last_heartbeat", now_seconds)))
    if state == STATE_CONNECTED and silence >= heartbeat_timeout_seconds:
        record["state"] = STATE_GRACE
        record["grace_started"] = now_seconds
        record["grace_reason"] = "connection_lost"
        state = STATE_GRACE
    elif state == STATE_GRACE and now_seconds - float(record.get("grace_started", now_seconds)) >= grace_seconds:
        record["state"] = STATE_DISCONNECTED
        record["disconnect_count"] = int(record.get("disconnect_count", 0)) + 1
        state = STATE_DISCONNECTED
    sessions[key] = record
    return state


## Explicitly leaving the live match starts the same 60-second return window.
## Merely thinking or not submitting a move must never call this method.
func report_explicit_leave(player_id: String, now_seconds: float, session_generation: int = -1) -> bool:
    var key := player_id.strip_edges()
    if not sessions.has(key):
        return false
    var record: Dictionary = sessions[key]
    if session_generation >= 0 and session_generation != int(record.get("session_generation", 0)):
        return false
    if String(record.get("state", STATE_CONNECTED)) == STATE_DISCONNECTED:
        return false
    if now_seconds < float(record.get("last_heartbeat", now_seconds)):
        return false
    record["state"] = STATE_GRACE
    record["grace_started"] = now_seconds
    record["grace_reason"] = "explicit_leave"
    sessions[key] = record
    return true

## Countdown is only exposed during an actual grace period, and only in its final
## configured window. No-move/turn time is deliberately not an input here.
func countdown_seconds(player_id: String, now_seconds: float) -> int:
    var key := player_id.strip_edges()
    if not sessions.has(key):
        return -1
    var record: Dictionary = sessions[key]
    if String(record.get("state", STATE_CONNECTED)) != STATE_GRACE:
        return -1
    var remaining := maxf(0.0, grace_seconds - maxf(0.0, now_seconds - float(record.get("grace_started", now_seconds))))
    if remaining > visible_countdown_seconds:
        return -1
    return int(ceil(remaining))

func grace_reason(player_id: String) -> String:
    var key := player_id.strip_edges()
    if not sessions.has(key):
        return ""
    return String((sessions[key] as Dictionary).get("grace_reason", ""))

func snapshot(player_id: String) -> Dictionary:
    var key := player_id.strip_edges()
    if not sessions.has(key):
        return {}
    return (sessions[key] as Dictionary).duplicate(true)

func remove_session(player_id: String) -> bool:
    var key := player_id.strip_edges()
    if not sessions.has(key):
        return false
    sessions.erase(key)
    return true
