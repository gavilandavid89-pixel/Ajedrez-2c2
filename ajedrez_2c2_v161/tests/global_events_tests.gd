extends SceneTree

const GlobalEventsScript = preload("res://core/events/global_events.gd")
const BoardVisualEventsScript = preload("res://core/visual/board_visual_events.gd")
const BoardPieceRendererScript = preload("res://core/visual/board_piece_renderer.gd")
var passed := 0
var failed := 0

func _initialize() -> void:
	var bus := GlobalEventsScript.new()
	root.add_child(bus)
	var received: Array = []
	bus.notification_requested.connect(func(message: String, kind: String, duration: float): received.append([message, kind, duration]))
	bus.notify("  Ready  ", "success", 100.0)
	_check("notification trims message and clamps duration", received.size() == 1 and received[0][0] == "Ready" and received[0][2] == 12.0)
	var context := {"mode": "analysis"}
	var screen_events: Array = []
	bus.screen_entered.connect(func(screen_id: String, payload: Dictionary): screen_events.append([screen_id, payload]))
	bus.enter_screen("analysis", context)
	context["mode"] = "changed"
	_check("screen context is isolated from caller mutation", screen_events.size() == 1 and screen_events[0][1]["mode"] == "analysis")
	_check("operation starts once", bus.begin_operation("engine-review", "Review") and not bus.begin_operation("engine-review", "Duplicate"))
	_check("operation ends once", bus.end_operation("engine-review", true, "done") and not bus.end_operation("engine-review", true))
	_check("blank operation id rejected", not bus.begin_operation("", "bad"))
	var visual_bus := BoardVisualEventsScript.new()
	root.add_child(visual_bus)
	var selected_events: Array[String] = []
	visual_bus.piece_selected.connect(func(_source: String, square: String): selected_events.append(square))
	visual_bus.publish_selection("match", "E2")
	_check("selection event normalizes algebraic square", selected_events.size() == 1 and selected_events[0] == "e2")
	visual_bus.publish_selection("match", "")
	_check("selection event supports explicit deselection", selected_events.size() == 2 and selected_events[1].is_empty())
	var visual_state := {"board": [["peon_blanca"]]}
	var received_states: Array = []
	visual_bus.board_state_changed.connect(func(_source: String, state: Dictionary): received_states.append(state))
	visual_bus.publish_state("match", visual_state)
	visual_state["board"][0][0] = "mutated"
	_check("board event deep-copies nested state", received_states.size() == 1 and received_states[0]["board"][0][0] == "peon_blanca")
	_check("shared piece renderer returns empty size for invalid cell", BoardPieceRendererScript.piece_size(null, 0.0) == Vector2.ZERO)
	var highlight_events: Array = []
	visual_bus.square_highlight_changed.connect(func(source: String, from_square: String, to_square: String, kind: String): highlight_events.append([source, from_square, to_square, kind]))
	visual_bus.publish_highlight("replay", " E2 ", "e4", "suggestion")
	visual_bus.publish_highlight("replay", "bad", "e4", "suggestion")
	visual_bus.publish_highlight("unknown", "e2", "e4", "suggestion")
	_check("highlight events normalize squares and reject malformed sources/squares", highlight_events.size() == 1 and highlight_events[0] == ["replay", "e2", "e4", "suggestion"])
	var interactions: Array = []
	visual_bus.board_interaction_changed.connect(func(source: String, selected_square: String, destinations: Array): interactions.append([source, selected_square, destinations]))
	visual_bus.publish_interaction("match", "E2", ["e4", "E4", "bad", "d4"])
	_check("interaction event normalizes and deduplicates legal destinations", interactions.size() == 1 and interactions[0][1] == "e2" and interactions[0][2] == ["e4", "d4"])
	var move_commits: Array = []
	visual_bus.move_committed.connect(func(source: String, move: Dictionary): move_commits.append(move))
	var move_payload := {"from": "e2", "to": "e4", "metadata": {"san": "e4"}}
	visual_bus.publish_move_committed("match", move_payload)
	move_payload["metadata"]["san"] = "changed"
	_check("committed move payload is deeply copied", move_commits.size() == 1 and move_commits[0]["metadata"]["san"] == "e4")
	var focus_events: Array[String] = []
	visual_bus.board_focus_requested.connect(func(_source: String, square: String): focus_events.append(square))
	visual_bus.request_focus("analysis", "G8")
	visual_bus.request_focus("analysis", "z9")
	_check("focus request accepts only valid chess squares", focus_events == ["g8"])
	print("GLOBAL EVENTS: %d OK / %d FAIL" % [passed, failed])
	quit(0 if failed == 0 else 1)

func _check(label: String, condition: bool) -> void:
	if condition:
		passed += 1
		print("  OK: ", label)
	else:
		failed += 1
		push_error("  FAIL: " + label)
