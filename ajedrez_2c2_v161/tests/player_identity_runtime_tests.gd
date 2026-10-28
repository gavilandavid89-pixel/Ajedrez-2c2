extends SceneTree

const IdentityTests = preload("res://tests/player_identity_tests.gd")

func _initialize() -> void:
    await process_frame
    var data = get_root().get_node_or_null("PlayerData")
    if data == null:
        push_error("PlayerData autoload no disponible")
        quit(1)
        return
    var runner = IdentityTests.new()
    var report: Dictionary = runner.run(data)
    print("PLAYER IDENTITY: %d/%d OK" % [int(report["passed"]), int(report["passed"]) + int(report["failed"])])
    for item in report["checks"]:
        print("[%s] %s" % ["OK" if bool(item["ok"]) else "FAIL", String(item["label"])])
    quit(0 if int(report["failed"]) == 0 else 1)
