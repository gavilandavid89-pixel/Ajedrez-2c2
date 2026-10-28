extends SceneTree

const Delegation = preload("res://domain/online/team_control_delegation.gd")
var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var d = Delegation.new()
	_check(not d.register_team("", "a", "b"), "Empty team ID rejected")
	_check(not d.register_team("red", "a", "a"), "Same player cannot occupy both seats")
	_check(d.register_team("red", "a", "b"), "Valid 2v2 team registers")
	_check(not d.register_team("blue", "b", "c"), "Player cannot be assigned to two teams")
	_check(not d.register_team("red", "c", "d"), "Duplicate team ID rejected")
	_check(d.can_control_seat("a", "a"), "Connected player controls own seat")
	_check(not d.can_control_seat("a", "b"), "Connected partner cannot control partner seat normally")
	_check(d.set_player_status("b", Delegation.STATUS_GRACE), "Grace state accepted")
	_check(not d.can_control_seat("a", "b"), "Grace period does not transfer control prematurely")
	_check(d.can_request_draw("a"), "Connected player can initiate draw request")
	_check(d.partner_approval_required_for_draw("a"), "Partner approval remains required during grace")
	_check(d.set_player_status("b", Delegation.STATUS_DISCONNECTED), "Confirmed disconnect accepted")
	_check(d.can_control_seat("a", "b"), "Active partner temporarily controls disconnected seat")
	_check(d.can_request_draw("a"), "Active partner can request draw alone")
	_check(not d.partner_approval_required_for_draw("a"), "Disconnected partner approval is bypassed")
	_check(d.can_resign_team("a"), "Active partner may resign for team")
	_check(not d.can_control_seat("c", "a"), "Opponent cannot control other team seat")
	_check(not d.can_control_seat("b", "b"), "Disconnected player cannot issue actions")
	_check(d.set_player_status("b", Delegation.STATUS_CONNECTED), "Reconnect restores partner connection state")
	_check(d.can_control_seat("b", "b"), "Reconnected partner regains own seat")
	_check(not d.can_control_seat("a", "b"), "Active partner loses delegated control after reconnect")
	_check(d.partner_approval_required_for_draw("a"), "Partner approval requirement restored after reconnect")
	_check(not d.set_player_status("missing", Delegation.STATUS_CONNECTED), "Unknown player status cannot be changed")
	_check(not d.set_player_status("a", "unknown"), "Unknown connection status rejected")
	_check(d.set_match_terminal("match-1"), "Match can be marked terminal once")
	_check(not d.set_match_terminal("match-1"), "Terminal transition is idempotent")
	_check(not d.can_control_seat("a", "a", "match-1"), "No move control after match ends")
	_check(not d.can_request_draw("a", "match-1"), "No draw action after match ends")
	_check(not d.can_resign_team("a", "match-1"), "No resignation action after match ends")
	_check(not d.can_control_seat("unknown", "a"), "Unknown actor rejected")
	_check(d.partner_of("a") == "b" and d.partner_of("b") == "a", "Partner lookup is symmetric")
	_check(d.partner_of("missing").is_empty(), "Unknown partner lookup is empty")
	print("V117 TEAM CONTROL DELEGATION: %d OK / %d FAILED" % [passed, failed])
	for failure in failures:
		push_error(failure)
	quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[OK] ", label)
	else:
		failed += 1
		failures.append(label)
		print("[FAIL] ", label)
