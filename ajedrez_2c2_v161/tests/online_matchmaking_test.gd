extends SceneTree

const SCENE := preload("res://scenes/online_matchmaking.tscn")
const AppConfig = preload("res://core/services/app.gd")

var failed := false

func _initialize() -> void:
    var app = root.get_node_or_null("App")
    if app != null:
        app.selected_mode = AppConfig.MODE_1C1
        app.selected_time_minutes = 15
        app.online_entry = "friend_join"
        app.join_room_code = "A2V7K9"
    var root_scene = SCENE.instantiate()
    root.add_child(root_scene)
    await process_frame
    await process_frame
    var card := root_scene.get_node("Center/Card") as Control
    if card.size.x <= 0.0 or card.size.y <= 0.0:
        failed = true
        print("[FAIL] matchmaking card has no size")
    else:
        print("[OK] matchmaking card visible and sized")
    if root_scene.get_node("Center/Card/Searching").text.is_empty():
        failed = true
        print("[FAIL] matchmaking status empty")
    else:
        print("[OK] matchmaking status present")
    if app != null and root_scene.get_node("Center/Card/Room/Code").text == "A2V7K9":
        print("[OK] join shell conserva código de sala")
    else:
        failed = true
        print("[FAIL] join shell perdió el código")
    print("1C1 ONLINE SHELL: %d OK / %d FALLARON" % [0 if failed else 3, 3 if failed else 0])
    quit(1 if failed else 0)
