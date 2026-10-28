extends SceneTree
const ReplayViewScript := preload("res://domain/replay/match_replay_view.gd")
const GameStateScript := preload("res://domain/chess/game_state.gd")
func _initialize() -> void:
    call_deferred("_run")
func _run() -> void:
    DisplayServer.window_set_size(Vector2i(390, 844))
    var view := ReplayViewScript.new()
    root.add_child(view)
    view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    await process_frame
    var game_state := GameStateScript.new()
    game_state.reset_match(GameStateScript.MODE_1C1_LOCAL)
    game_state.attempt_move(Vector2i(4,6), Vector2i(4,4))
    game_state.attempt_move(Vector2i(4,1), Vector2i(4,3))
    view.set_replay_data(game_state.replay_data(), game_state.replay_moves())
    view.set_match_metadata({"match_id":"V160_ANALYSIS_CAPTURE", "outcome":"win", "white_player":{"id":"you", "name":"Tú", "nexus":1200}, "black_player":{"id":"rival1", "name":"Rival", "nexus":1180}, "white_time":287.0, "black_time":274.0})
    view.set_engine_analysis({"moves":[{"classification":"Excelente", "coach_text":"Desarrollas una pieza y disputas el centro. Mantén la coordinación de tus piezas.", "loss":8.0, "best_move":"g1-f3"},{"classification":"Imprecisa", "coach_text":"Esta respuesta permite una mejora al rival. Considera desarrollar una pieza y proteger el centro.", "loss":42.0, "best_move":"b1-c3"}]})
    view.set_review_mode("analysis")
    view.set_replay_position(1)
    await process_frame
    await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("/mnt/data/v161_analisis_barra.png")
    view.set_review_mode("replay")
    await process_frame
    await RenderingServer.frame_post_draw
    get_root().get_texture().get_image().save_png("/mnt/data/v161_replay_planilla.png")
    quit(0)
