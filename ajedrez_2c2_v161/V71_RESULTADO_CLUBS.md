# V71 — Resultado de partida + Clubs/Friendly Social

## Resultado postpartida
- El antiguo panel `Result` queda como compatibilidad técnica y ya no se usa como interfaz principal.
- Nueva escena/componente `game_match_result_screen` ocupa toda la pantalla y usa `ScrollContainer`.
- Animación de entrada por bloques: los módulos del resultado parten separados y se ensamblan hacia el centro.
- `×` arriba a la izquierda cierra la pantalla final y devuelve al tablero terminado, sin permitir nuevas jugadas.
- Botón flotante `🏆 Resultado` permite volver a abrir el menú final mientras la partida ya terminó.
- Sección de equipo ganador con corona e iconos.
- En 2c2 se muestra `DESEMPEÑO DE PAREJA` usando datos ya existentes de PairModel (cambio de NEXUS de pareja, rating posterior y copas de pareja).
- Copas ganadas mostradas sin modificar el sistema competitivo.
- `ANALIZAR PARTIDA` abre el analizador; desde esa entrada el botón de volver lleva a Inicio.
- Cada jugador puede recibir una solicitud de amistad sin contaminar la tarjeta del jugador.
- Historial de jugadores al final de la pantalla; tocar icono/perfil abre `player_profile_screen` con opción de añadir amigo.

## Social de Club
- `Más` ya contiene Ajustes.
- `club_members_screen` es pantalla independiente con scroll.
- El detalle de club presenta `MIEMBROS · N →` como acceso directo a esa pantalla.
- La navegación `Club` lleva al chat cuando existe un club activo; si no, abre el buscador de clubes.
- `ClubChatService` conserva tarjetas de partidas amistosas dentro del chat y las recorta por historial cuando los mensajes viejos son desplazados.
- Las amistosas tienen flags explícitos:
  - `competitive=false`
  - `affects_rating=false`
  - `affects_cups=false`
  - `affects_pair_points=false`
  - `affects_nexus=false`
- Al completarse las aceptaciones necesarias, el desafío crea un estado de partida amistosa observable por miembros del club.
- Las tarjetas muestran un acceso pequeño `VER` para el visor de partida.
- `club_match_viewer_screen` es una escena independiente preparada para observación/replay.

## Límite actual
El visor y el estado social están conectados y aislados, pero la sincronización de jugadas en vivo entre varios dispositivos requiere el backend/flujo de partida amistosa. No se simula ni se presenta como sincronización de red real mientras ese transporte no exista.

## QA V71
- Godot 4.7.2 importación: OK
- Core: 39/39
- UI regression: 53/53
- Arquitectura V70: 61/61
- NEXUS: 27/27
- Movimiento/bots: 21/21
- Account Hub: 149/149
- Home: 17/17
- Navigation: 18/18
- V58: 42/42
- V59: 25/25
- V60: 15/15
- V61: 22/22
- Social V70: 35/35
- Match Result V71: 5/5
- Social Extensions V71: 9/9
- Responsive touch: 30/30
- Orientation/layout: 22/22

Sin errores de parser ni `SCRIPT ERROR` en la importación final. Los avisos de ALSA/root/leaks son propios de las ejecuciones headless de Godot en este entorno.
