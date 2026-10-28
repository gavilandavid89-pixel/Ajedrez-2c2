extends SceneTree

const SCENE := preload("res://scenes/account_hub.tscn")

func _initialize() -> void:
    await _capture("profile", "/mnt/data/account_profile.png")
    await _capture("ranking", "/mnt/data/account_ranking.png")
    await _capture("cups", "/mnt/data/account_cups.png")
    await _capture("appearance", "/mnt/data/account_appearance.png")
    await _capture("settings", "/mnt/data/account_settings.png")
    quit()

func _capture(page: String, path: String) -> void:
    var sv := SubViewport.new()
    sv.size = Vector2(360, 640)
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    root.add_child(sv)
    var scene = SCENE.instantiate()
    sv.add_child(scene)
    await process_frame
    await process_frame
    scene.page = page
    scene._refresh()
    await process_frame
    await process_frame
    var image := sv.get_texture().get_image()
    if image:
        image.save_png(path)
    sv.queue_free()
    await process_frame
