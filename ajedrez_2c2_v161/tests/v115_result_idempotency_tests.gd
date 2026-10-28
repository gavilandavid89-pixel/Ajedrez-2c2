extends SceneTree

const PlayerDataScript = preload("res://domain/player/player_data.gd")

class NoopPersistence:
    extends "res://domain/player/player_persistence_service.gd"
    func save_data() -> void:
        pass

var passed := 0
var failed := 0
var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var data = PlayerDataScript.new()
    data.name = "V115ResultIdempotencyQA"
    get_root().add_child(data)
    await process_frame
    data.persistence_service = NoopPersistence.new(data)
    data.history.clear()
    data.individual = {"cups":0,"lifetime_cups":0,"games":0,"wins":0,"losses":0,"draws":0,"rating":1200,"best_rating":1200,"uncertainty":240.0,"volatility":0.5,"form":0.0,"last_activity_at":0,"nexus_version":2}
    data.individual_1c1 = {"cups":0,"lifetime_cups":0,"games":0,"wins":0,"losses":0,"draws":0,"rating":1000,"best_rating":1000,"streak":0}

    var local_detail := {"match_id":"V115-LOCAL-DUP", "mode":2, "outcome":"win", "moves":[], "replay_data":{}}
    var local_first: Dictionary = data.record_noncompetitive_match(local_detail)
    var history_size_after_first: int = data.history.size()
    var local_second: Dictionary = data.record_noncompetitive_match({"match_id":"V115-LOCAL-DUP", "mode":2, "outcome":"loss", "moves":[], "replay_data":{}})
    _check(not bool(local_first.get("duplicate", false)) and bool(local_second.get("duplicate", false)), "Repeated noncompetitive finish is marked duplicate")
    _check(data.history.size() == history_size_after_first, "Repeated noncompetitive finish does not append another history row")
    _check(String(data.history.back().get("outcome", "")) == "win", "Duplicate noncompetitive result cannot overwrite the original outcome")

    var invalid_before: int = data.history.size()
    var invalid: Dictionary = data.record_result(1, "nonsense", "", 1000, 1000, "", {"match_id":"V115-INVALID"})
    _check(not bool(invalid.get("ok", true)) and data.history.size() == invalid_before, "Invalid competitive outcome is rejected without adding history")

    var competitive_detail := {"match_id":"V115-COMP-DUP", "partner_rating_before":1200}
    var competitive_first: Dictionary = data.record_result(1, "win", "", 1000, 1000, "", competitive_detail)
    var rating_after: int = int(data.individual_1c1.get("rating", 0))
    var games_after: int = int(data.individual_1c1.get("games", 0))
    var competitive_second: Dictionary = data.record_result(1, "loss", "", 1000, 1000, "", competitive_detail)
    _check(not bool(competitive_first.get("duplicate", false)) and bool(competitive_second.get("duplicate", false)), "Repeated competitive finish is marked duplicate")
    _check(int(data.individual_1c1.get("rating", 0)) == rating_after and int(data.individual_1c1.get("games", 0)) == games_after, "Repeated competitive finish cannot update rating or games twice")

    print("V115 RESULT IDEMPOTENCY: %d OK / %d FAILED" % [passed, failed])
    for failure in failures:
        push_error(failure)
    quit(0 if failed == 0 else 1)

func _check(condition: bool, label: String) -> void:
    if condition:
        passed += 1
        print("[OK] ", label)
    else:
        failed += 1
        failures.append(label)
        print("[FAIL] ", label)
