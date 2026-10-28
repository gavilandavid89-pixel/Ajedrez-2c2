# 1c1 Online — UX base

## Durante la partida
- No se muestran botones `Menú` ni `Reiniciar`.
- El botón de volver/cancelar del sistema queda bloqueado mientras la partida está activa.
- Se mantienen solamente las salidas propias de la partida: ganar, perder, rendirse o tablas.
- Cuando la partida termina aparece `Volver al menú`.
- Un reloj por lado: rival arriba y tú abajo en vertical; laterales en horizontal.
- Sin chat de equipo, sugerencias ni cambio de posición.
- Se mantienen Historial, Emotes, Rendirse y Tablas.
- Estado `● EN LÍNEA` en la cabecera.

## Matchmaking
`online_matchmaking.tscn` muestra la transición previa a la partida. Actualmente es una carcasa visual/local: todavía no existe matchmaking, sincronización ni transporte de red reales.

## Referencias de layout
La distribución sigue patrones habituales de ajedrez online móvil: reloj visible junto al área de juego, controles secundarios fuera del tablero y configuraciones separadas del área principal de juego.
