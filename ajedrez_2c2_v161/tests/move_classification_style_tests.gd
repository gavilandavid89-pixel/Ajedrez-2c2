extends SceneTree
const Style = preload("res://core/review/move_classification_style.gd")
func _initialize() -> void:
    var failed := 0
    if Style.color_for("Genial", Color.WHITE) != Color("#61A8FF"):
        push_error("[FALLA] Genial retains its existing classification color")
        failed += 1
    else: print("[OK] Existing Genial classification color is reused")
    if Style.color_for("Brillante", Color.WHITE) != Color("#C07CFF"):
        push_error("[FALLA] Brillante retains its existing classification color")
        failed += 1
    else: print("[OK] Existing Brillante classification color is reused")
    if Style.color_for("Sin clasificación", Color.WHITE) != Color.WHITE:
        push_error("[FALLA] Missing classification stays neutral")
        failed += 1
    else: print("[OK] Missing classification remains neutral")
    if not Style.is_important("Error grave") or Style.is_important("Sin clasificación"):
        push_error("[FALLA] Importance lookup uses existing labels only")
        failed += 1
    else: print("[OK] Important move lookup uses existing labels")
    print("MOVE CLASSIFICATION STYLE TESTS: %d OK / %d FALLARON" % [4-failed, failed])
    quit(1 if failed else 0)
