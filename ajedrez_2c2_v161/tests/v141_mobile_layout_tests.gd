extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var gesture := root.get_node_or_null("MobileScrollGesture")
    _check(gesture != null, "global mobile gesture agent is registered")

    await _show_scene("res://scenes/mode_menu.tscn")
    var home := current_scene
    var home_scroll := home.find_child("HomeScroll", true, false) as ScrollContainer
    _check(home_scroll != null, "home has a vertical scroll container")
    if home_scroll != null:
        _check(home_scroll.size.x <= get_root().get_visible_rect().size.x + 2.0, "home scroll stays within portrait viewport width")
        var subtitle := home.find_child("Subtitle", true, false) as Label
        _check(subtitle != null and subtitle.size.x <= home_scroll.size.x + 2.0, "home subtitle wraps within the visible content width")
        var play := home.find_child("PlayButton", true, false) as Button
        var before := home_scroll.scroll_vertical
        if gesture != null and play != null:
            var activations := [0]
            play.pressed.connect(func(): activations[0] += 1)
            var pos := play.get_global_rect().get_center()
            _send_touch(gesture, pos, true)
            _send_drag(gesture, pos + Vector2(1, -120))
            _check(home_scroll.scroll_vertical > before, "swiping across the Play button scrolls instead of activating it")
            _send_touch(gesture, pos + Vector2(1, -120), false)
            _check(not bool(gesture.get("_dragging")), "touch drag state resets after release")
            _check(activations[0] == 0, "drag release does not accidentally activate the button")
            home_scroll.scroll_vertical = 0
            await process_frame
            pos = play.get_global_rect().get_center()
            _send_touch(gesture, pos, true)
            _send_touch(gesture, pos, false)
            _check(activations[0] == 1, "a short tap still activates the button normally")

    var clubs_service := root.get_node_or_null("ClubsService")
    if clubs_service != null:
        clubs_service.join_club("c1")
    await _show_scene("res://scenes/club_browser_screen.tscn")
    var clubs := current_scene
    var club_scroll := clubs.find_child("ClubScroll", true, false) as ScrollContainer
    _check(club_scroll != null, "club browser has a scroll container")
    if club_scroll != null:
        _check(club_scroll.size.x <= get_root().get_visible_rect().size.x + 2.0, "club browser stays within portrait viewport width")
        var list := clubs.find_child("ClubList", true, false) as VBoxContainer
        if list != null and list.get_child_count() > 0:
            var card := list.get_child(0) as Button
            var row := card.get_child(0) as Control if card.get_child_count() > 0 else null
            _check(row != null and row.size.x >= card.size.x * 0.8, "club card content fills the card instead of collapsing into a narrow column")
        else:
            _check(false, "club browser contains club cards")

    await _show_scene("res://scenes/club_chat_screen.tscn")
    var chat := current_scene
    var composer := chat.find_child("ChatComposer", true, false) as Control
    var chat_nav := chat.find_child("Bar", true, false) as Control
    _check(composer != null, "club chat composer exists")
    _check(chat_nav != null, "club chat bottom navigation exists")
    if composer != null and chat_nav != null:
        var composer_bottom := composer.get_global_rect().end.y
        var nav_top := chat_nav.get_global_rect().position.y
        _check(composer_bottom <= nav_top + 4.0, "club chat composer does not overlap bottom navigation (composer %.1f, nav %.1f)" % [composer_bottom, nav_top])

    await _show_scene("res://scenes/club_members_screen.tscn")
    var members := current_scene
    var member_scroll := members.find_child("MembersScroll", true, false) as ScrollContainer
    var member_nav := members.find_child("Bar", true, false) as Control
    _check(member_scroll != null, "members screen has a scroll container")
    _check(member_nav != null, "members screen bottom navigation exists")
    if member_scroll != null:
        _check(member_scroll.size.x <= get_root().get_visible_rect().size.x + 2.0, "members scroll stays within portrait viewport width")
        _check(member_scroll.get_child(0).size.x >= member_scroll.size.x * 0.9, "member list fills the available width")
        var list := member_scroll.get_child(0)
        if list.get_child_count() > 0:
            var card := list.get_child(0) as Control
            _check(card.size.x >= member_scroll.size.x * 0.9 and card.size.y < 180.0, "member cards remain wide and compact")
    if member_scroll != null and member_nav != null:
        var list_bottom := member_scroll.get_global_rect().end.y
        var nav_top := member_nav.get_global_rect().position.y
        _check(list_bottom <= nav_top + 4.0, "members list ends above bottom navigation (list %.1f, nav %.1f)" % [list_bottom, nav_top])

    print("V141 MOBILE LAYOUT: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _show_scene(path: String) -> void:
    var err := change_scene_to_file(path)
    _check(err == OK, "scene loads: " + path.get_file())
    await process_frame
    await process_frame
    await create_timer(0.15).timeout

func _send_touch(service: Node, pos: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = 0
    event.pressed = pressed
    event.position = pos
    get_root().push_input(event, true)

func _send_drag(service: Node, pos: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = 0
    event.position = pos
    event.relative = Vector2(0, -120)
    get_root().push_input(event, true)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
