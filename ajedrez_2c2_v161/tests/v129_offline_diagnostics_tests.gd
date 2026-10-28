extends SceneTree
const ScreenshotAgentScript = preload("res://domain/supervision/screenshot_supervisor_agent.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var agent = ScreenshotAgentScript.new()
	var result: Dictionary = agent.capture_current_scene("headless_guard_test")
	if OS.has_feature("headless") or DisplayServer.get_name().to_lower() == "headless":
		_check(not bool(result.get("ok", true)), "Headless renderer safely refuses screenshot capture")
		_check(String(result.get("code", "")) == "capture_unavailable_headless", "Headless refusal returns explicit diagnostic code")
	else:
		_check(result.has("ok"), "Graphical capture returns structured result")
	var source := FileAccess.get_file_as_string("res://ui/screens/mode_menu.gd")
	_check(source.contains("_diagnostics_allowed_offline"), "Offline-only guard exists on diagnostics menu")
	_check(source.contains("_export_diagnostics_offline"), "Export action rechecks offline guard")
	_check(source.contains("set_item_disabled(item_index, not allowed)"), "Diagnostics option is disabled when online")
	_check(source.contains("hub.export_qa_bundle(20)"), "Menu exports bounded QA bundle")
	print("V129 OFFLINE DIAGNOSTICS: %d OK / %d FAILED" % [passed, failed])
	for failure in failures: push_error(failure)
	quit(0 if failed == 0 else 1)
func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		failures.append(label)
	print(("[OK] " if ok else "[FAIL] ") + label)
