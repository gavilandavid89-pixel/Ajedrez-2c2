extends SceneTree

const ScreenCatalogScript = preload("res://core/navigation/screen_catalog.gd")
const AppScript = preload("res://core/services/app.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const ChatScript = preload("res://domain/social/club_chat_service.gd")

var passed := 0
var failed := 0
var total_actions := 0
var per_screen: Dictionary = {}
var modal_interactions := 0
const MAX_ACTIONS_PER_SCREEN := 180

func _initialize() -> void:
    var app: Node = RuntimeServicesScript.get_autoload("App")
    if app == null:
        _fail("App autoload no disponible")
        quit(1)
        return
    app.navigation_audit_mode = true
    var player_data: Node = RuntimeServicesScript.get_autoload("PlayerData")
    if player_data != null and player_data.get("settings") is Dictionary:
        # El auditor ejecuta partidas y botones masivamente; el sonido real no
        # aporta cobertura aquí y algunos backends de audio retienen playback.
        player_data.settings["sound"] = false
    _prepare_social_context()
    var routes: Dictionary = ScreenCatalogScript.all()
    for screen_id in routes.keys():
        await _audit_screen(String(screen_id), String(routes[screen_id]))
    app.navigation_audit_mode = false
    print("FULL SCREEN FLOW V87: %d OK / %d FALLARON / %d interacciones" % [passed, failed, total_actions])
    for screen_id in per_screen.keys():
        print("  %s -> %d acciones" % [screen_id, int(per_screen[screen_id])])
    quit(0 if failed == 0 else 1)

func _prepare_social_context() -> void:
    var clubs: Node = RuntimeServicesScript.get_autoload("ClubsService")
    if clubs != null:
        var active: Dictionary = clubs.get_active_club()
        if active.is_empty():
            var created: Dictionary = clubs.create_club("QA Club", "♞", "Auditoría", clubs.ACCESS_PUBLIC, 0)
            if not created.is_empty():
                clubs.active_club_id = String(created.get("id", ""))
        elif not clubs.is_joined(String(active.get("id", ""))):
            clubs.join_club(String(active.get("id", "")))
    var friends: Node = RuntimeServicesScript.get_autoload("FriendsService")
    if friends != null:
        var pending: Array = friends.get_pending_requests() if friends.has_method("get_pending_requests") else []
        if pending.is_empty() and friends.has_method("send_request"):
            friends.send_request("qa_friend_pending", "QA Amigo", "♞", 1200, "audit")
    var chat: Node = RuntimeServicesScript.get_autoload("ClubChatService")
    if chat != null and clubs != null:
        var club: Dictionary = clubs.get_active_club()
        if not club.is_empty():
            var cid := String(club.get("id", ""))
            if clubs.has_method("can_approve_requests") and clubs.can_approve_requests(cid):
                clubs.join_requests_by_club[cid] = [{"id":"qa_join_request","name":"QA Solicitante","nexus":1100,"requested_at":Time.get_unix_time_from_system()}]
            if chat.get_watchable_matches(cid).is_empty():
                var challenge: Dictionary = chat.create_challenge(cid, "1c1")
                var challenge_id := String(challenge.get("id", ""))
                chat.accept_challenge(cid, challenge_id, "qa_friend")
                var matches: Array = chat.get_watchable_matches(cid)
                if not matches.is_empty():
                    var app: Node = RuntimeServicesScript.get_autoload("App")
                    app.club_match_view_id = String(matches[0].get("id", ""))
                    app.club_match_view_club_id = cid

func _audit_screen(screen_id: String, path: String) -> void:
    if screen_id == "auth":
        var auth: Node = RuntimeServicesScript.get_autoload("AuthService")
        if auth != null and auth.has_method("accept_external_identity"):
            auth.accept_external_identity("google", {"account_id":"audit-google","display_name":"Auditoría","email":"audit@example.invalid","email_verified":true})
    var scene: PackedScene = load(path) as PackedScene
    if scene == null:
        _fail("%s: escena no carga" % screen_id)
        return
    var node: Node = scene.instantiate()
    node.name = "Audit_%s" % screen_id
    root.add_child(node)
    await process_frame
    await process_frame
    if not is_instance_valid(node) or not node.is_inside_tree():
        _fail("%s: no entra al árbol" % screen_id)
        return
    var action_count := 0
    var seen: Dictionary = {}
    for round_index in range(8):
        var interactive: Array[Node] = _interactive_nodes(node)
        var did_action := false
        for control in interactive:
            if not is_instance_valid(control) or not control.is_inside_tree():
                continue
            var key := str(control.get_instance_id())
            if seen.has(key):
                continue
            seen[key] = true
            did_action = true
            action_count += 1
            total_actions += 1
            if action_count > MAX_ACTIONS_PER_SCREEN:
                break
            await _interact(control)
            await process_frame
        if action_count > MAX_ACTIONS_PER_SCREEN or not did_action:
            break
    if action_count == 0 and screen_id == "loading":
        _check(node.is_inside_tree(), "%s: pantalla transitoria válida sin controles" % screen_id)
    else:
        _check(action_count > 0, "%s: tiene controles interactivos recorribles" % screen_id)
    per_screen[screen_id] = action_count
    _close_transient_windows()
    if is_instance_valid(node):
        node.queue_free()
        await process_frame

func _interactive_nodes(root_node: Node) -> Array[Node]:
    var result: Array[Node] = []
    _collect_interactive(root_node, result)
    return result

func _collect_interactive(node: Node, result: Array[Node]) -> void:
    if node is Button or node is LineEdit or node is TextEdit or node is SpinBox or node is OptionButton or node is CheckButton or node is CheckBox or node is HSlider:
        result.append(node)
    for child in node.get_children():
        if child is Node:
            _collect_interactive(child, result)

func _interact(control: Node) -> void:
    if control is LineEdit:
        var line := control as LineEdit
        if line.name.to_lower().find("search") >= 0:
            line.text = "club"
        elif line.name.to_lower().find("code") >= 0:
            line.text = "ABC234"
        else:
            line.text = "Auditoría"
        line.text_submitted.emit(line.text)
    elif control is TextEdit:
        var edit := control as TextEdit
        edit.text = "Texto de auditoría"
    elif control is SpinBox:
        var spin := control as SpinBox
        spin.value = clampf(spin.value + spin.step, spin.min_value, spin.max_value)
    elif control is OptionButton:
        var option := control as OptionButton
        if option.item_count > 0:
            option.select(option.item_count - 1)
            option.item_selected.emit(option.item_count - 1)
    elif control is CheckButton or control is CheckBox:
        var check := control as BaseButton
        check.button_pressed = not check.button_pressed
        check.toggled.emit(check.button_pressed)
    elif control is HSlider:
        var slider := control as HSlider
        slider.value = slider.min_value if slider.value > slider.min_value else slider.max_value
    elif control is Button:
        var button := control as Button
        if button.disabled:
            return
        var button_text := button.text.to_lower()
        if button_text.find("pegar") >= 0 or button.name.to_lower().find("paste") >= 0:
            # En headless no existe portapapeles del sistema; introducir un código válido es la interacción equivalente.
            if DisplayServer.get_name().to_lower() == "headless":
                var code_input := root.find_child("CodeInput", true, false)
                if code_input is LineEdit:
                    code_input.text = "ABC234"
                return
        button.pressed.emit()
        await process_frame
        await _audit_dialogs()
        # PopupMenus expose actions through PopupMenu rather than Buttons.
        await _audit_popups()
    await _audit_dialogs()
    await _audit_popups()

func _audit_dialogs() -> void:
    var dialogs: Array[Node] = []
    _collect_dialogs(root, dialogs)
    for dialog_node in dialogs:
        if not is_instance_valid(dialog_node):
            continue
        var dialog := dialog_node as ConfirmationDialog
        if dialog == null or not dialog.visible:
            continue
        modal_interactions += 1
        var ok_button := dialog.get_ok_button()
        if ok_button != null and not ok_button.disabled:
            ok_button.pressed.emit()
            await process_frame
        if is_instance_valid(dialog) and dialog.visible:
            var cancel_button := dialog.get_cancel_button()
            if cancel_button != null and not cancel_button.disabled:
                cancel_button.pressed.emit()
                await process_frame

func _audit_popups() -> void:
    var popup_menus: Array[Node] = []
    _collect_popup_menus(root, popup_menus)
    for popup_node in popup_menus:
        if not is_instance_valid(popup_node):
            continue
        var popup := popup_node as PopupMenu
        if popup == null or not popup.visible:
            continue
        var ids: Array[int] = []
        for i in range(popup.item_count):
            if not popup.is_item_disabled(i):
                ids.append(popup.get_item_id(i))
        for action_id in ids:
            if not is_instance_valid(popup):
                break
            if not popup.visible:
                break
            popup.id_pressed.emit(action_id)
            await process_frame
            if not is_instance_valid(popup):
                break
            var popup_name := String(popup.name)
            var refreshed := _find_popup_by_name(root, popup_name)
            if refreshed != null:
                popup = refreshed as PopupMenu

func _find_popup_by_name(node: Node, target_name: String) -> Node:
    if node is PopupMenu and node.name == target_name:
        return node
    for child in node.get_children():
        if child is Node:
            var found := _find_popup_by_name(child, target_name)
            if found != null:
                return found
    return null

func _collect_popup_menus(node: Node, result: Array[Node]) -> void:
    if node is PopupMenu:
        result.append(node)
    for child in node.get_children():
        if child is Node:
            _collect_popup_menus(child, result)

func _close_transient_windows() -> void:
    var panels: Array[Node] = []
    _collect_popup_panels(root, panels)
    for popup_node in panels:
        var popup := popup_node as PopupPanel
        if is_instance_valid(popup):
            popup.hide()
            popup.queue_free()
    var dialogs: Array[Node] = []
    _collect_file_dialogs(root, dialogs)
    for dialog_node in dialogs:
        var dialog := dialog_node as FileDialog
        if is_instance_valid(dialog):
            dialog.hide()
            dialog.queue_free()
    var message_dialogs: Array[Node] = []
    _collect_dialogs(root, message_dialogs)
    for dialog_node in message_dialogs:
        var dialog := dialog_node as AcceptDialog
        if is_instance_valid(dialog):
            dialog.hide()
            dialog.queue_free()

func _collect_dialogs(node: Node, result: Array[Node]) -> void:
    if node is ConfirmationDialog or node is AcceptDialog:
        result.append(node)
    for child in node.get_children():
        if child is Node:
            _collect_dialogs(child, result)

func _collect_popup_panels(node: Node, result: Array[Node]) -> void:
    if node is PopupPanel:
        result.append(node)
    for child in node.get_children():
        if child is Node:
            _collect_popup_panels(child, result)

func _collect_file_dialogs(node: Node, result: Array[Node]) -> void:
    if node is FileDialog:
        result.append(node)
    for child in node.get_children():
        if child is Node:
            _collect_file_dialogs(child, result)

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
    else:
        _fail(label)

func _fail(label: String) -> void:
    failed += 1
    push_error("[FAIL] " + label)
