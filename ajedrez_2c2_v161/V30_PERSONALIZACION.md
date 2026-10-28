# V30 · Personalización separada

## Decisión de UX

- **Apariencia** = identidad visual del jugador: icono de perfil, marco y título.
- **Reacciones** = experiencia durante la partida: tablero, piezas y reacciones rápidas.
- El perfil solo ofrece accesos compactos a ambos apartados; no duplica sus configuraciones.
- El título seleccionado se muestra debajo del nombre durante la partida.

## Datos persistentes

`PlayerData.appearance` mantiene separado:

- `board_theme`
- `piece_set`
- `profile_frame`
- `player_title`

La migración es hacia atrás compatible porque los valores ausentes vuelven a `classic` / `jugador`.

## Game HUD

La tarjeta de jugador usa el perfil local de `PlayerData` para nombre, avatar, marco y título. Los perfiles de prueba restantes conservan valores visuales propios desde `profile_data.gd`.
