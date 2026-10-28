extends RefCounted
class_name ChessGameBotService

const BotData = preload("res://domain/bots/bot_data.gd")
const ChessBotController = preload("res://domain/bots/bot_controller.gd")

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

func set_temporary_bot(slot: int, bot_profile_id: String) -> bool:
    if slot < 0 or slot >= host.SLOTS or bot_profile_id.strip_edges().is_empty():
        return false
    if host.mode not in [host.MODE_2C2, host.MODE_1C1]:
        return false
    if not host.slot_active[slot]:
        return false
    if BotData.get_profile(bot_profile_id).is_empty():
        return false
    host.bot_slots[slot] = bot_profile_id.strip_edges()
    host.slot_profile_ids[slot] = "bot:%s" % bot_profile_id.strip_edges()
    return true

func clear_bot_slots() -> void:
    host.bot_slots.clear()

func is_bot_slot(slot: int) -> bool:
    return host.bot_slots.has(slot)

func is_bot_turn() -> bool:
    return is_bot_slot(host.current_slot) and host.current_actor_slot() == host.current_slot

func bot_take_turn() -> bool:
    if not host.running or host.pending_promotion != host.NO_SQUARE or not is_bot_turn():
        return false
    var active_slot: int = int(host.current_slot)
    var active_bot_id := String(host.bot_slots.get(active_slot, host.bot_id))
    var white: bool = host.slot_colors[active_slot] == host.TEAM_WHITE
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var pick: Dictionary = ChessBotController.choose_move_with_profile(host.board, host.rules, host.castling_rights, host.en_passant_target, white, active_bot_id, rng)
    if pick.is_empty():
        host.finish(1 - host.slot_colors[active_slot], "El Bot (%s) no tiene movimientos" % active_bot_id)
        return false
    return host.attempt_move(pick["from"], pick["to"], "dama", true)

func bot_prepare_suggestion() -> bool:
    if not host.running or host.mode != host.MODE_2C2 or host.pending_promotion != host.NO_SQUARE or not is_bot_turn():
        return false
    var actor: int = int(host.current_actor_slot())
    var mate: int = int(host.active_teammate(actor))
    if actor < 0 or mate < 0 or not host.slot_active[mate]:
        return false
    var active_bot_id := String(host.bot_slots.get(actor, host.bot_id))
    var white: bool = host.slot_colors[actor] == host.TEAM_WHITE
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var pick: Dictionary = ChessBotController.choose_move_with_profile(host.board, host.rules, host.castling_rights, host.en_passant_target, white, active_bot_id, rng)
    if pick.is_empty():
        return false
    return host.propose_suggestion(pick["from"], pick["to"])
