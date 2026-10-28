extends SceneTree
const JournalScript = preload("res://domain/supervision/supervisor_journal.gd")
const HubScript = preload("res://core/services/supervisor_hub.gd")
var passed := 0
var failed := 0
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var test_path := "user://v130_bundle_journal.jsonl"
 var journal := JournalScript.new()
 journal.configure_path(test_path)
 journal.record("v130_test", "info", "current_segment_event", {"test": true})
 var backup_path := test_path + ".1"
 var backup := FileAccess.open(backup_path, FileAccess.WRITE)
 backup.store_line(JSON.stringify({"agent":"old_test","severity":"warning","code":"rotated_segment_event","details":{}}))
 backup.close()
 var hub := HubScript.new()
 root.add_child(hub)
 # Hub owns a default journal; set up a focused test journal and export via the hub.
 hub.journal.configure_path(test_path)
 var result: Dictionary = hub.export_qa_bundle(0)
 _check(bool(result.get("ok", false)), "QA bundle exports successfully")
 var zip := ZIPReader.new()
 var open_err := zip.open(String(result.get("path", "")))
 _check(open_err == OK, "QA bundle can be opened")
 if open_err == OK:
  var entries := zip.get_files()
  _check(entries.has("supervisor_diagnostics.jsonl"), "Current diagnostic segment included")
  _check(entries.has("supervisor_diagnostics_previous.jsonl"), "Rotated diagnostic segment included")
  zip.close()
 root.remove_child(hub)
 hub.free()
 DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
 DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
 print("V130 QA BUNDLE ROTATION: %d OK / %d FAILED" % [passed, failed])
 quit(0 if failed == 0 else 1)
func _check(condition: bool, label: String) -> void:
 if condition:
  passed += 1
  print("[OK] " + label)
 else:
  failed += 1
  push_error("[FAIL] " + label)
