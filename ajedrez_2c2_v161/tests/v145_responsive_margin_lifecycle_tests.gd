extends SceneTree

const Factory := preload("res://ui/components/social/social_ui_factory.gd")
const ControllerScript := preload("res://core/layout/responsive_margin_controller.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    await process_frame
    var host := Control.new()
    host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(host)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    host.add_child(margin)
    Factory.configure_main_content_margin(host, margin, 14, 104, 12, 12, 174, 16, 16)
    await process_frame
    await process_frame
    var controller := host.get_node_or_null("ResponsiveMarginController") as ResponsiveMarginController
    _check(controller != null, "shared factory creates a screen-owned responsive controller")
    _check(margin.offset_left == 12.0 and margin.offset_right == -12.0, "portrait margins applied")
    _check(margin.offset_top == 14.0 and margin.offset_bottom == -104.0, "portrait top and navigation reserve applied")

    var viewport := get_root()
    var callable := Callable(controller, "_on_viewport_size_changed") if controller != null else Callable()
    _check(controller != null and viewport.size_changed.is_connected(callable), "controller owns viewport resize subscription")
    host.queue_free()
    await process_frame
    _check(controller == null or not is_instance_valid(controller), "controller is destroyed with its screen")
    _check(not viewport.size_changed.is_connected(callable), "viewport callback disconnects when screen is destroyed")
    # A second host validates that orientation margins are set for a wide viewport.
    get_root().size = Vector2i(960, 540)
    await process_frame
    await process_frame
    var host2 := Control.new()
    host2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.add_child(host2)
    var margin2 := MarginContainer.new()
    margin2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    host2.add_child(margin2)
    Factory.configure_main_content_margin(host2, margin2, 14, 104, 12, 12, 174, 16, 16)
    await process_frame
    await process_frame
    _check(margin2.offset_left == 174.0 and margin2.offset_right == -16.0, "landscape margins applied")
    _check(margin2.offset_top == 10.0 and margin2.offset_bottom == -16.0, "landscape safe area applied")
    print("V145 RESPONSIVE MARGIN LIFECYCLE: %d OK / %d FAILED" % [passed, failed])
    quit(1 if failed else 0)

func _check(ok: bool, message: String) -> void:
    if ok:
        passed += 1
        print("[OK] " + message)
    else:
        failed += 1
        push_error("[FAIL] " + message)
