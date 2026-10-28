extends SceneTree

const HubScript = preload("res://core/services/supervisor_hub.gd")
const JournalScript = preload("res://domain/supervision/supervisor_journal.gd")
const ScreenshotAgentScript = preload("res://domain/supervision/screenshot_supervisor_agent.gd")

var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hub = HubScript.new()
	hub.name = "TestSupervisorHub"
	root.add_child(hub)
	await process_frame
	_check(hub.journal != null, "Hub initializes shared persistent journal")
	_check(hub.match_agent != null and hub.replay_agent != null and hub.interface_agent != null and hub.board_piece_agent != null and hub.screenshot_agent != null, "All five agents are connected through the hub")
	_check(hub.replay_agent.journal == hub.journal and hub.interface_agent.journal == hub.journal and hub.board_piece_agent.journal == hub.journal and hub.screenshot_agent.journal == hub.journal, "Agents share one diagnostic journal")
	var screen_report: Dictionary = hub.report_scene_ready("res://scenes/mode_menu.tscn", false)
	_check(bool(screen_report.get("ok", false)), "Ready screen event accepted by hub")
	_check(hub.interface_agent.current_screen == "res://scenes/mode_menu.tscn", "Interface agent tracks actual ready scene")
	var replay := {"states": [{"board": "rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR"}]}
	var replay_result: Dictionary = hub.audit_replay(replay, [])
	_check(bool(replay_result.get("ok", false)), "Replay audit routed through hub")
	var board: Array = []
	for y in range(8):
		var row: Array[String] = []
		for x in range(8): row.append("")
		board.append(row)
	board[0][4] = "rey_negro"
	board[7][4] = "rey_blanca"
	var board_result: Dictionary = hub.audit_board(board, ["rey_negro", "rey_blanca"], "classic", "classic", Rect2(0, 0, 640, 640), Vector2(720, 1280))
	_check(bool(board_result.get("ok", false)), "Board audit routed through hub")
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.1, 0.2, 0.3, 1.0))
	var captured: Dictionary = hub.screenshot_agent.capture_image(image, "v127_integration", {"screen": "test"})
	_check(bool(captured.get("ok", false)), "Screenshot agent writes an image through shared agent instance")
	_check(hub.recent_diagnostics(100).any(func(e: Dictionary) -> bool: return String(e.get("code", "")) == "scene_ready_reported"), "Hub writes scene lifecycle to diagnostics")
	_check(hub.diagnostics_path() == JournalScript.DEFAULT_PATH, "Diagnostic path remains persistent user:// storage")
	var bundle: Dictionary = hub.export_qa_bundle(2)
	_check(bool(bundle.get("ok", false)), "QA bundle exports diagnostics, manifest, and recent captures")
	var bundle_path := String(bundle.get("path", ""))
	_check(FileAccess.file_exists(bundle_path), "QA export ZIP exists and can be shared by the user")
	var reader := ZIPReader.new()
	var zip_error := reader.open(bundle_path)
	_check(zip_error == OK, "QA export is a readable ZIP archive")
	if zip_error == OK:
		var zip_files := reader.get_files()
		_check(zip_files.has("supervisor_diagnostics.jsonl"), "QA export includes persistent diagnostic log")
		_check(zip_files.has("qa_captures/manifest.jsonl"), "QA export includes screenshot manifest")
		reader.close()
	print("V127 SUPERVISION INTEGRATION: %d OK / %d FAILED" % [passed, failed])
	for failure in failures: push_error(failure)
	hub.queue_free()
	quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[OK] ", label)
	else:
		failed += 1
		failures.append(label)
		print("[FAIL] ", label)
