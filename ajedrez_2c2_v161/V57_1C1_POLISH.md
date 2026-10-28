# V57 — Pulido competitivo 1c1 + revisión móvil

## Objetivo
Reforzar la identidad competitiva del 1c1 y mejorar su presentación en móvil sin modificar ninguna regla ni mecánica del 2c2.

## Cambios
- El menú principal muestra en 1c1 rating, liga, copas, V/D/T, racha y distancia a la siguiente liga.
- Barra visual de progreso de liga exclusiva para 1c1.
- El selector online 1c1 muestra el contexto competitivo antes de entrar.
- Matchmaking 1c1 corregido para móviles estrechos: la tarjeta ya no conserva un mínimo de escritorio.
- Matchmaking 1c1 incorpora barra de progreso visual adaptada al tema.
- En móvil 1c1, el indicador de turno se compacta a `TU TURNO` / `TURNO RIVAL` para conservar espacio sobre el tablero.
- Perfil/menú móvil reserva espacio superior suficiente para que el avatar no tape el título.
- Se añadió la prueba V57 de presentación 1c1.
- Se añadieron capturas y script de showcase para revisión visual.

## Límites respetados
- No se modificaron turnos, equipos, compañeros, reglas de movimiento, legalidad, victoria/derrota, comunicación ni sugerencias del 2c2.
- No se cambió la mecánica Sugerir.
- El contexto de 2c2 en el selector online conserva su introducción original.

## QA Godot 4.7.2
- V57 presentación 1c1: 5/5.
- Competitivo y separación 1c1/2c2: 34/34.
- Online setup: 37/37.
- UI regression: 53/53.
- Responsive mode menu: 27/27.
- Responsive touch targets: 30/30.
- Movement/Bot regression: 22/22.
- Core: 39/39.
- Capturas visuales revisadas a 360x640 con renderizado OpenGL mediante Xvfb.

## Nota de entorno
Godot muestra ocasionalmente advertencias `ObjectDB leaked` al cerrar algunas suites de prueba. Las aserciones funcionales correspondientes pasan; no se detectó una regresión funcional asociada a esas advertencias.
