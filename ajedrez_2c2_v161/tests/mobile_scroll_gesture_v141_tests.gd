extends SceneTree

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var service := root.get_node_or_null("MobileScrollGesture")
    _check(service != null, "mobile scroll gesture service is registered globally")
    if service == null:
        quit(1)
        return

    var scroll := ScrollContainer.new()
    scroll.name = "GestureTestScroll"
    scroll.position = Vector2(20, 20)
    scroll.size = Vector2(240, 240)
    scroll.mouse_filter = Control.MOUSE_FILTER_STOP
    scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    root.add_child(scroll)
    var content := VBoxContainer.new()
    content.custom_minimum_size = Vector2(220, 900)
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(content)
    var button := Button.new()
    button.text = "Button beneath finger"
    button.custom_minimum_size.y = 80
    content.add_child(button)
    await process_frame
    await process_frame

    var touch := InputEventScreenTouch.new()
    touch.index = 0
    touch.pressed = true
    touch.position = Vector2(80, 80)
    service.call("_input", touch)
    var drag := InputEventScreenDrag.new()
    drag.index = 0
    drag.position = Vector2(80, 35)
    drag.relative = Vector2(0, -45)
    service.call("_input", drag)
    _check(int(scroll.scroll_vertical) > 0, "drag starting over a button scrolls the parent container")
    _check(bool(service.get("_dragging")), "gesture is recognized as a drag after threshold")
    var release := InputEventScreenTouch.new()
    release.index = 0
    release.pressed = false
    release.position = Vector2(80, 35)
    service.call("_input", release)
    _check(not bool(service.get("_dragging")), "gesture state resets on finger release")

    scroll.scroll_vertical = 0
    var horizontal_touch := InputEventScreenTouch.new()
    horizontal_touch.index = 0
    horizontal_touch.pressed = true
    horizontal_touch.position = Vector2(80, 80)
    service.call("_input", horizontal_touch)
    var horizontal_drag := InputEventScreenDrag.new()
    horizontal_drag.index = 0
    horizontal_drag.position = Vector2(150, 76)
    horizontal_drag.relative = Vector2(70, -4)
    service.call("_input", horizontal_drag)
    _check(int(scroll.scroll_vertical) > 0, "horizontal-dominant gesture falls back to vertical scrolling when no horizontal scroller exists")
    var horizontal_release := InputEventScreenTouch.new()
    horizontal_release.index = 0
    horizontal_release.pressed = false
    horizontal_release.position = horizontal_drag.position
    service.call("_input", horizontal_release)
    _check(not bool(service.get("_dragging")), "axis-fallback gesture resets cleanly")

    scroll.queue_free()
    await process_frame
    print("MOBILE SCROLL V141: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
