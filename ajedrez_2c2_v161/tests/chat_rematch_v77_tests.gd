extends SceneTree

const ChessGameSocialServiceScript = preload("res://domain/chess/game_social_service.gd")
const ChessGameStateScript = preload("res://domain/chess/game_state.gd")
const RematchServiceScript = preload("res://domain/social/rematch_service.gd")

func _check(condition: bool, message: String) -> void:
    if not condition:
        push_error("FAIL: " + message)
        quit(1)

func _init() -> void:
    call_deferred("_run")

func _run() -> void:
    var host: Node = ChessGameStateScript.new()
    get_root().add_child(host)
    host.reset_match(1, 10)
    host.chat("hola rival")
    _check(host.chat_history.size() == 1, "1c1 conserva chat compartido con rival")
    _check(String(host.chat_history[0]).find("hola rival") >= 0, "mensaje 1c1 entra al historial")
    var chat_scene := load("res://scenes/game_chat_panel.tscn") as PackedScene
    var chat_ui: Node = chat_scene.instantiate()
    _check(chat_ui.get_node("Input").placeholder_text == "Escribir", "chat usa placeholder minimalista")
    _check(chat_ui.get_node("Close").flat, "cierre del chat no usa plantilla")
    _check(chat_ui.get_node_or_null("Title") == null, "chat no muestra titulo contextual")
    chat_ui.queue_free()
    host.reset_match(0, 10)
    host.chat("hola equipo y rivales")
    _check(host.chat_history.size() == 1, "2c2 usa un unico historial de partida")

    var rematch: Node = RematchServiceScript.new()
    get_root().add_child(rematch)
    _check(rematch.receive_request("juanito", "Juanito", "m42", 1, "♞"), "recibir solicitud")
    _check(rematch.get_pending_requests().size() == 1, "solicitud pendiente")
    var req: Dictionary = rematch.get_latest_request()
    _check(String(req.get("requester_name", "")) == "Juanito", "nombre de notificacion")
    _check(rematch.accept_request(String(req.get("id", ""))), "aceptar solicitud")
    _check(rematch.get_pending_requests().is_empty(), "solicitud eliminada al aceptar")
    var hud_text := FileAccess.get_file_as_string("res://ui/screens/game_hud.gd")
    var mode_text := FileAccess.get_file_as_string("res://ui/screens/mode_menu.gd")
    _check(hud_text.find("Chat con el rival") == -1, "chat no muestra etiqueta 1c1")
    _check(hud_text.find("Chat de la partida") == -1, "chat no muestra etiqueta 2c2")
    _check(hud_text.find("Escribe al rival") == -1, "chat no muestra placeholder contextual 1c1")
    _check(hud_text.find("Escribe al equipo y rivales") == -1, "chat no muestra placeholder contextual 2c2")
    _check(mode_text.find("Puedes aceptar o rechazar") == -1, "revancha no muestra texto auxiliar")
    print("CHAT/REMATCH V78: 12/12")
    quit(0)
