extends SceneTree

const AccountScene := preload("res://scenes/account_hub.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var player = root.get_node_or_null("PlayerData")
    var app = root.get_node_or_null("App")
    _check(player != null, "PlayerData autoload available")
    _check(app != null, "App autoload available")
    if player == null or app == null:
        quit(1)
        return

    await process_frame
    await process_frame
    var original_history: Array[Dictionary] = player.history.duplicate(true)
    var record := {
        "match_id": "V35_TEST_MATCH",
        "timestamp": Time.get_unix_time_from_system(),
        "mode": 0,
        "outcome": "win",
        "partner": "Compañero",
        "opponents": ["Rival A", "Rival B"],
        "move_count": 12,
        "moves": [{"actor": "Jugador A", "from": "e2", "to": "e4", "captured": "", "castle": false, "en_passant": false, "promotion": false}],
        "replay_data": {"states": []},
        "reason": "Jaque mate",
        "analysis_ready": true,
        "analysis_viewed": false,
        "rating_delta": 15,
        "rating_after": 1015,
        "cup_delta": 1,
        "cups_after": 11,
    }
    var test_history: Array[Dictionary] = [record]
    player.history = test_history
    app.account_start_page = "history"

    var account := AccountScene.instantiate()
    root.add_child(account)
    await process_frame
    await process_frame

    _check(account.page == "history", "Historial abre correctamente")
    var history_buttons := _buttons_with_text(account, "Analizar partida")
    _check(history_buttons.size() == 1, "Historial muestra un único botón Analizar partida")
    _check(not _subtree_text_contains(account.body, "jugadas"), "Historial no muestra el detalle de jugadas")

    if history_buttons.size() == 1:
        history_buttons[0].pressed.emit()
        await process_frame
        await process_frame
    _check(account.page == "analysis", "Analizar partida abre directamente el estudio")
    _check(_buttons_with_text(account, "Analizar").is_empty(), "No hay un segundo botón Analizar intermedio")
    _check(bool(player.history[0].get("analysis_viewed", false)), "Entrar al estudio marca el análisis como visto")
    _check(not _subtree_text_contains(account.body, "Rendimiento final"), "El análisis no obliga a pasar por un resumen antes del tablero")
    _check(not _subtree_text_contains(account.body, "Datos de la partida"), "El análisis no muestra datos secundarios encima del estudio")
    _check(not _buttons_with_text(account, "Ver partida completa").size() > 0, "El análisis no duplica el acceso a la partida completa")
    _check(account.body.find_child("GameReviewStudy", true, false) != null, "El análisis abre directamente el estudio interactivo")
    _check(not player.history[0].has("analysis_report"), "El análisis heurístico antiguo ya no se guarda")

    account.page = "history"
    account._refresh()
    await process_frame
    await process_frame
    _check(_buttons_with_text(account, "Ver").size() == 1, "Tras analizar, Historial muestra solo Ver")

    var ver_buttons := _buttons_with_text(account, "Ver")
    if ver_buttons.size() == 1:
        ver_buttons[0].pressed.emit()
        await process_frame
        await process_frame
    _check(account.page == "analysis", "Ver abre directamente el estudio de la partida")
    _check(_buttons_with_text(account, "Ver análisis").is_empty(), "No hay un segundo menú Ver análisis")
    var study: Node = account.body.find_child("GameReviewStudy", true, false)
    _check(study != null, "El estudio interactivo está presente")
    if study != null:
        var move_scroll := study.find_child("MoveStripScroll", true, false) as ScrollContainer
        _check(move_scroll != null and move_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED, "La tira de jugadas no usa scroll vertical")
        _check(move_scroll != null and move_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO, "La tira de jugadas usa scroll horizontal")
    _check(_buttons_with_text(account, "⏮").is_empty() and _buttons_with_text(account, "⏭").is_empty(), "El estudio no usa controles de reproductor de vídeo")

    account.queue_free()
    await process_frame
    player.history = original_history
    player.save_data()

    print("V35 HISTORIAL: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _buttons_with_text(root_node: Node, value: String) -> Array[Button]:
    var found: Array[Button] = []
    for child in root_node.get_children():
        if child is Button and child.text.strip_edges() == value:
            found.append(child)
        found.append_array(_buttons_with_text(child, value))
    return found

func _subtree_text_contains(root_node: Node, value: String) -> bool:
    for child in root_node.get_children():
        if child is Label and String(child.text).findn(value) >= 0:
            return true
        if child is Button and String(child.text).findn(value) >= 0:
            return true
        if _subtree_text_contains(child, value):
            return true
    return false

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
