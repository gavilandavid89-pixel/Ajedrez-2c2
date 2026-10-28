extends RefCounted
class_name GameFlowController

const AppConfig = preload("res://core/services/app.gd")
const ScreenCatalog = preload("res://core/navigation/screen_catalog.gd")
const Navigation = preload("res://core/navigation/navigation_service.gd")

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
var last_move_count: int:
    get: return int(host.last_move_count)
    set(value): host.last_move_count = value
var last_feedback_move_count: int:
    get: return int(host.last_feedback_move_count)
    set(value): host.last_feedback_move_count = value
var bot_wait: float:
    get: return float(host.bot_wait)
    set(value): host.bot_wait = value
var bot_turn_key: String:
    get: return String(host.bot_turn_key)
    set(value): host.bot_turn_key = value
var bot_suggestion_sent: bool:
    get: return bool(host.bot_suggestion_sent)
    set(value): host.bot_suggestion_sent = value
var bot_suggestion_hold: float:
    get: return float(host.bot_suggestion_hold)
    set(value): host.bot_suggestion_hold = value
var suggestion_mode: bool:
    get: return bool(host.suggestion_mode)
    set(value): host.suggestion_mode = value
var last_result_entry: Dictionary:
    get: return host.last_result_entry
    set(value): host.last_result_entry = value

func _app() -> Node:
    return host._app()

func _selected_mode() -> int:
    return int(host._selected_mode())

func _selected_time_minutes() -> int:
    return int(host._selected_time_minutes())

func _reset() -> void:
    if game.mode == AppConfig.MODE_2C2 or game.mode == AppConfig.MODE_1C1:
        return
    game.reset_match(_selected_mode(), _selected_time_minutes())
    game.randomize_roles()
    board_view.set_selected(Vector2i(-1, -1))
    board_view.set_flipped(game.local_team() == game.TEAM_BLACK)
    hud.set_selected_text(game.NO_SQUARE)
    last_move_count = 0
    last_feedback_move_count = 0
    bot_wait = 0.0
    bot_turn_key = ""
    suggestion_mode = false
    if hud != null and hud.has_method("set_suggestion_mode"):
        hud.set_suggestion_mode(false)

func _open_latest_analysis() -> void:
    if game == null or game.running:
        return
    var match_id := String(last_result_entry.get("match_id", ""))
    if match_id.is_empty():
        return
    var app := _app()
    if app != null:
        app.account_start_page = "analysis"
        app.analysis_return_to_home = true
    Navigation.go(ScreenCatalog.ACCOUNT)

func _rematch() -> void:
    if game == null:
        return
    if game.mode == AppConfig.MODE_2C2 or game.mode == AppConfig.MODE_1C1:
        var app := _app()
        if app != null:
            app.online_entry = "random"
        Navigation.go(ScreenCatalog.ONLINE_MATCHMAKING)
        return
    game.reset_match(_selected_mode(), _selected_time_minutes())
    game.randomize_roles()
    board_view.set_selected(Vector2i(-1, -1))
    board_view.set_flipped(game.local_team() == game.TEAM_BLACK)
    hud.set_selected_text(game.NO_SQUARE)
    last_move_count = 0
    last_feedback_move_count = 0
    bot_wait = 0.0
    bot_turn_key = ""
    suggestion_mode = false
    if hud != null and hud.has_method("set_suggestion_mode"):
        hud.set_suggestion_mode(false)

func _go_back() -> void:
    # After a finished match, the result screen must always offer a direct route
    # home; the online-match guard applies only while the match is still running.
    if game != null and game.running and (game.mode == AppConfig.MODE_2C2 or game.mode == AppConfig.MODE_1C1):
        return
    Navigation.go(ScreenCatalog.MAIN_MENU)
