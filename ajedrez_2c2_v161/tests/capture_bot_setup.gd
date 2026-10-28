extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	change_scene_to_file("res://scenes/bot_setup.tscn")
	await process_frame
	await process_frame
	var vp := get_root().get_viewport()
	var image := vp.get_texture().get_image()
	image.save_png("/mnt/data/ajedrez_work/bot_setup_720x1280.png")
	quit()
