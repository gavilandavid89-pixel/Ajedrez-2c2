extends SceneTree

const MODE_MENU = preload("res://scenes/mode_menu.tscn")
const AppConfig = preload("res://core/services/app.gd")

var target := "/mnt/data/friend_setup_capture.png"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var menu = MODE_MENU.instantiate()
    root.add_child(menu)
    await process_frame
    await process_frame
    var setup = menu.get_node("OnlineSetup")
    setup.open_for_mode(AppConfig.MODE_1C1)
    setup._show_friend()
    await process_frame
    await process_frame
    var image = root.get_viewport().get_texture().get_image()
    image.save_png(target)
    menu.queue_free()
    quit()
