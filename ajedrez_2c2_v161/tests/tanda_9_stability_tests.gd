extends SceneTree

const GameScene := preload("res://scenes/game.tscn")
const GameState := preload("res://domain/chess/game_state.gd")
const BotData := preload("res://domain/bots/bot_data.gd")
const AppConfig := preload("res://core/services/app.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    await process_frame
    _test_gallery_safety()
    _test_turn_normalization()
    _test_bot_delays_are_natural()
    await _test_real_touch_sequence()
    print("TANDA 9 ESTABILIDAD: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _ok(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        print("[FAIL] ", label)

func _test_gallery_safety() -> void:
    var root := "user://ajedrez_2c2"
    for dir_path in [root, root + "/cache", root + "/backup"]:
        DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
        var marker := ProjectSettings.globalize_path(dir_path + "/.nomedia")
        if not FileAccess.file_exists(marker):
            var f := FileAccess.open(marker, FileAccess.WRITE)
            if f: f.close()
        _ok(FileAccess.file_exists(marker), "directorio privado con .nomedia: %s" % dir_path)

    var offenders: Array[String] = []
    var scan := DirAccess.open("res://")
    _scan_for_public_media_paths(scan, "res://", offenders)
    _ok(offenders.is_empty(), "assets no usan rutas publicas de galeria")

func _scan_for_public_media_paths(dir, prefix: String, offenders: Array[String]) -> void:
    if dir == null:
        return
    dir.list_dir_begin()
    var name: String = dir.get_next()
    while not name.is_empty():
        if name in [".godot", ".git", "tests"]:
            name = dir.get_next()
            continue
        var path := prefix + name
        if dir.current_is_dir():
            var child := DirAccess.open(path)
            _scan_for_public_media_paths(child, path + "/", offenders)
        elif name.ends_with(".gd"):
            var f := FileAccess.open(path, FileAccess.READ)
            var text := f.get_as_text() if f else ""
            for token in ["DCIM", "/Pictures", "/Movies", "/Download", "Environment.DIRECTORY_PICTURES", "Environment.DIRECTORY_MOVIES"]:
                if token in text:
                    offenders.append(path + " -> " + token)
        name = dir.get_next()
    dir.list_dir_end()

func _test_turn_normalization() -> void:
    var game := GameState.new()
    root.add_child(game)
    game.reset_match(GameState.MODE_2C2, 1)
    game.force_slot_absent(0)
    _ok(game.current_slot == 0 or game.current_slot == 2, "ausencia inicial no rompe el turno")
    if game.current_slot == 0:
        game.attempt_move(Vector2i(4,6), Vector2i(4,4))
    _ok(game.current_actor_slot() >= 0, "siempre existe actor válido mientras el equipo tenga representante")
    game.queue_free()
    await process_frame

func _test_bot_delays_are_natural() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 12345
    var seen := {}
    for id in ["mateo", "nora", "tactico", "estratega", "aegis"]:
        var base := BotData.thinking_time_for(id)
        var delay := BotData.thinking_delay_for(id, rng)
        _ok(delay >= 0.70 and delay <= 2.10, "delay válido %s" % id)
        _ok(abs(delay - base) <= 0.15, "delay %s varía de forma controlada" % id)
        seen[id] = delay
    _ok(seen["mateo"] > seen["aegis"], "Elo influye en la espera (Mateo vs Aegis)")

func _board_point(board, logical: Vector2i) -> Vector2:
    var cell: float = board.board_rect.size.x / 8.0
    var screen := logical
    if board.flipped:
        screen = Vector2i(7 - logical.x, 7 - logical.y)
    return board.get_global_transform_with_canvas() * (board.board_rect.position + Vector2((screen.x + 0.5) * cell, (screen.y + 0.5) * cell))

func _touch(root_game, logical: Vector2i) -> void:
    var p := _board_point(root_game.board_view, logical)
    var down := InputEventScreenTouch.new()
    down.position = p
    down.pressed = true
    root_game._input(down)
    var up := InputEventScreenTouch.new()
    up.position = p
    up.pressed = false
    root_game._input(up)

func _test_real_touch_sequence() -> void:
    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = AppConfig.MODE_VS_BOT
    var root_game = GameScene.instantiate()
    root.add_child(root_game)
    await process_frame
    await process_frame
    var game: GameState = root_game.game
    root_game.queue_free()
    await process_frame
