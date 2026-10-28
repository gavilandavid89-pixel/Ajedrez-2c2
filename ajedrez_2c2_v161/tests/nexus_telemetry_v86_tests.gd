extends SceneTree

const TelemetryScript = preload("res://domain/competitive/competitive_telemetry_service.gd")
var passed := 0
var failed := 0

func _init() -> void:
	var telemetry := TelemetryScript.new()
	root.add_child(telemetry)
	await process_frame
	telemetry.clear_local_buffer()
	_test_schema(telemetry)
	_test_privacy(telemetry)
	_test_pending_buffer(telemetry)
	print("NEXUS TELEMETRY V86: %d/%d OK" % [passed, passed + failed])
	quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _test_schema(telemetry: Node) -> void:
	var event: Dictionary = telemetry.record_match({
		"competitive":true,"mode":0,"match_id":"m1","timestamp":123,"outcome":"win",
		"rating_before":1000,"rating_after":1015,"rating_delta":15,"opponent_rating_before":1100,
		"expected":0.36,"surprise":0.64,"uncertainty_before":320.0,"uncertainty_after":300.0,
		"nexus_version":2
	},{"reason":"checkmate","move_count":42,"match_minutes":8})
	_ok(not event.is_empty(), "crea evento competitivo")
	_ok(int(event.get("schema_version",0)) == 1, "schema version 1")
	_ok(String(event.get("event_type", "")) == "competitive_match_result", "tipo correcto")
	_ok(String(event.get("mode", "")) == "2c2", "modo 2c2")
	_ok(int(event.get("rating_before",0)) == 1000, "rating antes")
	_ok(float(event.get("expected",0)) > 0.3, "expectativa conservada")

func _test_privacy(telemetry: Node) -> void:
	var event: Dictionary = telemetry.pending_events()[0]
	_ok(not event.has("name"), "no guarda nombre")
	_ok(not event.has("email"), "no guarda email")
	_ok(not event.has("ip"), "no guarda IP")
	_ok(not event.has("replay_data"), "no guarda replay")
	_ok(String(event.get("actor_key", "")).length() == 64, "actor pseudonimizado")

func _test_pending_buffer(telemetry: Node) -> void:
	_ok(telemetry.pending_count() == 1, "evento queda en buffer local")
	_ok(telemetry.server_url == "", "sin servidor no intenta enviar")
