extends SceneTree
const GameState=preload("res://domain/chess/game_state.gd")
const Replay=preload("res://domain/replay/match_replay_view.gd")
func _initialize():
 var game=GameState.new(); game.reset_match(GameState.MODE_1C1_LOCAL)
 game.attempt_move(Vector2i(4,6),Vector2i(4,4)); game.attempt_move(Vector2i(4,1),Vector2i(4,3)); game.attempt_move(Vector2i(6,7),Vector2i(5,5)); game.attempt_move(Vector2i(1,0),Vector2i(2,2))
 var v=Replay.new(); root.add_child(v); await process_frame; await process_frame; v.set_replay_data(game.replay_data(),game.replay_moves())
 await process_frame; await process_frame;
 var im=get_root().get_viewport().get_texture().get_image(); im.save_png("/mnt/data/v40_replay_board.png")
 quit(0)
