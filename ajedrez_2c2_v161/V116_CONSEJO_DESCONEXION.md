# V116 — Consejo: política de desconexión y reconexión

## Decisión
Se añade una máquina de estados pura y testeable para preparar la futura implementación de red autoritativa. No se presenta como detección real ni se conecta aún al motor de resultados.

## Política
- `connected`: heartbeats recibidos dentro del umbral.
- `grace_period`: silencio superior al timeout; todavía no se adjudica una derrota.
- `disconnected`: expiró el periodo de gracia.
- Heartbeat válido durante gracia/desconectado restaura el estado a conectado.
- La generación de sesión evita que un heartbeat atrasado de una conexión antigua reactive una sesión nueva.
- Se rechazan IDs vacíos, sesiones desconocidas y timestamps fuera de orden.

Valores de prueba/configuración: heartbeat timeout 8 s; periodo de gracia 20 s. Son valores iniciales editables, pendientes de medir y decidir para partidas reales.

## Pruebas
`tests/v116_disconnect_policy_tests.gd`: **18/18 aprobadas**.
`tests/v115_result_idempotency_tests.gd`: **6/6 aprobadas**.
Importación del proyecto con Godot 4.7.2: exit 0.

## Límites
- No hay sockets, heartbeat de red, backend ni integración con matchmaking en esta entrega.
- La máquina de estados solo modela la política y permite probar casos deterministas.
- No adjudica ganador ni modifica rating. La autoridad futura deberá validar la partida y decidir cómo tratar reconexiones, abandono, caída del servidor y desconexión de compañero/rival.
- No se han realizado pruebas en Android físico.

## Próximo paso
Implementar el adaptador de red y el protocolo de sesión contra un backend real; después, integrar el estado confirmado por servidor con pausa/reconexión y resultado idempotente, sin permitir que el cliente declare su propia victoria.
