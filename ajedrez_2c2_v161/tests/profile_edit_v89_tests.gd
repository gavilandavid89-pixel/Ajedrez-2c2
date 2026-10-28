extends SceneTree

const ACCOUNT := preload("res://scenes/account_hub.tscn")
const PLAYER := preload("res://domain/player/player_data.gd")
const RUNTIME := preload("res://core/services/runtime_services.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var data := PLAYER.new()
    data.name = "PlayerData_V89_Test"
    root.add_child(data)
    await process_frame

    data.set_appearance("name_color", "gold")
    _check(data.get_appearance("name_color", "cream") == "gold", "name color gold persists")
    data.set_appearance("name_color", "purple")
    _check(data.get_appearance("name_color", "cream") == "gold", "invalid name color rejected")

    _check(String(data.profile.get("avatar", "")) == "res://assets/avatars/avatar_you.svg", "default avatar is the project avatar")
    _check(data.set_avatar("res://assets/avatars/avatar_you.svg"), "default avatar can be explicitly restored")

    var account = ACCOUNT.instantiate()
    root.add_child(account)
    await process_frame
    data.set_appearance("player_title", "jugador")
    account.page = "profile"
    account._refresh()
    await process_frame
    _check(_contains_text(account, "EDITAR PERFIL"), "profile exposes edit profile entry")

    var app = RUNTIME.get_autoload("App")
    if app != null:
        app.account_start_page = "profile_edit"
    account.queue_free()
    await process_frame
    var routed_account = ACCOUNT.instantiate()
    root.add_child(routed_account)
    await process_frame
    _check(String(routed_account.page) == "profile_edit", "account hub accepts direct profile_edit route")
    account = routed_account

    account.page = "profile_edit"
    account._refresh()
    await process_frame
    _check(_contains_text(account, "Editar perfil"), "edit profile page exists")
    _check(_contains_text(account, "Nombre") and _contains_text(account, "Icono") and _contains_text(account, "Título") and _contains_text(account, "Marco") and _contains_text(account, "Color del nombre"), "edit profile contains all requested identity controls")
    _check(_contains_text(account, "Elegir desde galería"), "edit profile exposes gallery action")
    _check(_contains_text(account, "Usar avatar predeterminado"), "edit profile exposes default avatar reset")
    _check(_contains_text(account, "Dorado") and _contains_text(account, "Azul") and _contains_text(account, "Verde") and _contains_text(account, "Rojo"), "edit profile exposes name color choices")
    _check(data.get_appearance("player_title", "jugador") == "jugador", "default title remains jugador")
    data.set_appearance("player_title", "estratega")
    _check(data.get_appearance("player_title", "jugador") == "estratega", "title can be changed")

    var name_edit := account.find_child("ProfileNameEdit", true, false)
    _check(name_edit is LineEdit, "edit profile has editable name field")
    if name_edit is LineEdit:
        var account_data := RUNTIME.get_autoload("PlayerData")
        var original_name := String(account_data.profile.get("name", "Tú")) if account_data != null else "Tú"
        name_edit.text = "Eragon"
        var save := _find_button(account, "Guardar nombre")
        if save != null:
            save.pressed.emit()
            await process_frame
        _check(account_data != null and String(account_data.profile.get("name", "")) == "Eragon", "edited name is persisted in PlayerData")
        if account_data != null:
            account_data.set_display_name(original_name)

    print("PROFILE EDIT V89: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _find_button(root_node: Node, label: String) -> Button:
    for node in root_node.find_children("*", "Button", true, false):
        if node is Button and String(node.text) == label:
            return node
    return null

func _contains_text(root_node: Node, needle: String) -> bool:
    if root_node is Label or root_node is Button:
        if String(root_node.text).find(needle) >= 0:
            return true
    for child in root_node.get_children():
        if _contains_text(child, needle):
            return true
    return false

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
