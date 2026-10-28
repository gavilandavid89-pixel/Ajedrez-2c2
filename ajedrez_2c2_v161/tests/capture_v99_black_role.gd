extends SceneTree

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(390,844))
	await process_frame
	var app = root.get_node_or_null("App")
	if app != null:
		app.selected_mode = 1
	var game_scene = load("res://scenes/game.tscn").instantiate()
	root.add_child(game_scene)
	await process_frame
	await process_frame
	var game = game_scene.game
	game.assign_roles_for_local_team(game.TEAM_BLACK)
	game_scene.board_view.set_flipped(true)
	game_scene.hud.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	image.save_png("/mnt/data/v99_game_as_black.png")
	print("V99 CAPTURE: local_team=", game.local_team(), " current_team=", game.current_team(), " current_slot=", game.current_slot, " flipped=", game_scene.board_view.flipped)
	quit(0)
