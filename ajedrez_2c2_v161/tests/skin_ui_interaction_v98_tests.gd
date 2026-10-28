extends SceneTree

const ACCOUNT_SCENE := preload("res://scenes/account_hub.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var account = ACCOUNT_SCENE.instantiate()
    root.add_child(account)
    await process_frame
    await process_frame
    account.page = "reactions"
    account._refresh()
    await process_frame
    await process_frame

    var data = root.get_node_or_null("PlayerData")
    if data == null:
        _fail("PlayerData disponible")
        quit(1)
        return
    data.appearance["board_theme"] = "classic"
    data.appearance["piece_set"] = "classic"
    account.page_renderer._preview_board_theme = "classic"
    account.page_renderer._preview_piece_set = "classic"
    account._refresh()
    await process_frame

    var buttons: Array[Button] = []
    _collect_buttons(account, buttons)
    var previews: Array[Button] = []
    var equips: Array[Button] = []
    for b in buttons:
        if b.text == "Previsualizar": previews.append(b)
        if b.text == "Equipar": equips.append(b)
    _check(previews.size() == 4, "hay cuatro acciones de previsualización independientes")
    _check(equips.size() == 2, "hay dos acciones de equipamiento independientes")

    if previews.size() >= 4:
        previews[1].pressed.emit()
        await process_frame
        _check(account.page_renderer._preview_board_theme == "graphite_gold", "previsualizar tablero grafito no cambia equipamiento")
        _check(data.get_appearance("board_theme", "classic") == "classic", "previsualizar tablero mantiene clásico equipado")
        previews = []
        buttons = []
        _collect_buttons(account, buttons)
        for b in buttons:
            if b.text == "Previsualizar": previews.append(b)
        if previews.size() >= 4:
            previews[3].pressed.emit()
            await process_frame
            _check(account.page_renderer._preview_piece_set == "graphite_gold", "previsualizar piezas grafito no cambia equipamiento")
            _check(data.get_appearance("piece_set", "classic") == "classic", "previsualizar piezas mantiene clásicas equipadas")
            _check(account.page_renderer._preview_board_theme == "graphite_gold" and account.page_renderer._preview_piece_set == "graphite_gold", "la preview compone tablero y piezas sin equiparlos")

    # Equipar solo piezas y verificar que el tablero sigue clásico.
    buttons = []
    _collect_buttons(account, buttons)
    equips = []
    for b in buttons:
        if b.text == "Equipar" and not b.disabled: equips.append(b)
    _check(equips.size() == 2, "las dos opciones nuevas siguen siendo equipables por separado")
    if equips.size() == 2:
        equips[1].pressed.emit()
        await process_frame
        _check(data.get_appearance("board_theme", "classic") == "classic", "equipar piezas no cambia el tablero")
        _check(data.get_appearance("piece_set", "classic") == "graphite_gold", "equipar piezas aplica solo piezas")

    data.appearance["board_theme"] = "classic"
    data.appearance["piece_set"] = "classic"
    account.queue_free()
    await process_frame
    print("SKIN_UI_INTERACTION_V98_TESTS: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _collect_buttons(node: Node, out: Array[Button]) -> void:
    for child in node.get_children():
        if child is Button:
            out.append(child as Button)
        _collect_buttons(child, out)

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] %s" % label)
    else:
        failed += 1
        push_error("[FALLA] %s" % label)

func _fail(label: String) -> void:
    failed += 1
    push_error("[FALLA] %s" % label)
