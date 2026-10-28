extends SceneTree

const SCENES := {
    "home": "res://scenes/mode_menu.tscn",
    "friends": "res://scenes/friends_screen.tscn",
    "clubs": "res://scenes/club_browser_screen.tscn",
    "club_detail": "res://scenes/club_detail_screen.tscn",
    "club_create": "res://scenes/club_create_screen.tscn",
    "members": "res://scenes/club_members_screen.tscn",
    "chat": "res://scenes/club_chat_screen.tscn",
    "more": "res://scenes/more_screen.tscn",
    "account": "res://scenes/account_hub.tscn"
}

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa_previews/v146/portrait"))
    root.size = Vector2i(390, 844)
    await process_frame
    await process_frame
    _seed_club_service()
    for key in SCENES:
        await _capture(key, String(SCENES[key]))
    print("V146 portrait captures complete")
    quit(0)

func _seed_club_service() -> void:
    var service := root.get_node_or_null("ClubsService")
    if service == null:
        return
    service.active_club_id = "c1"
    service.selected_club_id = "c1"
    if service.has_method("join_club"):
        service.join_club("c1")

func _capture(key: String, path: String) -> void:
    var packed := load(path) as PackedScene
    if packed == null:
        push_error("Unable to load scene: " + path)
        return
    var scene := packed.instantiate() as Control
    if scene == null:
        push_error("Scene root is not Control: " + path)
        return
    root.add_child(scene)
    await process_frame
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    var filename := ProjectSettings.globalize_path("res://qa_previews/v146/portrait/%s.png" % key)
    var error := root.get_texture().get_image().save_png(filename)
    if error != OK:
        push_error("Failed to save screenshot: " + filename)
    else:
        print("CAPTURE " + filename)
    scene.queue_free()
    await process_frame
