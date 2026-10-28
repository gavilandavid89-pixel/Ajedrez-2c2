extends SceneTree
const GAME_SCENE = preload("res://scenes/game.tscn")
func _initialize() -> void:
    await process_frame
    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = 0
        app.selected_time_minutes = 10
    var sv := SubViewport.new()
    sv.size = Vector2i(390, 844)
    sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sv.disable_3d = true
    root.add_child(sv)
    var game = GAME_SCENE.instantiate()
    sv.add_child(game)
    await process_frame
    await process_frame
    game.game.attempt_move(Vector2i(4, 6), Vector2i(4, 4))
    game._on_state_changed()
    await create_timer(0.09).timeout
    var img = sv.get_texture().get_image()
    img.save_png("/mnt/data/v100_move_mid_animation.png")
    await create_timer(0.35).timeout
    img = sv.get_texture().get_image()
    img.save_png("/mnt/data/v100_move_after_landing.png")
    print("CAPTURED mid-animation and post-landing frames")
    game.queue_free()
    sv.queue_free()
    await process_frame
    await process_frame
    var audio = root.get_node_or_null("AudioFeedback")
    if audio != null and audio.player != null:
        audio.player.stop()
        audio.playback = null
        audio.player.stream = null
        audio.player.queue_free()
        audio.player = null
    await process_frame
    quit(0)
