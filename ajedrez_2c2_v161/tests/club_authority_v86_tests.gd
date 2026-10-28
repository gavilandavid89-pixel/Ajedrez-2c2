extends SceneTree

var passed := 0
var failed := 0
var ClubsScript = preload("res://domain/social/clubs_service.gd")

func _init() -> void:
	var clubs := ClubsScript.new()
	root.add_child(clubs)
	await process_frame
	_test_role_assignment_rules(clubs)
	_test_same_role_swap(clubs)
	_test_kick_hierarchy(clubs)
	_test_caps(clubs)
	print("CLUB AUTHORITY V86: %d/%d OK" % [passed, passed + failed])
	quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func _test_role_assignment_rules(clubs: Node) -> void:
	var club := "c1"
	var king := "seed_c1_founder"
	var queen := "c1_mica"
	var pawn := "c1_member_5"
	_ok(clubs.can_assign_role(club, pawn, clubs.ROLE_QUEEN, king), "Rey puede asignar Dama")
	_ok(not clubs.can_assign_role(club, king, clubs.ROLE_QUEEN, queen), "Dama no puede gestionar al Rey")
	_ok(clubs.can_assign_role(club, pawn, clubs.ROLE_QUEEN, queen), "Dama puede asignar su propio rango a rango inferior")
	_ok(not clubs.can_assign_role(club, pawn, clubs.ROLE_FOUNDER, queen), "Dama no puede asignar Rey")
	_ok(not clubs.can_assign_role(club, pawn, clubs.ROLE_QUEEN, pawn), "Peon no gestiona roles")

func _test_same_role_swap(clubs: Node) -> void:
	var club := "c1"
	var king := "seed_c1_founder"
	var queen := "c1_mica"
	var old_queen_role: String = clubs.member_role(club, queen)
	_ok(old_queen_role == clubs.ROLE_QUEEN, "Mica empieza como Dama")
	_ok(clubs.set_member_role(club, queen, clubs.ROLE_FOUNDER, king), "Rey puede entregar su propio rango")
	_ok(clubs.member_role(club, queen) == clubs.ROLE_FOUNDER, "objetivo toma Rey")
	_ok(clubs.member_role(club, king) == clubs.ROLE_QUEEN, "Rey reemplazado toma rango anterior del objetivo")
	# Restaurar para las siguientes comprobaciones del catálogo.
	_ok(clubs.set_member_role(club, king, clubs.ROLE_FOUNDER, queen), "nueva Dama puede devolver el Rey")
	_ok(clubs.member_role(club, king) == clubs.ROLE_FOUNDER, "Rey restaurado")
	_ok(clubs.member_role(club, queen) == old_queen_role, "Dama restaurada")

func _test_kick_hierarchy(clubs: Node) -> void:
	var club := "c1"
	var king := "seed_c1_founder"
	var queen := "c1_mica"
	var pawn := "c1_member_5"
	_ok(clubs.can_remove_member(club, pawn, king), "Rey puede expulsar Peon")
	_ok(clubs.can_remove_member(club, pawn, queen), "Dama puede expulsar Peon")
	_ok(not clubs.can_remove_member(club, king, queen), "Dama no puede expulsar Rey")
	_ok(not clubs.can_remove_member(club, queen, queen), "Dama no puede expulsarse a sí misma")
	_ok(not clubs.remove_member(club, queen, queen), "expulsión inválida no altera miembro")

func _test_caps(clubs: Node) -> void:
	_ok(clubs.STAFF_CAPS[clubs.ROLE_QUEEN] == 2, "máximo 2 Damas")
	_ok(clubs.STAFF_CAPS[clubs.ROLE_ROOK] == 3, "máximo 3 Torres")
	_ok(clubs.STAFF_CAPS[clubs.ROLE_BISHOP] == 5, "máximo 5 Alfiles")
	_ok(clubs.STAFF_CAPS[clubs.ROLE_KNIGHT] == 9, "máximo 9 Caballos")
