# v22 — Orientación y responsive de partida

## Cambios
- Orientación móvil cambiada a sensor completo (`SCREEN_SENSOR`), permitiendo vertical y horizontal.
- Solicitud explícita de orientación sensor en Android/iOS al iniciar.
- Columnas laterales de partida en horizontal pasan a ser dinámicas (220–320 px) para evitar perfiles diminutos.
- Barra inferior horizontal usa el ancho de pantalla disponible, no solo el ancho del tablero.
- Chat e historial en horizontal usan la columna lateral real.
- Selector de reacciones en horizontal usa hasta 4 columnas y una anchura mayor.
- PlayerCard aumenta altura y tipografía cuando dispone de espacio suficiente.
- El layout vertical existente se mantiene separado.

## Pruebas Godot 4.7.2
- Orientation/layout v22: 22/22
- Responsive audit: 1504/1504
- Core: 38/38
- Movement/bot regression: 18/18
- Bot integration: 6/6
- Bot difficulty: 39/39
- Competitive: 24/24
- Online setup: 37/37
- Matchmaking: 8/8
- Profile/UI: 9/9
- Account Hub: 100/100
- Storage: 18/18 + runtime 10/10
- Tandas 5–7: 23/23
- Tanda 8: 5345/5345
- UI regression: 51/51

## Nota de prueba de orientación
Godot en Linux/Xvfb no puede reproducir físicamente el sensor de rotación de un teléfono. Se validó la configuración de orientación sensor y se ejecutaron layouts reales en 720x1280, 360x640, 1280x720 y 800x480. La confirmación física final del giro en Android queda para el dispositivo.
