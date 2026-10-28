extends RefCounted
class_name TouchObserverAgent

## Low-overhead touch telemetry. Observes input only; never consumes or mutates gameplay.
const DOUBLE_TAP_WINDOW_MS := 360
const DOUBLE_TAP_DISTANCE_PX := 28.0
const MAX_TOUCH_EVENTS := 160
const MAX_TAP_DURATION_MS := 900

var journal: SupervisorJournal
var session_id := ""
var touch_count := 0
var press_count := 0
var release_count := 0
var outside_board_count := 0
var double_tap_count := 0
var same_square_double_tap_count := 0
var unmatched_release_count := 0
var duplicate_press_count := 0
var long_press_count := 0
var drag_count := 0
var blocked_touch_count := 0
var action_result_count := 0
var _last_completed_tap_ms := -1000000
var _last_completed_tap_press_ms := -1000000
var _last_completed_tap_sequence := -1
var _last_completed_tap_position := Vector2(-100000.0, -100000.0)
var _last_completed_tap_square := Vector2i(-1, -1)
var _last_completed_tap_index := -1
var _last_press_sequence := -1
var _last_press_ms := -1
var _last_press_position := Vector2.ZERO
var _last_press_square := Vector2i(-1, -1)
var _last_press_index := -1
var _last_press_selected := Vector2i(-1, -1)
var _active_pointers: Dictionary = {}

func _init(shared_journal: SupervisorJournal = null) -> void:
    journal = shared_journal
    session_id = "%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]

func observe_touch(pressed: bool, screen_position: Vector2, logical_square: Vector2i, selected_square: Vector2i, running: bool, blocked_reason: String = "", pointer_index: int = 0) -> Dictionary:
    touch_count += 1
    var now_ms := Time.get_ticks_msec()
    var kind := "press" if pressed else "release"
    var result := {"event": kind, "sequence": touch_count, "press_sequence": -1, "double_tap": false, "same_square_double_tap": false, "pointer_index": pointer_index}
    if logical_square == Vector2i(-1, -1):
        outside_board_count += 1
    if not blocked_reason.is_empty():
        blocked_touch_count += 1

    if pressed:
        press_count += 1
        if _active_pointers.has(pointer_index):
            duplicate_press_count += 1
            _record("warning", "touch_press_without_previous_release", {"pointer_index": pointer_index, "previous_press_sequence": _active_pointers[pointer_index].get("sequence", -1)})
        var elapsed := now_ms - _last_completed_tap_press_ms
        var release_gap := now_ms - _last_completed_tap_ms
        var distance := screen_position.distance_to(_last_completed_tap_position)
        var same_pointer := pointer_index == _last_completed_tap_index
        var within_window := _last_completed_tap_press_ms >= 0 and elapsed >= 0 and elapsed <= DOUBLE_TAP_WINDOW_MS and distance <= DOUBLE_TAP_DISTANCE_PX and same_pointer
        var same_square := within_window and logical_square != Vector2i(-1, -1) and logical_square == _last_completed_tap_square
        result["double_tap"] = within_window
        result["same_square_double_tap"] = same_square
        result["interval_ms"] = elapsed if _last_completed_tap_ms >= 0 else -1
        result["distance_px"] = snappedf(distance, 0.1) if _last_completed_tap_ms >= 0 else -1.0
        if within_window:
            double_tap_count += 1
            if same_square:
                same_square_double_tap_count += 1
            _record("warning" if same_square else "info", "double_tap_observed", {
                "session_id": session_id, "pointer_index": pointer_index, "interval_ms": elapsed,
                "distance_px": snappedf(distance, 0.1), "same_square": same_square,
                "square_x": logical_square.x, "square_y": logical_square.y,
                "previous_square_x": _last_completed_tap_square.x, "previous_square_y": _last_completed_tap_square.y,
                "previous_press_sequence": _last_completed_tap_sequence, "press_to_press_ms": elapsed, "release_to_press_ms": release_gap
            })
        _last_press_sequence = touch_count
        _last_press_ms = now_ms
        _last_press_position = screen_position
        _last_press_square = logical_square
        _last_press_index = pointer_index
        _last_press_selected = selected_square
        _active_pointers[pointer_index] = {"sequence": touch_count, "time_ms": now_ms, "position": screen_position, "square": logical_square, "selected": selected_square, "blocked_reason": blocked_reason}
        result["press_sequence"] = touch_count
    else:
        release_count += 1
        if not _active_pointers.has(pointer_index):
            unmatched_release_count += 1
            _record("warning", "touch_release_without_observed_press", {"pointer_index": pointer_index, "screen_x": screen_position.x, "screen_y": screen_position.y})
        else:
            var press: Dictionary = _active_pointers[pointer_index]
            var duration := maxi(0, now_ms - int(press.get("time_ms", now_ms)))
            var origin: Vector2 = press.get("position", screen_position)
            var travel := origin.distance_to(screen_position)
            result["press_sequence"] = int(press.get("sequence", -1))
            result["duration_ms"] = duration
            result["travel_px"] = snappedf(travel, 0.1)
            if duration >= MAX_TAP_DURATION_MS:
                long_press_count += 1
                _record("warning", "touch_long_press", {"press_sequence": result["press_sequence"], "pointer_index": pointer_index, "duration_ms": duration, "travel_px": snappedf(travel, 0.1)})
            if travel > DOUBLE_TAP_DISTANCE_PX:
                drag_count += 1
            # Only completed short taps qualify as the first half of a double tap.
            if duration < MAX_TAP_DURATION_MS and travel <= DOUBLE_TAP_DISTANCE_PX and String(press.get("blocked_reason", "")).is_empty():
                _last_completed_tap_ms = now_ms
                _last_completed_tap_press_ms = int(press.get("time_ms", now_ms))
                _last_completed_tap_sequence = int(press.get("sequence", -1))
                _last_completed_tap_position = screen_position
                _last_completed_tap_square = logical_square
                _last_completed_tap_index = pointer_index
            _active_pointers.erase(pointer_index)

    var details := {
        "session_id": session_id, "sequence": touch_count, "press_sequence": result["press_sequence"],
        "phase": kind, "monotonic_ms": now_ms, "pointer_index": pointer_index,
        "screen_x": snappedf(screen_position.x, 0.1), "screen_y": snappedf(screen_position.y, 0.1),
        "square_x": logical_square.x, "square_y": logical_square.y,
        "selected_x": selected_square.x, "selected_y": selected_square.y,
        "running": running, "blocked_reason": blocked_reason,
        "double_tap": bool(result["double_tap"]), "same_square_double_tap": bool(result["same_square_double_tap"])
    }
    if result.has("duration_ms"):
        details["duration_ms"] = result["duration_ms"]
        details["travel_px"] = result["travel_px"]
    if result.has("interval_ms"):
        details["interval_ms"] = result["interval_ms"]
        details["distance_px"] = result["distance_px"]
        details["previous_tap_press_sequence"] = _last_completed_tap_sequence
    _record("info", "touch_observed", details)
    if touch_count % MAX_TOUCH_EVENTS == 0:
        _record("info", "touch_observer_checkpoint", summary())
    return result

func observe_result(code: String, selected_before: Vector2i, selected_after: Vector2i, move_count_before: int, move_count_after: int, suggestion_mode: bool) -> void:
    action_result_count += 1
    var now_ms := Time.get_ticks_msec()
    _record("info", "touch_action_result", {
        "session_id": session_id, "related_press_sequence": _last_press_sequence,
        "monotonic_ms": now_ms, "latency_since_press_ms": maxi(0, now_ms - _last_press_ms) if _last_press_ms >= 0 else -1,
        "result_code": code, "selected_before_x": selected_before.x, "selected_before_y": selected_before.y,
        "selected_after_x": selected_after.x, "selected_after_y": selected_after.y,
        "selection_changed": selected_before != selected_after,
        "moves_before": move_count_before, "moves_after": move_count_after,
        "move_count_changed": move_count_before != move_count_after,
        "suggestion_mode": suggestion_mode
    })

func summary() -> Dictionary:
    return {"session_id": session_id, "touch_count": touch_count, "press_count": press_count, "release_count": release_count,
        "outside_board_count": outside_board_count, "double_tap_count": double_tap_count,
        "same_square_double_tap_count": same_square_double_tap_count, "unmatched_release_count": unmatched_release_count,
        "duplicate_press_count": duplicate_press_count, "long_press_count": long_press_count,
        "drag_count": drag_count, "blocked_touch_count": blocked_touch_count,
        "action_result_count": action_result_count, "active_pointer_count": _active_pointers.size()}

func _record(severity: String, code: String, details: Dictionary) -> void:
    if journal != null:
        journal.record("touch_observer", severity, code, details)
