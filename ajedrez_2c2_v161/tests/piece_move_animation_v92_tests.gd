extends SceneTree

const GameScene = preload("res://scenes/game.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    await process_frame
    var app = get_root().get_node_or_null("App")
    if app != null:
        app.navigation_audit_mode = true
    var game_screen = GameScene.instantiate()
    root.add_child(game_screen)
    await process_frame
    await process_frame

    var board = game_screen.get_node_or_null("Board")
    _ok(board != null, "board exists")
    _ok(board != null and board.move_animator != null, "move animator is modular and attached to board")

    var audio = get_root().get_node_or_null("AudioFeedback")
    _ok(audio != null and not audio._spec("move_impact").is_empty(), "move landing sound is registered")
    _ok(audio != null and not audio._spec("capture_impact").is_empty(), "capture landing sound is registered")

    if board != null:
        var game = game_screen.game
        _ok(not board.is_move_animation_active(), "animator idle before a move")
        _ok(game.attempt_move(Vector2i(4, 6), Vector2i(4, 4)), "test move accepted")
        game_screen._on_state_changed()
        _ok(board.is_move_animation_active(), "animation starts after move state is applied")
        _ok(board.move_animator.active_segments.size() == 1, "normal move has one visual segment")
        _ok(board.move_animator.should_hide_piece_at(Vector2i(4, 4)), "final square is hidden while piece is traveling")

        await create_timer(0.45).timeout
        _ok(not board.is_move_animation_active(), "animation finishes")
        _ok(game.get_piece(Vector2i(4, 4)) == "peon_blanca", "logical board remains authoritative")

        # Enroque: both king and rook animate together.
        game.reset_match(3, 1)
        await process_frame
        game.board = [
            ["", "", "", "", "rey_negro", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["", "", "", "", "", "", "", ""],
            ["rey_blanca", "", "", "", "", "", "", "torre_blanca"],
        ]
        game.current_slot = 0
        var castle_move := {
            "from": "e1",
            "to": "g1",
            "piece": "rey_blanca",
            "captured": "",
            "castle": true,
            "en_passant": false,
            "promotion": false
        }
        board.animate_move(castle_move)
        _ok(board.move_animator.active_segments.size() == 2, "castling animates king and rook")
        await create_timer(0.40).timeout
        _ok(not board.is_move_animation_active(), "castling animation finishes")

    game_screen.queue_free()
    await process_frame
    await process_frame
    if audio != null and audio.player != null:
        audio.player.stop()
        audio.playback = null
        audio.player.stream = null
        audio.player.queue_free()
        audio.player = null
    await process_frame
    await process_frame
    print("V92 MOVE ANIMATION: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _ok(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
