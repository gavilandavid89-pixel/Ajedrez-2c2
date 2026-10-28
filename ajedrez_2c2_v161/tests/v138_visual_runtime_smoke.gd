extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        push_error("[FAIL] " + label)

func _run() -> void:
    await process_frame
    var hub := root.get_node_or_null("SupervisorHub")
    _check(hub != null, "QA supervisor autoload exists")
    _check(FileAccess.file_exists("user://qa_session_active.json"), "automatic session marker is written")
    var home: Control = load("res://scenes/mode_menu.tscn").instantiate()
    root.add_child(home)
    await process_frame
    await process_frame
    var scroll := home.get_node_or_null("HomeScroll") as ScrollContainer
    var center := home.get_node_or_null("HomeScroll/HomeMargin") as CenterContainer
    _check(scroll != null and center != null, "home scroll and center exist")
    _check(center != null and center.size_flags_vertical == Control.SIZE_SHRINK_BEGIN, "home content is top aligned instead of vertically centered and clipped")
    _check(scroll != null and scroll.mouse_filter == Control.MOUSE_FILTER_PASS, "home scroll doesn't consume unrelated empty-area input")
    home.queue_free()
    var clubs := root.get_node_or_null("ClubsService")
    if clubs != null:
        clubs.active_club_id = "c1"
    var club_screen: Control = load("res://scenes/club_chat_screen.tscn").instantiate()
    root.add_child(club_screen)
    await process_frame
    await process_frame
    var members := club_screen.find_child("MembersButton", true, false) as Button
    var composer := club_screen.find_child("ChatComposer", true, false) as Control
    var send := club_screen.find_child("SendMessage", true, false) as Button
    _check(members != null and members.size.x >= 110.0, "club member action has enough horizontal width")
    _check(composer != null and composer.get_combined_minimum_size().y <= 65.0, "club chat composer stays compact")
    _check(send != null and send.size.x >= 48.0, "club send action stays an icon-sized touch target")
    var bundle: Dictionary = hub.export_qa_bundle(4) if hub != null else {"ok": false}
    _check(bool(bundle.get("ok", false)), "QA bundle exports without manual menu interaction")
    print("V138 VISUAL/QA SMOKE: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed > 0 else 0)
