# V124 — Miniagentes de supervisión y diario persistente

## Agentes
- **Match agent**: registra observaciones de estado, cuenta regresiva, recomendación de abandono y reconexión. No modifica por sí mismo tablero, turnos ni resultado.
- **Replay agent**: inspecciona estructura del replay (posiciones, codificación de tablero, cantidad de estados y coordenadas). Es una auditoría estructural; no sustituye la validación legal completa de ajedrez.
- **Interface agent**: registra cambios de pantalla a través de `RuntimeServices.change_scene`, fallos de navegación e incidencias de interfaz comunicadas por código/pruebas.
- **Journal**: conserva los últimos eventos en memoria y añade cada evento a un archivo JSON Lines para revisar incidencias entre ejecuciones.

## Dónde encontrar el archivo
El registro persistente está en `user://supervisor_diagnostics.jsonl`. Godot resuelve `user://` a la carpeta de datos del usuario del proyecto. Cada línea es un objeto JSON independiente; el archivo rotado usa el sufijo `.1`.

El autoload `SupervisorHub` ofrece `diagnostics_path()`, `recent_diagnostics(limit)` y `export_diagnostics_text()` para una futura pantalla de diagnóstico/exportación.

## Privacidad y límites
El diario filtra claves típicas de email, contraseña, token, IP, chat y nombre; limita la longitud y cantidad de detalles y rota el archivo al superar aproximadamente 1 MiB. No registrar chat, credenciales, IP ni datos personales desde los agentes.

Godot no expone automáticamente todos los errores del panel Debugger a un script de juego. Este sistema registra eventos instrumentados, fallos de navegación e incidencias comunicadas por código/pruebas; no es captura universal de cada error interno ni inspección visual autónoma. Hay que seguir revisando Output y Debugger.

## Pruebas V124
- Miniagentes y diario: 12/12
- Supervisor V123: 22/22
- Política de gracia V122: 25/25
- Suite principal: 42/42
- Importación headless: completada sin errores de análisis/script en el registro; aparece la advertencia del entorno por ejecutar Godot como root.
- Ejecución headless del proyecto: se mantuvo activa hasta el límite de observación de 20 segundos sin errores en Output. Esto no certifica todos los recorridos visuales.
