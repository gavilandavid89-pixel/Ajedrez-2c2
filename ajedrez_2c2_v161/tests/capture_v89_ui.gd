extends SceneTree
const MAIN=preload("res://scenes/mode_menu.tscn")
const ACCOUNT=preload("res://scenes/account_hub.tscn")
func _initialize():
    DisplayServer.window_set_size(Vector2i(720,1280))
    await process_frame
    await process_frame
    var main=MAIN.instantiate(); root.add_child(main)
    await process_frame; await process_frame
    var img=get_root().get_texture().get_image()
    img.save_png("/mnt/data/aj2c2_work/v89/home_720x1280.png")
    main.queue_free(); await process_frame
    var account=ACCOUNT.instantiate(); root.add_child(account)
    await process_frame; await process_frame
    account.page="profile_edit"; account._refresh()
    await process_frame; await process_frame
    img=get_root().get_texture().get_image()
    img.save_png("/mnt/data/aj2c2_work/v89/profile_edit_720x1280.png")
    account.queue_free(); await process_frame
    quit(0)
