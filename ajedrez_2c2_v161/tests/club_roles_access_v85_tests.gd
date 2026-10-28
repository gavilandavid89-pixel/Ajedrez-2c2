extends SceneTree

const Clubs = preload("res://domain/social/clubs_service.gd")
const ClubChat = preload("res://domain/social/club_chat_service.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
	var clubs := Clubs.new()
	root.add_child(clubs)
	_test_catalog_limits(clubs)
	_test_roles(clubs)
	_test_nexus_request_flow(clubs)
	_test_invite_flow(clubs)
	_test_capacity(clubs)
	_test_2c2_challenge_and_sides()
	print("CLUB ACCESS/ROLES V85: %d OK / %d FALLARON" % [passed, failed])
	clubs.queue_free()
	quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _test_catalog_limits(clubs: Node) -> void:
	for club in clubs.all_available():
		_ok(int(club.get("members", 0)) <= clubs.MAX_MEMBERS, "ningún club supera 50 miembros")
		_ok(int(club.get("min_nexus", 0)) >= 0 and int(club.get("min_nexus", 0)) <= clubs.MAX_NEXUS_REQUIREMENT, "NEXUS de acceso en 0-3000")

func _test_roles(clubs: Node) -> void:
	var club: Dictionary = clubs.create_club("Roles", "♚", "", clubs.ACCESS_PUBLIC, 0)
	var id := String(club.get("id", ""))
	var local_id: String = clubs.local_id()
	_ok(clubs.member_role(id, local_id) == clubs.ROLE_FOUNDER, "creador recibe Rey/Fundador")
	_ok(clubs.role_power(clubs.ROLE_FOUNDER) > clubs.role_power(clubs.ROLE_QUEEN), "Rey está sobre Dama")
	_ok(clubs.role_power(clubs.ROLE_QUEEN) > clubs.role_power(clubs.ROLE_ROOK), "Dama está sobre Torre")
	_ok(clubs.role_power(clubs.ROLE_ROOK) > clubs.role_power(clubs.ROLE_BISHOP), "Torre está sobre Alfil")
	_ok(clubs.role_power(clubs.ROLE_BISHOP) > clubs.role_power(clubs.ROLE_KNIGHT), "Alfil está sobre Caballo")
	_ok(clubs.role_power(clubs.ROLE_KNIGHT) > clubs.role_power(clubs.ROLE_PAWN), "Caballo está sobre Peón")
	for i in range(9):
		_ok(clubs._add_member(id, {"id":"staff%d" % i,"name":"S%d" % i,"nexus":500,"icon":"♟"}), "entra miembro %d" % i)
	for i in range(2):
		_ok(clubs.set_member_role(id, "staff%d" % i, clubs.ROLE_QUEEN), "se puede crear Dama %d" % i)
	_ok(not clubs.set_member_role(id, "staff8", clubs.ROLE_QUEEN), "tercera Dama supera el cupo")
	_ok(clubs.set_member_role(id, "staff2", clubs.ROLE_ROOK), "Rey puede asignar Torre")
	_ok(clubs.set_member_role(id, "staff3", clubs.ROLE_FOUNDER), "Rey puede transferir su propio rango")
	_ok(clubs.member_role(id, "staff3") == clubs.ROLE_FOUNDER, "objetivo recibe Rey")
	_ok(clubs.member_role(id, local_id) == clubs.ROLE_PAWN, "quien cede Rey toma el rango anterior del objetivo")

func _test_nexus_request_flow(clubs: Node) -> void:
	var club: Dictionary = clubs.create_club("NexusReq", "♛", "", clubs.ACCESS_NEXUS, 1000)
	var id := String(club.get("id", ""))
	# El fundador ya pertenece al club, así que simulamos un solicitante externo
	# mediante la estructura de solicitudes para probar el flujo de autoridad sin
	# alterar la identidad global del jugador durante el test.
	clubs.join_requests_by_club[id] = [{"id":"requester","name":"Solicitante","nexus":1200,"requested_at":Time.get_unix_time_from_system()}]
	_ok(clubs.get_join_requests(id).size() == 1, "solicitud privada queda pendiente")
	_ok(not clubs.can_approve_requests(id, "requester"), "solicitante no puede aprobar su propia solicitud")
	_ok(clubs.approve_join_request(id, "requester"), "autoridad puede aceptar solicitud")
	_ok(clubs.member_role(id, "requester") == clubs.ROLE_PAWN, "aceptado entra como Peón")
	_ok(clubs.is_joined(id), "fundador mantiene su membresía")

func _test_invite_flow(clubs: Node) -> void:
	var club: Dictionary = clubs.create_club("Invitacion", "♞", "", clubs.ACCESS_INVITE, 0)
	var id := String(club.get("id", ""))
	var local: String = clubs.local_id()
	_ok(not clubs.accept_invitation(id, "friend"), "sin invitación no se puede aceptar")
	_ok(clubs.invite_player(id, "friend", "Amigo", 900, local), "autoridad puede emitir invitación")
	_ok(clubs.has_invitation(id, "friend"), "la invitación queda almacenada")
	_ok(not clubs.accept_invitation(id, "friend"), "solo el invitado real puede aceptar su invitación")

func _test_capacity(clubs: Node) -> void:
	var club: Dictionary = clubs.create_club("Capacidad", "♜", "", clubs.ACCESS_PUBLIC, 0)
	var id := String(club.get("id", ""))
	for i in range(49):
		var ok: bool = clubs._add_member(id, {"id":"capacity_%d" % i,"name":"C%d" % i,"nexus":500,"icon":"♟"})
		_ok(ok, "se puede ocupar plaza %d" % i)
	_ok(clubs.get_members(id).size() == 50, "club llega exactamente a 50")
	_ok(not clubs._add_member(id, {"id":"overflow","name":"Overflow","nexus":500,"icon":"♟"}), "51er miembro es rechazado")

func _test_2c2_challenge_and_sides() -> void:
	var chat := ClubChat.new()
	root.add_child(chat)
	var challenge := chat.create_challenge("test", "2c2")
	var cid := String(challenge.get("id", ""))
	_ok(String(challenge.get("mode", "")) == "2c2", "reto se crea como 2c2")
	for i in range(3):
		# El API de prueba permite representar participantes externos.
		_ok(chat.accept_challenge("test", cid, "external_%d" % i), "participante %d puede unirse" % i)
	var active := chat.get_active_challenges("test")
	_ok(active.size() == 1, "reto sigue pendiente hasta elegir bandos")
	var c: Dictionary = active[0]
	_ok(String(chat.roster_text(c)).find("🔍") < 0, "los cuatro huecos ya tienen jugador")
	# El creador es la identidad local.
	_ok(chat.choose_challenge_side("test", cid, 0), "creador puede elegir blancas")
	# Refrescamos el desafío: el snapshot anterior es una copia.
	var refreshed: Array = chat.get_active_challenges("test")
	var current: Dictionary = refreshed[0]
	_ok(chat.available_team_slots(current).get("white", 0) == 1, "queda una plaza blanca")
	_ok(chat.available_team_slots(current).get("black", 0) == 2, "quedan dos plazas negras")
	chat.queue_free()
