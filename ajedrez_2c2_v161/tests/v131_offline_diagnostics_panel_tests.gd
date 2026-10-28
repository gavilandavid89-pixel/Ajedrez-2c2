extends SceneTree
var passed := 0
var failed := 0
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var source := FileAccess.get_file_as_string("res://ui/screens/mode_menu.gd")
 _check(source.contains("OfflineDiagnosticsPanel"), "Offline diagnostics opens a readable panel")
 _check(source.contains("hub.recent_diagnostics(20)"), "Panel shows bounded recent diagnostics")
 _check(source.contains("Exportar paquete QA"), "Panel exposes a manual QA export action")
 _check(source.contains("_export_qa_bundle_offline()"), "Export uses a dedicated offline action")
 _check(source.contains("if not _diagnostics_allowed_offline()"), "Offline guard is rechecked at action time")
 _check(source.contains("JSON.stringify(details)"), "Panel shows event context for investigation")
 print("V131 OFFLINE DIAGNOSTICS PANEL: %d OK / %d FAILED" % [passed, failed])
 quit(0 if failed == 0 else 1)
func _check(ok: bool, label: String) -> void:
 if ok: passed += 1
 else:
  failed += 1
  push_error("[FAIL] " + label)
