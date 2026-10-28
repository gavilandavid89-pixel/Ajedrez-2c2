extends SceneTree

const AuthScript = preload("res://domain/auth/auth_service.gd")
const ChatScript = preload("res://domain/social/club_chat_service.gd")
const PlayerDataScene = preload("res://domain/player/player_data.gd")
const FriendsScene = preload("res://domain/social/friends_service.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var auth := AuthScript.new()
    root.add_child(auth)
    await process_frame
    auth.sign_out()
    _check(not auth.is_authenticated(), "auth comienza sin cuenta externa")
    _check(auth.provider_label("google") == "Google", "Google tiene etiqueta")
    _check(auth.provider_label("play_games") == "Google Play Juegos", "Play Juegos tiene etiqueta")
    var rejected := auth.accept_external_identity("google", {})
    _check(not bool(rejected.get("ok", false)), "identidad sin account_id es rechazada")
    var accepted := auth.accept_external_identity("google", {"account_id":"google-user-1","display_name":"Eragon","email":"user@example.com","photo_url":"https://example.invalid/avatar","email_verified":true})
    _check(bool(accepted.get("ok", false)), "identidad Google puede completar el login")
    _check(auth.current_account().get("account_id", "") == "google-user-1", "cuenta estable queda asociada")
    _check(auth.current_account().get("email", "") == "user@example.com", "correo de proveedor queda disponible para perfil")
    _check(auth.request_profile_data(["display_name", "email"]).get("ok", false), "se puede solicitar perfil permitido")
    _check(auth.current_account().get("status", "") == "authenticated", "sesión activa no se confunde con identidad vinculada")

    var chat := ChatScript.new()
    root.add_child(chat)
    await process_frame
    _check(chat.send_emote("c1", "Eragon", "bien"), "chat de club admite emoticono")
    var messages: Array = chat.get_messages("c1")
    _check(messages.size() == 1 and String(messages[0].get("kind", "")) == "emote", "emoticono se persiste como evento de chat")
    _check(String(messages[0].get("emote_id", "")) == "bien", "emoticono conserva su id")

    var friends := FriendsScene.new()
    root.add_child(friends)
    await process_frame
    _check(friends.send_request("friend_v87", "Nuevo amigo"), "solicitud queda pendiente")
    _check(friends.get_pending_requests().size() == 1, "bandeja de solicitudes contiene la petición")
    _check(friends.accept_request("friend_v87"), "solicitud puede aceptarse")
    _check(friends.is_friend("friend_v87"), "aceptada pasa a amigos")

    print("AUTH/SOCIAL V87: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
