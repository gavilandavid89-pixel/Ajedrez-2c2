extends Node
class_name CompetitiveTelemetryService

# Recolector preparado para conectar el servidor real sin cambiar NEXUS.
# No guarda nombres, emails, IPs, replay ni mensajes: solo señales necesarias
# para calibrar expectativa, incertidumbre, fuerza y comportamiento del motor.
const SCHEMA_VERSION := 1
const STORAGE_PATH := "user://nexus_competitive_telemetry.jsonl"
const MAX_PENDING_EVENTS := 5000
const ENDPOINT_PATH := "/v1/telemetry/nexus"

var enabled := true
var server_url := ""
var auth_token := ""
var _pending: Array[Dictionary] = []
var _http: HTTPRequest
var _flush_in_progress := false

func _ready() -> void:
	_load_pending()

func configure_server(base_url: String, token: String = "") -> void:
	server_url = base_url.strip_edges().trim_suffix("/")
	auth_token = token
	if not server_url.is_empty():
		flush()

func clear_server() -> void:
	server_url = ""
	auth_token = ""

func pending_count() -> int:
	return _pending.size()

func clear_local_buffer() -> void:
	_pending.clear()
	_persist_pending()

func pending_events() -> Array[Dictionary]:
	return _pending.duplicate(true)

func record_match(entry: Dictionary, detail: Dictionary = {}) -> Dictionary:
	if not enabled or not bool(entry.get("competitive", false)):
		return {}
	var mode := int(entry.get("mode", -1))
	if mode != 0 and mode != 1:
		return {}

	var event := {
		"schema_version": SCHEMA_VERSION,
		"event_type": "competitive_match_result",
		"event_id": _event_id(),
		"timestamp": int(entry.get("timestamp", Time.get_unix_time_from_system())),
		"match_id": String(entry.get("match_id", "")),
		"mode": "2c2" if mode == 0 else "1c1",
		"outcome": String(entry.get("outcome", "draw")),
		"reason": String(detail.get("reason", "")),
		"actor_key": _anonymous_key(_local_player_id()),
		"season_id": int(entry.get("season_id", 1)),
		"nexus_version": int(entry.get("nexus_version", 0)),
		"rating_before": int(entry.get("rating_before", entry.get("rating_after", 0) - entry.get("rating_delta", 0))),
		"rating_after": int(entry.get("rating_after", 0)),
		"rating_delta": int(entry.get("rating_delta", 0)),
		"opponent_rating_before": int(entry.get("opponent_rating_before", 1000)),
		"opponent_pair_rating_before": int(entry.get("opponent_pair_rating_before", 1000)),
		"partner_rating_before": int(entry.get("partner_rating_before", 1000)),
		"expected": float(entry.get("expected", 0.5)),
		"surprise": float(entry.get("surprise", 0.0)),
		"uncertainty_before": float(entry.get("uncertainty_before", 0.0)),
		"uncertainty_after": float(entry.get("uncertainty_after", 0.0)),
		"pair_expected": float(entry.get("pair_expected", 0.5)),
		"pair_uncertainty_before": float(entry.get("pair_uncertainty_before", 0.0)),
		"pair_uncertainty_after": float(entry.get("pair_uncertainty_after", 0.0)),
		"pair_effect": float(entry.get("pair_effect", 0.0)),
		"pair_rating_before": int(entry.get("pair_rating_before", 0)),
		"pair_rating_delta": int(entry.get("pair_rating_delta", 0)),
		"pair_rating_after": int(entry.get("pair_rating_after", 0)),
		"pair_effect_before": float(entry.get("pair_effect_before", 0.0)),
		"move_count": int(detail.get("move_count", 0)),
		"match_minutes": int(detail.get("match_minutes", 0)),
		"bot_id": String(detail.get("bot_id", "")),
		"bot_nexus": int(detail.get("bot_nexus", 0)),
		"bot_engine_rating": int(detail.get("bot_elo", 0)),
	}
	_pending.append(event)
	if _pending.size() > MAX_PENDING_EVENTS:
		_pending = _pending.slice(_pending.size() - MAX_PENDING_EVENTS, MAX_PENDING_EVENTS)
	_persist_pending()
	if not server_url.is_empty():
		flush()
	return event.duplicate(true)

func flush() -> void:
	if server_url.is_empty() or _pending.is_empty() or _flush_in_progress:
		return
	if _http == null or not is_instance_valid(_http):
		_http = HTTPRequest.new()
		_http.name = "CompetitiveTelemetryHTTP"
		add_child(_http)
	if _http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	_flush_in_progress = true
	var payload := JSON.stringify({"schema_version": SCHEMA_VERSION, "events": _pending})
	var headers := ["Content-Type: application/json"]
	if not auth_token.is_empty():
		headers.append("Authorization: Bearer %s" % auth_token)
	var err := _http.request(server_url + ENDPOINT_PATH, headers, HTTPClient.METHOD_POST, payload)
	if err != OK:
		_flush_in_progress = false
		return
	var result: Array = await _http.request_completed
	_flush_in_progress = false
	if result.size() < 2:
		return
	var response_code := int(result[1])
	if response_code >= 200 and response_code < 300:
		_pending.clear()
		_persist_pending()

func export_pending(path: String = "user://nexus_telemetry_export.jsonl") -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	for event in _pending:
		file.store_line(JSON.stringify(event))
	file.close()
	return true

func _event_id() -> String:
	return "%s-%s" % [str(Time.get_unix_time_from_system()), str(Time.get_ticks_usec())]

func _local_player_id() -> String:
	var player_data := get_node_or_null("/root/PlayerData")
	if player_data == null:
		return "anonymous"
	return String(player_data.profile.get("id", "anonymous"))

func _anonymous_key(value: String) -> String:
	return ("aj2c2-telemetry-v1:" + value).sha256_text()

func _load_pending() -> void:
	_pending.clear()
	if not FileAccess.file_exists(STORAGE_PATH):
		return
	var file := FileAccess.open(STORAGE_PATH, FileAccess.READ)
	if file == null:
		return
	while not file.eof_reached() and _pending.size() < MAX_PENDING_EVENTS:
		var line := file.get_line().strip_edges()
		if line.is_empty():
			continue
		var parsed = JSON.parse_string(line)
		if parsed is Dictionary:
			_pending.append(parsed)
	file.close()

func _persist_pending() -> void:
	var file := FileAccess.open(STORAGE_PATH, FileAccess.WRITE)
	if file == null:
		return
	for event in _pending:
		file.store_line(JSON.stringify(event))
	file.close()
