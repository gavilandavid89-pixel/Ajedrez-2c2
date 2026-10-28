extends SceneTree

const MatchContextScript = preload("res://core/context/match_context_service.gd")
const MatchEventsScript = preload("res://core/events/match_events.gd")
const PlayerHeaderScript = preload("res://ui/components/player/player_header.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var context := MatchContextScript.new()
	root.add_child(context)
	context.begin_match({"match_id": "test-match", "white_player": {"name": "Blancas", "rating": 1200}, "black_player": {"name": "Negras", "rating": 1250}, "white_time": 300.0, "black_time": 280.0})
	_check(context.player("white").get("name") == "Blancas", "global context stores white player metadata")
	_check(context.player("black").get("rating") == 1250, "global context stores black rating")
	context.update_player("white", {"avatar": "res://assets/avatars/avatar_you.svg"})
	_check(context.player("white").get("name") == "Blancas", "partial player update preserves existing name")
	context.record_move_clock(3, 271.0, 280.0, "black")
	_check(context.clock_history().size() == 1, "clock history records a move snapshot")
	var snapshot := context.snapshot()
	snapshot.players.white.name = "mutated"
	_check(context.player("white").get("name") == "Blancas", "snapshot is a defensive copy")
	var events := MatchEventsScript.new()
	root.add_child(events)
	var observed := [false]
	events.player_updated.connect(func(color: String, _data: Dictionary): observed[0] = color == "white")
	events.publish_player("white", {"name": "Blancas"})
	_check(observed[0], "global player event is emitted")
	var header := PlayerHeaderScript.new()
	root.add_child(header)
	header.set_player_data({"id": "you", "name": "Blancas", "rating": 1200})
	header.set_clock(91.0, true)
	_check(header.clock_label.text == "1:31" and header.rating_label.text == "1200 Elo", "shared player header renders rating and clock")
	print("MATCH CONTEXT GLOBAL TESTS: %d OK / %d FALLARON" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[OK] " + label)
	else:
		failed += 1
		push_error("[FALLA] " + label)
