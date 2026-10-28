extends SceneTree

const BOARD_PATH := "res://ui/components/board.gd"
const PREVIEW_PATH := "res://ui/components/account_page_renderer.gd"
const CUSTOMIZATION_PATH := "res://domain/player/player_customization_service.gd"
const PLAYER_DATA_PATH := "res://domain/player/player_data.gd"
const PLAYER := preload("res://domain/player/player_data.gd")
const CLASSIC_DIR := "res://assets/pieces"
const SKIN_DIR := "res://assets/pieces/skin_graphite_gold"

var passed := 0
var failed := 0

func _initialize() -> void:
    var source := FileAccess.get_file_as_string(BOARD_PATH)
    var preview := FileAccess.get_file_as_string(PREVIEW_PATH)
    var customization := FileAccess.get_file_as_string(CUSTOMIZATION_PATH)
    var player_source := FileAccess.get_file_as_string(PLAYER_DATA_PATH)

    _check(source.contains('"classic": {"light": Color("#F0D9B5"), "dark": Color("#B58863")}'), "el tablero clásico conserva sus colores originales")
    _check(source.contains('"graphite_gold": {"light": Color("#68707A"), "dark": Color("#30363E")}'), "la skin grafito + dorado tiene su propio tablero")
    _check(source.contains('res://assets/pieces/white_queen.png'), "las piezas clásicas siguen en sus assets originales")
    _check(source.contains('res://assets/pieces/skin_graphite_gold/white_queen.png'), "la nueva skin usa assets separados")
    _check(preview.contains('res://assets/pieces/white_queen.png'), "la vista previa conserva las piezas clásicas")
    _check(preview.contains('res://assets/pieces/skin_graphite_gold/white_queen.png'), "la vista previa muestra la nueva skin")
    _check(customization.contains('"board_theme": ["classic", "graphite_gold"]'), "el tema nuevo es seleccionable sin reemplazar classic")
    _check(customization.contains('"piece_set": ["classic", "graphite_gold"]'), "el conjunto nuevo es seleccionable sin reemplazar classic")
    _check(player_source.contains('"board_theme": "classic"'), "classic sigue siendo el valor predeterminado del tablero")
    _check(player_source.contains('"piece_set": "classic"'), "classic sigue siendo el valor predeterminado de las piezas")
    var data := PLAYER.new()
    data.name = "SkinTestPlayerData"
    root.add_child(data)
    await process_frame
    _check(data.set_game_skin("graphite_gold"), "la skin completa se puede activar desde un único método")
    _check(data.get_appearance("board_theme", "classic") == "graphite_gold" and data.get_appearance("piece_set", "classic") == "graphite_gold", "la skin completa sincroniza tablero y piezas")
    data.set_game_skin("classic")
    _check(data.get_appearance("board_theme", "classic") == "classic" and data.get_appearance("piece_set", "classic") == "classic", "la prueba restaura la skin clásica al terminar")
    data.queue_free()

    for piece in ["white_rook","white_knight","white_bishop","white_queen","white_king","white_pawn","black_rook","black_knight","black_bishop","black_queen","black_king","black_pawn"]:
        _check(FileAccess.file_exists("%s/%s.png" % [CLASSIC_DIR, piece]), "classic conserva %s" % piece)
        _check(FileAccess.file_exists("%s/%s.png" % [SKIN_DIR, piece]), "skin_graphite_gold contiene %s" % piece)

    print("CLASSIC_PLUS_SKIN_V95_TESTS: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] %s" % label)
    else:
        failed += 1
        push_error("[FALLA] %s" % label)
