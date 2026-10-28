# Ajedrez 2c2 — V122: minuto de gracia y cuenta regresiva

## Decisión del consejo
La desconexión y el abandono explícito usan un plazo de gracia de **60 segundos**. La cuenta regresiva visual se expone únicamente durante los **últimos 10 segundos** de ese plazo. Así evitamos que la interfaz anuncie prematuramente una derrota mientras el jugador sigue conectado y pensando.

## Cambios realizados
- `domain/online/disconnection_policy.gd`
  - El plazo de gracia predeterminado pasa de 20 a 60 segundos.
  - Se mantiene separado el umbral de detección por heartbeat (8 s por defecto) del minuto de gracia.
  - Se agrega `report_explicit_leave(...)`, que inicia el mismo plazo al salir explícitamente, validando generación de sesión y marca temporal.
  - Se agrega `countdown_seconds(...)`: devuelve `-1` si no existe una gracia activa o si quedan más de 10 segundos; en la ventana final devuelve los segundos restantes.
  - Se registra el motivo de gracia (`connection_lost` o `explicit_leave`).
- `tests/v122_grace_countdown_tests.gd`: pruebas de desconexión, abandono, sesión obsoleta, reconexión y jugador conectado que piensa.

## Regla que queda protegida
**No mover no equivale a desconectarse.** Mientras el jugador mantiene su conexión/heartbeat, pensar una jugada no inicia el minuto de desconexión ni muestra su cuenta regresiva. El reloj normal de la partida sigue siendo independiente. La detección real de conexión y la adjudicación competitiva final deberán conectarse al backend autoritativo; este módulo por sí solo no detecta sockets reales ni declara automáticamente el resultado de una partida en producción.

## Validación ejecutada con Godot 4.7.2
- V122 minuto de gracia: **25 OK / 0 fallidos**.
- V116 política previa de desconexión: **18 OK / 0 fallidos**.
- V120 turnos, reconexión y resultado: **16 OK / 0 fallidos**.
- Suite principal: **42 OK / 0 fallidos**.
- Importación de proyecto ejecutada; no se observaron errores de parseo/script en la salida.

## Alcance
Es una mejora interna y testeable de la política. No representa todavía una conexión a un servidor real. La partida y su reloj autoritativo deben seguir siendo independientes de la pantalla/dispositivo conectado; la futura integración del servidor deberá aplicar el resultado una sola vez cuando venza el plazo.
