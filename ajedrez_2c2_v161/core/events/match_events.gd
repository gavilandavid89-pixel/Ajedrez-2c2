extends Node

## Stable semantic events shared by live play, replay, analysis, study and puzzles.
signal match_loaded(match_id: String, metadata: Dictionary)
signal match_started(match_id: String)
signal match_finished(match_id: String, result: Dictionary)
signal match_result_changed(match_id: String, result: Dictionary)
signal player_updated(color: String, player: Dictionary)
signal clock_updated(move_index: int, white_seconds: float, black_seconds: float, active_color: String)
signal replay_started(match_id: String)
signal replay_paused(match_id: String)
signal replay_position_changed(match_id: String, move_index: int)
signal replay_speed_changed(match_id: String, speed: float)
signal analysis_requested(match_id: String, move_index: int)
signal analysis_started(match_id: String)
signal analysis_progress(match_id: String, progress: float)
signal analysis_completed(match_id: String, report: Dictionary)
signal variation_selected(match_id: String, variation: Array)

func publish_match_loaded(match_id: String, metadata: Dictionary = {}) -> void:
	if not match_id.strip_edges().is_empty():
		match_loaded.emit(match_id, metadata.duplicate(true))

func publish_player(color: String, player: Dictionary) -> void:
	if color in ["white", "black"]:
		player_updated.emit(color, player.duplicate(true))

func publish_clock(move_index: int, white_seconds: float, black_seconds: float, active_color: String = "") -> void:
	clock_updated.emit(maxi(0, move_index), maxf(0.0, white_seconds), maxf(0.0, black_seconds), active_color if active_color in ["white", "black"] else "")

func publish_replay_position(match_id: String, move_index: int) -> void:
	if not match_id.strip_edges().is_empty():
		replay_position_changed.emit(match_id, maxi(0, move_index))
