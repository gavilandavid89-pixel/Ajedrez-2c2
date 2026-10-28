extends SceneTree

const BOARD_PATH := "res://ui/components/board.gd"
const PREVIEW_PATH := "res://ui/components/account_page_renderer.gd"
const PLAYER := preload("res://domain/player/player_data.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var board := FileAccess.get_file_as_string(BOARD_PATH)
    var preview := FileAccess.get_file_as_string(PREVIEW_PATH)
    _check(preview.contains("Previsualizar"), "la pantalla ofrece previsualización antes de equipar")
    _check(preview.contains("Equipar"), "la pantalla ofrece equipamiento explícito")
    _check(preview.contains("_preview_board_theme"), "el tablero usa estado temporal de previsualización")
    _check(preview.contains("_preview_piece_set"), "las piezas usan estado temporal de previsualización")
    _check(not preview.contains("_data().set_game_skin(skin_id)"), "la interfaz ya no equipa tablero y piezas como un único bloque")
    _check(preview.contains('"board_theme", value'), "el tablero se equipa mediante su propia clave")
    _check(preview.contains('"piece_set", value'), "las piezas se equipan mediante su propia clave")
    _check(board.contains('var board_theme: String = "classic"'), "la partida conserva tablero clásico como fallback")
    _check(board.contains('var piece_set: String = "classic"'), "la partida conserva piezas clásicas como fallback")

    var data := PLAYER.new()
    data.name = "IndependentSkinTest"
    root.add_child(data)
    await process_frame
    data.appearance["board_theme"] = "classic"
    data.appearance["piece_set"] = "classic"
    _check(data.get_appearance("board_theme", "classic") == "classic" and data.get_appearance("piece_set", "classic") == "classic", "estado inicial clásico")
    data.set_appearance("piece_set", "graphite_gold")
    _check(data.get_appearance("board_theme", "classic") == "classic" and data.get_appearance("piece_set", "classic") == "graphite_gold", "permite piezas nuevas sobre tablero clásico")
    data.set_appearance("board_theme", "graphite_gold")
    _check(data.get_appearance("board_theme", "classic") == "graphite_gold" and data.get_appearance("piece_set", "classic") == "graphite_gold", "permite equipar después el tablero de forma independiente")
    data.set_appearance("board_theme", "classic")
    _check(data.get_appearance("board_theme", "classic") == "classic" and data.get_appearance("piece_set", "classic") == "graphite_gold", "volver al tablero clásico no cambia las piezas")
    data.set_appearance("piece_set", "classic")
    data.queue_free()
    print("SKIN_INDEPENDENT_PREVIEW_V98_TESTS: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] %s" % label)
    else:
        failed += 1
        push_error("[FALLA] %s" % label)
