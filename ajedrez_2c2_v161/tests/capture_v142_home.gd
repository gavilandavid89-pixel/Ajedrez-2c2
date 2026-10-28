extends SceneTree
const HOME = preload("res://scenes/mode_menu.tscn")
func _initialize() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    await process_frame
    var home = HOME.instantiate()
    root.add_child(home)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var img = get_root().get_texture().get_image()
    img.save_png("/mnt/data/v142_home_top.png")
    var scroll = home.get_node_or_null("HomeScroll") as ScrollContainer
    if scroll != null:
        scroll.scroll_vertical = 330
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        get_root().get_texture().get_image().save_png("/mnt/data/v142_home_scrolled.png")
    quit(0)
