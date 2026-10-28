extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    get_root().size = Vector2i(844, 390)
    await process_frame
    var viewport_size := get_root().get_visible_rect().size
    if viewport_size.x <= viewport_size.y:
        print("V141 LANDSCAPE LAYOUT: SKIPPED (run with a landscape viewport)")
        quit(0)
        return
    _check(true, "test viewport is landscape")

    await _show("res://scenes/mode_menu.tscn")
    _check_nav_and_content("HomeScroll", "home")
    var home := current_scene
    var title := home.find_child("Title", true, false) as Control
    var profile := home.find_child("ProfileButton", true, false) as Control
    if profile == null:
        profile = home.find_child("Profile", true, false) as Control
    _check(title != null and title.get_global_rect().position.x > 170.0, "home title stays to the right of the side navigation")
    _check(profile == null or profile.get_global_rect().position.x > 170.0, "home profile does not overlap the side navigation")

    await _show("res://scenes/club_browser_screen.tscn")
    _check_nav_and_content("ClubScroll", "club browser")

    await _show("res://scenes/friends_screen.tscn")
    _check_nav_and_content("FriendsScroll", "friends")

    await _show("res://scenes/more_screen.tscn")
    _check_nav_and_content("MoreScroll", "more options")

    var clubs := root.get_node_or_null("ClubsService")
    if clubs != null:
        clubs.join_club("c1")
    await _show("res://scenes/club_chat_screen.tscn")
    _check_nav_and_content("ChatScroll", "club chat")

    await _show("res://scenes/club_members_screen.tscn")
    _check_nav_and_content("MembersScroll", "club members")

    print("V141 LANDSCAPE LAYOUT: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _check_nav_and_content(scroll_name: String, label: String) -> void:
    var nav := current_scene.find_child("MainNavigation", true, false) as Control
    var bar := current_scene.find_child("Bar", true, false) as Control
    var scroll := current_scene.find_child(scroll_name, true, false) as ScrollContainer
    _check(nav != null and bar != null, label + " has side navigation")
    _check(bar != null and bar.size.x <= 170.0, label + " side navigation stays compact")
    _check(scroll != null and scroll.get_global_rect().position.x >= 170.0, label + " content begins after side navigation")
    if bar != null and scroll != null:
        _check(bar.get_global_rect().end.x <= scroll.get_global_rect().position.x + 2.0, label + " scroll area does not sit underneath side navigation")

func _show(path: String) -> void:
    var err := change_scene_to_file(path)
    _check(err == OK, "scene loads: " + path.get_file())
    await process_frame
    await process_frame
    await create_timer(0.15).timeout

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
