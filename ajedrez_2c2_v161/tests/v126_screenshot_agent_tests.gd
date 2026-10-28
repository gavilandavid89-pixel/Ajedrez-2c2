extends SceneTree
const JournalScript = preload("res://domain/supervision/supervisor_journal.gd")
const ScreenshotAgentScript = preload("res://domain/supervision/screenshot_supervisor_agent.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var journal = JournalScript.new()
	journal.configure_path("user://v126_screenshot_test_diagnostics.jsonl")
	var agent = ScreenshotAgentScript.new(journal)
	var sub := SubViewport.new()
	sub.size = Vector2i(320, 180)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub.transparent_bg = false
	root.add_child(sub)
	var rect := ColorRect.new()
	rect.color = Color(0.2, 0.4, 0.6, 1.0)
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sub.add_child(rect)
	await process_frame
	await process_frame
	var test_image := Image.create(320, 180, false, Image.FORMAT_RGBA8)
	test_image.fill(Color(0.2, 0.4, 0.6, 1.0))
	var good: Dictionary = agent.capture_image(test_image, "V126 test frame", {"screen": "test", "width_hint": 320, "email": "do-not-store@example.com"})
	_check(bool(good.get("ok", false)), "Agent captures a viewport frame")
	_check(FileAccess.file_exists(String(good.get("path", ""))), "Captured PNG exists on disk")
	var image := Image.load_from_file(String(good.get("path", "")))
	_check(image != null and image.get_width() == 320 and image.get_height() == 180, "Saved screenshot dimensions match viewport")
	_check(FileAccess.file_exists("user://qa_captures/manifest.jsonl"), "Capture manifest persists to disk")
	var manifest_file := FileAccess.open("user://qa_captures/manifest.jsonl", FileAccess.READ)
	var manifest_text := manifest_file.get_as_text() if manifest_file != null else ""
	_check(manifest_text.contains("V126_test_frame") or manifest_text.contains("v126_test_frame"), "Manifest records capture label")
	_check(not manifest_text.contains("do-not-store@example.com"), "Capture metadata filters sensitive fields")
	var bad: Dictionary = agent.capture_viewport(null, "invalid")
	_check(not bool(bad.get("ok", true)), "Missing viewport is reported instead of crashing")
	_check(journal.recent_events(20).any(func(event: Dictionary) -> bool: return event.get("code", "") == "screenshot_captured"), "Successful capture is added to diagnostic journal")
	print("V126 SCREENSHOT AGENT: %d OK / %d FAILED" % [passed, failed])
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
