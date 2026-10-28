extends SceneTree

const AppConfig = preload("res://core/services/app.gd")
const GameState = preload("res://domain/chess/game_state.gd")
const SETUP_SCENE = preload("res://scenes/online_setup.tscn")
const MODE_MENU = preload("res://scenes/mode_menu.tscn")
const MATCH_SCENE = preload("res://scenes/online_matchmaking.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    await _test_mode_menu_opens_online_setup()
    await _test_time_selection_and_mode()
    await _test_friend_room_interface()
    await _test_join_room_interface()
    await _test_matchmaking_interface()
    await _test_compact_mobile_layout()
    _test_clock_only_active_turn()
    _test_selected_time_reaches_game_state()
    print("ONLINE SETUP RESULT: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _test_mode_menu_opens_online_setup() -> void:
    var menu = MODE_MENU.instantiate()
    root.add_child(menu)
    await process_frame
    var setup = menu.get_node("OnlineSetup")
    menu.get_node("Margin/VBox/2c2").emit_signal("pressed")
    await process_frame
    _check(setup.visible and setup.selected_mode == AppConfig.MODE_2C2, "2c2 abre mini menú online")
    setup._show_main()
    setup._set_time(15)
    _check(setup.selected_minutes == 15, "15' queda seleccionado en 2c2")
    setup._show_friend()
    _check(setup.friend_page and setup.get_node("Modal/Friend").visible, "2c2 amigo abre página privada")
    setup._close()
    menu.get_node("Margin/VBox/1c1").emit_signal("pressed")
    await process_frame
    _check(setup.visible and setup.selected_mode == AppConfig.MODE_1C1, "1c1 abre mini menú online")
    menu.queue_free()
    await process_frame

func _test_time_selection_and_mode() -> void:
    var setup = SETUP_SCENE.instantiate()
    root.add_child(setup)
    await process_frame
    setup.open_for_mode(AppConfig.MODE_2C2)
    _check(setup.visible, "overlay online se abre sobre menú")
    _check(setup.get_node("Modal/Title").text == "2c2 · COOPERATIVO", "setup identifica 2c2")
    setup._set_time(20)
    _check(setup.selected_minutes == 20 and setup.get_node("Modal/Main/Time/20").button_pressed, "selección 20' funciona")
    setup._set_time(15)
    _check(setup.selected_minutes == 15 and setup.get_node("Modal/Main/Time/15").button_pressed, "selección 15' funciona")
    setup.queue_free()
    await process_frame

func _test_friend_room_interface() -> void:
    var setup = SETUP_SCENE.instantiate()
    root.add_child(setup)
    await process_frame
    setup.open_for_mode(AppConfig.MODE_1C1)
    setup._show_friend()
    _check(setup.get_node("Modal/Friend").visible and not setup.get_node("Modal/Main").visible, "panel jugar con amigo abre")
    var app = root.get_node_or_null("App")
    if app != null:
        app.prepare_friend_room()
    setup._sync_room_info()
    _check(not String(setup.get_node("Modal/Friend/Code").text).is_empty(), "código de sala presente")
    _check(String(setup.get_node("Modal/Friend/InviteCard/Link").text).begins_with("https://"), "enlace de invitación presente")
    _check(is_instance_valid(setup.get_node("Modal/Friend/QR")), "vista QR presente")
    var card = setup.get_node("Modal/Friend/InviteCard") as Control
    var note = setup.get_node("Modal/Friend/InviteCard/Note") as Control
    var link = setup.get_node("Modal/Friend/InviteCard/Link") as Control
    var copy = setup.get_node("Modal/Friend/InviteCard/CopyStatus") as Control
    _check(_inside(card, note), "nota de sala queda dentro de la tarjeta")
    _check(_inside(card, link), "enlace queda dentro de la tarjeta")
    _check(_inside(card, copy), "estado de copiado queda dentro de la tarjeta")
    var qr = setup.get_node("Modal/Friend/QR") as Control
    var code = setup.get_node("Modal/Friend/Code") as Control
    _check(not _overlap(qr, code), "QR no tapa el código")
    setup.queue_free()
    await process_frame

func _test_join_room_interface() -> void:
    var setup = SETUP_SCENE.instantiate()
    root.add_child(setup)
    await process_frame
    setup.open_for_mode(AppConfig.MODE_1C1)
    setup._show_friend()
    _check(setup.get_node("Modal/Friend/JoinRoom").visible, "opción unirse visible en sala privada")
    setup._show_join()
    _check(setup.get_node("Modal/Join").visible and not setup.get_node("Modal/Friend").visible, "página unirse abre correctamente")
    var input := setup.get_node("Modal/Join/CodeInput") as LineEdit
    input.text = "A2V7K9"
    _check(setup._parse_join_preview() == "A2V7K9", "código de 6 caracteres válido")
    input.text = "https://ajedrez2c2.app/r/A2V7K9"
    _check(setup._parse_join_preview() == "A2V7K9", "enlace de invitación se convierte en código")
    input.text = "BAD"
    _check(setup._parse_join_preview() == "", "código inválido se rechaza")
    var received := {"mode": -1, "minutes": -1, "code": ""}
    setup.join_requested.connect(func(m, minutes, code):
        received["mode"] = m
        received["minutes"] = minutes
        received["code"] = code
    )
    setup._set_time(15)
    _check(setup.get_node("Modal/Join/RoomSettings").text.begins_with("El tiempo y las reglas"), "unirse deja el tiempo a cargo de la sala")
    input.text = "A2V7K9"
    setup._join_room()
    _check(received["mode"] == AppConfig.MODE_1C1 and received["minutes"] == 15 and received["code"] == "A2V7K9", "unirse emite datos correctos")
    setup.queue_free()
    await process_frame

func _test_matchmaking_interface() -> void:
    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = AppConfig.MODE_2C2
        app.selected_time_minutes = 15
        app.online_entry = "friend"
        app.prepare_friend_room()
    var scene = MATCH_SCENE.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    _check(scene.get_node("Center/Card/Title").text == "2c2 · ONLINE", "matchmaking reconoce modo 2c2")
    _check(scene.get_node("Center/Card/Room").visible, "matchmaking muestra sala privada")
    _check(scene.get_node("Center/Card/Room/Code").text == app.friend_room_code if app != null else true, "matchmaking muestra código correcto")
    scene.queue_free()
    await process_frame

func _test_clock_only_active_turn() -> void:
    var g: GameState = GameState.new()
    root.add_child(g)
    g.reset_match(GameState.MODE_1C1, 10)
    var white_before: float = g.team_time[0]
    var black_before: float = g.team_time[1]
    g._process(1.0)
    _check(g.team_time[0] < white_before and is_equal_approx(g.team_time[1], black_before), "solo reloj del turno blanco corre")
    g._advance_turn()
    var white_hold: float = g.team_time[0]
    var black_start: float = g.team_time[1]
    g._process(1.0)
    _check(is_equal_approx(g.team_time[0], white_hold) and g.team_time[1] < black_start, "solo reloj del turno negro corre")
    g.queue_free()

func _test_selected_time_reaches_game_state() -> void:
    var app = root.get_node_or_null("App")
    var minutes := 20
    if app != null:
        app.selected_time_minutes = minutes
    var g: GameState = GameState.new()
    root.add_child(g)
    g.reset_match(GameState.MODE_1C1, minutes)
    _check(g.match_minutes == 20 and is_equal_approx(g.team_time[0], 1200.0) and is_equal_approx(g.team_time[1], 1200.0), "20' llega al reloj real")
    g.queue_free()

func _test_compact_mobile_layout() -> void:
    var sv := SubViewport.new()
    sv.size = Vector2(360, 640)
    sv.render_target_update_mode = SubViewport.UPDATE_ONCE
    root.add_child(sv)
    var setup = SETUP_SCENE.instantiate()
    sv.add_child(setup)
    await process_frame
    setup.open_for_mode(AppConfig.MODE_2C2)
    setup._show_main()
    await process_frame
    var modal := setup.get_node("Modal") as Control
    _check(modal.size.x <= 332.0 and modal.size.y <= 606.0, "compact modal stays within mobile viewport")
    var title := setup.get_node("Modal/Title") as Control
    _check(_inside(modal, title), "online title fits compact mobile")
    setup._show_friend()
    await process_frame
    _check(_inside(modal, setup.get_node("Modal/Friend/Back")), "friend back button fits compact mobile")
    _check(_inside(modal, setup.get_node("Modal/Friend/JoinRoom")), "friend join button fits compact mobile")
    setup._show_join()
    await process_frame
    var room := setup.get_node("Modal/Join/RoomSettings") as Control
    var join_button := setup.get_node("Modal/Join/Join") as Control
    var back := setup.get_node("Modal/Join/Back") as Control
    _check(_inside(modal, room), "join room-settings fits compact mobile")
    _check(_inside(modal, join_button), "join action fits compact mobile")
    _check(_inside(modal, back), "join back fits compact mobile")
    _check(not _overlap(room, join_button), "room-settings does not overlap join action")
    setup.queue_free()
    sv.queue_free()
    await process_frame

func _inside(parent: Control, child: Control) -> bool:
    var r := Rect2(child.position, child.size)
    return Rect2(Vector2.ZERO, parent.size).encloses(r)

func _overlap(a: Control, b: Control) -> bool:
    var ar := Rect2(a.position, a.size)
    var br := Rect2(b.position, b.size)
    return ar.intersects(br)

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        print("[FAIL] ", label)
