# Revisión profunda — reloj por equipos

## Regla aplicada
En 2c2 cada color/equipo comparte un único reloj. No existe un reloj independiente por jugador.

## Cambios
- Eliminado el nodo `Clock` de `PlayerCard.tscn`.
- `PlayerCard.gd` ya no recibe ni actualiza tiempos.
- Añadidos `BlackInfo/TeamClock` y `WhiteInfo/TeamClock` en `game_hud.tscn`.
- `game_hud.gd` actualiza exactamente un reloj por equipo usando `game.team_time[team]`.
- El mismo esquema se aplica a 1c1, VS IA y 1c1 Local: un reloj por lado/equipo.
- El intercambio de posiciones no crea ni mueve relojes; solo cambia perfiles/slots.
- El sistema de ausencia tampoco crea relojes adicionales.
- Los emotes se muestran sobre `PlayerCard` sin incorporar un segundo reloj.
- Se sincronizó `board.gd` y `game_hud.gd` a `top_reserved = 180` para que el texto de turno no se monte sobre el tablero en vertical.

## Verificación de código
La suite final reporta:

**37 OK / 0 fallos**

Incluye una prueba explícita que exige:
- dos nodos `TeamClock`, uno para cada equipo;
- cero nodos `Clock` dentro de `PlayerCard`.

## Verificación visual
Se ejecutó Godot 4.7.2 en 720x1280 y 1280x720.
Las capturas finales muestran un solo reloj por equipo y ninguna repetición de reloj dentro de las tarjetas individuales.
