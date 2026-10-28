extends RefCounted
class_name TeamControlDelegation

## Pure policy for temporary 2v2 teammate control while the backend is unavailable.
## A future server must authenticate actor_id and own connection state; this class is not networking.
const STATUS_CONNECTED := "connected"
const STATUS_GRACE := "grace_period"
const STATUS_DISCONNECTED := "disconnected"
const ACTION_MOVE := "move"
const ACTION_REQUEST_DRAW := "request_draw"
const ACTION_RESIGN_TEAM := "resign_team"

var teams: Dictionary = {}
var player_team: Dictionary = {}
var player_status: Dictionary = {}
var terminal_match_ids: Dictionary = {}

func register_team(team_id: String, player_a: String, player_b: String) -> bool:
	var tid := team_id.strip_edges()
	var a := player_a.strip_edges()
	var b := player_b.strip_edges()
	if tid.is_empty() or a.is_empty() or b.is_empty() or a == b or teams.has(tid):
		return false
	if player_team.has(a) or player_team.has(b):
		return false
	teams[tid] = {"players": [a, b], "active": true}
	player_team[a] = tid
	player_team[b] = tid
	player_status[a] = STATUS_CONNECTED
	player_status[b] = STATUS_CONNECTED
	return true

## Only trusted session/disconnection code should call this method.
func set_player_status(player_id: String, status: String) -> bool:
	var pid := player_id.strip_edges()
	if not player_team.has(pid):
		return false
	if status not in [STATUS_CONNECTED, STATUS_GRACE, STATUS_DISCONNECTED]:
		return false
	var previous := String(player_status.get(pid, STATUS_CONNECTED))
	# Connection transitions must not move backwards because of delayed events:
	# once confirmed disconnected, a stale grace heartbeat cannot revoke delegation.
	if previous == STATUS_DISCONNECTED and status == STATUS_GRACE:
		return false
	player_status[pid] = status
	return true

func set_match_terminal(match_id: String) -> bool:
	var mid := match_id.strip_edges()
	if mid.is_empty() or terminal_match_ids.has(mid):
		return false
	terminal_match_ids[mid] = true
	return true

func is_match_terminal(match_id: String) -> bool:
	return terminal_match_ids.has(match_id.strip_edges())

func partner_of(player_id: String) -> String:
	var pid := player_id.strip_edges()
	if not player_team.has(pid):
		return ""
	var team: Dictionary = teams.get(String(player_team[pid]), {})
	for member in team.get("players", []):
		if String(member) != pid:
			return String(member)
	return ""

func can_control_seat(actor_id: String, seat_owner_id: String, match_id: String = "") -> bool:
	var actor := actor_id.strip_edges()
	var owner := seat_owner_id.strip_edges()
	if actor.is_empty() or owner.is_empty() or not player_team.has(actor) or not player_team.has(owner):
		return false
	if not match_id.strip_edges().is_empty() and is_match_terminal(match_id):
		return false
	if String(player_team[actor]) != String(player_team[owner]):
		return false
	if String(player_status.get(actor, STATUS_DISCONNECTED)) != STATUS_CONNECTED:
		return false
	if actor == owner:
		return true
	return String(player_status.get(owner, STATUS_CONNECTED)) == STATUS_DISCONNECTED

func can_request_draw(actor_id: String, match_id: String = "") -> bool:
	if not _is_connected_team_member(actor_id) or (not match_id.strip_edges().is_empty() and is_match_terminal(match_id)):
		return false
	# A connected teammate may request a draw even if the partner is in grace;
	# partner approval is only bypassed once the partner is confirmed disconnected.
	return true

func partner_approval_required_for_draw(actor_id: String) -> bool:
	if not _is_connected_team_member(actor_id):
		return true
	var partner := partner_of(actor_id)
	return String(player_status.get(partner, STATUS_DISCONNECTED)) != STATUS_DISCONNECTED

func can_resign_team(actor_id: String, match_id: String = "") -> bool:
	return _is_connected_team_member(actor_id) and (match_id.strip_edges().is_empty() or not is_match_terminal(match_id))

func _is_connected_team_member(player_id: String) -> bool:
	var pid := player_id.strip_edges()
	return player_team.has(pid) and String(player_status.get(pid, STATUS_DISCONNECTED)) == STATUS_CONNECTED
