extends SceneTree

const SKIN_DIR := "res://assets/pieces/skin_graphite_gold"
const CLASSIC_DIR := "res://assets/pieces"
const WHITE := Color8(255, 255, 255, 255)
const GOLD := Color8(232, 181, 52, 255)
const BLACK := Color8(10, 13, 18, 255)
const BLUE := Color8(82, 101, 132, 255)

var passed := 0
var failed := 0

func _initialize() -> void:
    for piece in ["rook", "knight", "bishop", "queen", "king", "pawn"]:
        var white_path := "%s/white_%s.png" % [SKIN_DIR, piece]
        var black_path := "%s/black_%s.png" % [SKIN_DIR, piece]
        _check(_count_color(white_path, WHITE) >= 500, "blanca %s está realmente rellena de blanco" % piece)
        _check(_count_color(white_path, GOLD) >= 500, "blanca %s conserva borde/detalle dorado" % piece)
        _check(_count_color(black_path, BLACK) >= 500, "negra %s mantiene relleno negro" % piece)
        _check(_count_color(black_path, BLUE) >= 500, "negra %s usa contorno azul" % piece)
        _check(FileAccess.file_exists("%s/white_%s.png" % [CLASSIC_DIR, piece]), "classic blanca %s permanece separada" % piece)
        _check(FileAccess.file_exists("%s/black_%s.png" % [CLASSIC_DIR, piece]), "classic negra %s permanece separada" % piece)
    print("SKIN_GRAPHITE_GOLD_V97_TESTS: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _count_color(path: String, color: Color) -> int:
    var image := Image.load_from_file(ProjectSettings.globalize_path(path))
    if image == null or image.is_empty():
        return 0
    var count := 0
    for y in image.get_height():
        for x in image.get_width():
            if image.get_pixel(x, y) == color:
                count += 1
    return count

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] %s" % label)
    else:
        failed += 1
        push_error("[FALLA] %s" % label)
