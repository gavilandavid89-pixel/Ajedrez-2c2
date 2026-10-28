extends SceneTree

const GAME_SCENE = preload("res://scenes/game.tscn")
var passed := 0
var failed := 0

func _initialize() -> void:
    await process_frame
    var screen = GAME_SCENE.instantiate()
    root.add_child(screen)
    await process_frame
    await process_frame
    var board = screen.get_node("Board")
    var game = screen.game
    _ok(board != null and board.move_animator != null, "animator attached to live board")
    _ok(game.attempt_move(Vector2i(4, 6), Vector2i(4, 4)), "e2-e4 accepted")
    screen._on_state_changed()
    _ok(board.is_move_animation_active(), "live game starts a visual move")
    _ok(board.last_move_highlight.get("from", "") == "e2", "origin square stored for highlight")
    _ok(board.last_move_highlight.get("to", "") == "e4", "destination square stored for highlight")
    _ok(board._parse_square("e2") == Vector2i(4, 6), "origin maps to correct board square")
    _ok(board._parse_square("e4") == Vector2i(4, 4), "destination maps to correct board square")
    await create_timer(0.08).timeout
    _ok(board.is_move_animation_active(), "piece is still travelling mid-animation")
    _ok(board.move_animator.elapsed > 0.0 and board.move_animator.elapsed < board.move_animator.duration, "animation interpolates elapsed progress")
    await create_timer(0.40).timeout
    _ok(not board.is_move_animation_active(), "piece lands and animation finishes")
    var audio = root.get_node_or_null("AudioFeedback")
    _ok(audio != null and bool(audio._spec("move_impact").get("wood", false)), "normal landing uses wood-like transient sound")
    _ok(audio != null and bool(audio._spec("capture_impact").get("wood", false)), "capture landing uses differentiated wood-like sound")
    game.reset_match(0, 10)
    screen._on_state_changed()
    _ok(board.last_move_highlight.is_empty(), "reset clears previous move highlights")
    _ok(not board.is_move_animation_active(), "reset cancels any previous animation")
    screen.queue_free()
    await process_frame
    print("MOVE_FEEDBACK_V100: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
