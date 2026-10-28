extends RefCounted
class_name ScreenshotSupervisorAgent

## Captures real viewport frames on demand and records an index for later inspection.
const CAPTURE_DIR := "user://qa_captures"
const MANIFEST_PATH := "user://qa_captures/manifest.jsonl"
var journal: SupervisorJournal
var sequence := 0
var last_capture_path := ""

func _init(shared_journal: SupervisorJournal = null) -> void:
	journal = shared_journal

func capture_viewport(viewport: Viewport, label: String, metadata: Dictionary = {}) -> Dictionary:
	if _is_headless_renderer():
		return _fail("capture_unavailable_headless", {"label": label, "renderer": DisplayServer.get_name()})
	if viewport == null:
		return _fail("capture_missing_viewport", {"label": label})
	var texture := viewport.get_texture()
	if texture == null:
		return _fail("capture_renderer_unavailable", {"label": label})
	var image := texture.get_image()
	return capture_image(image, label, metadata)

func capture_image(image: Image, label: String, metadata: Dictionary = {}) -> Dictionary:
	if image == null or image.is_empty() or image.get_width() <= 0 or image.get_height() <= 0:
		return _fail("capture_empty_frame", {"label": label})
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	if dir_error != OK and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(CAPTURE_DIR)):
		return _fail("capture_directory_failed", {"error": dir_error})
	sequence += 1
	# Microseconds prevent collisions when multiple captures happen in one second
	# or the app is relaunched and the in-memory sequence resets.
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	var micros := str(Time.get_ticks_usec() % 1000000).pad_zeros(6)
	var safe_label := _safe_label(label)
	var filename := "%s_%s_%04d_%s.png" % [stamp, micros, sequence, safe_label]
	var path := CAPTURE_DIR.path_join(filename)
	var save_error := image.save_png(path)
	if save_error != OK:
		return _fail("capture_save_failed", {"error": save_error, "label": safe_label})
	last_capture_path = path
	var entry := {
		"timestamp_unix": int(Time.get_unix_time_from_system()),
		"sequence": sequence,
		"label": safe_label,
		"path": path,
		"width": image.get_width(),
		"height": image.get_height(),
		"metadata": _safe_metadata(metadata),
	}
	var manifest := FileAccess.open(MANIFEST_PATH, FileAccess.READ_WRITE)
	if manifest == null:
		manifest = FileAccess.open(MANIFEST_PATH, FileAccess.WRITE)
	if manifest == null:
		return _fail("capture_manifest_open_failed", {"label": safe_label})
	manifest.seek_end()
	manifest.store_line(JSON.stringify(entry))
	manifest.flush()
	if journal != null:
		journal.record("screenshot_agent", "info", "screenshot_captured", {"label": safe_label, "width": image.get_width(), "height": image.get_height(), "path": path})
	return {"ok": true, "path": path, "width": image.get_width(), "height": image.get_height(), "sequence": sequence}

func capture_current_scene(label: String, metadata: Dictionary = {}) -> Dictionary:
	if _is_headless_renderer():
		return _fail("capture_unavailable_headless", {"label": label, "renderer": DisplayServer.get_name()})
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		return capture_viewport(loop.root, label, metadata)
	return _fail("capture_no_scene_tree", {"label": label})

func _is_headless_renderer() -> bool:
	return OS.has_feature("headless") or DisplayServer.get_name().to_lower() == "headless"

func _fail(code: String, details: Dictionary) -> Dictionary:
	if journal != null:
		journal.record("screenshot_agent", "error", code, details)
	return {"ok": false, "code": code}

func _safe_label(value: String) -> String:
	var result := value.strip_edges().to_lower()
	for character in [" ", "/", "\\", ":", "*", "?", "\"", "<", ">", "|"]:
		result = result.replace(character, "_")
	if result.is_empty():
		result = "capture"
	return result.substr(0, 48)

func _safe_metadata(source: Dictionary) -> Dictionary:
	var clean: Dictionary = {}
	for key in source.keys():
		if clean.size() >= 12:
			break
		var key_text := String(key).to_lower()
		if key_text.contains("email") or key_text.contains("password") or key_text.contains("token") or key_text.contains("ip") or key_text.contains("chat") or key_text.contains("name"):
			continue
		var value: Variant = source[key]
		if value is String:
			clean[key_text] = value.substr(0, 120).replace("\n", " ")
		elif value is int or value is float or value is bool or value == null:
			clean[key_text] = value
		else:
			clean[key_text] = str(value).substr(0, 80)
	return clean
