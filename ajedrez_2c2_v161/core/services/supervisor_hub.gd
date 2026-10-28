extends Node

## Shared deterministic mini-agent hub. Agents report observations; authoritative
## game services remain responsible for changing match state and final results.
const RegistryScript = preload("res://core/services/qa_agent_registry.gd")
const SCREENSHOT_MANIFEST_PATH := "user://qa_captures/manifest.jsonl"
const SCREENSHOT_CAPTURE_DIR := "user://qa_captures"
const SESSION_MARKER_PATH := "user://qa_session_active.json"
var _shutdown_report_written := false
var _last_scene_path := "unknown"

var journal: SupervisorJournal
var replay_agent: ReplaySupervisorAgent
var interface_agent: InterfaceSupervisorAgent
var board_piece_agent: BoardPieceSupervisorAgent
var screenshot_agent: ScreenshotSupervisorAgent
var touch_observer: TouchObserverAgent
var match_agent: MatchSupervisor
var bundle_exporter: QABundleExporter

func _ready() -> void:
	var registry_check: Dictionary = RegistryScript.validate_paths()
	if not bool(registry_check.get("ok", false)):
		push_error("QA agent registry has missing paths: %s" % str(registry_check.get("missing_agents", [])))
	journal = load(RegistryScript.get_agent_path("journal")).new()
	replay_agent = load(RegistryScript.get_agent_path("replay")).new(journal)
	interface_agent = load(RegistryScript.get_agent_path("interface")).new(journal)
	board_piece_agent = load(RegistryScript.get_agent_path("board_piece")).new(journal)
	screenshot_agent = load(RegistryScript.get_agent_path("screenshot")).new(journal)
	touch_observer = load(RegistryScript.get_agent_path("touch_observer")).new(journal)
	match_agent = load(RegistryScript.get_agent_path("match")).new()
	bundle_exporter = load(RegistryScript.get_agent_path("bundle_exporter")).new()
	match_agent.configure_journal(journal)
	journal.record("supervisor_hub", "info", "agents_initialized", {"agents": ["match", "replay", "interface", "board_piece", "screenshot", "touch_observer", "journal", "bundle_exporter"], "registry_version": RegistryScript.REGISTRY_VERSION, "registry_valid": bool(registry_check.get("ok", false)), "version": 141})
	_begin_session_watch()
	call_deferred("_capture_initial_scene")


func _begin_session_watch() -> void:
	# A hard crash cannot execute shutdown callbacks. Keep a tiny marker so the
	# next launch can recognize the previous session and export its saved journal.
	if FileAccess.file_exists(SESSION_MARKER_PATH):
		journal.record("supervisor_hub", "error", "previous_session_ended_uncleanly", {"marker": SESSION_MARKER_PATH, "recovery": "automatic_bundle_on_start"})
		call_deferred("_export_recovered_session_bundle")
	var marker := FileAccess.open(SESSION_MARKER_PATH, FileAccess.WRITE)
	if marker != null:
		marker.store_string(JSON.stringify({"started_unix": int(Time.get_unix_time_from_system()), "godot": Engine.get_version_info().get("string", "unknown")}))
		marker.flush()

func _export_recovered_session_bundle() -> void:
	if bundle_exporter == null:
		return
	var result := export_qa_bundle(20)
	journal.record("supervisor_hub", "info" if bool(result.get("ok", false)) else "error", "recovered_session_bundle_result", {"ok": bool(result.get("ok", false)), "code": result.get("code", "ok"), "path": result.get("path", "user://qa_supervisor_bundle.zip")})

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_write_shutdown_report()

func _write_shutdown_report() -> void:
	if _shutdown_report_written or journal == null:
		return
	_shutdown_report_written = true
	journal.record("supervisor_hub", "info", "session_shutdown_report", {"timestamp_unix": int(Time.get_unix_time_from_system()), "scene": _last_scene_path})
	var result := export_qa_bundle(20)
	if not bool(result.get("ok", false)):
		journal.record("supervisor_hub", "error", "automatic_shutdown_bundle_failed", {"code": result.get("code", "unknown"), "error": result.get("error", -1)})
	# Reaching this callback means a normal close was observed. A crash leaves the
	# marker behind; the next launch then labels and exports the interrupted run.
	if FileAccess.file_exists(SESSION_MARKER_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_MARKER_PATH))

func observe_touch(pressed: bool, screen_position: Vector2, logical_square: Vector2i, selected_square: Vector2i, running: bool, blocked_reason: String = "", pointer_index: int = 0) -> Dictionary:
	if touch_observer == null:
		return {}
	return touch_observer.observe_touch(pressed, screen_position, logical_square, selected_square, running, blocked_reason, pointer_index)

func observe_touch_result(code: String, selected_before: Vector2i, selected_after: Vector2i, move_count_before: int, move_count_after: int, suggestion_mode: bool) -> void:
	if touch_observer != null:
		touch_observer.observe_result(code, selected_before, selected_after, move_count_before, move_count_after, suggestion_mode)

func touch_observer_summary() -> Dictionary:
	return touch_observer.summary() if touch_observer != null else {}

func record_runtime_error(source: String, message: String, details: Dictionary = {}) -> bool:
	var entry := details.duplicate(true)
	entry["source"] = source
	entry["message"] = message
	return journal.record("runtime", "error", "runtime_error", entry)

func diagnostics_path() -> String:
	return journal.log_path if journal != null else "user://supervisor_diagnostics.jsonl"

func recent_diagnostics(limit: int = 20) -> Array[Dictionary]:
	return journal.recent_events(limit) if journal != null else []

func export_diagnostics_text() -> String:
	return journal.export_text() if journal != null else ""



func _capture_initial_scene() -> void:
	# The configured main scene does not pass through App.change_scene(), so
	# explicitly observe it once the first frame has entered the tree.
	await get_tree().process_frame
	var scene := get_tree().current_scene
	if scene == null:
		journal.record("supervisor_hub", "warning", "initial_scene_unavailable", {})
		return
	var path := scene.scene_file_path
	if not path.is_empty():
		_last_scene_path = path
		report_scene_ready(path, not OS.has_feature("headless"))

func export_qa_bundle(max_screenshots: int = 12) -> Dictionary:
	if bundle_exporter == null:
		journal.record("supervisor_hub", "error", "qa_bundle_exporter_unavailable", {})
		return {"ok": false, "code": "qa_bundle_exporter_unavailable"}
	var rotated_log_path := journal.log_path + ".1"
	return bundle_exporter.export_bundle(
		journal,
		export_diagnostics_text(),
		rotated_log_path,
		SCREENSHOT_MANIFEST_PATH,
		SCREENSHOT_CAPTURE_DIR,
		touch_observer_summary(),
		max_screenshots
	)

func report_scene_ready(scene_path: String, take_capture: bool = true) -> Dictionary:
	var result := {"ok": true, "scene_path": scene_path, "capture": {"ok": false, "code": "capture_disabled"}}
	if scene_path.strip_edges().is_empty():
		journal.record("supervisor_hub", "error", "scene_ready_empty_path", {})
		return {"ok": false, "code": "empty_scene_path"}
	_last_scene_path = scene_path
	if interface_agent != null:
		interface_agent.report_screen(scene_path, {"transition": "completed"})
	if take_capture and screenshot_agent != null:
		var capture: Dictionary = capture_screen("screen_" + scene_path.get_file().get_basename(), {"scene_path": scene_path, "capture_reason": "scene_ready"})
		result["capture"] = capture
		if not bool(capture.get("ok", false)):
			journal.record("supervisor_hub", "warning", "scene_capture_failed", {"scene_path": scene_path, "code": capture.get("code", "unknown")})
	journal.record("supervisor_hub", "info", "scene_ready_reported", {"scene_path": scene_path, "capture_requested": take_capture})
	return result

func audit_replay(replay: Dictionary, moves: Array) -> Dictionary:
	if replay_agent == null:
		return {"ok": false, "issues": ["replay_agent_unavailable"]}
	return replay_agent.inspect_replay(replay, moves)

func audit_board(board: Variant, texture_keys: Array, theme_id: String, piece_set_id: String, board_rect: Rect2, viewport_size: Vector2) -> Dictionary:
	if board_piece_agent == null:
		return {"ok": false, "issues": ["board_agent_unavailable"]}
	return board_piece_agent.inspect_board(board, texture_keys, theme_id, piece_set_id, board_rect, viewport_size)

func capture_screen(label: String, metadata: Dictionary = {}) -> Dictionary:
	if screenshot_agent == null:
		return {"ok": false, "code": "screenshot_agent_unavailable"}
	return screenshot_agent.capture_current_scene(label, metadata)
