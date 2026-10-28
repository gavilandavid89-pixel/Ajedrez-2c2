extends SceneTree

const SKIN_DIR := "res://assets/pieces/skin_graphite_gold"
const CLASSIC_DIR := "res://assets/pieces"
const WHITE_FILL := Color(1.0, 1.0, 1.0, 1.0)
const BLACK_FILL := Color(10.0 / 255.0, 13.0 / 255.0, 18.0 / 255.0, 1.0)

var passed := 0
var failed := 0

func _initialize() -> void:
    for piece in ["rook", "knight", "bishop", "queen", "king", "pawn"]:
        _check(_filled_pixels("%s/white_%s.png" % [SKIN_DIR, piece], WHITE_FILL) >= 500, "blanca %s tiene relleno blanco visible" % piece)
        _check(_filled_pixels("%s/black_%s.png" % [SKIN_DIR, piece], BLACK_FILL) >= 500, "negra %s tiene relleno negro visible" % piece)
        _check(FileAccess.file_exists("%s/white_%s.png" % [CLASSIC_DIR, piece]), "classic blanca %s intacta" % piece)
        _check(FileAccess.file_exists("%s/black_%s.png" % [CLASSIC_DIR, piece]), "classic negra %s intacta" % piece)
    print("FILLED_PIECE_SKIN_V96_TESTS: %d OK / %d FALLARON" % [passed, failed])
    quit(0 if failed == 0 else 1)

func _filled_pixels(path: String, color: Color) -> int:
    var image := Image.load_from_file(ProjectSettings.globalize_path(path))
    if image == null or image.is_empty():
        return 0
    var target := Color8(int(color.r * 255.0), int(color.g * 255.0), int(color.b * 255.0), 255)
    var count := 0
    for y in image.get_height():
        for x in image.get_width():
            if image.get_pixel(x, y) == target:
                count += 1
    return count

func _check(ok: bool, label: String) -> void:
    if ok:
        passed += 1
        print("[OK] %s" % label)
    else:
        failed += 1
        push_error("[FALLA] %s" % label)
