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

    # Case A: the teammate's turn has already begun under delegation.
    game.current_slot = 2
    _check(game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Disconnect of seat whose turn is live is accepted")
    _check(game.current_actor_slot() == 0, "Active teammate receives the live delegated turn")
    _check(game.set_slot_connection_status(2, Policy.STATUS_CONNECTED), "Reconnect during the delegated turn is accepted")
    _check(game.slot_active[2], "Returning teammate is marked connected")
    _check(game.current_actor_slot() == 0, "Returning teammate cannot take back an already assigned turn")
    _check(game.delegated_turn_actor.get(2, -1) == 0, "Turn lock preserves the original delegated actor")

    # The turn lock is cleared only on a real turn advance; when seat 2 comes
    # around again, it is now a normal connected seat.
    game._advance_turn()
    _check(game.current_slot == 3, "Turn advances in the existing 2c2 order")
    _check(not game.delegated_turn_actor.has(2), "Completed delegated turn lock is cleared")
    game.current_slot = 2
    _check(game.current_actor_slot() == 2, "Original player controls the next turn assigned to their seat")

    # Case B: reconnect before the disconnected seat's turn begins. No turn was
    # delegated yet, so the original player keeps the upcoming turn.
    game.current_slot = 0
    _check(game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Second disconnect is accepted before teammate turn")
    _check(game.set_slot_connection_status(2, Policy.STATUS_CONNECTED), "Reconnect before teammate turn is accepted")
    game.current_slot = 2
    _check(game.current_actor_slot() == 2, "Reconnect before turn assignment preserves the upcoming turn")

    # Case C: final result is immutable; reconnect is a route request only.
    var match_id := String(game.match_uid)
    game.finish(-1, "Prueba final")
    var routed_slots: Array[int] = []
    game.terminal_reconnect_requested.connect(func(slot): routed_slots.append(slot))
    _check(not game.set_slot_connection_status(2, Policy.STATUS_CONNECTED), "Reconnect after match end cannot change match state")
    _check(routed_slots == [2], "Reconnect after match end requests final-result routing")
    _check(not game.running and game.team_delegation_policy.is_match_terminal(match_id), "Final result remains terminal after reconnect")
    _check(not game.set_slot_connection_status(2, Policy.STATUS_DISCONNECTED), "Post-match disconnect cannot mutate terminal session")

    print("V120 RECONNECT/TURN/RESULT: %d OK / %d FAILED" % [passed, failed])
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
