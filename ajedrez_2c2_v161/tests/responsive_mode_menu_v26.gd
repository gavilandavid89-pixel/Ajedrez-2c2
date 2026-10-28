extends SceneTree

const SCENE := preload("res://scenes/mode_menu.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    for vp in [Vector2(360, 640), Vector2(390, 844), Vector2(691, 1379), Vector2(800, 480), Vector2(1280, 720)]:
        await _check_viewport(vp)
    _check(int(ProjectSettings.get_setting("display/window/size/viewport_width", -1)) == 720, "base viewport width is 720")
    _check(int(ProjectSettings.get_setting("display/window/size/viewport_height", -1)) == 720, "base viewport height is 720")
    print("MODE MENU RESPONSIVE V26: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check_viewport(vp: Vector2) -> void:
    var sub := SubViewport.new()
    sub.size = vp
    sub.render_target_update_mode = SubViewport.UPDATE_ONCE
    root.add_child(sub)
    var holder := Node2D.new()
    sub.add_child(holder)
    var menu: Control = SCENE.instantiate()
    holder.add_child(menu)
    await process_frame
    await process_frame
    var vbox := menu.get_node("Margin/VBox") as VBoxContainer
    var primary := menu.get_node("Margin/VBox/2c2") as Button
    var secondary := menu.get_node("Margin/VBox/1c1") as Button
    var profile := menu.get_node("ProfileButton") as Button
    var portrait := vp.y >= vp.x
    var width_ratio := 0.92 if portrait else 0.68
    var max_width := 720.0 if portrait else 920.0
    var min_width := 320.0 if portrait else 520.0
    var expected_width := clampf(vp.x * width_ratio, min_width, max_width)
    _check(absf(vbox.custom_minimum_size.x - expected_width) < 0.5, "menu width scales at %s" % vp)
    _check(primary.custom_minimum_size.y >= 56.0, "primary target remains touchable at %s" % vp)
    _check(secondary.custom_minimum_size.y >= 56.0, "secondary target remains touchable at %s" % vp)
    _check(profile.custom_minimum_size.x >= 48.0 and profile.custom_minimum_size.x <= 60.0, "profile is icon-only and touchable at %s" % vp)
    _check(profile.text.strip_edges().is_empty(), "profile shows no player name at %s" % vp)
    _check(profile.icon != null, "profile exposes avatar icon at %s" % vp)
    var nav = menu.get_node_or_null("MainNavigation")
    _check(nav != null and nav.get_node("Bar/Items").get_child_count() == 4, "main navigation remains present at %s" % vp)
    sub.queue_free()

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        print("[FAIL] ", label)
