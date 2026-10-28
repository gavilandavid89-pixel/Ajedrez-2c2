# Ajedrez 2c2 — V121: separar conexión y partido

## Decisión de arquitectura
La conexión es estado de la vista/sesión del cliente; el partido es estado autoritativo independiente. Perder la conexión de un visor no borra, pausa, reinicia ni modifica por sí mismo el tablero, el turno, los relojes, el historial o el resultado.

## Implementación
Se añadió `domain/online/match_view_session.gd`, que solo administra la conexión del visor, la ruta de pantalla y la revisión del snapshot recibido. No contiene lógica de movimiento ni muta el estado de ajedrez.

- La reconexión a una partida en curso dirige a `live_match` usando el snapshot actual.
- La reconexión a una partida terminada dirige a `match_result` y conserva el resultado recibido.
- Los snapshots viejos se rechazan para que una vista atrasada no reemplace otra más reciente.
- Desconectar o reconectar al visor no modifica el diccionario de estado de la partida.
- El módulo no abre sockets ni declara que ya exista backend; el futuro servidor deberá proporcionar snapshots autenticados y persistidos.

La política de delegación 2c2 sigue separada: el estado de conexión puede originar un evento confiable para esa política, pero la capa de visualización no decide jugadas ni resultados.

## Pruebas V121
Nueva suite `tests/v121_match_view_session_tests.gd`: 17/17 aprobadas.

Se validó en Godot 4.7.2 headless, además de las suites de regresión existentes seleccionadas.

## Límites
No es un servidor de partidas ni persistencia online. El snapshot se pasa como entrada para poder probar la frontera de arquitectura. La integración futura debe validar identidad, permisos, revisión de estado y autoridad del servidor.
