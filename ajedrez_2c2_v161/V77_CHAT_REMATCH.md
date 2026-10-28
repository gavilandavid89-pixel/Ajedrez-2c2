# V77 — Chat de partida + solicitudes de revancha

## Cambios

- 1c1: el chat se presenta como conversación directa con el rival.
- 2c2: el chat se presenta como chat de la partida y su placeholder deja explícito que incluye equipo y rivales.
- Se conserva un único historial de chat por partida; no se creó un segundo canal separado.
- Se añadió `RematchService` como módulo aislado para solicitudes de revancha pendientes.
- El Home muestra arriba una notificación compacta cuando existe una solicitud pendiente:
  - “Juanito te ha pedido la revancha”
  - botón `✓` para aceptar
  - botón `×` para rechazar
- Aceptar elimina la solicitud y envía al matchmaking online.
- Rechazar elimina la solicitud sin alterar rating/copas.
- La notificación se reposiciona con el ancho del viewport.

## Capturas reales con Godot 4.7.2

- `/mnt/data/v77_rematch_notification7.png`
- `/mnt/data/v77_1c1_chat.png`
- `/mnt/data/v77_2c2_chat.png`

## QA

- Godot 4.7.2 importación: OK
- Chat/Revancha V77: 7/7
- Core: 39/39
- Arquitectura modular: 59/59
- Social V70: 35/35
- Social V71 EXT: 9/9

## Nota

Los avisos de ALSA aparecen porque la sesión de captura no dispone de dispositivo de audio; Godot cae al driver de audio dummy. No corresponde al juego.

Los runners headless de pruebas dejan recursos/ObjectDB al cerrar, igual que otros runners existentes; no se ha introducido lógica de gameplay para ocultarlo.

No se modificaron reglas de 2c2.
