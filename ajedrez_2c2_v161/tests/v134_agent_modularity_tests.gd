extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var registry_script = load("res://core/services/qa_agent_registry.gd")
	var registry_check: Dictionary = registry_script.validate_paths()
	_check(bool(registry_check.get("ok", false)), "central registry resolves every agent path")
	_check(registry_script.get_agent_path("touch_observer") == "res://domain/supervision/touch_observer_agent.gd", "touch observer path is owned by registry")
	_check(registry_script.get_agent_path("bundle_exporter") == "res://domain/supervision/qa_bundle_exporter.gd", "bundle exporter path is owned by registry")
	_check(registry_script.get_agent_path("unknown_agent").is_empty(), "unknown agent id fails closed")

	var hub_source := FileAccess.get_file_as_string("res://core/services/supervisor_hub.gd")
	var exporter_source := FileAccess.get_file_as_string("res://domain/supervision/qa_bundle_exporter.gd")
	_check(hub_source.contains("RegistryScript.get_agent_path(\"touch_observer\")"), "hub creates agents through registry rather than direct preload paths")
	_check(not hub_source.contains("preload(\"res://domain/supervision/touch_observer_agent.gd\")"), "hub does not hardcode touch agent file path")
	_check(hub_source.contains("bundle_exporter.export_bundle("), "hub delegates archive creation to dedicated exporter")
	_check(exporter_source.contains("func export_bundle("), "bundle exporter has isolated public contract")
	_check(not exporter_source.contains("get_node_or_null(\"SupervisorHub\")"), "exporter does not depend back on hub")
	_check(not exporter_source.contains("change_scene"), "exporter cannot mutate navigation")
	_check(exporter_source.contains("clampi(max_screenshots, 0, 40)"), "exporter keeps bounded screenshot budget")

	var observer_script = load("res://domain/supervision/touch_observer_agent.gd")
	var observer = observer_script.new(null)
	observer.observe_touch(true, Vector2(100, 100), Vector2i(3, 4), Vector2i(-1, -1), true, "", 0)
	observer.observe_touch(false, Vector2(100, 100), Vector2i(3, 4), Vector2i(3, 4), true, "", 0)
	var second: Dictionary = observer.observe_touch(true, Vector2(101, 100), Vector2i(3, 4), Vector2i(3, 4), true, "", 0)
	_check(bool(second.get("same_square_double_tap", false)), "modularity changes preserve double-tap detection")

	print("V134 AGENT MODULARITY: %d OK / %d FAILED" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[FAIL] " + label)
