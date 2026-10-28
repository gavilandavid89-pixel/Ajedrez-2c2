# V128 — Recuperación de diagnósticos entre sesiones

## Objetivo
El diario del supervisor ya no depende exclusivamente de los eventos que ocurrieron en el proceso actual. Al iniciar o configurar una ruta de diario, recupera hasta 100 eventos JSONL válidos desde disco a la memoria reciente.

## Cambio
- `SupervisorJournal._init()` intenta recuperar el diario predeterminado.
- `configure_path()` limpia el buffer de memoria y carga el archivo elegido, evitando mezclar eventos de rutas distintas.
- Se ignoran líneas vacías y JSON inválido; solo se recuperan objetos que tengan `agent` y `code`.
- La recuperación está acotada a los últimos 100 eventos para controlar memoria en Android.
- Los eventos recuperados siguen disponibles mediante `recent_events()` y `export_text()`.

## Validación Godot 4.7.2
- Importación headless: salida 0; sin `SCRIPT ERROR`, `Parse Error` ni `ERROR:` en el registro.
- V128 recuperación del diario: 8/8.
- V127 integración de supervisión: 15/15.
- V124 miniagentes: 12/12.
- V121 sesión/reconexión: 17/17.
- V119 transiciones y carreras: 29/29.

## Límites conocidos
- Esto recupera el diario persistente del supervisor, no captura mágicamente todos los mensajes del panel Debugger de Godot.
- No añade una IA autónoma: los agentes siguen siendo supervisores deterministas.
- La inspección visual de capturas todavía requiere comprobaciones visuales o revisión externa; el diario por sí solo no entiende píxeles.
