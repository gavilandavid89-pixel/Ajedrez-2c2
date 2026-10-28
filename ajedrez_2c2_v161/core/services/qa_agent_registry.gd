extends RefCounted
class_name QAAgentRegistry

## Single runtime manifest for QA agents. If an agent file is moved, update its path
## here instead of scattering preload paths through the runtime.
const REGISTRY_VERSION := 1
const AGENT_PATHS := {
	"journal": "res://domain/supervision/supervisor_journal.gd",
	"replay": "res://domain/supervision/replay_supervisor_agent.gd",
	"interface": "res://domain/supervision/interface_supervisor_agent.gd",
	"board_piece": "res://domain/supervision/board_piece_supervisor_agent.gd",
	"screenshot": "res://domain/supervision/screenshot_supervisor_agent.gd",
	"touch_observer": "res://domain/supervision/touch_observer_agent.gd",
	"match": "res://domain/online/match_supervisor.gd",
	"bundle_exporter": "res://domain/supervision/qa_bundle_exporter.gd"
}

const REQUIRED_AGENT_IDS := ["journal", "replay", "interface", "board_piece", "screenshot", "touch_observer", "match", "bundle_exporter"]

static func get_agent_path(agent_id: String) -> String:
	return String(AGENT_PATHS.get(agent_id, ""))

static func validate_paths() -> Dictionary:
	var missing: Array[String] = []
	for agent_id in REQUIRED_AGENT_IDS:
		var path := get_agent_path(agent_id)
		if path.is_empty() or not ResourceLoader.exists(path):
			missing.append(agent_id)
	return {"ok": missing.is_empty(), "registry_version": REGISTRY_VERSION, "missing_agents": missing, "registered_count": AGENT_PATHS.size()}
