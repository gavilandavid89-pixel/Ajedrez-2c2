extends SceneTree

const FriendsScript := preload("res://domain/social/friends_service.gd")
const ClubsScript := preload("res://domain/social/clubs_service.gd")
const ChatScript := preload("res://domain/social/club_chat_service.gd")
const MoreScene := preload("res://scenes/more_screen.tscn")
const FriendsScene := preload("res://scenes/friends_screen.tscn")
const ClubsScene := preload("res://scenes/club_browser_screen.tscn")
const DetailScene := preload("res://scenes/club_detail_screen.tscn")
const CreateScene := preload("res://scenes/club_create_screen.tscn")
const ChatScene := preload("res://scenes/club_chat_screen.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var friends := FriendsScript.new()
    root.add_child(friends)
    _check(friends.get_friends().size() == 2, "Amigos muestra solo relaciones aceptadas")
    _check(friends.send_request("new_player", "Neo", "♞", 600, "match_result"), "solicitud de amistad puede crearse")
    _check(not friends.is_friend("new_player"), "solicitud no se convierte en amigo antes de aceptar")
    _check(friends.accept_request("new_player"), "solicitud puede aceptarse")
    _check(friends.is_friend("new_player"), "aceptado aparece como amigo")

    var clubs := ClubsScript.new()
    root.add_child(clubs)
    _check(clubs.visible_clubs().size() == 6, "Clubes comienza con una tanda limitada")
    _check(clubs.can_load_more(), "Clubes puede cargar más")
    clubs.load_more()
    _check(clubs.visible_clubs().size() == 10, "Clubes carga otra tanda al llegar al tope")
    _check(clubs.visible_clubs("NEXUS").size() >= 1, "barra de búsqueda encuentra clubes")
    var c := clubs.create_club("Mi Club", "♛", "", "private", 500)
    _check(not c.is_empty(), "crear club requiere nombre e icono")
    _check(clubs.is_joined(String(c.get("id", ""))), "club creado queda activo para su fundador")
    _check(String(clubs.get_active_club().get("name", "")) == "Mi Club", "club activo queda seleccionado")

    var chat := ChatScript.new()
    root.add_child(chat)
    _check(chat.send_message(String(c.get("id", "")), "Eragon", "Hola"), "chat permite enviar mensajes")
    var challenge_1c1 := chat.create_challenge(String(c.get("id", "")), "1c1")
    _check(not challenge_1c1.is_empty(), "club chat crea desafío 1c1")
    _check(not bool(challenge_1c1.get("competitive", true)), "desafío amistoso no es competitivo")
    _check(not bool(challenge_1c1.get("affects_rating", true)), "desafío amistoso no afecta rating")
    _check(not bool(challenge_1c1.get("affects_cups", true)), "desafío amistoso no afecta copas")
    _check(not bool(challenge_1c1.get("affects_pair_points", true)), "desafío amistoso no afecta pareja")
    var challenge_2c2 := chat.create_challenge(String(c.get("id", "")), "2c2")
    _check(int(challenge_2c2.get("required", 0)) == 3, "2c2 exige tres aceptaciones además del creador")
    _check(chat.get_active_challenges(String(c.get("id", ""))).size() == 2, "desafíos pendientes permanecen en el chat")
    _check(not chat.accept_challenge(String(c.get("id", "")), String(challenge_2c2.get("id", ""))), "el creador no puede autoaceptar su propio reto")
    _check(chat.cancel_challenge(String(c.get("id", "")), String(challenge_2c2.get("id", ""))), "creador puede cancelar desafío pendiente")

    var more := MoreScene.instantiate()
    root.add_child(more)
    await process_frame
    _check(more.find_child("MainNavigation", true, false) != null, "Más tiene navegación principal")
    _check(more.find_child("Title", true, false) != null, "Más es pantalla independiente")
    _check(_find_text(more, "⚙  Ajustes"), "Ajustes vive dentro de Más")
    _check(_find_text(more, "📊  Rankings"), "Rankings vive dentro de Más")
    more.queue_free()

    var friends_ui := FriendsScene.instantiate()
    root.add_child(friends_ui)
    await process_frame
    _check(friends_ui.find_child("FriendsScroll", true, false) != null, "pantalla Amigos usa scroll")
    friends_ui.queue_free()

    var clubs_ui := ClubsScene.instantiate()
    root.add_child(clubs_ui)
    await process_frame
    _check(clubs_ui.find_child("Search", true, false) != null, "Clubes tiene barra de búsqueda")
    _check(_find_text(clubs_ui, "CREAR MI CLUB"), "Clubes tiene creación propia")
    clubs_ui.queue_free()

    var autoclubs := root.get_node_or_null("ClubsService")
    if autoclubs != null:
        autoclubs.mark_detail_seen("c1")
        autoclubs.join_club("c1")
        var detail_ui := DetailScene.instantiate()
        root.add_child(detail_ui)
        await process_frame
        _check(_find_text(detail_ui, "MIEMBROS"), "detalle del club muestra miembros")
        _check(_find_text(detail_ui, "ABRIR CHAT DEL CLUB"), "club unido puede abrir su chat")
        detail_ui.queue_free()
        var create_ui := CreateScene.instantiate()
        root.add_child(create_ui)
        await process_frame
        _check(create_ui.find_child("MinimumNexus", true, false) != null, "crear club prepara requisito NEX")
        _check(_find_text(create_ui, "GALERÍA"), "crear club ofrece galería")
        create_ui.queue_free()
        var chat_ui := ChatScene.instantiate()
        root.add_child(chat_ui)
        await process_frame
        _check(_find_text(chat_ui, "DESAFIAR"), "chat del club permite desafiar")
        _check(_find_text(chat_ui, String(autoclubs.get_active_club().get("name", "Club"))), "chat muestra nombre del club arriba")
        chat_ui.get_node("MainNavigation")
        _check(chat_ui.has_method("_show_member_profile"), "chat permite abrir perfil de compañeros")
        chat_ui.queue_free()

    print("SOCIAL V70: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _find_text(root_node: Node, target: String) -> bool:
    if root_node is Label and String(root_node.text).find(target) >= 0:
        return true
    if root_node is Button and String(root_node.text).find(target) >= 0:
        return true
    for child in root_node.get_children():
        if _find_text(child, target):
            return true
    return false

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
