extends SceneTree

const ACCOUNT := preload("res://scenes/account_hub.tscn")
const PLAYER := preload("res://domain/player/player_data.gd")
const GAME_HUD := preload("res://scenes/game_hud.tscn")
const PLAYER_CARD := preload("res://scenes/player_card.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var data := PLAYER.new()
    data.name = "PlayerData_Test"
    root.add_child(data)
    await process_frame
    data.set_appearance("profile_frame", "classic")
    data.set_appearance("player_title", "jugador")
    await process_frame

    _check(data.get_appearance("profile_frame", "classic") == "classic", "frame default classic")
    _check(data.get_appearance("player_title", "jugador") == "jugador", "title default jugador")
    data.set_appearance("profile_frame", "gold")
    _check(data.get_appearance("profile_frame", "classic") == "gold", "gold frame is stored")
    data.set_appearance("player_title", "veterano")
    _check(data.get_appearance("player_title", "jugador") == "veterano", "editable title is stored")

    var card = PLAYER_CARD.instantiate()
    root.add_child(card)
    await process_frame
    card.set_profile({"name":"Prueba", "avatar":"res://assets/avatars/avatar_you.svg", "title":"Jugador", "frame":"gold", "tag":"Jugador"}, "A", true, false, Color("#D4A548"))
    _check(card.get_node("Info/Title").text == "", "player card keeps title hidden in compact in-game identity")
    _check(card.get_node("AvatarFrame") != null, "player card has dedicated avatar frame node")

    var account = ACCOUNT.instantiate()
    root.add_child(account)
    await process_frame
    account.page = "profile"
    account._refresh()
    await process_frame
    _check(_contains_text(account, "👤 Identidad") and _contains_text(account, "🎨 Experiencia"), "profile exposes separate personalization entries")

    account.page = "appearance"
    account._refresh()
    await process_frame
    _check(_contains_text(account, "Icono de perfil") and _contains_text(account, "Marco del perfil") and _contains_text(account, "Título de jugador"), "appearance contains identity visuals")
    _check(not _contains_text(account, "Tablero"), "appearance does not contain board configuration")
    _check(not _contains_text(account, "Piezas"), "appearance does not contain piece configuration")

    account.page = "reactions"
    account._refresh()
    await process_frame
    _check(_contains_text(account, "Tablero") and _contains_text(account, "Piezas") and _contains_text(account, "Experiencia"), "reactions contains board pieces and reactions")
    _check(account.body.get_child_count() >= 4, "reactions stays as one organized experience screen")

    var hud = GAME_HUD.instantiate()
    root.add_child(hud)
    await process_frame
    var game = preload("res://domain/chess/game_state.gd").new()
    root.add_child(game)
    await process_frame
    hud.set_game(game)
    await process_frame
    var local_card = hud.cards_by_slot.get(0, null)
    _check(local_card != null, "game HUD builds local player card")
    if local_card != null:
        _check(local_card.get_node("Info/Title").text != "A • Jugador", "game HUD uses the new title field")

    print("PERSONALIZATION RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _contains_text(root_node: Node, needle: String) -> bool:
    for node in root_node.get_children():
        if node is Label or node is Button:
            if String(node.text).find(needle) >= 0:
                return true
        if _contains_text(node, needle):
            return true
    return false

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
