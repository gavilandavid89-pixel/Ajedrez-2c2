extends SceneTree

const ReplayViewScript := preload("res://domain/replay/match_replay_view.gd")
const GameStateScript := preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(390, 844))
	var view := ReplayViewScript.new()
	root.add_child(view)
	await process_frame
	var game_state := GameStateScript.new()
	game_state.reset_match(GameStateScript.MODE_1C1_LOCAL)
	game_state.attempt_move(Vector2i(4,6), Vector2i(4,4))
	game_state.attempt_move(Vector2i(4,1), Vector2i(4,3))
	view.set_replay_data(game_state.replay_data(), game_state.replay_moves())
	view.set_match_metadata({"match_id":"V158_ANALYSIS_CAPTURE", "outcome":"win", "white_player":{"id":"you", "name":"Tú", "rating":1200}, "black_player":{"id":"rival1", "name":"Rival", "rating":1180}, "white_time":287.0, "black_time":274.0})
	view.set_review_mode("analysis")
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := get_root().get_texture().get_image()
	image.save_png("/mnt/data/v158_analysis_shared_layout.png")
	quit(0)
