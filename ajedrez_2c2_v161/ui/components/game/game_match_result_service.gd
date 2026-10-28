extends RefCounted
class_name GameMatchResultService

const Competitive = preload("res://domain/competitive/competitive_system.gd")
const AppConfig = preload("res://core/services/app.gd")
const RuntimeServicesScript = preload("res://core/services/runtime_services.gd")
const MatchContext = preload("res://domain/competitive/match_context.gd")
const BotData = preload("res://domain/bots/bot_data.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var game: Variant:
    get: return host.game
var board_view: Variant:
    get: return host.board_view
var hud: Variant:
    get: return host.hud
var audio_feedback: Variant:
    get: return host.audio_feedback
var last_result_entry: Dictionary:
    get: return host.last_result_entry
    set(value): host.last_result_entry = value

func _on_match_finished(team: int, reason: String) -> void:
    if board_view != null:
        board_view.set_selected(Vector2i(-1, -1))
    var player_data = RuntimeServicesScript.get_autoload("PlayerData")
    if player_data != null:
        var outcome := "draw"
        if team == game.TEAM_WHITE:
            outcome = "win"
        elif team == game.TEAM_BLACK:
            outcome = "loss"
        var partner := ""
        var partner_id := ""
        if game.mode == AppConfig.MODE_2C2 and game.SLOTS > 2:
            partner = String(game.slot_owners[2])
            partner_id = String(game.slot_profile_ids[2])
        var opponent_names: Array[String] = []
        for slot in range(game.SLOTS):
            if slot < game.slot_owners.size() and not String(game.slot_owners[slot]).is_empty():
                if game.mode == AppConfig.MODE_2C2 and game.slot_colors[slot] == game.TEAM_BLACK:
                    opponent_names.append(String(game.slot_owners[slot]))
                elif game.mode != AppConfig.MODE_2C2 and slot == 1:
                    opponent_names.append(String(game.slot_owners[slot]))
        var app = RuntimeServicesScript.get_autoload("App")
        var context: Dictionary = {}
        if app != null and app.competitive_match_context is Dictionary:
            context = app.competitive_match_context.duplicate(true)
        var opponent_rating := MatchContext.individual_opponent_rating(context, Competitive.DEFAULT_RATING)
        var opponent_pair_rating := MatchContext.pair_opponent_rating(context, Competitive.DEFAULT_RATING)
        var partner_rating := MatchContext.partner_rating(context, Competitive.DEFAULT_RATING)
        if game.mode == AppConfig.MODE_1C1 and game.bot_id != "":
            opponent_rating = BotData.elo_for(game.bot_id)
        elif game.mode == AppConfig.MODE_1C1 and game.bot_slots.has(1):
            opponent_rating = BotData.elo_for(String(game.bot_slots[1]))
        elif game.mode == AppConfig.MODE_2C2 and not game.bot_slots.is_empty():
            if game.bot_slots.has(2):
                partner_rating = BotData.elo_for(String(game.bot_slots[2]))
            var opponent_sum := 0
            var opponent_count := 0
            for slot in range(game.SLOTS):
                if game.slot_colors[slot] == game.TEAM_BLACK and game.bot_slots.has(slot):
                    opponent_sum += BotData.elo_for(String(game.bot_slots[slot]))
                    opponent_count += 1
            if opponent_count > 0:
                opponent_rating = roundi(float(opponent_sum) / float(opponent_count))
                opponent_pair_rating = opponent_rating
        var detail: Dictionary = {
            "match_id": String(game.match_uid),
            "competitive": game.mode == AppConfig.MODE_2C2 or game.mode == AppConfig.MODE_1C1,
            "winner_team": team,
            "reason": reason,
            "match_minutes": game.match_minutes,
            "move_count": game.move_history.size(),
            "moves": game.replay_moves(),
            "replay_data": game.replay_data(),
            "players": game.slot_owners.duplicate(),
            "player_ids": game.slot_profile_ids.duplicate(),
            "player_colors": game.slot_colors.duplicate(),
            "white_time": float(game.team_time[game.TEAM_WHITE]),
            "black_time": float(game.team_time[game.TEAM_BLACK]),
            "clock_history": (host.get_node_or_null("/root/MatchContext").clock_history() if host.get_node_or_null("/root/MatchContext") != null else []),
            "opponents": opponent_names,
            "partner_id": partner_id,
            "bot_id": game.bot_id if game.mode == AppConfig.MODE_VS_BOT else "",
            "bot_elo": game.bot_target_elo if game.mode == AppConfig.MODE_VS_BOT else 0,
            "bot_nexus": game.bot_target_nexus if game.mode == AppConfig.MODE_VS_BOT else 0,
            "analysis_ready": true,
            "competitive_match_context": context,
            "opponent_rating_before": opponent_rating,
            "opponent_pair_rating": opponent_pair_rating,
            "partner_rating_before": partner_rating,
        }
        if game.mode == AppConfig.MODE_2C2 or game.mode == AppConfig.MODE_1C1:
            last_result_entry = player_data.record_result(game.mode, outcome, partner, opponent_rating, opponent_pair_rating, partner_id, detail)
        else:
            detail["outcome"] = outcome
            detail["mode"] = game.mode
            detail["partner"] = partner
            last_result_entry = player_data.record_noncompetitive_match(detail)
        var telemetry := RuntimeServicesScript.get_autoload("CompetitiveTelemetry")
        if telemetry != null and telemetry.has_method("record_match") and (game.mode == AppConfig.MODE_2C2 or game.mode == AppConfig.MODE_1C1) and not bool(last_result_entry.get("duplicate", false)):
            telemetry.record_match(last_result_entry, detail)
        if app != null:
            app.competitive_match_context = {}
        if hud != null and hud.has_method("set_result_entry"):
            hud.set_result_entry(last_result_entry)
    if hud != null:
        hud.refresh()
    var app_node = RuntimeServicesScript.get_autoload("App")
    if audio_feedback != null and not (app_node != null and bool(app_node.navigation_audit_mode)):
        audio_feedback.play_feedback("result")
