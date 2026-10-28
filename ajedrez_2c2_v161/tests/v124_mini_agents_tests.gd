extends SceneTree
const JournalScript = preload("res://domain/supervision/supervisor_journal.gd")
const ReplayAgentScript = preload("res://domain/supervision/replay_supervisor_agent.gd")
const InterfaceAgentScript = preload("res://domain/supervision/interface_supervisor_agent.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var journal = JournalScript.new()
	var temp_path := "user://v124_test_diagnostics.jsonl"
	journal.configure_path(temp_path)
	_check(journal.record("test_agent", "info", "test_event", {"safe": 3, "email": "private@example.com", "board": "array"}), "Journal writes persistent diagnostic event")
	var text := journal.export_text()
	_check(text.contains("test_event"), "Journal can read exported diagnostic log")
	_check(not text.contains("private@example.com"), "Journal excludes sensitive email detail")
	_check(journal.recent_events(1).size() == 1, "Journal exposes recent in-memory events")

	var replay_agent = ReplayAgentScript.new(journal)
	var good_replay := {"states": [{"board": "rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR"}, {"board": "rnbqkbnrpppppppp................................PPPPPPPPRNBQKBNR"}]}
	var good_moves: Array = [{"from": "e2", "to": "e4"}]
	var good_audit: Dictionary = replay_agent.inspect_replay(good_replay, good_moves)
	_check(bool(good_audit.get("ok", false)), "Replay agent accepts structurally complete replay")
	var bad_audit: Dictionary = replay_agent.inspect_replay({"states": [{"board": "short"}]}, [{"from": "z9", "to": "e4"}])
	_check(not bool(bad_audit.get("ok", true)), "Replay agent detects malformed board and coordinates")
	_check(bad_audit.get("issues", []).size() >= 2, "Replay agent returns actionable issue list")

	var ui_agent = InterfaceAgentScript.new(journal)
	_check(ui_agent.report_screen("home"), "Interface agent accepts screen transition")
	_check(ui_agent.report_screen("home"), "Repeated screen report is idempotent")
	_check(not ui_agent.report_layout_check("match", Vector2(720, 720), 32.0, true, false), "Interface agent detects overlap and undersized touch targets")
	_check(int(ui_agent.issue_counts.get("layout_regression", 0)) == 1, "Interface issue occurrence counter increments")
	_check(journal.recent_events(20).size() >= 5, "Agents share one diagnostic journal")

	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	print("V124 MINI AGENTS: %d OK / %d FAILED" % [passed, failed])
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
