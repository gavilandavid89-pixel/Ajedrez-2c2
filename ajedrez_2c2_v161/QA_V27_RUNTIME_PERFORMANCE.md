# Ajedrez 2c2 — QA v27: movimiento, rendimiento y transiciones

## Cambios
- Entrada de partida unificada en `Game._input`: mouse + ScreenTouch + mouse emulado desde touch, con deduplicación.
- `Board._gui_input` dejó de competir con el controlador de partida para evitar dobles movimientos.
- Scroll de Perfil reforzado para ScreenTouch/ScreenDrag y mouse emulado; se restablece correctamente al salir de foco/escena.
- El HUD de partida reduce su hot-loop a una actualización dinámica de 10 Hz; las reacciones solo se refrescan mientras el selector está visible.
- Cachés de texturas de avatar y preview conservadas.
- Splash nativo y color de limpieza alineados con la pantalla de carga oscura.
- Transición persistente de escena mediante `App` para evitar flashes grises al cambiar de escena.

## Pruebas en Godot 4.7.2
- Núcleo: 38/38
- Base extra: 9/9
- Competitivo: 24/24
- Matchmaking: 8/8
- Online setup: 37/37
- Online shell: 3/3
- Identidad runtime: 7/7
- Profile entry: 4/4
- Historial: 5/5
- Bots: 39/39
- Integración bots: 6/6
- Movimiento + bots + touch/mouse: 20/20
- Account Hub: 108/108
- Profile UI: 9/9
- Performance de Perfil: 3/3
- Menu responsive: 22/22
- Touch targets: 30/30
- Orientación/layout: 22/22
- UI regression: 51/51
- Auditoría visual responsive: 1504/1504
- Seguridad de servicios runtime: 4/4
- Storage: 18/18
- Tandas 5–7: 23/23
- Tanda 8 / estrés: 5348/5348

Total de comprobaciones funcionales acumuladas en esta batería: 7342/7342.

## Nota de entorno
Godot bajo Xvfb usa `llvmpipe`, V-Sync no disponible y el audio cae al driver dummy ALSA. Son advertencias del entorno de laboratorio. Las pruebas funcionales terminan con código 0.

La orientación física y la interacción táctil en un dispositivo Android real deben validarse también en el teléfono del usuario.
