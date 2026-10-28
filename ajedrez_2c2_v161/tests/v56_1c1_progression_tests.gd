extends SceneTree

const PlayerDataScript = preload("res://domain/player/player_data.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    var data = PlayerDataScript.new()
    data.name = "PlayerData_V56"
    root.add_child(data)
    await process_frame
    data.individual = {"cups": 73, "lifetime_cups": 73, "games": 8, "wins": 5, "losses": 3, "draws": 0, "rating": 1072, "best_rating": 1072}
    data.individual_1c1 = {"cups": 198, "lifetime_cups": 198, "games": 12, "wins": 9, "losses": 3, "draws": 0, "rating": 1124, "best_rating": 1124, "streak": 3}
    data.history.clear()

    var entry := data.record_result(1, "win", "", 1000, 1000)
    _check(int(entry["rating_after"]) == int(data.individual_1c1["rating"]), "1c1 rating_after matches 1c1 stats")
    _check(int(entry["cups_after"]) == int(data.individual_1c1["cups"]), "1c1 cups_after matches 1c1 stats")
    _check(int(entry["streak_after"]) == 4, "1c1 streak increments after win")
    _check(int(data.individual["rating"]) == 1072 and int(data.individual["cups"]) == 73, "2c2 stats remain untouched")

    _check(int(entry.get("streak_after", 0)) == 4 and String(entry.get("league_after", "")).length() > 0, "1c1 result contract exposes streak and league for UI")

    print("V56 1C1 RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
