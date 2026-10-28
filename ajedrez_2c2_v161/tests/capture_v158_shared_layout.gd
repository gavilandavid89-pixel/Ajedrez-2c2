extends SceneTree

const AccountScene := preload("res://scenes/account_hub.tscn")
const GameScene := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DisplayServer.window_set_size(Vector2i(390, 844))
	var player = root.get_node_or_null("PlayerData")
	var app = root.get_node_or_null("App")
	if player == null or app == null:
		quit(1)
		return
	await process_frame
	player.history.clear()
	var game_state := GameState.new()
	game_state.reset_match(GameState.MODE_1C1_LOCAL)
	game_state.attempt_move(Vector2i(4,6), Vector2i(4,4))
	game_state.attempt_move(Vector2i(4,1), Vector2i(4,3))
	game_state.attempt_move(Vector2i(6,7), Vector2i(5,5))
	game_state.attempt_move(Vector2i(1,0), Vector2i(2,2))
	player.record_noncompetitive_match({
		"match_id":"V158_LAYOUT_CAPTURE", "mode":GameState.MODE_1C1_LOCAL, "outcome":"win",
		"move_count":4, "moves":game_state.replay_moves(), "replay_data":game_state.replay_data(),
		"players":["Tú", "Rival"], "player_colors":["white", "black"],
		"white_player":{"id":"you", "name":"Tú", "rating":1200, "avatar":"res://assets/avatars/avatar_you.svg"},
		"black_player":{"id":"rival1", "name":"Rival", "rating":1180, "avatar":"res://assets/avatars/avatar_rival1.svg"},
		"white_time":287.0, "black_time":274.0,
		"clock_history":[{"move_index":0,"white_seconds":300.0,"black_seconds":300.0,"active_color":"white"},{"move_index":2,"white_seconds":287.0,"black_seconds":274.0,"active_color":"white"}]
	})
	game_state.free()
	app.account_start_page = "history"
	var account := AccountScene.instantiate()
	root.add_child(account)
	await process_frame
	await process_frame
	account.selected_history_index = player.history.size() - 1
	account.page = "replay"
	account._refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_save("/mnt/data/v158_replay_shared_layout.png")
	account.queue_free()
	await process_frame
	var live := GameScene.instantiate()
	root.add_child(live)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	_save("/mnt/data/v158_partida_shared_layout.png")
	live.queue_free()
	await process_frame
	player.history.clear()
	player.save_data()
	quit(0)

func _save(path: String) -> void:
	var image := get_root().get_texture().get_image()
	image.save_png(path)
