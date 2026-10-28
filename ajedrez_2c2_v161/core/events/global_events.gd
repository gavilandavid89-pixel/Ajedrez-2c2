extends Node

## App-wide event bus for reusable UI/system behavior. Keep payloads data-only.
signal screen_entered(screen_id: String, context: Dictionary)
signal screen_exited(screen_id: String)
signal preference_changed(key: String, value: Variant)
signal notification_requested(message: String, kind: String, duration_seconds: float)
signal modal_requested(modal_id: String, payload: Dictionary)
signal operation_started(operation_id: String, label: String)
signal operation_finished(operation_id: String, success: bool, message: String)
signal connectivity_changed(online: bool)

var _active_screen_id := ""
var _active_operations: Dictionary = {}

func enter_screen(screen_id: String, context: Dictionary = {}) -> void:
	var clean_id := screen_id.strip_edges()
	if clean_id.is_empty():
		return
	if not _active_screen_id.is_empty() and _active_screen_id != clean_id:
		screen_exited.emit(_active_screen_id)
	_active_screen_id = clean_id
	screen_entered.emit(clean_id, context.duplicate(true))

func set_preference(key: String, value: Variant) -> void:
	var clean_key := key.strip_edges()
	if clean_key.is_empty():
		return
	preference_changed.emit(clean_key, value)

func notify(message: String, kind: String = "info", duration_seconds: float = 2.5) -> void:
	var clean_message := message.strip_edges()
	if clean_message.is_empty():
		return
	notification_requested.emit(clean_message, kind, clampf(duration_seconds, 0.5, 12.0))

func request_modal(modal_id: String, payload: Dictionary = {}) -> void:
	var clean_id := modal_id.strip_edges()
	if not clean_id.is_empty():
		modal_requested.emit(clean_id, payload.duplicate(true))

func begin_operation(operation_id: String, label: String) -> bool:
	var clean_id := operation_id.strip_edges()
	if clean_id.is_empty() or _active_operations.has(clean_id):
		return false
	_active_operations[clean_id] = label
	operation_started.emit(clean_id, label)
	return true

func end_operation(operation_id: String, success: bool, message: String = "") -> bool:
	var clean_id := operation_id.strip_edges()
	if not _active_operations.has(clean_id):
		return false
	_active_operations.erase(clean_id)
	operation_finished.emit(clean_id, success, message)
	return true

func is_operation_active(operation_id: String) -> bool:
	return _active_operations.has(operation_id)
