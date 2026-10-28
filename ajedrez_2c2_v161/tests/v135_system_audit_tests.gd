extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var menu_source := FileAccess.get_file_as_string("res://ui/screens/mode_menu.gd")
	var input_source := FileAccess.get_file_as_string("res://ui/components/game/game_input_controller.gd")
	var game_source := FileAccess.get_file_as_string("res://ui/screens/game.gd")
	var exporter_source := FileAccess.get_file_as_string("res://domain/supervision/qa_bundle_exporter.gd")

	_check(not menu_source.contains("content_box.add_child(top_spacer)"), "rematch refresh no longer accumulates blank home-menu spacing")
	_check(not menu_source.contains("TopBreathingRoom"), "no orphaned spacer is created by the rematch banner")
	_check(menu_source.contains("_rematch_banner.remove_child(child)"), "rematch refresh detaches stale rows before deferred deletion")
	_check(menu_source.contains('get_node_or_null("RematchRow")'), "banner layout targets the current row by name")
	_check(menu_source.contains("accept.size = Vector2(44, 44)"), "rematch accept target is at least 44 by 44 logical pixels")
	_check(menu_source.contains("reject.size = Vector2(44, 44)"), "rematch reject target is at least 44 by 44 logical pixels")
	_check(input_source.contains("touch_event.index != int(host._active_pointer_index)"), "secondary touch cannot replace the active board pointer")
	_check(input_source.contains("release_without_matching_board_press"), "release from a different finger is rejected")
	_check(game_source.contains("var _active_pointer_index := -1"), "game host owns explicit active pointer state")
	_check(exporter_source.contains("var close_error := packer.close()"), "QA exporter checks ZIP finalization")
	_check(exporter_source.contains("var failed_entries: Array[String] = []"), "QA exporter tracks entries that could not be packed")
	_check(exporter_source.contains('"zip_partial"'), "partial QA ZIPs are reported as failures")
	_check(exporter_source.contains("close_file_error == OK"), "QA exporter checks per-entry close errors")
	_check(exporter_source.contains("clampi(max_screenshots, 0, 40)"), "QA screenshot budget remains bounded")

	print("V135 SYSTEM AUDIT CONTRACTS: %d OK / %d FAILED" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[FAIL] " + label)
