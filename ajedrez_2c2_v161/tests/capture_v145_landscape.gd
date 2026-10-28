extends SceneTree

const SCENES := {
    "home_landscape": "res://scenes/mode_menu.tscn",
    "friends_landscape": "res://scenes/friends_screen.tscn",
    "clubs_landscape": "res://scenes/club_browser_screen.tscn",
    "more_landscape": "res://scenes/more_screen.tscn"
}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    get_root().size = Vector2i(844, 390)
    await process_frame
    for key in SCENES:
        var scene := load(String(SCENES[key])).instantiate() as Control
        root.add_child(scene)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png("/mnt/data/v145_%s.png" % key)
        scene.queue_free()
        await process_frame
    quit(0)
