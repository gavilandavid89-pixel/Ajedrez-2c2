extends Node

## Shared, presentation-independent snapshot of a chess match.
## Screens may render this data differently, but must not own competing copies.
signal match_context_changed(snapshot: Dictionary)
signal player_data_changed(color: String, player: Dictionary)
signal clock_snapshot_changed(snapshot: Dictionary)
signal match_result_changed(result: Dictionary)

const VALID_COLORS := ["white", "black"]
var _match: Dictionary = {}
var _players: Dictionary = {"white": {}, "black": {}}
var _clocks: Dictionary = {"white": 0.0, "black": 0.0}
var _clock_history: Array[Dictionary] = []
var _result: Dictionary = {}
var _move_index := 0

func begin_match(metadata: Dictionary = {}) -> void:
	_match = metadata.duplicate(true)
	_players = {"white": _normalize_player(metadata.get("white_player", {})), "black": _normalize_player(metadata.get("black_player", {}))}
	_clocks = {"white": maxf(0.0, float(metadata.get("white_time", 0.0))), "black": maxf(0.0, float(metadata.get("black_time", 0.0)))}
	_clock_history.clear()
	_move_index = 0
	_result.clear()
	_publish()

func update_player(color: String, data: Dictionary) -> bool:
	if not VALID_COLORS.has(color):
		return false
	var merged: Dictionary = _players.get(color, {}).duplicate(true)
	for key in ["id", "name", "avatar", "rating", "country", "team", "status"]:
		if data.has(key):
			merged[key] = data[key]
	merged["rating"] = maxi(0, int(merged.get("rating", 0)))
	_players[color] = merged
	player_data_changed.emit(color, merged.duplicate(true))
	_publish()
	return true

func set_clocks(white_seconds: float, black_seconds: float, active_color: String = "") -> void:
	_clocks["white"] = maxf(0.0, white_seconds)
	_clocks["black"] = maxf(0.0, black_seconds)
	clock_snapshot_changed.emit({"move_index": _move_index, "white_seconds": _clocks.white, "black_seconds": _clocks.black, "active_color": active_color}.duplicate(true))

func record_move_clock(move_index: int, white_seconds: float, black_seconds: float, active_color: String = "") -> void:
	_move_index = maxi(0, move_index)
	set_clocks(white_seconds, black_seconds, active_color)
	var entry := {"move_index": _move_index, "white_seconds": _clocks.white, "black_seconds": _clocks.black, "active_color": active_color}
	if _clock_history.is_empty() or _clock_history[_clock_history.size() - 1] != entry:
		_clock_history.append(entry)
		if _clock_history.size() > 1000:
			_clock_history.pop_front()

func set_result(result: Dictionary) -> void:
	_result = result.duplicate(true)
	match_result_changed.emit(_result.duplicate(true))
	_publish()

func snapshot() -> Dictionary:
	return {"match": _match.duplicate(true), "players": _players.duplicate(true), "clocks": _clocks.duplicate(true), "clock_history": _clock_history.duplicate(true), "result": _result.duplicate(true), "move_index": _move_index}

func player(color: String) -> Dictionary:
	return _players.get(color, {}).duplicate(true) if VALID_COLORS.has(color) else {}

func clock_seconds(color: String) -> float:
	return maxf(0.0, float(_clocks.get(color, 0.0))) if VALID_COLORS.has(color) else 0.0

func clock_history() -> Array[Dictionary]:
	return _clock_history.duplicate(true)

func _publish() -> void:
	match_context_changed.emit(snapshot())

func _normalize_player(raw: Variant) -> Dictionary:
	var data: Dictionary = raw.duplicate(true) if raw is Dictionary else {}
	return {"id": String(data.get("id", "")), "name": String(data.get("name", "Jugador")), "avatar": String(data.get("avatar", "")), "rating": maxi(0, int(data.get("rating", 0))), "country": String(data.get("country", "")), "team": String(data.get("team", "")), "status": String(data.get("status", "active"))}
