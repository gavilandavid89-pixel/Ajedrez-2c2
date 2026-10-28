extends SceneTree

const AccountScene := preload("res://scenes/account_hub.tscn")

var passed := 0
var failed := 0

func _initialize() -> void:
    var host := AccountScene.instantiate()
    root.add_child(host)
    await process_frame
    await process_frame
    host.page = "ranking"
    host.ranking_mode = "1c1"
    host._refresh()
    await process_frame
    _check(host.body != null, "Pantalla de ranking carga")
    var mode_row: Node = null
    for child in host.body.get_children():
        var row: Node = child.find_child("RankingModes", true, false)
        if row != null:
            mode_row = row
            break
    _check(mode_row != null, "Ranking tiene selector 1c1/2c2")
    if mode_row != null:
        _check(mode_row.get_node_or_null("Ranking1c1") != null and mode_row.get_node_or_null("Ranking2c2") != null, "Existen modos separados")
        var b2 := mode_row.get_node("Ranking2c2") as Button
        b2.emit_signal("pressed")
        await process_frame
        _check(String(host.ranking_mode) == "2c2", "El selector cambia a 2c2")
        var has_2c2 := false
        var has_1c1 := false
        for child in host.body.get_children():
            var text := _collect_text(child)
            has_2c2 = has_2c2 or text.find("2c2 · NEXUS") >= 0
            has_1c1 = has_1c1 or text.find("1c1 · NEXUS") >= 0
        _check(has_2c2, "Modo 2c2 muestra su clasificación")
        _check(not has_1c1, "Modo 2c2 no mezcla tablas 1c1")
    host.queue_free()
    await process_frame
    print("RANKING MODES V91: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed else 0)

func _collect_text(node: Node) -> String:
    var out := ""
    if node is Label:
        out += String(node.text) + " "
    elif node is Button:
        out += String(node.text) + " "
    for c in node.get_children():
        out += _collect_text(c)
    return out

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FAIL] " + label)
