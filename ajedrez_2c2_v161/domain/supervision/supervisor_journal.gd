extends RefCounted
class_name SupervisorJournal

## Small persistent diagnostic journal shared by deterministic agents.
## Runtime output is stored in user:// so exported Android builds can write it.
const DEFAULT_PATH := "user://supervisor_diagnostics.jsonl"
const MAX_FILE_BYTES := 1024 * 1024
const MAX_DETAIL_CHARS := 500
var log_path := DEFAULT_PATH
var memory_events: Array[Dictionary] = []
var max_memory_events := 100

func _init() -> void:
	# Recover the last events from the previous app session so a supervisor can
	# inspect persisted failures after relaunch, not only events from this process.
	_load_recent_from_disk()

func configure_path(path: String) -> bool:
	var clean := path.strip_edges()
	if clean.is_empty():
		return false
	log_path = clean
	memory_events.clear()
	_load_recent_from_disk()
	return true

func _load_recent_from_disk() -> void:
	if not FileAccess.file_exists(log_path):
		return
	var file := FileAccess.open(log_path, FileAccess.READ)
	if file == null:
		return
	var recovered: Array[Dictionary] = []
	while file.get_position() < file.get_length():
		var line := file.get_line()
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary and parsed.has("code") and parsed.has("agent"):
			recovered.append(parsed)
	if recovered.size() > max_memory_events:
		recovered = recovered.slice(recovered.size() - max_memory_events, recovered.size())
	memory_events.append_array(recovered)

func record(agent: String, severity: String, code: String, details: Dictionary = {}) -> bool:
	var event := {
		"timestamp_unix": int(Time.get_unix_time_from_system()),
		"agent": _safe_text(agent, 48),
		"severity": _safe_text(severity.to_lower(), 16),
		"code": _safe_text(code, 80),
		"details": _sanitize_details(details),
	}
	memory_events.append(event)
	while memory_events.size() > max_memory_events:
		memory_events.pop_front()
	var directory := log_path.get_base_dir()
	if not directory.is_empty() and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)):
		var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
		if make_error != OK:
			return false
	_rotate_if_needed()
	var file := FileAccess.open(log_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(log_path, FileAccess.WRITE)
	if file == null:
		return false
	file.seek_end()
	file.store_line(JSON.stringify(event))
	file.flush()
	return FileAccess.get_open_error() == OK

func recent_events(limit: int = 20) -> Array[Dictionary]:
	var count := clampi(limit, 0, max_memory_events)
	return memory_events.slice(maxi(0, memory_events.size() - count), memory_events.size())

func export_text() -> String:
	var file := FileAccess.open(log_path, FileAccess.READ)
	return file.get_as_text() if file != null else ""

func _rotate_if_needed() -> void:
	if not FileAccess.file_exists(log_path) or FileAccess.get_file_as_bytes(log_path).size() < MAX_FILE_BYTES:
		return
	var backup := log_path + ".1"
	if FileAccess.file_exists(backup):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(log_path), ProjectSettings.globalize_path(backup))
	if err != OK:
		# Keep logging available if rotation is blocked; the caller still gets an error if open fails.
		return

func _sanitize_details(source: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	var allowed := 0
	for key_variant in source.keys():
		if allowed >= 16:
			break
		var key := _safe_text(String(key_variant), 48).to_lower()
		if key.contains("email") or key.contains("password") or key.contains("token") or key.contains("ip") or key.contains("chat") or key.contains("name"):
			continue
		var value: Variant = source[key_variant]
		if value is String:
			clean[key] = _safe_text(value, MAX_DETAIL_CHARS)
		elif value is int or value is float or value is bool or value == null:
			clean[key] = value
		elif value is Array:
			clean[key] = "array[%d]" % value.size()
		elif value is Dictionary:
			clean[key] = "dictionary[%d]" % value.size()
		else:
			clean[key] = _safe_text(str(value), 80)
		allowed += 1
	return clean

func _safe_text(value: String, max_chars: int) -> String:
	var clean := value.replace("\n", " ").replace("\r", " ").strip_edges()
	if clean.length() > max_chars:
		clean = clean.substr(0, max_chars)
	return clean
