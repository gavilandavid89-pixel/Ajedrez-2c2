extends RefCounted
class_name PlayerHistoryService

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner


var history: Variant:
    get: return host.history
    set(value): host.history = value
var season: Variant:
    get: return host.season
    set(value): host.season = value

func save_data() -> void:
    host.save_data()

func _emit_changed() -> void:
    host.data_changed.emit()

func append_entry(entry: Dictionary, notify: bool = false) -> Dictionary:
    var item := entry.duplicate(true)
    host.history.append(item)
    _trim_history()
    host.save_data()
    if notify:
        host.data_changed.emit()
    return host.history[-1] if not host.history.is_empty() else item

func append_entry_no_save(entry: Dictionary) -> Dictionary:
    var item := entry.duplicate(true)
    host.history.append(item)
    _trim_history()
    return host.history[-1] if not host.history.is_empty() else item

func record_noncompetitive_match(match_detail: Dictionary) -> Dictionary:
    # Finishing a match can be emitted again by a retry, scene transition, or
    # duplicate signal. A stable ID must make local/practice history idempotent
    # just like competitive results, without saving or notifying twice.
    var requested_match_id := String(match_detail.get("match_id", "")).strip_edges()
    if not requested_match_id.is_empty():
        for previous in history:
            if previous is Dictionary and String(previous.get("match_id", "")).strip_edges() == requested_match_id:
                var duplicate_entry: Dictionary = previous.duplicate(true)
                duplicate_entry["duplicate"] = true
                duplicate_entry["ok"] = true
                return duplicate_entry
    var entry := match_detail.duplicate(true)
    entry["match_id"] = requested_match_id if not requested_match_id.is_empty() else _generate_match_id()
    entry["timestamp"] = int(entry.get("timestamp", Time.get_unix_time_from_system()))
    entry["season_id"] = int(entry.get("season_id", season.get("id", 1)))
    entry["season_name"] = String(entry.get("season_name", season.get("name", "Temporada 1")))
    entry["competitive"] = false
    entry["analysis_viewed"] = bool(entry.get("analysis_viewed", false))
    history.append(entry)
    _trim_history()
    save_data()
    _emit_changed()
    return entry

func mark_history_analysis_viewed(match_id: String, notify: bool = true) -> bool:
    var target := match_id.strip_edges()
    if target.is_empty():
        return false
    for i in range(history.size()):
        var item: Variant = history[i]
        if item is Dictionary and String(item.get("match_id", "")) == target:
            if bool(item.get("analysis_viewed", false)):
                return false
            item["analysis_viewed"] = true
            history[i] = item
            save_data()
            if notify:
                _emit_changed()
            return true
    return false

func history_analysis_viewed(match_id: String) -> bool:
    var target := match_id.strip_edges()
    if target.is_empty():
        return false
    for item in history:
        if item is Dictionary and String(item.get("match_id", "")) == target:
            return bool(item.get("analysis_viewed", false))
    return false

func _trim_history() -> void:
    if history.size() > 100:
        history = history.slice(history.size() - 100)

func _generate_match_id() -> String:
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    return "MATCH_%08X%08X" % [rng.randi(), rng.randi()]
