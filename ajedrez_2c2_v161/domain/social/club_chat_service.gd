extends Node

const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")

signal changed()

var messages_by_club: Dictionary = {}
var challenges_by_club: Dictionary = {}
var matches_by_club: Dictionary = {}
const MAX_CHAT_ITEMS := 80
const TEAM_WHITE := 0
const TEAM_BLACK := 1

func _local_identity() -> Dictionary:
	var player_data := RuntimeServicesScript.get_autoload("PlayerData")
	if player_data != null:
		return {
			"id": String(player_data.profile.get("id", "local_player")),
			"name": String(player_data.profile.get("name", "Jugador")),
			"icon": "♟",
		}
	return {"id": "local_player", "name": "Jugador", "icon": "♟"}

func _messages(club_id: String) -> Array:
	if not messages_by_club.has(club_id):
		messages_by_club[club_id] = []
	return messages_by_club[club_id]

func _challenges(club_id: String) -> Array:
	if not challenges_by_club.has(club_id):
		challenges_by_club[club_id] = []
	return challenges_by_club[club_id]

func _matches(club_id: String) -> Array:
	if not matches_by_club.has(club_id):
		matches_by_club[club_id] = []
	return matches_by_club[club_id]

func _trim_messages(club_id: String) -> void:
	var list := _messages(club_id)
	if list.size() > MAX_CHAT_ITEMS:
		messages_by_club[club_id] = list.slice(list.size() - MAX_CHAT_ITEMS)

func get_messages(club_id: String) -> Array:
	return _messages(club_id).duplicate(true)

func send_message(club_id: String, author: String, text_value: String, icon: String = "♟") -> bool:
	var text := text_value.strip_edges()
	if club_id.is_empty() or text.is_empty():
		return false
	_messages(club_id).append({"author":author,"icon":icon,"text":text,"kind":"message"})
	_trim_messages(club_id)
	changed.emit()
	return true

func send_emote(club_id: String, author: String, emote_id: String, icon: String = "♟") -> bool:
	var id := emote_id.strip_edges()
	if club_id.is_empty() or id.is_empty():
		return false
	_messages(club_id).append({"author":author,"icon":icon,"text":"","kind":"emote","emote_id":id})
	_trim_messages(club_id)
	changed.emit()
	return true

func create_challenge(club_id: String, mode: String) -> Dictionary:
	if mode != "1c1" and mode != "2c2":
		return {}
	var identity := _local_identity()
	var players_required := 2 if mode == "1c1" else 4
	var challenge := {
		"id": "%s_%d" % [mode, Time.get_ticks_msec()],
		"mode": mode,
		"sender_id": String(identity.get("id", "local_player")),
		"sender": String(identity.get("name", "Jugador")),
		"acceptor_ids": [],
		"acceptor_names": {},
		"slots": [String(identity.get("id", "local_player")), "", "", ""],
		"slot_names": [String(identity.get("name", "Jugador")), "", "", ""],
		"slot_teams": [ -1, -1, -1, -1 ],
		"players_required": players_required,
		"accepted": 0,
		"required": 1 if mode == "1c1" else 3,
		"status": "pending",
		"kind": "challenge",
		"competitive": false,
		"affects_rating": false,
		"affects_cups": false,
		"affects_pair_points": false,
		"affects_nexus": false,
	}
	_challenges(club_id).append(challenge)
	_messages(club_id).append({
		"author":String(identity.get("name", "Jugador")),
		"icon":String(identity.get("icon", "♟")),
		"text":"Desafío amistoso %s · %s" % [mode.to_upper(), roster_text(challenge)],
		"kind":"challenge",
		"challenge_id":challenge["id"],
	})
	changed.emit()
	return challenge.duplicate(true)

func get_active_challenges(club_id: String) -> Array:
	var result: Array[Dictionary] = []
	for challenge in _challenges(club_id):
		if String(challenge.get("status", "")) == "pending" or String(challenge.get("status", "")) == "ready":
			result.append(challenge.duplicate(true))
	return result

func _find_challenge(club_id: String, challenge_id: String) -> Dictionary:
	for challenge in _challenges(club_id):
		if String(challenge.get("id", "")) == challenge_id:
			return challenge
	return {}

func _local_slot(challenge: Dictionary) -> int:
	var id := String(_local_identity().get("id", "local_player"))
	var slots: Array = challenge.get("slots", []) if challenge.get("slots", []) is Array else []
	for i in range(slots.size()):
		if String(slots[i]) == id:
			return i
	return -1

func accept_challenge(club_id: String, challenge_id: String, participant_id: String = "") -> bool:
	var identity := _local_identity()
	var voter_id := participant_id.strip_edges()
	if voter_id.is_empty():
		voter_id = String(identity.get("id", "local_player")).strip_edges()
	var challenge := _find_challenge(club_id, challenge_id)
	if challenge.is_empty() or String(challenge.get("status", "")) != "pending":
		return false
	if voter_id.is_empty() or voter_id == String(challenge.get("sender_id", "")):
		return false
	var acceptor_ids: Array = challenge.get("acceptor_ids", []) if challenge.get("acceptor_ids", []) is Array else []
	if acceptor_ids.has(voter_id):
		return false
	var slots: Array = challenge.get("slots", [])
	var slot_names: Array = challenge.get("slot_names", [])
	var first_empty := -1
	for i in range(1, slots.size()):
		if String(slots[i]).is_empty():
			first_empty = i
			break
	if first_empty < 0:
		return false
	acceptor_ids.append(voter_id)
	slots[first_empty] = voter_id
	slot_names[first_empty] = String(identity.get("name", "Jugador")) if voter_id == String(identity.get("id", "local_player")) else voter_id
	challenge["acceptor_ids"] = acceptor_ids
	challenge["slots"] = slots
	challenge["slot_names"] = slot_names
	var acceptor_names: Dictionary = challenge.get("acceptor_names", {}) if challenge.get("acceptor_names", {}) is Dictionary else {}
	acceptor_names[voter_id] = slot_names[first_empty]
	challenge["acceptor_names"] = acceptor_names
	challenge["accepted"] = acceptor_ids.size()
	if String(challenge.get("mode", "")) == "1c1":
		challenge["slot_teams"] = [TEAM_WHITE, TEAM_BLACK, -1, -1]
		challenge["status"] = "ready"
		begin_friendly_match(club_id, challenge_id)
	else:
		challenge["status"] = "pending"
		if _ready_for_2c2(challenge):
			challenge["status"] = "ready"
			begin_friendly_match(club_id, challenge_id)
	changed.emit()
	return true

func choose_challenge_side(club_id: String, challenge_id: String, team: int, participant_id: String = "") -> bool:
	if team != TEAM_WHITE and team != TEAM_BLACK:
		return false
	var identity := _local_identity()
	var target_id := participant_id.strip_edges()
	if target_id.is_empty():
		target_id = String(identity.get("id", "local_player"))
	if target_id != String(identity.get("id", "local_player")):
		return false
	var challenge := _find_challenge(club_id, challenge_id)
	if challenge.is_empty() or String(challenge.get("mode", "")) != "2c2":
		return false
	var slot := _local_slot(challenge)
	if slot < 0:
		return false
	if String(challenge.get("status", "")) == "accepted":
		return false
	var teams: Array = challenge.get("slot_teams", [ -1, -1, -1, -1 ])
	var current_team := int(teams[slot])
	var count_team := 0
	for value in teams:
		if int(value) == team:
			count_team += 1
	if current_team != team and count_team >= 2:
		return false
	teams[slot] = team
	challenge["slot_teams"] = teams
	if _ready_for_2c2(challenge):
		challenge["status"] = "ready"
		begin_friendly_match(club_id, challenge_id)
	else:
		challenge["status"] = "pending"
	changed.emit()
	return true

func _ready_for_2c2(challenge: Dictionary) -> bool:
	var slots: Array = challenge.get("slots", [])
	var teams: Array = challenge.get("slot_teams", [])
	if slots.size() < 4 or teams.size() < 4:
		return false
	for slot in slots:
		if String(slot).is_empty():
			return false
	var white_count := 0
	var black_count := 0
	for team in teams:
		if int(team) == TEAM_WHITE: white_count += 1
		elif int(team) == TEAM_BLACK: black_count += 1
	return white_count == 2 and black_count == 2

func available_team_slots(challenge: Dictionary) -> Dictionary:
	var result := {"white":2,"black":2}
	var teams: Array = challenge.get("slot_teams", []) if challenge.get("slot_teams", []) is Array else []
	for team in teams:
		if int(team) == TEAM_WHITE: result["white"] = int(result["white"]) - 1
		elif int(team) == TEAM_BLACK: result["black"] = int(result["black"]) - 1
	return result

func roster_text(challenge: Dictionary) -> String:
	var names: Array = challenge.get("slot_names", []) if challenge.get("slot_names", []) is Array else []
	var teams: Array = challenge.get("slot_teams", []) if challenge.get("slot_teams", []) is Array else []
	var parts: Array[String] = []
	for i in range(4):
		var name := "🔍" if i >= names.size() or String(names[i]).is_empty() else String(names[i])
		if String(challenge.get("mode", "")) == "2c2" and i < teams.size():
			if int(teams[i]) == TEAM_WHITE: name += " · Blancas"
			elif int(teams[i]) == TEAM_BLACK: name += " · Negras"
		parts.append(name)
	return "(" + "/".join(parts) + ")"

func cancel_challenge(club_id: String, challenge_id: String) -> bool:
	var challenge := _find_challenge(club_id, challenge_id)
	if challenge.is_empty() or String(challenge.get("status", "")) == "accepted":
		return false
	var local_id := String(_local_identity().get("id", "local_player"))
	if local_id != String(challenge.get("sender_id", "")):
		return false
	challenge["status"] = "cancelled"
	_messages(club_id).append({"author":"Sistema","icon":"♟","text":"Desafío cancelado.","kind":"system"})
	_trim_messages(club_id)
	changed.emit()
	return true

func required_acceptances(mode: String) -> int:
	return 1 if mode == "1c1" else 3

func begin_friendly_match(club_id: String, challenge_id: String) -> Dictionary:
	var challenge := _find_challenge(club_id, challenge_id)
	if challenge.is_empty():
		return {}
	var existing := String(challenge.get("match_id", ""))
	if not existing.is_empty():
		for match_data in _matches(club_id):
			if String(match_data.get("id", "")) == existing:
				return match_data.duplicate(true)
	var mode := String(challenge.get("mode", "1c1"))
	if mode == "2c2" and not _ready_for_2c2(challenge):
		return {}
	var match_id := "CLUB_%d" % Time.get_ticks_msec()
	var names: Array = challenge.get("slot_names", []) if challenge.get("slot_names", []) is Array else []
	var ids: Array = challenge.get("slots", []) if challenge.get("slots", []) is Array else []
	var teams: Array = challenge.get("slot_teams", []) if challenge.get("slot_teams", []) is Array else []
	var match_data := {
		"id": match_id,
		"challenge_id": challenge_id,
		"mode": mode,
		"status": "live",
		"players": names.duplicate(true),
		"player_ids": ids.duplicate(true),
		"slot_teams": teams.duplicate(true),
		"watchable": true,
		"competitive": false,
		"affects_rating": false,
		"affects_cups": false,
		"affects_pair_points": false,
		"affects_nexus": false,
		"moves": 0,
		"winner_team": -1,
		"replay_data": {},
	}
	_matches(club_id).append(match_data)
	challenge["match_id"] = match_id
	challenge["status"] = "accepted"
	_messages(club_id).append({
		"author":"Sistema",
		"icon":"♟",
		"text":"Partida amistosa en curso · %s" % roster_text(challenge),
		"kind":"club_match",
		"match_id":match_id,
	})
	_trim_messages(club_id)
	changed.emit()
	return match_data.duplicate(true)

func get_watchable_matches(club_id: String) -> Array:
	var result: Array[Dictionary] = []
	for match_data in _matches(club_id):
		if bool(match_data.get("watchable", true)):
			result.append(match_data.duplicate(true))
	return result

func finish_friendly_match(club_id: String, match_id: String, winner_team: int = -1, moves: int = 0, replay_data: Dictionary = {}) -> bool:
	for match_data in _matches(club_id):
		if String(match_data.get("id", "")) != match_id:
			continue
		match_data["status"] = "finished"
		match_data["winner_team"] = winner_team
		match_data["moves"] = max(0, moves)
		match_data["replay_data"] = replay_data.duplicate(true)
		_messages(club_id).append({
			"author":"Sistema",
			"icon":"🏆",
			"text":"Partida amistosa finalizada · %d jugadas" % int(match_data["moves"]),
			"kind":"club_match",
			"match_id":match_id,
		})
		_trim_messages(club_id)
		changed.emit()
		return true
	return false

func get_match(club_id: String, match_id: String) -> Dictionary:
	for match_data in _matches(club_id):
		if String(match_data.get("id", "")) == match_id:
			return match_data.duplicate(true)
	return {}
