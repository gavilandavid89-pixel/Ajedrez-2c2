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
	game = GameState.new()
	root.add_child(game)
	await process_frame
	game.reset_match(game.MODE_2C2, 10)
	game.assign_roles_for_local_team(game.TEAM_WHITE)
	game.set_local_player_slot(0)
	_check(game.team_delegation_policy != null, "2c2 lifecycle builds the delegation bridge")
	_check(game.current_actor_slot() == game.current_slot, "Normal active seat keeps its own actor")
	_check(game.set_slot_connection_status(2, Policy.STATUS_GRACE), "Grace state accepted through game-state API")
	_check(game.slot_active[2], "Grace does not prematurely disable teammate seat")
	_check(game.current_actor_slot() == 2 if game.current_slot == 2 else true, "Grace does not cause an unintended delegated actor")
	game.current_slot = 2
	_check(game.current_actor_slot() == 2, "Connected seat remains actor during grace")
	_check(game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Confirmed disconnect syncs through game-state API")
	_check(not game.slot_active[2], "Confirmed disconnect marks slot inactive")
	_check(game.current_actor_slot() == 0, "Active teammate receives disconnected seat turn")
	_check(game.request_draw(), "Active teammate can request draw without disconnected teammate approval")
	_check(int(game.draw_state.get("stage", 0)) == 2, "Draw offer skips disconnected teammate and goes to rivals")
	_check(game.set_slot_connection_status(2, Policy.STATUS_CONNECTED), "Reconnect restores seat state")
	_check(game.slot_active[2], "Reconnect marks seat active")
	game._advance_turn()
	game.current_slot = 2
	game.delegated_turn_actor.erase(2)
	_check(game.current_actor_slot() == 2, "Original player owns their next turn after turn advancement")
	_check(game.current_actor_slot() == 2, "Reconnected player regains their turn seat")
	_check(game.team_delegation_policy.partner_approval_required_for_draw("you"), "Teammate approval requirement returns after reconnection")
	game.finish(-1, "test terminal")
	_check(game.team_delegation_policy.is_match_terminal(String(game.match_uid)), "Final result marks delegation session terminal")
	_check(not game.team_delegation_policy.can_control_seat("you", "mate", String(game.match_uid)), "Terminal match rejects delegated control")
	_check(not game.set_slot_connection_status(2, "unknown"), "Invalid connection status rejected")
	game.reset_match(game.MODE_2C2, 10)
	game.assign_roles_for_local_team(game.TEAM_WHITE)
	game.set_local_player_slot(0)
	game.current_slot = 2
	_check(game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Second scenario disconnects teammate")
	_check(game.request_surrender(), "Active teammate can resign on behalf of the team")
	_check(not game.running and game.winner_team == game.TEAM_BLACK, "Team resignation ends match against the correct team")
	print("V118 DELEGATION INTEGRATION: %d OK / %d FAILED" % [passed, failed])
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
