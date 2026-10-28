# Persistencia y sincronización — Ajedrez 2c2

## Capas

- `user://ajedrez_2c2/profile.json`: estado local principal del jugador.
- `user://ajedrez_2c2/backup/profile.json.bak`: copia de recuperación.
- `user://ajedrez_2c2/cache/`: datos derivados y reconstruibles para acceso rápido.
- `user://ajedrez_2c2/sync_queue.json`: cola offline de cambios pendientes.
- `cloud_sync.gd`: punto de integración para el servidor futuro; no simula red.

## Guardado seguro

Los documentos se escriben primero a un temporal y luego se reemplazan. Antes de rotar el backup se comprueba que el archivo actual sea JSON válido, para no convertir una corrupción en la nueva copia de seguridad.

El primer guardado también crea backup. Si la primaria se corrompe, se puede leer la copia anterior y reparar la primaria sin destruir el backup bueno.

## Caché

La caché no es fuente de verdad. Actualmente se generan:

- `profile_summary`: identidad, rating, copas y reacciones equipadas.
- `history_index`: metadatos de las partidas, sin sustituir el historial completo.

Puede borrarse y reconstruirse sin perder progreso.

## Cola offline

Cada guardado genera dos operaciones coalescidas:

- `profile_core`: identidad, competitivo, pareja, ajustes, apariencia y reacciones.
- `history`: historial completo, incluido `replay_data`.

La cola evita duplicados usando una clave de coalescencia. El servidor futuro podrá procesar las operaciones por `id` sin que la app pierda cambios cuando esté offline.

## Nube

La nube está **preparada pero desactivada**. `CloudSync` no inventa una conexión ni marca una sincronización como exitosa sin transporte real. Cuando exista el backend, el adaptador será el punto único para subir y descargar datos.
