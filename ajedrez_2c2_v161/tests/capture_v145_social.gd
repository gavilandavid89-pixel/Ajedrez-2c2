extends SceneTree

const SCENES := {
    "home": "res://scenes/mode_menu.tscn",
    "friends": "res://scenes/friends_screen.tscn",
    "clubs": "res://scenes/club_browser_screen.tscn",
    "more": "res://scenes/more_screen.tscn",
    "members": "res://scenes/club_members_screen.tscn",
    "chat": "res://scenes/club_chat_screen.tscn"
}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    get_root().size = Vector2i(390, 844)
    await process_frame
    var clubs_service := root.get_node_or_null("ClubsService")
    if clubs_service != null:
        clubs_service.active_club_id = "c1"
        clubs_service.selected_club_id = "c1"
    for key in SCENES:
        var scene := load(String(SCENES[key])).instantiate() as Control
        root.add_child(scene)
        await process_frame
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        image.save_png("/mnt/data/v145_%s.png" % key)
        scene.queue_free()
        await process_frame
    quit(0)
