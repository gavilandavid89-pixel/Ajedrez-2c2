# Flujo online

## Entrada
`Menú -> 2c2 / 1c1 ONLINE -> Mini menú`

## Mini menú
- Partida
- Jugar con un amigo
- 10'
- 15'
- 20'

El tiempo seleccionado se guarda en `App.selected_time_minutes`.

## Amigo
`Jugar con un amigo -> Crear sala / Unirse -> QR / enlace / código -> Esperando invitado`

En 2c2 el invitado queda preparado como compañero. En 1c1 el invitado queda preparado como rival.

### Unirse
- El usuario puede pegar un enlace de invitación o escribir el código de 6 caracteres.
- El flujo valida el código antes de pasar a la pantalla de espera.
- La lectura de QR con cámara queda para la capa de red/dispositivo; la sala ya admite QR como medio de invitación.

## Público
`Partida -> Matchmaking -> Rival encontrado -> Partida`

## Reloj
- 2c2: un reloj por equipo.
- 1c1 online: un reloj por lado.
- Solo corre el reloj correspondiente al turno activo.

## Pendiente de backend
- Matchmaking real.
- Creación/entrada real de salas.
- QR que resuelva a una invitación real.
- Sincronización de jugadas.
- Sincronización de reloj y reconexión.

## Unirse a una sala privada
`Jugar con un amigo -> Unirse a una sala -> código/enlace -> sala de espera`

- 1c1: quien entra queda como rival del anfitrión.
- 2c2: quien entra queda preparado como compañero del anfitrión.
- Se admite un código de 6 caracteres o un enlace con `/r/CODIGO`.
- El tiempo y las reglas pertenecen a la sala del anfitrión; el invitado no los cambia.
- El escaneo de QR con cámara se conectará cuando se implemente la capa de red/dispositivo.

## Política de desconexión preparada para backend (V116)

`domain/online/disconnection_policy.gd` define una máquina de estados determinista para la futura autoridad de servidor:

- `connected`: la sesión recibe heartbeats válidos.
- `grace_period`: no llegó un heartbeat dentro del umbral; la partida todavía no debe convertirse automáticamente en derrota.
- `disconnected`: expiró el periodo de gracia y el servidor puede aplicar la política de reconexión/abandono definida por la sala.

Valores iniciales configurables: 8 segundos sin heartbeat para entrar en gracia y 20 segundos de gracia. Son valores provisionales de diseño, no una decisión final de equilibrio.

La política valida IDs de jugador, orden temporal de heartbeats y generación de sesión para rechazar mensajes tardíos de una conexión sustituida. Usa el tiempo proporcionado por el servidor; no es una detección real de red por sí sola.

**No está conectada aún a una red real ni al resultado competitivo.** Cuando se implemente backend, el servidor deberá autenticar cada heartbeat, guardar el estado de partida, decidir el timeout y arbitrar la reconexión. El cliente solo presenta el estado que el servidor confirma. Una caída del servidor debe ser un estado separado y nunca adjudicarse automáticamente como derrota del jugador.
