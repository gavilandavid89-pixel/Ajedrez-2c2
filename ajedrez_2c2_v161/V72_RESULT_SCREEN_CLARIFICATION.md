# V72 — Resultado de partida + amistad limpia

## Cambios
- La pantalla final ya no contiene una lista de perfiles/historial de jugadores.
- El historial del Inicio conserva los iconos de pareja y rivales como accesos a sus perfiles.
- Se eliminó completamente el texto/indicador de NEXUS de pareja del resultado.
- La amistad en el resultado usa un pequeño botón `+` superpuesto al avatar de jugadores que no son el usuario.
- No se añadieron botones grandes de “Añadir amigo”.
- Si el jugador perdió, aparece `REVANCHA` habilitado para solicitarla.
- Si el jugador ganó, aparece `ACEPTAR` deshabilitado y gris hasta que llegue una solicitud de revancha.
- Se añadió `set_rematch_requested(bool)` al módulo de resultado para activar ACEPTAR cuando el rival realmente solicite revancha.
- Se conserva el scroll vertical y la animación de ensamblaje del menú.
- El tablero sigue bloqueado al finalizar.

## QA
- Core: 39/39
- Arquitectura: 59/59
- Social V70: 35/35
- Social extendido V71: 9/9
- Resultado actualizado: 10/10
- Importación Godot 4.7.2: OK

## Nota
Los runners antiguos de navegación que requieren una escena o contexto específico no se consideran parte del QA de esta corrección; no se modificaron las mecánicas de 2c2.
