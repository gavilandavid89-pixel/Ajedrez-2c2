extends SceneTree

const GameState = preload("res://domain/chess/game_state.gd")
const Policy = preload("res://domain/online/team_control_delegation.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []
var game

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var policy = Policy.new()
	_check(policy.register_team("white", "p0", "p2"), "Transition test team registers")
	_check(policy.set_player_status("p2", Policy.STATUS_GRACE), "Connected to grace is valid")
	_check(policy.set_player_status("p2", Policy.STATUS_DISCONNECTED), "Grace to disconnected is valid")
	_check(not policy.set_player_status("p2", Policy.STATUS_GRACE), "Stale grace event cannot overwrite confirmed disconnect")
	_check(policy.can_control_seat("p0", "p2"), "Stale grace event cannot revoke teammate delegation")
	_check(policy.set_player_status("p2", Policy.STATUS_CONNECTED), "Disconnected to connected is valid reconnection")
	_check(not policy.can_control_seat("p0", "p2"), "Reconnect revokes teammate delegation")

	game = GameState.new()
	root.add_child(game)
	await process_frame
	game.reset_match(game.MODE_2C2, 10)
	game.assign_roles_for_local_team(game.TEAM_WHITE)
	game.set_local_player_slot(0)
	game.current_slot = 2
	_check(game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Match bridge confirms disconnect")
	_check(game.current_actor_slot() == 0, "Active teammate is delegated actor")
	_check(game.request_draw(), "Active teammate can offer draw during delegated turn")
	_check(int(game.draw_state.get("stage", 0)) == 2, "Draw offer skips disconnected teammate")
	_check(game.set_slot_connection_status(2, Policy.STATUS_CONNECTED), "Teammate reconnects while draw is pending")
	_check(int(game.draw_state.get("stage", 0)) == 2, "Reconnect does not erase pending draw offer")
	_check(game.slot_active[2], "Reconnected seat is active again")
	_check(game.current_actor_slot() == 0, "Reconnect during delegated turn does not steal the already assigned turn")
	game._advance_turn()
	game.current_slot = 2
	game.delegated_turn_actor.erase(2)
	_check(game.current_actor_slot() == 2, "Original player controls the next unassigned turn")
	_check(game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Second disconnect can occur in the same match")
	_check(not game.set_slot_connection_status(2, Policy.STATUS_GRACE), "Delayed grace event cannot overwrite second confirmed disconnect")
	_check(not game.slot_active[2], "Rejected stale event leaves seat delegated/inactive")

	var old_uid := String(game.match_uid)
	game.finish(-1, "draw test terminal")
	_check(not game.running, "Terminal transition stops match")
	_check(game.team_delegation_policy.is_match_terminal(old_uid), "Terminal state is reflected in delegation policy")
	var terminal_reconnects := []
	game.terminal_reconnect_requested.connect(func(slot): terminal_reconnects.append(slot))
	_check(not game.set_slot_connection_status(2, Policy.STATUS_CONNECTED), "Late reconnect does not mutate a terminal match")
	_check(terminal_reconnects == [2], "Late reconnect requests navigation to the final result screen")
	_check(not game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Late disconnect event is rejected after match termination")
	_check(not game.team_delegation_policy.can_control_seat("you", "mate", old_uid), "No delegated control after terminal transition")

	game.reset_match(game.MODE_2C2, 10)
	game.assign_roles_for_local_team(game.TEAM_WHITE)
	game.set_local_player_slot(0)
	game.current_slot = 2
	_check(game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "New match starts with independent connection state")
	_check(game.request_surrender(), "Active teammate may resign for disconnected teammate's team")
	_check(not game.running, "Team resignation ends match")
	_check(not game.set_slot_connection_status(2, Policy.STATUS_CONNECTED), "Reconnect cannot reopen a surrendered match")

	print("V119 TRANSITION RACES: %d OK / %d FAILED" % [passed, failed])
	for failure in failures:
		push_error(failure)
	game.queue_free()
	quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[OK] ", label)
	else:
		failed += 1
		failures.append(label)
		print("[FAIL] ", label)
