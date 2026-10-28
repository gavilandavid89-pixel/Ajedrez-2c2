extends RefCounted
class_name QABundleExporter

## Owns only QA ZIP assembly. It does not own agents, UI, or match state.
const DEFAULT_OUTPUT_PATH := "user://qa_supervisor_bundle.zip"
const DEFAULT_MANIFEST_PATH := "user://qa_captures/manifest.jsonl"
const DEFAULT_CAPTURE_DIR := "user://qa_captures"

func export_bundle(journal: Variant, diagnostics_text: String, rotated_log_path: String, manifest_path: String, capture_dir_path: String, touch_summary: Dictionary, max_screenshots: int = 12, output_path: String = DEFAULT_OUTPUT_PATH) -> Dictionary:
	if journal == null:
		return {"ok": false, "code": "journal_unavailable"}
	var packer := ZIPPacker.new()
	var open_error := packer.open(output_path)
	if open_error != OK:
		journal.record("qa_bundle_exporter", "error", "qa_bundle_open_failed", {"error": open_error})
		return {"ok": false, "code": "zip_open_failed", "error": open_error}
	var included: Array[String] = []
	var failed_entries: Array[String] = []
	if not diagnostics_text.is_empty():
		_add_tracked(packer, "supervisor_diagnostics.jsonl", diagnostics_text.to_utf8_buffer(), included, failed_entries)
	if FileAccess.file_exists(rotated_log_path):
		var rotated_bytes := FileAccess.get_file_as_bytes(rotated_log_path)
		if not rotated_bytes.is_empty():
			_add_tracked(packer, "supervisor_diagnostics_previous.jsonl", rotated_bytes, included, failed_entries)
	if FileAccess.file_exists(manifest_path):
		var manifest_bytes := FileAccess.get_file_as_bytes(manifest_path)
		if not manifest_bytes.is_empty():
			_add_tracked(packer, "qa_captures/manifest.jsonl", manifest_bytes, included, failed_entries)
	var capture_dir_absolute := ProjectSettings.globalize_path(capture_dir_path)
	var pngs: Array[String] = []
	if DirAccess.dir_exists_absolute(capture_dir_absolute):
		for file_name in DirAccess.get_files_at(capture_dir_absolute):
			if file_name.get_extension().to_lower() == "png":
				pngs.append(file_name)
	pngs.sort()
	var bounded_limit := clampi(max_screenshots, 0, 40)
	var first_index := maxi(0, pngs.size() - bounded_limit)
	var screenshot_count := 0
	for i in range(first_index, pngs.size()):
		var file_name := pngs[i]
		var archive_path := "qa_captures/" + file_name
		var bytes := FileAccess.get_file_as_bytes(capture_dir_absolute.path_join(file_name))
		if bytes.is_empty():
			failed_entries.append(archive_path)
			continue
		var count_before := included.size()
		_add_tracked(packer, archive_path, bytes, included, failed_entries)
		if included.size() > count_before:
			screenshot_count += 1
	_add_tracked(packer, "touch_observer_summary.json", JSON.stringify(touch_summary, "\t").to_utf8_buffer(), included, failed_entries)
	var close_error := packer.close()
	if close_error != OK or not failed_entries.is_empty():
		var failure_code := "zip_close_failed" if close_error != OK else "zip_partial"
		journal.record("qa_bundle_exporter", "error", "qa_bundle_failed", {
			"code": failure_code,
			"close_error": close_error,
			"failed_entries": failed_entries,
			"file_count": included.size(),
			"path": output_path
		})
		return {
			"ok": false,
			"code": failure_code,
			"error": close_error,
			"path": output_path,
			"files": included,
			"failed_entries": failed_entries,
			"file_count": included.size(),
			"screenshot_count": screenshot_count
		}
	journal.record("qa_bundle_exporter", "info", "qa_bundle_exported", {"file_count": included.size(), "screenshot_count": screenshot_count, "path": output_path})
	return {"ok": true, "path": output_path, "files": included, "file_count": included.size(), "screenshot_count": screenshot_count, "failed_entries": []}

func _add_tracked(packer: ZIPPacker, archive_path: String, bytes: PackedByteArray, included: Array[String], failed_entries: Array[String]) -> void:
	if _add_bytes(packer, archive_path, bytes):
		included.append(archive_path)
	else:
		failed_entries.append(archive_path)

func _add_bytes(packer: ZIPPacker, archive_path: String, bytes: PackedByteArray) -> bool:
	var start_error := packer.start_file(archive_path)
	if start_error != OK:
		return false
	var write_error := packer.write_file(bytes)
	var close_file_error := packer.close_file()
	return write_error == OK and close_file_error == OK
