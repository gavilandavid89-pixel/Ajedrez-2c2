extends RefCounted
class_name InterfaceSupervisorAgent

var journal: SupervisorJournal
var current_screen := ""
var last_screen_change_unix := 0
var issue_counts: Dictionary = {}

func _init(shared_journal: SupervisorJournal = null) -> void:
	journal = shared_journal

func report_screen(screen_id: String, context: Dictionary = {}) -> bool:
	var screen := screen_id.strip_edges()
	if screen.is_empty():
		return report_issue("empty_screen_id", "Navigation reported an empty screen id")
	if screen == current_screen:
		return true
	var previous := current_screen
	current_screen = screen
	last_screen_change_unix = int(Time.get_unix_time_from_system())
	if journal != null:
		return journal.record("interface_agent", "info", "screen_changed", {"from_screen": previous, "to_screen": screen, "context_keys": context.keys()})
	return true

func report_issue(code: String, details: String, severity: String = "warning") -> bool:
	var issue_code := code.strip_edges()
	if issue_code.is_empty():
		issue_code = "unspecified_ui_issue"
	issue_counts[issue_code] = int(issue_counts.get(issue_code, 0)) + 1
	if journal == null:
		return false
	return journal.record("interface_agent", severity, issue_code, {"screen": current_screen, "details": details, "occurrences": issue_counts[issue_code]})

func report_layout_check(screen_id: String, viewport_size: Vector2, minimum_touch_target: float, overlap_detected: bool, clipped_content: bool) -> bool:
	var has_issue := overlap_detected or clipped_content or minimum_touch_target < 40.0 or viewport_size.x <= 0.0 or viewport_size.y <= 0.0
	if not has_issue:
		if journal != null:
			journal.record("interface_agent", "info", "layout_check_passed", {"screen": screen_id, "width": viewport_size.x, "height": viewport_size.y})
		return true
	report_issue("layout_regression", "overlap=%s clipped=%s touch_target=%.1f viewport=%.0fx%.0f" % [str(overlap_detected), str(clipped_content), minimum_touch_target, viewport_size.x, viewport_size.y], "error")
	return false
