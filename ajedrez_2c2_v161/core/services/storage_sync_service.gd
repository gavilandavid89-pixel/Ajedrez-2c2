extends RefCounted
class_name StorageSyncService

var host: Node

func _init(owner: Node = null) -> void:
    host = owner

func bind(owner: Node) -> void:
    host = owner

var SYNC_QUEUE_PATH: String:
    get: return String(host.SYNC_QUEUE_PATH)
var MAX_SYNC_QUEUE: int:
    get: return int(host.MAX_SYNC_QUEUE)

func _absolute(path: String) -> String:
    return host._absolute(path)

func read_json(path: String, fallback: Variant = {}) -> Variant:
    return host.read_json(path, fallback)

func write_json_atomic(path: String, data: Variant, backup_path: String = "") -> bool:
    return host.write_json_atomic(path, data, backup_path)

func _load_queue() -> Array:
    var parsed: Variant = read_json(SYNC_QUEUE_PATH, [])
    if not (parsed is Array):
        return []
    var cleaned: Array = []
    for raw in parsed:
        if not (raw is Dictionary):
            continue
        var item: Dictionary = raw
        # Drop the pre-v20 profile marker: it never contained enough data to sync.
        if String(item.get("coalesce_key", "")) == "entity:profile":
            continue
        cleaned.append(item)
    return cleaned

func _save_queue(queue: Array) -> bool:
    return write_json_atomic(SYNC_QUEUE_PATH, queue)

func enqueue_sync(operation: Dictionary) -> bool:
    var queue := _load_queue()
    var op := operation.duplicate(true)
    if not op.has("id"):
        op["id"] = "SYNC_%08X%08X" % [Time.get_ticks_msec(), randi()]
    op["created_at"] = int(op.get("created_at", Time.get_unix_time_from_system()))
    op["attempts"] = int(op.get("attempts", 0))
    # Coalesce snapshots so offline play cannot create unbounded profile writes.
    var coalesce_key := String(op.get("coalesce_key", ""))
    if not coalesce_key.is_empty():
        for i in range(queue.size() - 1, -1, -1):
            if queue[i] is Dictionary and String(queue[i].get("coalesce_key", "")) == coalesce_key:
                queue[i] = op
                queue = queue.slice(maxi(0, queue.size() - MAX_SYNC_QUEUE))
                return _save_queue(queue)
    queue.append(op)
    if queue.size() > MAX_SYNC_QUEUE:
        queue = queue.slice(queue.size() - MAX_SYNC_QUEUE)
    return _save_queue(queue)

func get_sync_queue() -> Array[Dictionary]:
    var raw := _load_queue()
    var out: Array[Dictionary] = []
    for item in raw:
        if item is Dictionary:
            out.append(item.duplicate(true))
    return out

func sync_queue_size() -> int:
    return get_sync_queue().size()

func remove_sync_operation(operation_id: String) -> bool:
    var queue := _load_queue()
    for i in range(queue.size()):
        if queue[i] is Dictionary and String(queue[i].get("id", "")) == operation_id:
            queue.remove_at(i)
            return _save_queue(queue)
    return false

func clear_sync_queue() -> void:
    if FileAccess.file_exists(SYNC_QUEUE_PATH):
        DirAccess.remove_absolute(_absolute(SYNC_QUEUE_PATH))

func note_local_change(entity: String, payload: Dictionary) -> bool:
    return enqueue_sync({
        "type": "upsert",
        "entity": entity,
        "coalesce_key": "entity:%s" % entity,
        "payload": payload.duplicate(true),
    })
