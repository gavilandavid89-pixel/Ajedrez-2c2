# V126 — Agente de capturas de QA

## Objetivo
Añadir una vía reproducible para guardar imágenes del viewport y dejar índice/metadatos en disco, para inspección posterior sin depender de observar el juego en vivo.

## Implementación
- `domain/supervision/screenshot_supervisor_agent.gd`: captura un `Viewport` real en ejecución (`capture_viewport`) o persiste una `Image` (`capture_image`, útil para pruebas automatizadas).
- `core/services/supervisor_hub.gd`: crea el agente y expone `capture_screen(label, metadata)`.
- Capturas: `user://qa_captures/`.
- Índice: `user://qa_captures/manifest.jsonl`.
- Los eventos también se agregan a `user://supervisor_diagnostics.jsonl`.
- Se filtran claves sensibles como email, password, token, IP, chat y name del metadata.
- Si se ejecuta con renderer headless sin textura disponible, el agente registra el error en lugar de fingir una captura.

## Uso desde código
```gdscript
# Llamar cuando la pantalla ya se haya dibujado (por ejemplo, tras esperar un frame):
var result: Dictionary = SupervisorHub.capture_screen("match_board", {"screen": "match", "test_case": "initial_position"})
if not result.get("ok", false):
    push_warning("No se pudo capturar QA: %s" % result.get("code", "unknown"))
```

Para inspeccionar transiciones con precisión, el código que conoce cuándo terminó de dibujarse la pantalla debe invocar la captura después de ese punto. No se dispara una captura en cada frame, para evitar llenar el almacenamiento.

## Pruebas
- V126 captura y persistencia: 8/8.
- V125 tablero/piezas: 7/7.
- V124 miniagentes: 12/12.
- V123 supervisor de partidas: 22/22.
- V120 turnos/reconexión/resultados: 16/16.

La prueba headless valida la escritura PNG, índice y diario; no prueba el acceso a una textura de ventana real, porque el renderer dummy de headless no expone una imagen de viewport. En una ejecución gráfica, `capture_viewport` lee el viewport real.

## Grabación de vídeo
V126 no codifica vídeo automáticamente. Para defectos temporales (animaciones, parpadeos, navegación) conviene complementar las capturas con grabación de pantalla de la plataforma o una herramienta externa. Las capturas puntuales consumen menos almacenamiento y sirven para comparar estados exactos; el vídeo sirve para entender secuencias.
