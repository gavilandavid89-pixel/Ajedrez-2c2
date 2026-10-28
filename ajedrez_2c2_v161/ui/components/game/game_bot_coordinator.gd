extends RefCounted
class_name GameBotCoordinator

const BotDataScript = preload("res://domain/bots/bot_data.gd")
const AppConfig = preload("res://core/services/app.gd")

const BOT_SUGGESTION_READ_TIME := 2.0

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var game: Variant:
    get: return host.game
var bot_wait: float:
    get: return float(host.bot_wait)
    set(value): host.bot_wait = value
var bot_think_time: float:
    get: return float(host.bot_think_time)
    set(value): host.bot_think_time = value
var bot_suggestion_sent: bool:
    get: return bool(host.bot_suggestion_sent)
    set(value): host.bot_suggestion_sent = value
var bot_suggestion_hold: float:
    get: return float(host.bot_suggestion_hold)
    set(value): host.bot_suggestion_hold = value
var bot_turn_key: String:
    get: return String(host.bot_turn_key)
    set(value): host.bot_turn_key = value
var bot_delay_rng: Variant:
    get: return host.bot_delay_rng

func _process(delta: float) -> void:
    if game == null or not game.running:
        return
    if host.board_view != null and host.board_view.has_method("is_move_animation_active") and host.board_view.is_move_animation_active():
        return

    if game.is_bot_turn():
        bot_wait += delta
        var bot_id := String(game.bot_slots.get(game.current_slot, game.bot_id))
        var turn_key := "%d:%d:%s" % [game.current_slot, game.move_history.size(), bot_id]
        if turn_key != bot_turn_key:
            bot_turn_key = turn_key
            bot_wait = 0.0
            bot_suggestion_sent = false
            bot_suggestion_hold = 0.0
            bot_delay_rng.randomize()
            bot_think_time = BotDataScript.thinking_delay_for(bot_id, bot_delay_rng)
        # En 2c2 el bot puede mostrar primero una sugerencia a su compañero humano.
        if game.mode == AppConfig.MODE_2C2 and not bot_suggestion_sent and game.active_teammate(game.current_slot) == 0:
            if bot_wait >= bot_think_time * 0.55:
                if game.bot_prepare_suggestion():
                    bot_suggestion_sent = true
                    # La sugerencia debe poder leerse antes de que el bot juegue.
                    bot_suggestion_hold = BOT_SUGGESTION_READ_TIME
        if bot_suggestion_hold > 0.0:
            bot_suggestion_hold = maxf(0.0, bot_suggestion_hold - delta)
        if bot_wait >= bot_think_time and bot_suggestion_hold <= 0.0:
            bot_wait = 0.0
            bot_suggestion_sent = false
            bot_suggestion_hold = 0.0
            bot_turn_key = ""
            game.bot_take_turn()
    else:
        bot_wait = 0.0
        bot_suggestion_sent = false
        bot_suggestion_hold = 0.0
        bot_turn_key = ""
