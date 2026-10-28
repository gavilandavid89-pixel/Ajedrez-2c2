extends SceneTree

const Competitive = preload("res://domain/competitive/competitive_system.gd")
const PlayerDataScript = preload("res://domain/player/player_data.gd")

var passed := 0
var failed := 0

func _initialize() -> void:
    _check(Competitive.expected_score(1000, 1000) == 0.5, "expected score equal ratings is 0.5")
    _check(Competitive.rating_delta(1000, 1000, "win") > 0, "equal-rating win raises rating")
    _check(Competitive.rating_delta(1000, 1000, "loss") < 0, "equal-rating loss lowers rating")
    _check(Competitive.rating_delta(1000, 1150, "win") > Competitive.rating_delta(1000, 850, "win"), "upset win changes rating more")

    _check(Competitive.cup_delta(1000, 1000, "win") == 10, "similar win is +10 cups")
    _check(Competitive.cup_delta(1000, 1200, "win") == 13, "stronger-rival win is +13 cups")
    _check(Competitive.cup_delta(1000, 800, "win") == 7, "weaker-rival win is +7 cups")
    _check(Competitive.cup_delta(1000, 1200, "draw") == 6, "draw vs stronger is +6 cups")
    _check(Competitive.cup_delta(1000, 800, "draw") == 2, "draw vs weaker is +2 cups")
    _check(Competitive.cup_delta(1000, 1200, "loss") == -2, "loss vs much stronger is -2 cups")
    _check(Competitive.cup_delta(1000, 1000, "loss") == -6, "similar loss is -6 cups")
    _check(Competitive.cup_total_after(0, -6) == 0, "cups cannot go below zero")

    var bronze := Competitive.league_for_cups(0)
    var gold := Competitive.league_for_cups(500)
    var legend := Competitive.league_for_cups(2500)
    _check(String(bronze["name"]) == "Bronce", "0 cups is Bronze")
    _check(String(gold["name"]) == "Oro", "500 cups is Gold")
    _check(String(legend["name"]) == "Leyenda", "2500 cups is Legend")

    var data := PlayerDataScript.new()
    data.name = "CompetitiveTestPlayer"
    get_root().add_child(data)
    await process_frame
    data.individual = {
        "cups": 0,
        "lifetime_cups": 0,
        "games": 0,
        "wins": 0,
        "losses": 0,
        "draws": 0,
        "rating": 1000,
        "best_rating": 1000,
    }
    data.pair_records.clear()
    data.history.clear()
    data.individual_1c1 = {
        "cups": 0,
        "lifetime_cups": 0,
        "games": 0,
        "wins": 0,
        "losses": 0,
        "draws": 0,
        "rating": 1000,
        "best_rating": 1000,
    }

    var result := data.record_result(0, "win", "Compañero", 1000, 1000)
    _check(int(result["cup_delta"]) == 10, "2c2 win awards 10 cups")
    _check(int(data.individual["cups"]) == 10, "individual cups updated")
    _check(int(data.individual["rating"]) > 1000, "individual rating updated")
    var pair_key := data.pair_key("Compañero")
    _check(data.pair_records.has(pair_key), "pair record created")
    _check(int(data.pair_records[pair_key]["cups"]) == 10, "pair cups updated separately")
    _check(int(data.pair_records[pair_key]["rating"]) > 1000, "pair rating updated separately")
    _check(int(result["pair_cup_delta"]) == 10, "pair cup delta stored")
    _check(int(data.history.size()) == 1, "competitive history stored")

    var cups_2c2_before_1c1 := int(data.individual["cups"])
    var rating_2c2_before_1c1 := int(data.individual["rating"])
    var one_v_one_result := data.record_result(1, "loss", "", 1000, 1000)
    _check(int(data.individual["games"]) == 1 and int(data.individual["wins"]) == 1, "1c1 does not alter 2c2 stats")
    _check(int(data.individual["cups"]) == cups_2c2_before_1c1 and int(data.individual["rating"]) == rating_2c2_before_1c1, "1c1 leaves 2c2 cups and rating untouched")
    _check(int(data.individual_1c1["games"]) == 1 and int(data.individual_1c1["losses"]) == 1, "1c1 result updates its own stats")
    _check(int(data.individual_1c1["cups"]) == 0, "1c1 cups are independent and cannot inherit 2c2 cups")
    _check(int(one_v_one_result["cups_after"]) == int(data.individual_1c1["cups"]) and int(one_v_one_result["rating_after"]) == int(data.individual_1c1["rating"]), "1c1 history stores its own rating and cups totals")
    _check(int(one_v_one_result.get("streak_after", -1)) == 0 and String(one_v_one_result.get("league_after", "")) == "Bronce", "1c1 result stores isolated streak and league")
    data.record_result(1, "win", "", 1000, 1000)
    data.record_result(1, "win", "", 1000, 1000)
    _check(int(data.individual_1c1.get("streak", 0)) == 2, "1c1 winning streak increments independently")
    _check(int(data.individual["wins"]) == 1 and int(data.individual["cups"]) == cups_2c2_before_1c1, "1c1 streak/progression never alters 2c2")
    _check(data.individual_1c1_rank_rows()[0].has("cups") and data.individual_1c1_cup_rank_rows()[0].has("rating"), "1c1 rankings expose independent metrics")

    var legacy := PlayerDataScript.new()
    legacy.name = "LegacyCompetitiveTest"
    get_root().add_child(legacy)
    await process_frame
    legacy.individual = {"cups": 99, "lifetime_cups": 99, "games": 2, "wins": 2, "losses": 0, "draws": 0, "rating": 1040, "best_rating": 1040}
    legacy.individual_1c1 = legacy._blank_competitive_stats()
    legacy.history = [
        {"mode": 0, "competitive": true, "outcome": "win", "rating_delta": 15, "cup_delta": 10},
        {"mode": 1, "competitive": true, "outcome": "win", "rating_delta": 15, "cup_delta": 10},
    ]
    legacy._migrate_legacy_competitive_split()
    _check(int(legacy.individual["games"]) == 1 and int(legacy.individual["cups"]) == 10, "legacy migration isolates old 2c2 history")
    _check(int(legacy.individual_1c1["games"]) == 1 and int(legacy.individual_1c1["cups"]) == 10, "legacy migration recovers old 1c1 history")

    print("COMPETITIVE RESULTADO: %d OK / %d FALLARON" % [passed, failed])
    quit(1 if failed > 0 else 0)

func _check(value: bool, label: String) -> void:
    if value:
        passed += 1
        print("[OK] " + label)
    else:
        failed += 1
        push_error("[FALLA] " + label)
