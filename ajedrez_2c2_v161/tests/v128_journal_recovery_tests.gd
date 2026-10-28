extends SceneTree
const JournalScript = preload("res://domain/supervision/supervisor_journal.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var path := "user://v128_recovery_test.jsonl"
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path): DirAccess.remove_absolute(absolute)
	var first = JournalScript.new()
	_check(first.configure_path(path), "Test journal path accepted")
	_check(first.record("board_agent", "warning", "piece_texture_missing", {"piece": "rey_negro"}), "Diagnostic written to disk")
	var second = JournalScript.new()
	_check(second.configure_path(path), "Second journal opens same path")
	var events: Array[Dictionary] = second.recent_events(10)
	_check(events.size() == 1, "Previous-session diagnostic recovered into memory")
	_check(String(events[0].get("code", "")) == "piece_texture_missing", "Recovered diagnostic preserves event code")
	_check(second.export_text().contains("piece_texture_missing"), "Recovered event remains exportable")
	_check(second.record("qa_agent", "info", "recovery_verified"), "New session can append after recovery")
	var third = JournalScript.new()
	third.configure_path(path)
	_check(third.recent_events(10).size() == 2, "Second restart recovers both prior and new events")
	print("V128 JOURNAL RECOVERY: %d OK / %d FAILED" % [passed, failed])
	for failure in failures: push_error(failure)
	quit(0 if failed == 0 else 1)
func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		failures.append(label)
	print(("[OK] " if ok else "[FAIL] ") + label)
