# V99 — Roles Blancas / Negras aleatorios

- El rol de partida queda separado de la apariencia/skin.
- El jugador local puede recibir Blancas o Negras al iniciar una partida real.
- En 2c2, el jugador local y su compañero comparten color; los dos rivales reciben el contrario.
- El primer turno siempre pertenece a Blancas, aunque el jugador local sea Negro.
- Si el jugador local es Negro, el tablero se orienta para jugar desde el lado negro.
- Las tarjetas de jugador también se recolocan: el usuario queda abajo y el rival arriba cuando corresponde.
- Las piezas siguen usando su variante visual por color real del tablero; la skin no decide el rol.
- Se mantiene una API determinista `assign_roles_for_local_team()` para pruebas/reconexión y una `randomize_roles()` para partidas reales.

## QA

- Random roles: 27/27
- Suite general: 39/39
- Bot integration: 6/6
- Orientation/layout: 22/22
- Graphite/gold skin: 36/36
- Independent preview: 13/13
- Skin UI interaction: 10/10
- Captura real Godot 4.7.2 con rol Negro: sin errores de script/parse/resource en el log.
- Advertencia restante en captura: V-Sync no soportado por el driver de Xvfb; sin errores del proyecto.
