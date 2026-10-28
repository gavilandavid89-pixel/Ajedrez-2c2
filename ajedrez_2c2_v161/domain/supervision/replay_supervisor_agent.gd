extends RefCounted
class_name ReplaySupervisorAgent

const PIECE_CODES := "PRNBQKprnbqk."
var journal: SupervisorJournal

func _init(shared_journal: SupervisorJournal = null) -> void:
	journal = shared_journal

## Structural audit only: this agent does not claim to prove chess legality.
func inspect_replay(replay: Dictionary, moves: Array) -> Dictionary:
	var issues: Array[String] = []
	var states: Variant = replay.get("states", null)
	if replay.is_empty():
		issues.append("empty_replay")
	elif not (states is Array):
		issues.append("states_not_array")
	else:
		if states.is_empty():
			issues.append("no_states")
		if states.size() < moves.size() + 1:
			issues.append("missing_position_after_move")
		if states.size() > 401:
			issues.append("state_limit_exceeded")
		for i in range(states.size()):
			if not (states[i] is Dictionary):
				issues.append("state_%d_not_dictionary" % i)
				continue
			var board := String(states[i].get("board", ""))
			if board.length() != 64:
				issues.append("state_%d_bad_board_length" % i)
				continue
			for j in range(board.length()):
				if not PIECE_CODES.contains(board.substr(j, 1)):
					issues.append("state_%d_invalid_piece_code" % i)
					break
	for i in range(moves.size()):
		if not (moves[i] is Dictionary):
			issues.append("move_%d_not_dictionary" % i)
			continue
		var move: Dictionary = moves[i]
		if not _valid_square(String(move.get("from", ""))) or not _valid_square(String(move.get("to", ""))):
			issues.append("move_%d_bad_coordinates" % i)
		if issues.size() >= 32:
			break
	var result := {"ok": issues.is_empty(), "issues": issues, "state_count": states.size() if states is Array else 0, "move_count": moves.size(), "structural_only": true}
	if journal != null:
		journal.record("replay_agent", "error" if not issues.is_empty() else "info", "replay_audit", {"ok": issues.is_empty(), "issue_count": issues.size(), "state_count": result.state_count, "move_count": moves.size(), "first_issue": issues[0] if not issues.is_empty() else "none"})
	return result

func _valid_square(square: String) -> bool:
	return square.length() == 2 and square[0] >= "a" and square[0] <= "h" and square[1] >= "1" and square[1] <= "8"
