# V33 — Test / consistency report

Runtime Godot 4.7.2 was not available in this execution environment, so this report does not claim runtime validation.

Static checks passed:
- Historial: `Analizar partida` before first analysis.
- Historial: `Ver` after analysis.
- Replay: compact `Analizar` before analysis.
- Replay: compact `Ver` after analysis.
- Analysis: `Replay` remains available as the secondary route to normal replay.
- Previous `Ver análisis` UI label removed from scene code.
- `analysis_viewed` remains persisted by the existing PlayerData flow.
- Test expectations updated for the new flow.
