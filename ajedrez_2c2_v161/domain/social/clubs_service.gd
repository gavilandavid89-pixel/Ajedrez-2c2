extends Node

const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const NexusTeamScript = preload("res://domain/competitive/nexus_team.gd")

signal changed()
signal page_loaded()

const BATCH_SIZE := 6
const MORE_BATCH_SIZE := 4
const MAX_MEMBERS := 50
const MAX_NEXUS_REQUIREMENT := 3000

const ACCESS_PUBLIC := "public"
const ACCESS_NEXUS := "nexus"
const ACCESS_INVITE := "invite"

const ROLE_FOUNDER := "rey"
const ROLE_QUEEN := "dama"
const ROLE_ROOK := "torre"
const ROLE_BISHOP := "alfil"
const ROLE_KNIGHT := "caballo"
const ROLE_PAWN := "peon"

const ROLE_POWER := {
	ROLE_PAWN: 0,
	ROLE_KNIGHT: 1,
	ROLE_BISHOP: 2,
	ROLE_ROOK: 3,
	ROLE_QUEEN: 4,
	ROLE_FOUNDER: 5,
}
const STAFF_CAPS := {
	ROLE_QUEEN: 2,
	ROLE_ROOK: 3,
	ROLE_BISHOP: 5,
	ROLE_KNIGHT: 9,
}

var _all_catalog: Array[Dictionary] = []
var _visible_count := 0
var active_club_id := ""
var selected_club_id := ""
var detail_seen_ids: Dictionary = {}
var joined_ids: Dictionary = {}
var members_by_club: Dictionary = {}
var join_requests_by_club: Dictionary = {}
var invites_by_club: Dictionary = {}
var _initialized := false

func _ready() -> void:
	_seed_catalog()
	_visible_count = mini(BATCH_SIZE, _all_catalog.size())

func _seed_catalog() -> void:
	if _initialized:
		return
	_initialized = true
	var seed: Array[Dictionary] = [
		{"id":"c1","name":"Los Caballos","description":"Club amistoso para partidas y análisis.","icon":"♞","members":28,"founder":"Mica","access_type":ACCESS_PUBLIC,"min_nexus":0},
		{"id":"c2","name":"Torre Norte","description":"Jugadores activos que buscan mejorar.","icon":"♜","members":35,"founder":"Alex","access_type":ACCESS_PUBLIC,"min_nexus":0},
		{"id":"c3","name":"Mate en Tres","description":"Retos, tácticas y partidas rápidas.","icon":"♟","members":18,"founder":"Luna","access_type":ACCESS_PUBLIC,"min_nexus":0},
		{"id":"c4","name":"NEXUS 500+","description":"Comunidad para jugadores con exigencia competitiva.","icon":"♛","members":47,"founder":"Noah","access_type":ACCESS_NEXUS,"min_nexus":500},
		{"id":"c5","name":"Guardia Real","description":"Club privado de amistades y práctica.","icon":"♚","members":28,"founder":"Sofia","access_type":ACCESS_INVITE,"min_nexus":0},
		{"id":"c6","name":"NEXUS 2500","description":"Club privado para jugadores de NEXUS alto.","icon":"♜","members":31,"founder":"Eragon","access_type":ACCESS_NEXUS,"min_nexus":2500},
	]
	for item in seed:
		_all_catalog.append(_normalize_club(item))
		_seed_members_for_club(item)
	for i in range(7, 41):
		var access := ACCESS_NEXUS if i % 4 == 0 else (ACCESS_INVITE if i % 5 == 0 else ACCESS_PUBLIC)
		var min_nexus := 400 + (i % 6) * 200 if access == ACCESS_NEXUS else 0
		var item := {
			"id": "c%d" % i,
			"name": "Club %02d" % i,
			"description": "Comunidad de ajedrez %02d. Explora, conoce jugadores y juega." % i,
			"icon": ["♟","♞","♜","♝","♛","♚"][i % 6],
			"members": 10 + (i * 7) % 40,
			"founder": "Fundador %02d" % i,
			"access_type": access,
			"min_nexus": min_nexus,
		}
		_all_catalog.append(_normalize_club(item))
		_seed_members_for_club(item)

func _normalize_club(raw: Dictionary) -> Dictionary:
	var item := raw.duplicate(true)
	item["members"] = clampi(int(item.get("members", 1)), 1, MAX_MEMBERS)
	var access := String(item.get("access_type", ""))
	if access.is_empty():
		access = ACCESS_PUBLIC if bool(item.get("public", false)) else (ACCESS_NEXUS if int(item.get("min_nexus", 0)) > 0 else ACCESS_INVITE)
	if not [ACCESS_PUBLIC, ACCESS_NEXUS, ACCESS_INVITE].has(access):
		access = ACCESS_PUBLIC
	item["access_type"] = access
	item["public"] = access == ACCESS_PUBLIC
	item["min_nexus"] = clampi(int(item.get("min_nexus", 0)), 0, MAX_NEXUS_REQUIREMENT)
	item["nexus_only"] = access == ACCESS_NEXUS
	return item

func _seed_members_for_club(raw: Dictionary) -> void:
	var club_id := String(raw.get("id", ""))
	if club_id.is_empty():
		return
	var founder_id := "seed_%s_founder" % club_id
	members_by_club[club_id] = [
		{"id":founder_id,"name":String(raw.get("founder","Fundador")),"icon":"♚","nexus":800,"role":ROLE_FOUNDER},
		{"id":"%s_mica" % club_id,"name":"Mica","icon":"♟","nexus":1200,"role":ROLE_QUEEN},
		{"id":"%s_alex" % club_id,"name":"Alex","icon":"♞","nexus":980,"role":ROLE_ROOK},
		{"id":"%s_luna" % club_id,"name":"Luna","icon":"♝","nexus":720,"role":ROLE_BISHOP},
		{"id":"%s_noah" % club_id,"name":"Noah","icon":"♜","nexus":640,"role":ROLE_KNIGHT},
	]
	for index in range(5, int(raw.get("members", 0))):
		members_by_club[club_id].append({
			"id":"%s_member_%d" % [club_id, index],
			"name":"Jugador %02d" % index,
			"icon":"♟",
			"nexus":500 + ((index * 37) % 1100),
			"role":ROLE_PAWN,
		})

func _ensure_initialized() -> void:
	if not _initialized:
		_seed_catalog()
		_visible_count = mini(BATCH_SIZE, _all_catalog.size())

func all_available() -> Array[Dictionary]:
	_ensure_initialized()
	return _all_catalog.duplicate(true)

func visible_clubs(search: String = "") -> Array[Dictionary]:
	_ensure_initialized()
	var source: Array = _all_catalog if not search.strip_edges().is_empty() else _all_catalog.slice(0, _visible_count)
	var results: Array[Dictionary] = []
	var needle := search.strip_edges().to_lower()
	for item in source:
		if needle.is_empty() or String(item.get("name", "")).to_lower().find(needle) >= 0 or String(item.get("description", "")).to_lower().find(needle) >= 0:
			results.append(item.duplicate(true))
	return results

func can_load_more() -> bool:
	_ensure_initialized()
	return _visible_count < _all_catalog.size()

func load_more() -> void:
	_ensure_initialized()
	if not can_load_more():
		return
	_visible_count = mini(_visible_count + MORE_BATCH_SIZE, _all_catalog.size())
	page_loaded.emit()

func get_club(club_id: String) -> Dictionary:
	_ensure_initialized()
	for item in _all_catalog:
		if String(item.get("id", "")) == club_id:
			return item.duplicate(true)
	return {}

func mark_detail_seen(club_id: String) -> void:
	if club_id.is_empty():
		return
	detail_seen_ids[club_id] = true
	selected_club_id = club_id
	changed.emit()

func has_seen_detail(club_id: String) -> bool:
	return bool(detail_seen_ids.get(club_id, false))

func _local_identity() -> Dictionary:
	var player_data := RuntimeServicesScript.get_autoload("PlayerData")
	if player_data == null:
		return {"id":"local_player","name":"Jugador","nexus":NexusTeamScript.DEFAULT_RATING}
	var stats: Dictionary = player_data.individual if player_data.individual is Dictionary else {}
	var identity_id := String(player_data.profile.get("id", "")).strip_edges()
	if identity_id.is_empty():
		identity_id = "local_player"
	var display_name := String(player_data.profile.get("name", "Jugador")).strip_edges()
	if display_name.is_empty():
		display_name = "Jugador"
	return {
		"id": identity_id,
		"name": display_name,
		"nexus": clampi(int(stats.get("rating", NexusTeamScript.DEFAULT_RATING)), 0, 3000),
	}

func local_id() -> String:
	return String(_local_identity().get("id", "local_player"))

func local_nexus() -> int:
	return int(_local_identity().get("nexus", NexusTeamScript.DEFAULT_RATING))

func _member_index(club_id: String, member_id: String) -> int:
	for i in range(_members(club_id).size()):
		if String(_members(club_id)[i].get("id", "")) == member_id:
			return i
	return -1

func _members(club_id: String) -> Array:
	if not members_by_club.has(club_id):
		members_by_club[club_id] = []
	return members_by_club[club_id]

func get_members(club_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member in _members(club_id):
		result.append(member.duplicate(true))
	return result

func member_role(club_id: String, member_id: String = "") -> String:
	var target := member_id.strip_edges()
	if target.is_empty():
		target = String(_local_identity().get("id", "local_player"))
	var index := _member_index(club_id, target)
	return ROLE_PAWN if index < 0 else String(_members(club_id)[index].get("role", ROLE_PAWN))

func role_power(role: String) -> int:
	return int(ROLE_POWER.get(role, 0))

func role_label(role: String) -> String:
	match role:
		ROLE_FOUNDER: return "Rey · Fundador"
		ROLE_QUEEN: return "Dama · Administrador"
		ROLE_ROOK: return "Torre · Moderador"
		ROLE_BISHOP: return "Alfil · Oficial"
		ROLE_KNIGHT: return "Caballo · Miembro destacado"
		_: return "Peón · Miembro"

func can_approve_requests(club_id: String, actor_id: String = "") -> bool:
	var role := member_role(club_id, actor_id)
	return role in [ROLE_FOUNDER, ROLE_QUEEN]

func can_invite(club_id: String, actor_id: String = "") -> bool:
	var role := member_role(club_id, actor_id)
	return role_power(role) >= role_power(ROLE_BISHOP)

func can_manage_roles(club_id: String, actor_id: String = "") -> bool:
	return role_power(member_role(club_id, actor_id)) >= role_power(ROLE_QUEEN)

func can_manage_member(club_id: String, target_id: String, actor_id: String = "") -> bool:
	var actor := String(actor_id).strip_edges()
	if actor.is_empty():
		actor = local_id()
	var target := String(target_id).strip_edges()
	if target.is_empty() or target == actor:
		return false
	var actor_power := role_power(member_role(club_id, actor))
	var target_power := role_power(member_role(club_id, target))
	return actor_power >= role_power(ROLE_QUEEN) and target_power < actor_power

func can_assign_role(club_id: String, target_id: String, role: String, actor_id: String = "") -> bool:
	if not ROLE_POWER.has(role) or target_id.is_empty():
		return false
	var actor := String(actor_id).strip_edges()
	if actor.is_empty():
		actor = local_id()
	var actor_role := member_role(club_id, actor)
	var actor_power := role_power(actor_role)
	var target_index := _member_index(club_id, target_id)
	if target_index < 0 or target_id == actor:
		return false
	var target_power := role_power(String(_members(club_id)[target_index].get("role", ROLE_PAWN)))
	# Nadie puede gestionar a un miembro que esté por encima de su rango.
	# El mismo rango sí es válido para el intercambio explícito de cargos.
	if target_power > actor_power:
		return false
	# Nadie puede asignar un rango superior al suyo. El mismo rango sí es válido:
	# en ese caso se hace un intercambio de cargos para mantener una única autoridad.
	if role_power(role) > actor_power:
		return false
	if actor_power < role_power(ROLE_QUEEN):
		return false
	if role == ROLE_FOUNDER and actor_role != ROLE_FOUNDER:
		return false
	return true

func can_remove_member(club_id: String, target_id: String, actor_id: String = "") -> bool:
	var actor := String(actor_id).strip_edges()
	if actor.is_empty():
		actor = local_id()
	var target_index := _member_index(club_id, target_id)
	if target_index < 0 or target_id == actor:
		return false
	var actor_role := member_role(club_id, actor)
	var target_role := String(_members(club_id)[target_index].get("role", ROLE_PAWN))
	# El Rey puede expulsar a cualquiera salvo a sí mismo; la Dama y rangos
	# superiores de staff solo pueden expulsar rangos inferiores.
	return role_power(actor_role) >= role_power(ROLE_QUEEN) and role_power(target_role) < role_power(actor_role)

func _club_full(club_id: String) -> bool:
	return get_members(club_id).size() >= MAX_MEMBERS

func is_joined(club_id: String) -> bool:
	var identity := _local_identity()
	if bool(joined_ids.get(club_id, false)):
		return true
	return _member_index(club_id, String(identity.get("id", "local_player"))) >= 0

func _add_member(club_id: String, member: Dictionary, role: String = ROLE_PAWN) -> bool:
	if _club_full(club_id):
		return false
	var id := String(member.get("id", "")).strip_edges()
	if id.is_empty() or _member_index(club_id, id) >= 0:
		return false
	var entry := member.duplicate(true)
	entry["role"] = role
	_members(club_id).append(entry)
	var club := get_club(club_id)
	if not club.is_empty():
		for item in _all_catalog:
			if String(item.get("id", "")) == club_id:
				item["members"] = _members(club_id).size()
				break
	joined_ids[id + "::" + club_id] = true
	return true

func join_club(club_id: String) -> bool:
	var club := get_club(club_id)
	if club.is_empty() or is_joined(club_id):
		if is_joined(club_id):
			active_club_id = club_id
			return true
		return false
	if String(club.get("access_type", ACCESS_PUBLIC)) != ACCESS_PUBLIC:
		return false
	var identity := _local_identity()
	if not _add_member(club_id, {"id":identity["id"],"name":identity["name"],"icon":"♟","nexus":identity["nexus"]}):
		return false
	active_club_id = club_id
	changed.emit()
	return true

func request_join(club_id: String) -> Dictionary:
	var club := get_club(club_id)
	if club.is_empty():
		return {"ok":false,"reason":"club_not_found"}
	if is_joined(club_id):
		active_club_id = club_id
		return {"ok":true,"status":"joined"}
	if _club_full(club_id):
		return {"ok":false,"reason":"club_full"}
	var identity := _local_identity()
	var access := String(club.get("access_type", ACCESS_PUBLIC))
	if access == ACCESS_PUBLIC:
		var joined := join_club(club_id)
		return {"ok":joined,"status":"joined" if joined else "failed"}
	if access == ACCESS_NEXUS and local_nexus() < int(club.get("min_nexus", 0)):
		return {"ok":false,"reason":"nexus_low","required":int(club.get("min_nexus", 0)),"current":local_nexus()}
	if access == ACCESS_INVITE:
		if not has_invitation(club_id, String(identity["id"])):
			return {"ok":false,"reason":"invite_required"}
		var invited_joined := accept_invitation(club_id, String(identity["id"]))
		return {"ok":invited_joined,"status":"joined" if invited_joined else "failed"}
	var requests: Array = join_requests_by_club.get(club_id, [])
	for existing in requests:
		if String(existing.get("id", "")) == String(identity["id"]):
			return {"ok":true,"status":"pending"}
	requests.append({"id":String(identity["id"]),"name":String(identity["name"]),"nexus":int(identity["nexus"]),"requested_at":Time.get_unix_time_from_system()})
	join_requests_by_club[club_id] = requests
	changed.emit()
	return {"ok":true,"status":"pending"}

func get_join_requests(club_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in join_requests_by_club.get(club_id, []):
		result.append(item.duplicate(true))
	return result

func approve_join_request(club_id: String, member_id: String, actor_id: String = "") -> bool:
	if not can_approve_requests(club_id, actor_id):
		return false
	if _club_full(club_id):
		return false
	var requests: Array = join_requests_by_club.get(club_id, [])
	for i in range(requests.size()):
		if String(requests[i].get("id", "")) != member_id:
			continue
		var request: Dictionary = requests[i]
		if not _add_member(club_id, request):
			return false
		requests.remove_at(i)
		join_requests_by_club[club_id] = requests
		changed.emit()
		return true
	return false

func reject_join_request(club_id: String, member_id: String, actor_id: String = "") -> bool:
	if not can_approve_requests(club_id, actor_id):
		return false
	var requests: Array = join_requests_by_club.get(club_id, [])
	for i in range(requests.size()):
		if String(requests[i].get("id", "")) == member_id:
			requests.remove_at(i)
			join_requests_by_club[club_id] = requests
			changed.emit()
			return true
	return false

func invite_player(club_id: String, player_id: String, player_name: String, player_nexus: int, actor_id: String = "") -> bool:
	if not can_invite(club_id, actor_id) or _club_full(club_id):
		return false
	var invites: Array = invites_by_club.get(club_id, [])
	for existing in invites:
		if String(existing.get("id", "")) == player_id:
			return false
	invites.append({"id":player_id,"name":player_name,"nexus":clampi(player_nexus,0,3000),"invited_by":String(_local_identity().get("id","local_player"))})
	invites_by_club[club_id] = invites
	changed.emit()
	return true

func has_invitation(club_id: String, player_id: String) -> bool:
	for invite in invites_by_club.get(club_id, []):
		if String(invite.get("id", "")) == player_id:
			return true
	return false

func accept_invitation(club_id: String, player_id: String = "") -> bool:
	var identity := _local_identity()
	var target := player_id if not player_id.is_empty() else String(identity.get("id", "local_player"))
	if target != String(identity.get("id", "local_player")):
		return false
	if not has_invitation(club_id, target) or _club_full(club_id):
		return false
	if not _add_member(club_id, {"id":target,"name":identity["name"],"nexus":identity["nexus"],"icon":"♟"}):
		return false
	var invites: Array = invites_by_club.get(club_id, [])
	for i in range(invites.size()):
		if String(invites[i].get("id", "")) == target:
			invites.remove_at(i)
			break
	invites_by_club[club_id] = invites
	active_club_id = club_id
	changed.emit()
	return true

func set_member_role(club_id: String, target_id: String, role: String, actor_id: String = "") -> bool:
	if not can_assign_role(club_id, target_id, role, actor_id):
		return false
	var actor := String(actor_id).strip_edges()
	if actor.is_empty():
		actor = local_id()
	var target_index := _member_index(club_id, target_id)
	var target_current := String(_members(club_id)[target_index].get("role", ROLE_PAWN))
	var actor_current := member_role(club_id, actor)

	if role == target_current:
		return true

	# Asignar el propio rango es un reemplazo: el objetivo toma el rango del
	# actor y el actor hereda el rango que tenía el objetivo. Así nunca existen
	# dos Reyes/Damas por una reasignación.
	if role == actor_current:
		var actor_index := _member_index(club_id, actor)
		if actor_index < 0:
			return false
		_members(club_id)[target_index]["role"] = actor_current
		_members(club_id)[actor_index]["role"] = target_current
		changed.emit()
		return true

	if role != ROLE_PAWN:
		var cap := int(STAFF_CAPS.get(role, MAX_MEMBERS))
		var used := 0
		for member in _members(club_id):
			if String(member.get("role", ROLE_PAWN)) == role:
				used += 1
		if target_current != role and used >= cap:
			return false

	_members(club_id)[target_index]["role"] = role
	changed.emit()
	return true

func remove_member(club_id: String, target_id: String, actor_id: String = "") -> bool:
	if not can_remove_member(club_id, target_id, actor_id):
		return false
	var idx := _member_index(club_id, target_id)
	if idx < 0:
		return false
	_members(club_id).remove_at(idx)
	joined_ids.erase(target_id + "::" + club_id)
	changed.emit()
	return true

func create_club(name: String, icon: String, description: String, access_type: String, min_nexus: int, gallery_path: String = "") -> Dictionary:
	_ensure_initialized()
	var trimmed := name.strip_edges()
	if trimmed.is_empty() or icon.strip_edges().is_empty():
		return {}
	if access_type == "private":
		access_type = ACCESS_NEXUS
	if not [ACCESS_PUBLIC, ACCESS_NEXUS, ACCESS_INVITE].has(access_type):
		return {}
	var identity := _local_identity()
	var founder := String(identity.get("name", "Jugador"))
	var founder_id := String(identity.get("id", "local_player"))
	var nexus := int(identity.get("nexus", NexusTeamScript.DEFAULT_RATING))
	var new_id := "local_%d" % Time.get_ticks_msec()
	var item := _normalize_club({
		"id": new_id,
		"name": trimmed,
		"description": description.strip_edges(),
		"icon": icon,
		"members": 1,
		"founder": founder,
		"access_type": access_type,
		"min_nexus": clampi(min_nexus, 0, MAX_NEXUS_REQUIREMENT),
		"gallery_path": gallery_path,
		"owner": true,
	})
	_all_catalog.push_front(item)
	members_by_club[new_id] = [{"id":founder_id,"name":founder,"icon":"♚","nexus":nexus,"role":ROLE_FOUNDER}]
	_visible_count = mini(maxi(_visible_count, BATCH_SIZE), _all_catalog.size())
	joined_ids[founder_id + "::" + new_id] = true
	active_club_id = new_id
	changed.emit()
	return item.duplicate(true)

func get_selected_club() -> Dictionary:
	return get_club(selected_club_id)

func get_active_club() -> Dictionary:
	return get_club(active_club_id)
