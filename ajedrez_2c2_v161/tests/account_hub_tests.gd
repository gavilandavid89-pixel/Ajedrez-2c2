extends SceneTree

const SCENE := preload("res://scenes/account_hub.tscn")
const PLAYER_DATA := preload("res://domain/player/player_data.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    # SceneTree._initialize happens before Autoload._ready() has finished loading
    # persisted data. Defer setup so this test clears history after PlayerData loads;
    # otherwise prior test runs can make the idempotency assertions flaky.
    call_deferred("_run")

func _run() -> void:
    await process_frame
    var data = root.get_node_or_null("PlayerData")
    if data == null:
        data = PLAYER_DATA.new()
        data.name = "PlayerData"
        root.add_child(data)
        await process_frame
    data.history.clear()
    data.profile["id"] = "USR_ACCOUNT_HUB_TEST"
    data.profile["name"] = "NexusQA"
    data.individual["rating"] = 1420
    data.individual["uncertainty"] = 110.0
    data.pair_records.clear()
    var pair_ab: Dictionary = data.ensure_pair_record(data.pair_key("B", "USR_B"), "B", "USR_B", 1300)
    pair_ab["games"] = 6
    pair_ab["pair_strength"] = 1510
    pair_ab["rating"] = 1510
    pair_ab["best_rating"] = 1535
    pair_ab["peak_strength"] = 1535
    data.pair_records[data.pair_key("B", "USR_B")] = pair_ab
    var pair_ac: Dictionary = data.ensure_pair_record(data.pair_key("C", "USR_C"), "C", "USR_C", 1200)
    pair_ac["games"] = 2
    pair_ac["pair_strength"] = 1490
    pair_ac["rating"] = 1490
    pair_ac["best_rating"] = 1490
    pair_ac["peak_strength"] = 1490
    data.pair_records[data.pair_key("C", "USR_C")] = pair_ac
    data.current_pair_id = data.pair_key("C", "USR_C")
    data.current_partner = {"id": "USR_C", "name": "C", "pair_key": data.current_pair_id}
    data._refresh_best_pair_id()
    _check(String(data.best_pair_id) == data.pair_key("B", "USR_B"), "best pair state is stored independently of current pair")
    for vp in [Vector2(360, 640), Vector2(390, 844), Vector2(720, 1280), Vector2(1280, 720)]:
        await _test_viewport(vp)
    print("ACCOUNT HUB RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _test_viewport(vp: Vector2) -> void:
    var root_node := SubViewport.new()
    root_node.size = vp
    root_node.render_target_update_mode = SubViewport.UPDATE_ONCE
    root.add_child(root_node)
    var scene := SCENE.instantiate()
    root_node.add_child(scene)
    await process_frame
    await process_frame

    _check(scene.viewport_size == vp, "viewport registered %s" % vp)
    _check(scene.content.size.x > 0 and scene.content.size.y > 0, "content has size %s" % vp)
    _check(scene.body.size.x > 0 and scene.body.size.y > 0, "content body has size %s" % vp)
    if vp.x <= 390.0:
        _check(scene.body.custom_minimum_size.x <= vp.x - 44.0 and scene.content.size.x <= vp.x, "mobile content width stays inside viewport %s" % vp)
    _check(not scene.tabs.visible and scene.tabs.get_child_count() == 0, "profile navigation has no visible tab menu %s" % vp)
    _check(scene.history_action != null and scene.get_node_or_null("SettingsAction") == null, "profile exposes history only; settings lives in Más %s" % vp)
    scene.page = "profile"
    scene._refresh()
    await process_frame
    if vp.x <= 390.0:
        var profile_card := scene.body.get_child(0) as Control
        _check(profile_card.size.x <= scene.body.size.x + 1.0, "profile card does not overflow mobile body %s" % vp)
    _check(_body_contains_text(scene, "Copas") and _body_contains_text(scene, "Rating"), "profile keeps core competitive metrics %s" % vp)
    _check(_body_contains_text(scene, "Pareja actual 2c2") and _body_contains_text(scene, "MEJOR"), "2c2 profile distinguishes current and best pair %s" % vp)
    _check(not _body_contains_text(scene, "🎨 Apariencia"), "profile does not contain customization navigation %s" % vp)
    _check(not _body_contains_text(scene, "⚡ Reacciones rápidas equipadas"), "profile does not contain reaction navigation %s" % vp)
    _check(_body_contains_text(scene, "Logros"), "profile keeps achievements section prepared %s" % vp)
    _check(scene.page == "profile", "profile remains a single information screen %s" % vp)
    scene.page = "ranking"
    scene._refresh()
    await process_frame
    _check(scene.body.get_child_count() > 0, "ranking renders %s" % vp)
    scene.page = "cups"
    scene._refresh()
    await process_frame
    _check(scene.body.get_child_count() > 0, "cups renders %s" % vp)

    var detail: Dictionary = {
        "match_id": "TEST_MATCH_%d" % int(vp.x),
        "mode": 2,
        "outcome": "win",
        "winner_team": 0,
        "reason": "Jaque mate",
        "move_count": 3,
        "moves": [
            {"actor": "Tú", "from": "e2", "to": "e4", "captured": "", "castle": false, "en_passant": false, "promotion": false},
            {"actor": "Bot", "from": "e7", "to": "e5", "captured": "", "castle": false, "en_passant": false, "promotion": false},
            {"actor": "Tú", "from": "f1", "to": "c4", "captured": "", "castle": false, "en_passant": false, "promotion": false}
        ],
        "bot_id": "nora",
        "bot_elo": 700,
        "opponents": ["Bot Nora"],
    }
    scene._data().record_noncompetitive_match(detail)
    scene.page = "history"
    scene._refresh()
    await process_frame
    _check(scene.body.get_child_count() > 0, "history renders %s" % vp)
    _check(scene._data().history.size() >= 1, "history stores completed match %s" % vp)
    var fresh_history_id := String(scene._data().history[-1].get("match_id", ""))
    _check(not bool(scene._data().history[-1].get("analysis_viewed", false)), "new history entry starts unanalysed %s" % vp)
    _check(_body_contains_text(scene, "Analizar partida"), "history exposes only Analizar partida as the initial action %s" % vp)
    _check(not _body_contains_text(scene, "Ver análisis"), "history does not expose redundant Ver análisis text %s" % vp)
    scene._open_history_primary(fresh_history_id)
    await process_frame
    await process_frame
    _check(scene.page == "analysis", "initial history action opens the study directly %s" % vp)
    # La disponibilidad de analysis_viewed depende de si el motor termina durante
    # este mismo frame; el flujo y su persistencia se cubren en la suite de historial.
    scene._open_history_analysis(fresh_history_id)
    for _i in range(4):
        await process_frame
        if bool(scene._data().history[-1].get("analysis_viewed", false)):
            break
    # La persistencia de `analysis_viewed` se cubre en history_interface_v35_tests.gd.
    _check(scene.page == "analysis", "first analysis opens analysis page %s" % vp)
    _check(not _body_contains_text(scene, "Ver partida completa"), "analysis no longer duplicates normal replay access %s" % vp)
    scene.page = "history"
    scene._refresh()
    await process_frame
    _check(_body_contains_text(scene, "Ver"), "analysed history entry changes its single action to Ver %s" % vp)
    _check(not _body_contains_text(scene, "Ver análisis"), "analysed history avoids redundant Ver análisis label %s" % vp)
    scene._open_history_primary(fresh_history_id)
    await process_frame
    await process_frame
    _check(scene.page == "analysis", "history Ver opens the saved study %s" % vp)
    scene._open_history_replay(fresh_history_id)
    await process_frame
    _check(scene.page == "replay", "normal replay remains a secondary view %s" % vp)
    _check(_body_contains_text(scene, "Ver"), "analysed replay changes its compact action to Ver %s" % vp)
    scene.page = "analysis"
    scene._refresh()
    await process_frame
    _check(scene.body.find_child("GameReviewStudy", true, false) != null, "analysis opens the saved-move study directly %s" % vp)
    scene.page = "appearance"
    scene._refresh()
    await process_frame
    _check(scene.body.get_child_count() >= 4, "appearance renders future customization UI %s" % vp)
    _check(scene._data().get_appearance("board_theme", "classic") == "classic", "board theme defaults to classic %s" % vp)
    _check(scene._data().get_appearance("piece_set", "classic") == "classic", "piece set defaults to classic %s" % vp)
    var individual_rows: Array[Dictionary] = scene._data().individual_cup_rank_rows()
    var individual_1c1_rows: Array[Dictionary] = scene._data().individual_1c1_cup_rank_rows()
    var pair_rows: Array[Dictionary] = scene._data().pair_cup_rank_rows()
    _check(not individual_rows.is_empty() and individual_rows[0].has("avatar") and individual_rows[0].has("cups"), "2c2 individual league rows expose avatar and cups %s" % vp)
    _check(not individual_1c1_rows.is_empty() and individual_1c1_rows[0].has("avatar") and individual_1c1_rows[0].has("cups"), "1c1 league rows expose avatar and cups %s" % vp)
    _check(not pair_rows.is_empty() and pair_rows[0].has("avatar1") and pair_rows[0].has("avatar2") and pair_rows[0].has("cups"), "pair league rows expose two avatars and cups %s" % vp)
    scene.page = "reactions"
    scene._refresh()
    await process_frame
    _check(scene.body.get_child_count() >= 3, "reactions page renders catalog and loadout %s" % vp)
    _check(scene._data().get_equipped_emotes().size() <= 6, "reaction loadout capped at six %s" % vp)
    scene.page = "settings"
    scene._refresh()
    await process_frame
    _check(scene.body.get_child_count() >= 4, "settings renders toggles %s" % vp)
    scene.queue_free()
    root_node.queue_free()
    await process_frame

func _buttons_with_text(root_node: Node, value: String) -> Array[Button]:
    var found: Array[Button] = []
    for node in root_node.get_children():
        if node is Button and String(node.text).strip_edges() == value:
            found.append(node)
        found.append_array(_buttons_with_text(node, value))
    return found

func _body_contains_text(root_node: Node, needle: String) -> bool:
    for node in root_node.get_children():
        if node is Label or node is Button:
            if String(node.text).find(needle) >= 0:
                return true
        if _body_contains_text(node, needle):
            return true
    return false

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
