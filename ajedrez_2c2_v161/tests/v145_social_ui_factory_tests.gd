extends SceneTree

const Factory := preload("res://ui/components/social/social_ui_factory.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    get_root().size = Vector2i(390, 844)
    await process_frame
    var host := Control.new()
    host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(host)
    var primary := Factory.make_primary("JUGAR", 40)
    var secondary := Factory.make_secondary("ACCIÓN", 40)
    host.add_child(primary)
    host.add_child(secondary)
    _check(primary.custom_minimum_size.y >= 52.0, "primary action enforces 52 px minimum")
    _check(secondary.custom_minimum_size.y >= 48.0, "secondary action enforces 48 px minimum")
    var body := VBoxContainer.new()
    body.custom_minimum_size = Vector2(260, 100)
    host.add_child(body)
    var top := Factory.make_top_bar("Un nombre de club extremadamente largo", body)
    await process_frame
    var title := top.get_node("Title") as Label
    _check(title.clip_text and title.text_overrun_behavior == TextServer.OVERRUN_TRIM_ELLIPSIS, "long top-bar titles have ellipsis fallback")
    _check(title.get_theme_font_size("font_size") <= 26, "long top-bar title reduces its font size")
    Factory.attach_main_nav(host, "friends", func(_section: String) -> void: pass)
    await process_frame
    var nav := host.get_node_or_null("MainNavigation")
    var buttons := nav.get_node("Bar/Items") as BoxContainer if nav != null else null
    _check(buttons != null and buttons.get_child_count() == 4, "bottom navigation keeps four stable destinations")
    if buttons != null:
        var friends_button := buttons.get_child(2) as Button
        _check(friends_button.size.x >= 76.0, "navigation targets retain minimum width")
        _check(friends_button.get_theme_font_size("font_size") <= 22, "navigation labels fit narrow phone widths")
    host.queue_free()
    await process_frame
    await process_frame
    print("V145 SOCIAL UI FACTORY: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
