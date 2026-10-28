extends SceneTree

const ChatScript := preload("res://domain/social/club_chat_service.gd")
const ClubsScript := preload("res://domain/social/clubs_service.gd")
const ViewerScene := preload("res://scenes/club_match_viewer_screen.tscn")
const MembersScene := preload("res://scenes/club_members_screen.tscn")
const DetailScene := preload("res://scenes/club_detail_screen.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var chat := ChatScript.new()
    root.add_child(chat)
    var challenge := chat.create_challenge("c1", "1c1")
    _check(chat.accept_challenge("c1", String(challenge.get("id", "")), "USR_FRIEND_1"), "aceptar reto inicia amistosa 1c1")
    var active := chat.get_watchable_matches("c1")
    _check(active.size() == 1, "partida amistosa visible para espectadores")
    _check(not bool(active[0].get("competitive", true)), "amistosa no es competitiva")
    var match_id := String(active[0].get("id", ""))
    _check(chat.finish_friendly_match("c1", match_id, 0, 24), "partida amistosa puede finalizar y quedar en chat")
    _check(String(chat.get_match("c1", match_id).get("status", "")) == "finished", "partida finalizada conserva estado")

    var clubs := root.get_node_or_null("ClubsService")
    _check(clubs != null, "club service está disponible para las pantallas")
    if clubs != null:
        clubs.join_club("c1")
    var detail := DetailScene.instantiate()
    root.add_child(detail)
    await process_frame
    await process_frame
    await process_frame
    _check(detail.find_child("MembersLink", true, false) != null, "detalle de club expone miembros como acceso")
    detail.queue_free()

    var members := MembersScene.instantiate()
    root.add_child(members)
    await process_frame
    await process_frame
    await process_frame
    _check(members.find_child("MembersScroll", true, false) != null, "miembros tiene pantalla independiente con scroll")
    members.queue_free()

    var viewer := ViewerScene.instantiate()
    root.add_child(viewer)
    await process_frame
    # Sin match seleccionado el visor vuelve al chat; comprobamos que la escena compila/entra al árbol.
    _check(viewer.is_inside_tree(), "visor de amistosa es escena independiente")
    viewer.queue_free()
    chat.queue_free()
    print("SOCIAL V71 EXT: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
