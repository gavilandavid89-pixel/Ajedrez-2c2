# QA agents — modular architecture (V134)

## Dependency direction

`SupervisorHub` is the composition root. It creates agents through `core/services/qa_agent_registry.gd`; agents must not look up the hub or instantiate sibling agents. Shared event persistence is injected through `SupervisorJournal`.

`QABundleExporter` is a separate output adapter. It receives the journal, serialized diagnostics, capture/manifest paths and touch summary as arguments. It does not access the scene tree, navigate screens, or mutate game/match state.

## Modules and contracts

- `core/services/qa_agent_registry.gd`: single source of truth for runtime agent script paths and registry validation.
- `core/services/supervisor_hub.gd`: lifecycle/composition and stable public façade used by gameplay/UI.
- `domain/supervision/touch_observer_agent.gd`: passive input observations and touch/action correlation only.
- `domain/supervision/interface_supervisor_agent.gd`: screen/interface observations.
- `domain/supervision/board_piece_supervisor_agent.gd`: board/piece consistency inspection.
- `domain/supervision/replay_supervisor_agent.gd`: replay consistency inspection.
- `domain/supervision/screenshot_supervisor_agent.gd`: explicit/on-demand capture.
- `domain/supervision/qa_bundle_exporter.gd`: ZIP assembly and bounded evidence selection.
- `domain/supervision/supervisor_journal.gd`: sanitized persistent event journal.
- `domain/online/match_supervisor.gd`: match policy observations; it does not replace authoritative match logic.

## Moving an agent later

1. Move the agent script and its adjacent resources together.
2. Update only that agent's path in `AGENT_PATHS` in `qa_agent_registry.gd`.
3. Run `tests/v134_agent_modularity_tests.gd` and the agent's own tests.
4. Keep the agent's public methods and journal contract stable. If the public contract changes, update the hub adapter and contract tests explicitly.

Avoid hardcoding agent file paths in gameplay/UI code. Gameplay/UI should call the stable `SupervisorHub` façade only. Tests may use direct paths to validate individual modules; those test paths must be updated when a module is moved.

## Safety and performance constraints

- Agents are observers; they must not consume input or alter chess rules, turn order, or match results.
- Capture is on-demand and bounded. ZIP export includes at most 40 screenshots.
- Diagnostics are written under `user://`; review package contents before sharing because local paths and interaction metadata may be sensitive.
