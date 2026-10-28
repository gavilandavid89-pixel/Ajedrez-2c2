extends SceneTree

var passed := 0
var failed := 0

const SCENES := [
    ["mode_menu", "res://scenes/mode_menu.tscn"],
    ["friends", "res://scenes/friends_screen.tscn"],
    ["clubs", "res://scenes/club_browser_screen.tscn"],
    ["club_detail", "res://scenes/club_detail_screen.tscn"],
    ["club_create", "res://scenes/club_create_screen.tscn"],
    ["members", "res://scenes/club_members_screen.tscn"],
    ["chat", "res://scenes/club_chat_screen.tscn"],
    ["more", "res://scenes/more_screen.tscn"],
    ["account", "res://scenes/account_hub.tscn"]
]

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    for viewport_size in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(844, 390)]:
        root.size = viewport_size
        await process_frame
        await process_frame
        _seed_club_service()
        for entry in SCENES:
            var screen_name := String(entry[0])
            var scene_path := String(entry[1])
            var packed := load(scene_path) as PackedScene
            _check(packed != null, "scene resource loads: " + screen_name)
            if packed == null:
                continue
            var screen := packed.instantiate() as Control
            root.add_child(screen)
            await process_frame
            await process_frame
            await process_frame
            var logical_viewport := root.get_visible_rect().size
            var scrolls := _find_scrolls(screen)
            for scroll in scrolls:
                var rect := scroll.get_global_rect()
                var fits := rect.position.x >= -0.6 and rect.end.x <= logical_viewport.x + 0.6
                if not fits:
                    print("[LAYOUT DIAGNOSTIC] screen=%s viewport=%s logical=%s scroll=%s rect=%s size=%s" % [screen_name, viewport_size, logical_viewport, scroll.get_path(), rect, scroll.size])
                _check(fits, "%s scroll fits logical canvas for %s" % [screen_name, viewport_size])
            if screen_name == "club_detail":
                var scroll := _find_first_scroll(screen)
                _check(scroll != null and scroll.size.x <= logical_viewport.x,
                    "club detail content does not force horizontal overflow %s" % viewport_size)
            if screen_name == "members" and viewport_size.x < viewport_size.y:
                _check(_find_label_text(screen, "Mica") != null, "member identity name remains visible on portrait")
                _check(_find_label_text(screen, "Rey · Fundador") != null, "member role remains visible on portrait")
                var profile_buttons := _find_buttons_with_text(screen, "PERFIL")
                _check(not profile_buttons.is_empty(), "member profile actions are present")
                if not profile_buttons.is_empty():
                    _check(profile_buttons[0].custom_minimum_size.y >= 48.0, "member profile button retains touch target")
            if screen_name == "club_create":
                var icon_scroll := screen.find_child("IconChoicesScroll", true, false) as ScrollContainer
                var gallery := screen.find_child("GalleryButton", true, false) as Button
                _check(icon_scroll != null and gallery != null, "club icon chooser and gallery action exist")
                if icon_scroll != null and gallery != null:
                    _check(icon_scroll.get_global_rect().end.x <= gallery.get_global_rect().position.x + 1.0,
                        "icon chooser leaves room for gallery button %s" % viewport_size)
                    _check(gallery.custom_minimum_size.x >= 80.0, "gallery button remains comfortably tappable")
            screen.queue_free()
            await process_frame
    print("V146 SOCIAL SCREEN FIT: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _seed_club_service() -> void:
    var service := root.get_node_or_null("ClubsService")
    if service == null:
        return
    service.active_club_id = "c1"
    service.selected_club_id = "c1"
    if service.has_method("join_club"):
        service.join_club("c1")

func _find_scrolls(node: Node) -> Array[ScrollContainer]:
    var found: Array[ScrollContainer] = []
    if node is ScrollContainer:
        found.append(node)
    for child in node.get_children():
        found.append_array(_find_scrolls(child))
    return found

func _find_first_scroll(node: Node) -> ScrollContainer:
    if node is ScrollContainer:
        return node as ScrollContainer
    for child in node.get_children():
        var found := _find_first_scroll(child)
        if found != null:
            return found
    return null

func _find_label_text(node: Node, target: String) -> Label:
    if node is Label and (node as Label).text == target:
        return node as Label
    for child in node.get_children():
        var found := _find_label_text(child, target)
        if found != null:
            return found
    return null

func _find_buttons_with_text(node: Node, target: String) -> Array[Button]:
    var found: Array[Button] = []
    if node is Button and (node as Button).text == target:
        found.append(node as Button)
    for child in node.get_children():
        found.append_array(_find_buttons_with_text(child, target))
    return found

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
