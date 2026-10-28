extends SceneTree
const SCENE = preload("res://scenes/account_hub.tscn")
var failed := 0
func _initialize() -> void:
    var vp := SubViewport.new(); vp.size = Vector2(390,844); vp.render_target_update_mode = SubViewport.UPDATE_DISABLED; root.add_child(vp)
    var scene = SCENE.instantiate(); vp.add_child(scene)
    await process_frame; await process_frame
    var scroll: ScrollContainer = scene.content.get_node("Scroll")
    var body = scene.body
    var before := int(scroll.scroll_vertical)
    var down := InputEventScreenTouch.new(); down.position = Vector2(180,400); down.pressed = true; scene._input(down)
    var drag := InputEventScreenDrag.new(); drag.position = Vector2(180,250); drag.relative = Vector2(0,-150); scene._input(drag)
    var after := int(scroll.scroll_vertical)
    var up := InputEventScreenTouch.new(); up.position = Vector2(180,250); up.pressed = false; scene._input(up)
    print("scroll before=",before," after=",after)
    if after <= before: failed += 1
    var start := Time.get_ticks_usec()
    for i in range(10):
        scene._refresh()
        await process_frame
    var elapsed_ms := float(Time.get_ticks_usec()-start)/1000.0
    print("10 profile refreshes ms=",elapsed_ms)
    if elapsed_ms > 2500.0: failed += 1
    # Stay on the screen for a while, then prove touch scrolling still responds.
    for i in range(180):
        await process_frame
    var idle_before := int(scroll.scroll_vertical)
    var down_late := InputEventScreenTouch.new(); down_late.position = Vector2(180,500); down_late.pressed = true; scene._input(down_late)
    var drag_late := InputEventScreenDrag.new(); drag_late.position = Vector2(180,340); drag_late.relative = Vector2(0,-160); scene._input(drag_late)
    var idle_after := int(scroll.scroll_vertical)
    var up_late := InputEventScreenTouch.new(); up_late.position = Vector2(180,340); up_late.pressed = false; scene._input(up_late)
    print("scroll after idle before=", idle_before, " after=", idle_after)
    if idle_after <= idle_before: failed += 1
    print("PROFILE PERF V27: %d/%d OK" % [3-failed,3])
    quit(1 if failed else 0)
