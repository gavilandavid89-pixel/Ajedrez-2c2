# V32 — Reporte de validación

## Validación estática
- `account_hub.gd` registra la página secundaria `replay`.
- Historial usa una única acción contextual: `Analizar` / `Ver análisis`.
- El replay normal conserva acceso a `Analizar` / `Ver análisis`.
- `player_data.gd` persiste `analysis_viewed` dentro del registro de partida.
- `record_result()` inicia nuevas partidas con `analysis_viewed = false`.
- `record_noncompetitive_match()` normaliza el campo para partidas existentes/nuevas.
- Existe API para marcar y consultar el estado sin depender de la escena (`mark_history_analysis_viewed`, `history_analysis_viewed`).
- Se evitó una doble actualización de UI al abrir análisis desde el historial/replay.
- Pruebas de interfaz actualizadas para cubrir: primera entrada, persistencia, segundo acceso, replay normal y retorno al análisis.

## Godot runtime
No se ejecutó Godot 4.7.2 en este entorno de trabajo porque el binario no está disponible. Por transparencia, la comprobación final de interacción táctil, renderizado y orientación debe hacerse en Godot 4.7.2/Android antes de continuar con otra tanda.
