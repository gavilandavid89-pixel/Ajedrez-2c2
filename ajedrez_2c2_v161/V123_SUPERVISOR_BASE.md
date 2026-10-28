# Ajedrez 2c2 — V123: base del supervisor

## Aclaración de reconexión tardía
Sí: el comportamiento ya estaba resuelto en V120/V121. Una reconexión con una instantánea autoritativa marcada `finished=true` debe ir a `match_result`; no debe reabrir la partida. V123 conserva esa regla y la cubre desde el supervisor.

## Cambios
- Nuevo `domain/online/match_supervisor.gd`: fachada determinista que conecta la política de desconexión con el enrutamiento de la sesión visual.
- Inspecciona el estado, expone la cuenta regresiva final y emite una recomendación de derrota una sola vez por combinación partida/jugador.
- La recomendación NO modifica el resultado. La autoridad real de la partida debe validar y aplicar el resultado terminal.
- Una instantánea final tiene prioridad sobre el estado de conexión; una vez observada, el supervisor no reabre la partida.
- Nuevo `tests/v123_match_supervisor_tests.gd`.

## Miniagente IA futuro
Esta base es deliberadamente determinista. En el futuro una IA supervisora podría revisar eventos anómalos, desconexiones repetidas, discrepancias de revisión y solicitudes duplicadas; pero no debería decidir resultados por intuición ni sustituir las reglas. La IA sería observadora y explicativa, mientras las decisiones competitivas siguen reglas verificables del servidor.

## Límites
Todavía no existe backend/socket autoritativo conectado. Este módulo no detecta conexiones reales ni aplica derrotas: coordina políticas internas y devuelve recomendaciones verificables.

## Validación ejecutada
- V123 supervisor: 22 OK / 0 fallidos.
- V122 minuto de gracia: 25 OK / 0 fallidos.
- V121 sesión de visualización/reconexión: 17 OK / 0 fallidos.
- V120 turnos, reconexión y resultado: 16 OK / 0 fallidos.
- V116 política de desconexión: 18 OK / 0 fallidos.
