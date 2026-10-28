# Ajedrez 2c2 — V51 Detalles de partida

## Sugerir: regla restaurada

Sugerir no ejecuta movimientos y no cambia las reglas de ajedrez.

Flujo:
1. El jugador toca `Sugerir`.
2. Selecciona una pieza si todavía no hay una seleccionada.
3. Selecciona la casilla destino.
4. Se crea una sugerencia privada para el compañero.
5. La pieza real no se mueve.
6. El compañero recibe la flecha fantasma y decide qué hacer.

Si la pieza ya estaba seleccionada al pulsar `Sugerir`, se pasa directamente a elegir destino.

La flecha se muestra únicamente al receptor. El emisor no ve su propia flecha.

## Historial durante la partida

Se eliminó el botón/panel de Historial de la pantalla de partida.

La lista compacta de movimientos queda directamente debajo del tablero, aprovechando el espacio que estaba prácticamente vacío.

No se elimina el historial persistente de la partida: los movimientos y replay siguen guardándose para Historial/Análisis.

## Final de partida

El resultado ya no aparece como un modal centrado que tapa el tablero de golpe.

Ahora:
- el tablero permanece visible;
- el resultado entra con una transición de aparición/escala;
- en vertical se coloca debajo del tablero;
- en horizontal usa la zona lateral;
- los controles normales se sustituyen por Revancha/Volver al menú cuando corresponde.

### Jaque mate

Cuando el motivo es jaque mate, el rey perdedor recibe una marca roja mucho más visible:
- relleno rojo translúcido;
- borde rojo grueso;
- punto de énfasis sobre el rey.

El resultado muestra `JAQUE MATE` y después Victoria/Derrota y el equipo ganador.

## Referencias de diseño estudiadas

Se revisaron referencias actuales de Chess.com y Lichess únicamente para patrones de interacción, no para copiar su interfaz.

Chess.com documenta que su Game Review móvil usa una lista de movimientos bajo el tablero, navegación jugada por jugada y un botón para saltar a la siguiente jugada clave. También documenta animaciones de resultado sobre el tablero y una celebración al ganar.

Lichess documenta un flujo de resultado con acceso posterior al tablero de análisis y controles de navegación asociados a la lista de movimientos.

## Pruebas V51

- Núcleo: 39/39 OK.
- UI regression: 51/51 OK.
- Refinamiento/bots: 23/23 OK.
- Sugerencias V50: 19/19 OK.
- Movimiento/bots: 22/22 OK.
- Replay móvil: 10/10 OK.
- Capturas visuales revisadas en 390x844 y 360x640.

Nota: las capturas y pruebas gráficas son Godot 4.7.2 sobre Linux/Xvfb. No sustituyen la prueba final en Android físico.
