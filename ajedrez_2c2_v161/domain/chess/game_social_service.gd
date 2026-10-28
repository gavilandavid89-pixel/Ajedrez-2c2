extends RefCounted
class_name ChessGameSocialService

const EmoteData = preload("res://domain/player/emote_data.gd")

var host: Node

func _init(owner: Node = null) -> void:
	host = owner

func bind(owner: Node) -> void:
	host = owner

func _local_slot() -> int:
	var slot := int(host.local_player_slot)
	return slot if slot >= 0 and slot < host.SLOTS else -1

func suggestion_visible_to(viewer_slot: int) -> bool:
	if host.suggestion.is_empty():
		return false
	return viewer_slot == int(host.suggestion["by_slot"]) or viewer_slot == int(host.suggestion["recipient_slot"])

func propose_suggestion(from: Vector2i, to: Vector2i) -> bool:
	if host.mode != host.MODE_2C2 or not host.running or host.pending_promotion != host.NO_SQUARE:
		return false
	if not host.suggestion.is_empty():
		host._emit_log("Ya hay una sugerencia activa; debe resolverse antes de crear otra.")
		return false
	if host.now() < host.suggestion_cooldown_until:
		host._emit_log("Sugerir en enfriamiento: %.1fs" % (host.suggestion_cooldown_until - host.now()))
		return false
	var piece: String = host.get_piece(from)
	# Las sugerencias son comunicación entre compañeros, no una jugada real.
	# Por eso no dependen del turno activo, pero sí deben usar una pieza del
	# equipo del jugador local y un movimiento válido en la posición actual.
	var actor: int = _local_slot()
	if actor < 0 or not host.slot_active[actor]:
		host._emit_log("No hay un jugador local activo para sugerir.")
		return false
	var mate: int = host.active_teammate(actor)
	if mate < 0 or not host.slot_active[mate]:
		host._emit_log("No hay un compañero activo para recibir la sugerencia.")
		return false
	var local_team: int = int(host.slot_colors[actor])
	var piece_matches_team: bool = (local_team == host.TEAM_WHITE and host.rules.is_white(piece)) or (local_team == host.TEAM_BLACK and host.rules.is_black(piece))
	if not piece_matches_team or not host.rules.valid(host.board, from, to, piece, host.castling_rights, host.en_passant_target):
		host._emit_log("Solo puedes sugerir movimientos válidos de tu equipo.")
		return false
	host.suggestion = {
		"from": from,
		"to": to,
		"by_slot": actor,
		"recipient_slot": mate,
		"status": "pending",
		"accepted": false,
		"questioned": false,
	}
	host.suggestion_cooldown_until = host.now() + host.SUGGESTION_COOLDOWN
	host._emit_log("💡 %s sugirió %s → %s a %s" % [host.slot_owners[actor], host.square_name(from), host.square_name(to), host.slot_owners[mate]])
	host.state_changed.emit()
	return true

func answer_suggestion(accept: bool, voter_slot: int = -1) -> bool:
	if host.suggestion.is_empty() or not host.running:
		return false
	var recipient: int = int(host.suggestion["recipient_slot"])
	var local := _local_slot()
	if voter_slot >= 0 and voter_slot != recipient:
		return false
	if local != recipient:
		return false
	if not host.slot_active[local]:
		return false
	if accept:
		host.suggestion["accepted"] = true
		host.suggestion["status"] = "accepted"
		host._emit_log("✅ Sugerencia aceptada. La jugada debe realizarse manualmente.")
	else:
		host._emit_log("❌ Sugerencia rechazada.")
		host.suggestion = {}
	host.state_changed.emit()
	return true

func question_suggestion(viewer_slot: int = -1) -> bool:
	if host.suggestion.is_empty() or not host.running:
		return false
	var recipient: int = int(host.suggestion["recipient_slot"])
	var local := _local_slot()
	if viewer_slot >= 0 and viewer_slot != recipient:
		return false
	if local != recipient or not host.slot_active[local]:
		return false
	if bool(host.suggestion.get("accepted", false)) or bool(host.suggestion.get("questioned", false)):
		return false
	if host.now() < host.question_cooldown_until:
		host._emit_log("Cuestionar está en enfriamiento.")
		return false
	host.suggestion["questioned"] = true
	host.suggestion["status"] = "questioned"
	host.question_cooldown_until = host.now() + host.QUESTION_COOLDOWN
	host._emit_log("⚠️ El compañero cuestionó la sugerencia. Puedes proponer otra jugada en tu próximo turno.")
	host.state_changed.emit()
	return true

func set_strategic_mode(enabled: bool) -> void:
	host.strategic_mode = enabled
	host._emit_log("Modo %s." % ("estratégico" if enabled else "clásico"))
	host.state_changed.emit()

func request_swap() -> bool:
	if host.mode != host.MODE_2C2 or not host.running or not host.strategic_mode:
		return false
	# Cambiar posiciones es una acción social/estratégica y se puede solicitar
	# en cualquier turno; solo se exige que ambos compañeros sigan activos.
	var actor: int = _local_slot()
	if actor < 0 or not host.slot_active[actor]:
		return false
	var mate: int = host.active_teammate(actor)
	if mate < 0 or not host.slot_active[mate]:
		host._emit_log("No se puede cambiar: falta un compañero activo.")
		return false
	if not host.swap_request.is_empty():
		return false
	host.swap_request = {"from": actor, "to": mate}
	host._emit_log("🔄 %s propone cambiar posición con %s." % [host.slot_owners[actor], host.slot_owners[mate]])
	host.state_changed.emit()
	return true

func answer_swap(accept: bool) -> bool:
	if host.swap_request.is_empty() or not host.running:
		return false
	var a: int = int(host.swap_request["from"])
	var b: int = int(host.swap_request["to"])
	if _local_slot() != b or not host.slot_active[b]:
		return false
	if accept:
		var tmp: String = host.slot_owners[a]
		host.slot_owners[a] = host.slot_owners[b]
		host.slot_owners[b] = tmp
		var tmp_profile: String = host.slot_profile_ids[a]
		host.slot_profile_ids[a] = host.slot_profile_ids[b]
		host.slot_profile_ids[b] = tmp_profile
		host._ensure_pair_stats()
		host._emit_log("🔄 Cambio aceptado. El turno sigue en %s y ahora actúa %s." % [host.current_slot_name(), host.current_owner()])
	else:
		host._emit_log("Cambio de posición rechazado.")
	host.swap_request = {}
	host.state_changed.emit()
	return true

func request_surrender() -> bool:
	if not host.running:
		return false
	if not host.surrender_request.is_empty():
		return false
	var actor: int = host.current_actor_slot()
	if actor < 0 or actor != _local_slot() or not host.slot_active[actor]:
		return false
	if host.mode == host.MODE_2C2:
		var mate: int = host.active_teammate(actor)
		if mate >= 0 and host.slot_active[mate]:
			host.surrender_request = {"from": actor, "waiting": mate}
			host._emit_log("🏳️ %s pide rendición; espera a su compañero." % host.slot_owners[actor])
		else:
			host.finish(1 - host.slot_colors[actor], "Rendición")
	else:
		host.finish(1 - host.slot_colors[actor], "Rendición")
	host.state_changed.emit()
	return true

func answer_surrender(accept: bool) -> bool:
	if host.surrender_request.is_empty() or not host.running:
		return false
	var waiting := int(host.surrender_request.get("waiting", -1))
	if _local_slot() != waiting or waiting < 0 or not host.slot_active[waiting]:
		return false
	var team: int = int(host.slot_colors[int(host.surrender_request.get("from", -1))])
	if accept:
		host.finish(1 - team, "Rendición del equipo")
	else:
		host._emit_log("Rendición rechazada. La partida continúa.")
		host.surrender_request = {}
	host.state_changed.emit()
	return true

func required_draw_voters() -> Array[int]:
	var result: Array[int] = []
	if int(host.draw_state.get("stage", 0)) != 2:
		return result
	var target_team: int = int(host.draw_state.get("target_team", -1))
	if target_team < 0:
		return result
	for i in range(host.SLOTS):
		if host.slot_colors[i] == target_team and host.slot_active[i]:
			result.append(i)
	return result

func request_draw() -> bool:
	if not host.running:
		return false
	var actor: int = host.current_actor_slot()
	if actor < 0 or actor != _local_slot() or not host.slot_active[actor]:
		return false
	# A valid FIDE draw claim is not an offer: no teammate/rival vote is required,
	# even if an earlier draw offer is pending.
	if host.claim_draw_by_rule():
		return true
	if int(host.draw_state.get("stage", 0)) != 0:
		return false
	var actor_team: int = int(host.slot_colors[actor])
	var mate: int = host.active_teammate(actor)
	if host.mode == host.MODE_2C2 and mate >= 0 and host.slot_active[mate]:
		host.draw_state = {"stage": 1, "by_slot": actor, "target_team": 1 - actor_team, "accepted_by": []}
		host._emit_log("🤝 %s propone tablas a su compañero." % host.slot_owners[actor])
	else:
		host.draw_state = {"stage": 2, "by_slot": actor, "target_team": 1 - actor_team, "accepted_by": []}
		host._emit_log("🤝 Propuesta de tablas enviada al rival.")
	host.state_changed.emit()
	return true

func answer_draw(accept: bool, voter_slot: int = -1) -> bool:
	var stage: int = int(host.draw_state.get("stage", 0))
	if stage == 0 or not host.running:
		return false
	if stage == 1:
		var by: int = int(host.draw_state["by_slot"])
		var mate: int = host.active_teammate(by)
		if _local_slot() != mate or (voter_slot >= 0 and voter_slot != mate):
			return false
		if not accept:
			host.draw_state = {"stage": 0, "by_slot": -1, "target_team": -1, "accepted_by": []}
			host._emit_log("Tablas rechazadas. Se continúa.")
		else:
			host.draw_state["stage"] = 2
			host.draw_state["accepted_by"] = []
			host._emit_log("🤝 Compañero aceptó. Propuesta enviada al equipo rival.")
		host.state_changed.emit()
		return true
	if stage == 2:
		var voters := required_draw_voters()
		var local := _local_slot()
		if local < 0 or not voters.has(local):
			return false
		if voter_slot >= 0 and voter_slot != local:
			return false
		if not accept:
			host.draw_state = {"stage": 0, "by_slot": -1, "target_team": -1, "accepted_by": []}
			host._emit_log("El equipo rival rechazó las tablas. Se continúa.")
			host.state_changed.emit()
			return true
		var accepted: Array = host.draw_state["accepted_by"]
		if not accepted.has(local):
			accepted.append(local)
		host.draw_state["accepted_by"] = accepted
		host._emit_log("🤝 %s aceptó las tablas (%d/%d)." % [host.slot_owners[local], accepted.size(), voters.size()])
		if accepted.size() >= voters.size():
			host.finish(-1, "Tablas acordadas")
		host.state_changed.emit()
		return true
	return false

func chat(text: String) -> void:
	var cleaned: String = text.strip_edges()
	if cleaned.is_empty():
		return
	var slot := _local_slot()
	var name: String = String(host.slot_owners[slot]) if slot >= 0 else "Jugador"
	var line: String = "%s: %s" % [name, cleaned]
	host.chat_history.append(line)
	host._emit_log("💬 " + line)

func emote(emote_id: String) -> bool:
	if host.mode == host.MODE_VS_BOT or not host.running:
		return false
	if emote_id.strip_edges().is_empty():
		return false
	var item: Dictionary = EmoteData.get_emote(emote_id)
	if item.is_empty():
		return false
	var remaining: float = host.emote_cooldown_until - host.now()
	if remaining > 0.01:
		return false
	# Las reacciones no alteran el tablero y no deben depender del turno.
	var slot: int = _local_slot()
	if slot < 0 or not host.slot_active[slot]:
		return false
	host.emote_cooldown_until = host.now() + host.EMOTE_COOLDOWN
	host.last_emote_id = emote_id
	host.last_emote_slot = slot
	host.emote_serial += 1
	host.emote_history.append("%s:%s" % [host.slot_owners[slot], emote_id])
	host._emit_log("%s %s" % [host.slot_owners[slot], String(item.get("label", emote_id))])
	host.state_changed.emit()
	return true
