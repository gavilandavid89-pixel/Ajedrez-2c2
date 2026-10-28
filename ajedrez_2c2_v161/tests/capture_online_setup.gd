extends SceneTree

const MODE_MENU = preload("res://scenes/mode_menu.tscn")
const AppConfig = preload("res://core/services/app.gd")

var target := "/mnt/data/online_setup_capture.png"

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var menu = MODE_MENU.instantiate()
    root.add_child(menu)
    await process_frame
    await process_frame
    menu.get_node("OnlineSetup").open_for_mode(AppConfig.MODE_2C2)
    await process_frame
    await process_frame
    var image = root.get_viewport().get_texture().get_image()
    image.save_png(target)
    menu.queue_free()
    quit()
