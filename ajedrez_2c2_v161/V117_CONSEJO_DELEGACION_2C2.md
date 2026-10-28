# Ajedrez 2c2 — V117: delegación temporal de funciones

## Objetivo

Formalizar como política interna la regla acordada para el equipo 2c2: si un compañero queda **confirmado como desconectado**, el integrante activo puede actuar temporalmente en el asiento del compañero, solicitar tablas sin su aprobación y rendirse por el equipo. Cuando el compañero vuelve a conectarse, recupera su asiento y se revoca la delegación automáticamente.

## Implementación

Nuevo módulo `domain/online/team_control_delegation.gd`:

- Registra equipos con dos miembros, impide duplicar jugadores entre equipos y evita IDs repetidos.
- Diferencia `connected`, `grace_period` y `disconnected`. Durante el periodo de gracia no transfiere el control.
- Solo permite controlar el asiento del compañero cuando su estado es `disconnected` y el actor sigue conectado y pertenece al mismo equipo.
- En reconexión, el control delegado se revoca por derivarse del estado actual, sin una bandera que pueda quedarse atascada.
- Expone si el compañero debe aprobar una petición de tablas. Esa aprobación deja de ser necesaria solo cuando está confirmado desconectado.
- Bloquea movimientos, petición de tablas y rendición después de marcar la partida como finalizada.
- No abre sockets ni autentica identidades. En una futura arquitectura online, el servidor debe verificar al actor y llamar a esta política con estados de sesión confiables.

## Pruebas

- `tests/v117_team_control_delegation_tests.gd`: **32/32 aprobadas**.
- `tests/v116_disconnect_policy_tests.gd`: **18/18 aprobadas**.
- `tests/run_tests.gd`: **42/42 aprobadas**.
- `tests/v112_rules_input_tests.gd`: **11/11 aprobadas**.
- `tests/nexus_team_tests.gd`: **27/27 aprobadas**.
- `tests/nexus_v2_tests.gd`: **10/10 aprobadas**.
- `tests/competitive_system_tests.gd`: **34/34 aprobadas**.
- `tests/v114_transition_tests.gd`: **13/13 aprobadas**.
- `tests/v115_result_idempotency_tests.gd`: **6/6 aprobadas**.

Total aritmético de las suites listadas: **193 aprobaciones**, con solapamiento entre suites; no son necesariamente 193 casos únicos.

## Limitaciones y decisiones pendientes

- La delegación se prueba como política aislada; todavía no se ha conectado al controlador real de turnos, la interfaz, el flujo de petición de tablas o un servidor online.
- El backend debe autenticar al jugador, asociar las sesiones a los asientos y serializar las acciones para evitar carreras entre reconexión y movimiento.
- El diseño actual trata la delegación como disponible solo después de estado `disconnected`, no durante `grace_period`, para evitar transferencias prematuras por pérdida temporal de paquetes.
- La solicitud de tablas sigue siendo una solicitud al rival según el flujo existente; la política solo elimina la necesidad de aprobación del compañero desconectado. No concede tablas automáticas.
- La rendición del miembro activo termina el equipo completo; una reconexión tardía no debe reabrir el encuentro.
- Sin pruebas en Android físico ni un backend real, no se declara lista la función para producción.

## Dictamen

La política y sus regresiones pasan en Godot 4.7.2. Es una base interna preparada para integrar, no una función online ya desplegada. Próximo paso: enlazar autorización con el servicio real de turnos y el flujo social/resultado, con pruebas de eventos simultáneos (reconexión y movimiento en el mismo instante).
